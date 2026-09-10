import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_product_settings_model.dart';

/// Service responsible for WooCommerce Product Settings REST API v3 operations:
/// `GET {{baseUrl}}/wp-json/wc/v3/settings/products`
/// `GET {{baseUrl}}/wp-json/wc/v3/settings/products/{{id}}`
class ProductSettingsService {
  final Dio _dio;

  ProductSettingsService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Fetches all WooCommerce product settings:
  /// `GET /wp-json/wc/v3/settings/products`
  Future<List<GetProductSettingsModel>> fetchProductSettings({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

    if (effectiveBaseUrl.isEmpty) {
      throw const WooCommerceException(
        message: 'Base URL is empty. Please configure WOOCOMMERCE_BASE_URL.',
      );
    }

    if (effectiveKey.isEmpty || effectiveSecret.isEmpty) {
      throw const WooCommerceException(
        message:
            'WooCommerce Consumer Key or Consumer Secret is missing. Please configure store credentials.',
      );
    }

    final isHttps = effectiveBaseUrl.toLowerCase().startsWith('https://');
    final resolvedAuthMode = (authMode == WooCommerceAuthMode.auto)
        ? (kIsWeb
            ? WooCommerceAuthMode.queryParameters
            : (isHttps
                ? WooCommerceAuthMode.header
                : WooCommerceAuthMode.queryParameters))
        : authMode;

    final headers = <String, dynamic>{
      'Accept': 'application/json',
      if (!kIsWeb) 'Content-Type': 'application/json',
    };

    final queryParams = <String, dynamic>{};

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final endpoint = '$effectiveBaseUrl${ApiEndpoints.productSettings}';

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: cancelToken,
      );

      final statusCode = response.statusCode ?? 200;

      if (statusCode >= 400) {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        throw WooCommerceException(
          message: errorMsg,
          statusCode: statusCode,
          errorData: response.data,
        );
      }

      final dynamic rawData = response.data;

      if (rawData is List) {
        return rawData
            .map((item) =>
                GetProductSettingsModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        try {
          final decoded = json.decode(rawData);
          if (decoded is List) {
            return decoded
                .map((item) => GetProductSettingsModel.fromJson(
                    item as Map<String, dynamic>))
                .toList();
          }
        } catch (e, st) {
          throw WooCommerceParseException(
            message: 'Failed to parse product settings response string.',
            statusCode: statusCode,
            originalData: rawData,
            stackTrace: st,
          );
        }
      }

      return [];
    } on DioException catch (dioErr) {
      throw WooCommerceException.fromDioException(dioErr);
    } on WooCommerceException {
      rethrow;
    } catch (e) {
      throw WooCommerceException(
        message: 'Unexpected error fetching product settings: $e',
      );
    }
  }

  /// Fetches a single product setting by ID:
  /// `GET /wp-json/wc/v3/settings/products/<id>`
  Future<GetProductSettingsModel> fetchProductSetting({
    required String id,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

    if (effectiveBaseUrl.isEmpty) {
      throw const WooCommerceException(
        message: 'Base URL is empty. Please configure WOOCOMMERCE_BASE_URL.',
      );
    }

    if (effectiveKey.isEmpty || effectiveSecret.isEmpty) {
      throw const WooCommerceException(
        message:
            'WooCommerce Consumer Key or Consumer Secret is missing. Please configure store credentials.',
      );
    }

    final isHttps = effectiveBaseUrl.toLowerCase().startsWith('https://');
    final resolvedAuthMode = (authMode == WooCommerceAuthMode.auto)
        ? (kIsWeb
            ? WooCommerceAuthMode.queryParameters
            : (isHttps
                ? WooCommerceAuthMode.header
                : WooCommerceAuthMode.queryParameters))
        : authMode;

    final headers = <String, dynamic>{
      'Accept': 'application/json',
      if (!kIsWeb) 'Content-Type': 'application/json',
    };

    final queryParams = <String, dynamic>{};

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final endpoint = '$effectiveBaseUrl${ApiEndpoints.productSetting(id)}';

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: cancelToken,
      );

      final statusCode = response.statusCode ?? 200;

      if (statusCode >= 400) {
        final errorMsg = _extractErrorMessage(response.data, statusCode);
        throw WooCommerceException(
          message: errorMsg,
          statusCode: statusCode,
          errorData: response.data,
        );
      }

      final dynamic rawData = response.data;
      if (rawData is Map<String, dynamic>) {
        return GetProductSettingsModel.fromJson(rawData);
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        final decoded = json.decode(rawData);
        if (decoded is Map<String, dynamic>) {
          return GetProductSettingsModel.fromJson(decoded);
        }
      }

      throw WooCommerceParseException(
        message: 'Invalid payload format for product setting ID: $id',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on DioException catch (dioErr) {
      throw WooCommerceException.fromDioException(dioErr);
    } on WooCommerceException {
      rethrow;
    } catch (e) {
      throw WooCommerceException(
        message: 'Unexpected error fetching product setting $id: $e',
      );
    }
  }

  String _sanitizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String _extractErrorMessage(dynamic data, int statusCode) {
    if (data is Map) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data['code'] != null) {
        return 'WooCommerce API Error (${data['code']})';
      }
    }
    return 'WooCommerce request failed with status code $statusCode';
  }
}
