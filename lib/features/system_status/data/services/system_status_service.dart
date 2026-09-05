import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/network_exceptions.dart';
import '../models/system_status_model.dart';


/// Authentication strategy for WooCommerce REST API requests.
enum WooCommerceAuthMode {
  /// Basic Auth transmitted via `Authorization: Basic base64(key:secret)` header (Recommended for HTTPS).
  header,

  /// Basic Auth transmitted via URL query parameters `?consumer_key=...&consumer_secret=...`.
  /// Useful when reverse proxies strip Authorization headers or on HTTP connections.
  queryParameters,

  /// Automatically picks [header] for HTTPS, and [queryParameters] for non-SSL HTTP.
  auto,
}

/// Exception thrown specifically when response payload fails JSON deserialization.
class WooCommerceParseException extends WooCommerceException {
  final dynamic originalData;
  final StackTrace? stackTrace;

  const WooCommerceParseException({
    required super.message,
    super.statusCode,
    this.originalData,
    this.stackTrace,
  }) : super(errorData: originalData);

  @override
  String toString() => 'WooCommerceParseException: $message (statusCode: $statusCode)';
}

/// API Service responsible for querying WooCommerce System Status endpoint:
/// `GET {{baseUrl}}/wp-json/wc/v3/system_status`
class SystemStatusService {
  final Dio _dio;

  SystemStatusService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches system status details from WooCommerce v3 REST API.
  ///
  /// - [baseUrl]: Optional override for store URL (defaults to [EnvConfig.baseUrl]).
  /// - [consumerKey]: Optional override for API consumer key (defaults to [EnvConfig.consumerKey]).
  /// - [consumerSecret]: Optional override for API consumer secret (defaults to [EnvConfig.consumerSecret]).
  /// - [authMode]: Specifies header-based or query-parameter-based auth (defaults to [WooCommerceAuthMode.auto]).
  /// - [cancelToken]: Allows cancellation of in-flight HTTP request.
  Future<GETSystemStatusModel> fetchSystemStatus({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Resolve effective connection configuration
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
        message: 'WooCommerce Consumer Key or Consumer Secret is missing.',
      );
    }

    // 2. Resolve Auth Mode (Auto detects SSL & Flutter Web CORS compatibility)
    final isHttps = effectiveBaseUrl.toLowerCase().startsWith('https://');
    final resolvedAuthMode = (authMode == WooCommerceAuthMode.auto)
        ? (kIsWeb
              ? WooCommerceAuthMode.queryParameters
              : (isHttps ? WooCommerceAuthMode.header : WooCommerceAuthMode.queryParameters))
        : authMode;

    // 3. Assemble Request Headers & Query Parameters
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.systemStatus}';

    // 4. Dispatch HTTP Request
    Response response;
    try {
      response = await _dio.get(
        requestUri,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true, // Validate status manually below
          sendTimeout: kIsWeb ? null : const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
        cancelToken: cancelToken,
      );

    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message: 'Network connection failed: ${e.toString()}',
      );
    }

    // 5. Evaluate HTTP Response Status Code
    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      final errorData = response.data;
      String errorMessage = 'Server responded with HTTP $statusCode';

      if (errorData is Map<String, dynamic>) {
        if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        } else if (errorData['code'] != null) {
          errorMessage = 'WooCommerce Error: ${errorData['code']}';
        }
      }

      if (statusCode == 401) {
        throw WooCommerceException(
          message: 'Authentication failed (401). Verify your Consumer Key and Consumer Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message: 'Access forbidden (403). Ensure the API key has Read permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode == 404) {
        throw WooCommerceException(
          message: 'System status endpoint not found (404). Verify the store URL and WooCommerce installation.',
          statusCode: 404,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message: 'Server internal error ($statusCode). Check WordPress server logs.',
          statusCode: statusCode,
          errorData: errorData,
        );
      } else {
        throw WooCommerceException(
          message: errorMessage,
          statusCode: statusCode,
          errorData: errorData,
        );
      }
    }

    // 6. Parse JSON Payload into GETSystemStatusModel
    try {
      dynamic rawData = response.data;
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      if (rawData is! Map<String, dynamic>) {
        throw WooCommerceParseException(
          message: 'Expected JSON object for system status but received ${rawData.runtimeType}',
          statusCode: statusCode,
          originalData: rawData,
        );
      }

      return GETSystemStatusModel.fromJson(rawData);
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse WooCommerce system status JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Removes trailing slash from base URL if present.
  static String _sanitizeBaseUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
