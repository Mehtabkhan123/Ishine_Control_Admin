import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_payment_gateways_model.dart';
import '../models/put_update_payment_gateways_model.dart';

/// Service responsible for WooCommerce Payment Gateways REST API v3 operations:
/// `GET {{baseUrl}}/wp-json/wc/v3/payment_gateways`
/// `PUT {{baseUrl}}/wp-json/wc/v3/payment_gateways/{{id}}`
class PaymentGatewaysService {
  final Dio _dio;

  PaymentGatewaysService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Fetches all WooCommerce payment gateways:
  /// `GET /wp-json/wc/v3/payment_gateways`
  Future<List<GetPaymentGatewaysModel>> fetchPaymentGateways({
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

    final endpoint = '$effectiveBaseUrl${ApiEndpoints.paymentGateways}';

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
                GetPaymentGatewaysModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        try {
          final decoded = json.decode(rawData);
          if (decoded is List) {
            return decoded
                .map((item) => GetPaymentGatewaysModel.fromJson(
                    item as Map<String, dynamic>))
                .toList();
          }
        } catch (e, st) {
          throw WooCommerceParseException(
            message: 'Failed to parse payment gateways response string.',
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
        message: 'Unexpected error fetching payment gateways: $e',
      );
    }
  }

  /// Fetches a single payment gateway by ID:
  /// `GET /wp-json/wc/v3/payment_gateways/<id>`
  Future<GetPaymentGatewaysModel> fetchPaymentGateway(
    String id, {
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

    final endpoint =
        '$effectiveBaseUrl${ApiEndpoints.paymentGateway(Uri.encodeComponent(id))}';

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
        return GetPaymentGatewaysModel.fromJson(rawData);
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        final decoded = json.decode(rawData);
        if (decoded is Map<String, dynamic>) {
          return GetPaymentGatewaysModel.fromJson(decoded);
        }
      }

      throw WooCommerceParseException(
        message: 'Invalid payment gateway payload format received.',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on DioException catch (dioErr) {
      throw WooCommerceException.fromDioException(dioErr);
    } on WooCommerceException {
      rethrow;
    } catch (e) {
      throw WooCommerceException(
        message: 'Unexpected error fetching payment gateway #$id: $e',
      );
    }
  }

  /// Updates an existing payment gateway by dynamic ID:
  /// `PUT /wp-json/wc/v3/payment_gateways/{{id}}`
  Future<PutUpdatePaymentGatewaysModel> updatePaymentGateway({
    required String id,
    required Map<String, dynamic> data,
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
      'Content-Type': 'application/json',
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

    final endpoint =
        '$effectiveBaseUrl${ApiEndpoints.paymentGateway(Uri.encodeComponent(id))}';

    try {
      final response = await _dio.put(
        endpoint,
        data: data,
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
        return PutUpdatePaymentGatewaysModel.fromJson(rawData);
      } else if (rawData is String && rawData.trim().isNotEmpty) {
        final decoded = json.decode(rawData);
        if (decoded is Map<String, dynamic>) {
          return PutUpdatePaymentGatewaysModel.fromJson(decoded);
        }
      }

      throw WooCommerceParseException(
        message: 'Invalid payment gateway update response received.',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on DioException catch (dioErr) {
      throw WooCommerceException.fromDioException(dioErr);
    } on WooCommerceException {
      rethrow;
    } catch (e) {
      throw WooCommerceException(
        message: 'Unexpected error updating payment gateway #$id: $e',
      );
    }
  }

  /// Sanitizes base URL by stripping trailing slashes
  String _sanitizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Extracts human-readable error messages from WooCommerce REST API errors
  String _extractErrorMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      if (data['message'] != null && data['message'].toString().isNotEmpty) {
        return data['message'].toString();
      }
      if (data['code'] != null) {
        return 'Error: ${data['code']} ($statusCode)';
      }
    }
    return 'WooCommerce request failed with status code $statusCode';
  }
}
