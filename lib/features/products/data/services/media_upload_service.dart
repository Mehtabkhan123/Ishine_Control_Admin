import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/post_create_model.dart';

/// Service for WooCommerce product image workflow.
///
/// Note: WooCommerce REST API credentials (Consumer Key & Consumer Secret)
/// authenticate `/wp-json/wc/v3/...` endpoints. WordPress core media upload
/// (`/wp-json/wp/v2/media`) requires WordPress user permissions or application passwords.
///
/// In the supported WooCommerce architecture, product images are attached by providing
/// direct image URLs (or existing media IDs) in `images: [ProductImageRef(src: "...")]`
/// when creating or updating products via `POST /wp-json/wc/v3/products` and
/// `PUT /wp-json/wc/v3/products/{id}`. WooCommerce server automatically downloads,
/// processes, and links the image to the product.
class MediaUploadService {
  final Dio _dio;

  MediaUploadService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Handles media upload validation.
  ///
  /// Direct binary upload to `/wp-json/wp/v2/media` is not supported by WooCommerce REST keys.
  /// Instead, WooCommerce natively supports attaching images via public or hosted Image URLs
  /// in the product creation and update payloads.
  Future<ProductImageRef> uploadMedia({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

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

    if (effectiveKey.isEmpty || effectiveSecret.isEmpty) {
      throw const WooCommerceException(
        message:
            'WooCommerce Consumer Key or Consumer Secret is missing. Please configure credentials in Settings or .env.',
        statusCode: 401,
      );
    }

    // Direct binary media upload is not supported by WooCommerce Consumer Key/Secret REST credentials.
    // The supported WooCommerce workflow is attaching images via direct image URLs in product create/update.
    throw const WooCommerceException(
      message:
          'Direct media file upload is not supported by WooCommerce REST API keys. Please use Image URLs to attach product images directly via WooCommerce.',
      statusCode: 405,
    );
  }

  static String _sanitizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
