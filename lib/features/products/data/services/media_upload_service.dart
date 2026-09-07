import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/post_create_model.dart';

/// Service for uploading media files for WooCommerce products.
///
/// Features a dual-strategy upload pipeline:
/// 1. Direct WordPress Media API (`POST /wp-json/wp/v2/media`) when a WordPress
///    Application Password (`WORDPRESS_APP_PASSWORD`) is configured.
/// 2. High-speed, secure image staging fallback via FreeImage CDN when only
///    standard WooCommerce REST API keys are present (or if WordPress denies
///    direct media endpoint access with HTTP 401).
///
/// When an image is staged with a direct HTTPS image URL, WooCommerce automatically
/// downloads (sideloads) the image into the store's WordPress media repository
/// (`wp-content/uploads/`) and creates a permanent local attachment ID upon product save.

class MediaUploadService {
  final Dio _dio;
  final Dio _externalDio;

  static const String _freeImageApiKey = '6d207e02198a847aa98d0a2a901485a5';
  static const String _freeImageUrl = 'https://freeimage.host/api/1/upload';

  MediaUploadService({Dio? dio, Dio? externalDio})
    : _dio = dio ?? Dio(),
      _externalDio = externalDio ?? dio ?? Dio();

  /// Uploads image bytes and returns a [ProductImageRef] containing either
  /// the created WordPress media attachment ID and/or the public direct image URL.
  Future<ProductImageRef> uploadMedia({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);

    if (effectiveBaseUrl.isEmpty) {
      throw const WooCommerceException(
        message: 'Base URL is empty. Please configure WOOCOMMERCE_BASE_URL.',
      );
    }

    if (bytes.isEmpty) {
      throw const WooCommerceException(
        message: 'Selected image file is empty (0 bytes).',
        statusCode: 400,
      );
    }

    // Strategy 1: If WordPress Application Password credentials are provided,
    // attempt direct WordPress media upload to /wp-json/wp/v2/media.
    if (EnvConfig.hasWordpressAppPassword) {
      try {
        final directRef = await _uploadDirectToWordPress(
          bytes: bytes,
          filename: filename,
          effectiveBaseUrl: effectiveBaseUrl,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
        return directRef;
      } catch (e) {
        debugPrint('[MediaUploadService] Direct WordPress upload failed ($e)');
        if (kIsWeb) {
          // On Web, browsers block third-party staging hosts with CORS errors.
          // Directly surface the credentials/upload error so the admin can fix it.
          if (e is WooCommerceException) rethrow;
          throw WooCommerceException(
            statusCode: 401,
            message:
                'Direct WordPress media upload failed: ${e.toString()}. Please check your WordPress username and Application Password.',
          );
        }
        debugPrint('[MediaUploadService] Falling back to staging gateway.');
      }
    } else if (kIsWeb) {
      // On Web, direct upload is required because browser CORS blocks anonymous CDN staging.
      throw const WooCommerceException(
        statusCode: 401,
        message:
            'WordPress Application Password required for browser image uploads. Please configure your WordPress credentials.',
      );
    }

    // Strategy 2: Image Staging Gateway fallback (for mobile/desktop platforms).
    // Staging allows device gallery images to be uploaded to a secure CDN and
    // handed to WooCommerce as public URLs, which WooCommerce then downloads
    // and binds permanently into the WordPress media library.

    return await _uploadViaStagingGateway(
      bytes: bytes,
      filename: filename,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  /// Attempts direct upload to WordPress Media API (/wp-json/wp/v2/media).
  Future<ProductImageRef> _uploadDirectToWordPress({
    required Uint8List bytes,
    required String filename,
    required String effectiveBaseUrl,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final mimeType = _lookupMimeType(filename);
    final user = EnvConfig.wordpressUsername;
    final pass = EnvConfig.wordpressAppPassword;
    final credentials = '$user:$pass';
    final encodedAuth = base64Encode(utf8.encode(credentials));

    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Authorization': 'Basic $encodedAuth',
      'Content-Disposition': 'attachment; filename="$filename"',
      'Content-Type': mimeType,
    };

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.media}';

    final response = await _dio.post(
      requestUri,
      data: bytes,
      options: Options(
        headers: headers,
        responseType: ResponseType.json,
        validateStatus: (status) => true,
        sendTimeout: kIsWeb ? null : const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
      cancelToken: cancelToken,
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      String? detailMsg;
      if (response.data is Map && response.data['message'] != null) {
        detailMsg = response.data['message'].toString();
      }

      throw WooCommerceException(
        message: statusCode == 401
            ? 'WordPress Media upload unauthorized (401)${detailMsg != null ? ': $detailMsg' : ''}. Ensure your WordPress username has upload permissions and the Application Password is valid.'
            : 'WordPress media upload rejected with HTTP $statusCode${detailMsg != null ? ': $detailMsg' : ''}',
        statusCode: statusCode,
        errorData: response.data,
      );
    }

    dynamic rawData = response.data;
    if (rawData is String) {
      rawData = jsonDecode(rawData);
    }

    if (rawData is Map<String, dynamic>) {
      final id = rawData['id'] is int
          ? rawData['id'] as int
          : int.tryParse(rawData['id']?.toString() ?? '');
      final src =
          rawData['source_url']?.toString() ??
          (rawData['guid'] is Map
              ? rawData['guid']['rendered']?.toString()
              : null);

      return ProductImageRef(id: id, src: src, name: filename);
    }

    throw WooCommerceParseException(
      message: 'Unexpected response from WordPress media endpoint.',
      statusCode: statusCode,
      originalData: rawData,
    );
  }

  /// Staging upload fallback: Uploads image bytes to FreeImage.host CDN.
  /// Returns a direct image URL which WooCommerce automatically imports into WordPress media library.
  Future<ProductImageRef> _uploadViaStagingGateway({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final base64Image = base64Encode(bytes);
      final formData = FormData.fromMap({
        'key': _freeImageApiKey,
        'action': 'upload',
        'source': base64Image,
        'format': 'json',
      });

      final response = await _externalDio.post(
        _freeImageUrl,
        data: formData,
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) => true,
          sendTimeout: kIsWeb ? null : const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
        onSendProgress: kIsWeb
            ? null
            : (sent, total) {
                if (total > 0 && onProgress != null) {
                  onProgress(sent / total);
                }
              },
        cancelToken: cancelToken,
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        dynamic data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        if (data is Map &&
            data['image'] != null &&
            data['image']['url'] != null) {
          final directUrl = data['image']['url'].toString();
          return ProductImageRef(src: directUrl, name: filename);
        }
      }

      String? errorMsg;
      if (response.data is Map) {
        final err = response.data['error'];
        if (err is Map && err['message'] != null) {
          errorMsg = err['message'].toString();
        }
      }

      throw WooCommerceException(
        message:
            'Image staging upload failed (HTTP $statusCode)${errorMsg != null ? ': $errorMsg' : ''}.',
        statusCode: statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      if (e is WooCommerceException) rethrow;
      throw WooCommerceException(
        message: 'Failed to upload image from device: ${e.toString()}',
      );
    }
  }

  static String _sanitizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _lookupMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'image/jpeg';
  }
}
