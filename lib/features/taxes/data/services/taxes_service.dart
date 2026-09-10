import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_tax_rates_model.dart';
import '../models/post_tax_rates_model.dart';

/// Response wrapper containing parsed tax rates list and pagination metadata.
class TaxRatesResponse {
  final List<GetTaxRatesModel> taxRates;
  final int totalTaxRates;
  final int totalPages;

  const TaxRatesResponse({
    required this.taxRates,
    this.totalTaxRates = 0,
    this.totalPages = 1,
  });
}

/// Service responsible for WooCommerce Tax Rates REST API v3 operations:
/// `GET {{baseUrl}}/wp-json/wc/v3/taxes?per_page=50&page=1`
class TaxesService {
  final Dio _dio;

  TaxesService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Fetches a paginated list of WooCommerce tax rates:
  /// `GET /wp-json/wc/v3/taxes?per_page=50&page=1`
  ///
  /// - [page]: Dynamic page index (1-based, default: 1).
  /// - [perPage]: Items per page (default: 50).
  /// - [taxClass]: Optional tax class filter (e.g. `'standard'`, `'reduced-rate'`).
  /// - [search]: Optional search query.
  Future<TaxRatesResponse> fetchTaxRates({
    int page = 1,
    int perPage = 50,
    String? taxClass,
    String? search,
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

    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (taxClass != null && taxClass.trim().isNotEmpty && taxClass.toLowerCase() != 'all') {
      queryParams['class'] = taxClass.trim().toLowerCase();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.taxes}';

    Response response;
    try {
      response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
          sendTimeout: kIsWeb ? null : const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while fetching tax rates: ${e.toString()}',
      );
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      final errorData = response.data;
      String errorMessage = 'Server responded with HTTP $statusCode';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
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

      final List<GetTaxRatesModel> taxRates = [];
      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map<String, dynamic>) {
            taxRates.add(GetTaxRatesModel.fromJson(item));
          }
        }
      }

      final totalTaxRatesStr = response.headers.value('x-wp-total');
      final totalPagesStr = response.headers.value('x-wp-totalpages');

      final totalTaxRates = int.tryParse(totalTaxRatesStr ?? '') ?? taxRates.length;
      final totalPages = int.tryParse(totalPagesStr ?? '') ?? 1;

      return TaxRatesResponse(
        taxRates: taxRates,
        totalTaxRates: totalTaxRates,
        totalPages: totalPages,
      );
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse tax rates list: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches a single tax rate by ID:
  /// `GET /wp-json/wc/v3/taxes/{{taxRateId}}`
  Future<GetTaxRatesModel> fetchTaxRate(
    int taxRateId, {
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.tax(taxRateId)}';

    Response response;
    try {
      response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
          sendTimeout: kIsWeb ? null : const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while fetching tax rate #$taxRateId: ${e.toString()}',
      );
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      final errorData = response.data;
      String errorMessage = 'Server responded with HTTP $statusCode';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
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

      if (rawData is Map<String, dynamic>) {
        return GetTaxRatesModel.fromJson(rawData);
      } else {
        throw const FormatException('Expected JSON object for tax rate');
      }
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse tax rate #$taxRateId: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Creates a new tax rate via WooCommerce REST API v3:
  /// `POST /wp-json/wc/v3/taxes`
  Future<PostTaxRatesModel> createTaxRate(
    PostTaxRatesModel taxRate, {
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.taxes}';
    final payload = taxRate.toCreateJson();

    Response response;
    try {
      response = await _dio.post(
        requestUri,
        data: payload,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
          sendTimeout: kIsWeb ? null : const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while creating tax rate: ${e.toString()}',
      );
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode != 201 && (statusCode < 200 || statusCode >= 300)) {
      final errorData = response.data;
      String errorMessage = 'Server responded with HTTP $statusCode';
      if (errorData is Map<String, dynamic> && errorData['message'] != null) {
        errorMessage = errorData['message'].toString();
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

      if (rawData is Map<String, dynamic>) {
        return PostTaxRatesModel.fromJson(rawData);
      } else {
        throw const FormatException('Expected JSON object for created tax rate');
      }
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse created tax rate response: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
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
}
