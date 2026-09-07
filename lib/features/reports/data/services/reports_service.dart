import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/sales_report_model.dart';
import '../models/top_seller_model.dart';



/// Service responsible for fetching sales analytics from WooCommerce REST API:
/// `GET {{baseUrl}}/wp-json/wc/v3/reports/sales`
class ReportsService {
  final Dio _dio;

  ReportsService({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches the sales report for a specified period or custom date range.

  /// - [period]: Standard period preset: `'week'`, `'month'`, `'last_month'`, `'year'`. Defaults to `'month'`.
  /// - [dateMin]: Optional start date in `YYYY-MM-DD` format.
  /// - [dateMax]: Optional end date in `YYYY-MM-DD` format.
  /// - [baseUrl]: Optional override for store URL.
  /// - [consumerKey]: Optional override for API key.
  /// - [consumerSecret]: Optional override for API secret.
  /// - [authMode]: Authentication strategy (defaults to [WooCommerceAuthMode.auto]).
  /// - [cancelToken]: For request cancellation.
  Future<GetSalesReportModel?> fetchSalesReport({
    String period = 'month',
    String? dateMin,
    String? dateMax,
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
        message: 'WooCommerce Consumer Key or Consumer Secret is missing.',
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
    final queryParams = <String, dynamic>{'period': period};

    if (dateMin != null && dateMin.isNotEmpty) {
      queryParams['date_min'] = dateMin;
    }
    if (dateMax != null && dateMax.isNotEmpty) {
      queryParams['date_max'] = dateMax;
    }

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.reportsSales}';

    Response response;
    try {
      response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
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
          message:
              'Authentication failed (401). Verify your Consumer Key and Consumer Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Read permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode == 404) {
        throw WooCommerceException(
          message: 'Sales report endpoint not found (404).',
          statusCode: 404,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message:
              'Server internal error ($statusCode). Check WordPress server logs.',
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

    // Parse JSON Payload
    try {
      dynamic rawData = response.data;
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      if (rawData is List) {
        if (rawData.isEmpty) {
          return null;
        }
        final firstItem = rawData.first;
        if (firstItem is Map<String, dynamic>) {
          return GetSalesReportModel.fromJson(firstItem);
        }
      } else if (rawData is Map<String, dynamic>) {
        return GetSalesReportModel.fromJson(rawData);
      }

      throw WooCommerceParseException(
        message:
            'Unexpected payload type for sales report: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse sales report JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches top selling products report from WooCommerce v3:
  /// `GET {{baseUrl}}/wp-json/wc/v3/reports/top_sellers?period=month`
  Future<List<TopSellerModel>> fetchTopSellers({
    String period = 'month',
    String? dateMin,
    String? dateMax,
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
        message: 'WooCommerce Consumer Key or Consumer Secret is missing.',
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
    final queryParams = <String, dynamic>{'period': period};

    if (dateMin != null && dateMin.isNotEmpty) {
      queryParams['date_min'] = dateMin;
    }
    if (dateMax != null && dateMax.isNotEmpty) {
      queryParams['date_max'] = dateMax;
    }

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.reportsTopSellers}';

    Response response;
    try {
      response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
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
          message:
              'Authentication failed (401). Verify your Consumer Key and Consumer Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Read permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode == 404) {
        throw WooCommerceException(
          message: 'Top sellers report endpoint not found (404).',
          statusCode: 404,
          errorData: errorData,
        );
      }

      throw WooCommerceException(
        message: errorMessage,
        statusCode: statusCode,
        errorData: errorData,
      );
    }

    try {
      dynamic rawData = response.data;
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      if (rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map((item) => TopSellerModel.fromJson(item))
            .toList();
      }

      throw WooCommerceParseException(
        message:
            'Unexpected payload type for top sellers report: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse top sellers JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
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

}
