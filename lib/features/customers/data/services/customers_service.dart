import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_customers_model.dart';
import '../models/get_single_customers_model.dart';

/// Response wrapper containing parsed customers list and pagination headers metadata.
class CustomersResponse {
  final List<GETCustomersModel> customers;
  final int totalCustomers;
  final int totalPages;

  const CustomersResponse({
    required this.customers,
    this.totalCustomers = 0,
    this.totalPages = 1,
  });
}

/// Service responsible for WooCommerce Customers REST API v3 operations:
/// `GET {{baseUrl}}/wp-json/wc/v3/customers?per_page=20&page=1&orderby=registered_date&order=desc`
class CustomersService {
  final Dio _dio;

  CustomersService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Fetches a paginated list of customers from WooCommerce:
  /// `GET /wp-json/wc/v3/customers`
  ///
  /// - [page]: Dynamic page index (1-based, default: 1).
  /// - [perPage]: Items per page (default: 20).
  /// - [orderby]: Sort field (default: `'registered_date'`).
  /// - [order]: Sort direction (default: `'desc'`).
  /// - [role]: Optional customer role filter (e.g. `'customer'`, `'subscriber'`, `'administrator'`).
  /// - [search]: Optional search query string.
  Future<CustomersResponse> fetchCustomers({
    int page = 1,
    int perPage = 20,
    String orderby = 'registered_date',
    String order = 'desc',
    String? role,
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
            'WooCommerce Consumer Key or Consumer Secret is missing. Please configure credentials.',
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
      'orderby': orderby,
      'order': order,
    };

    if (role != null && role.isNotEmpty && role.toLowerCase() != 'all') {
      queryParams['role'] = role.toLowerCase();
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.customers}';

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
            'Network connection failed while fetching customers: ${e.toString()}',
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

      final List<GETCustomersModel> customers = [];
      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map<String, dynamic>) {
            customers.add(GETCustomersModel.fromJson(item));
          }
        }
      }

      final totalCustomersStr = response.headers.value('x-wp-total');
      final totalPagesStr = response.headers.value('x-wp-totalpages');

      final totalCustomers =
          int.tryParse(totalCustomersStr ?? '') ?? customers.length;
      final totalPages = int.tryParse(totalPagesStr ?? '') ?? 1;

      return CustomersResponse(
        customers: customers,
        totalCustomers: totalCustomers,
        totalPages: totalPages,
      );
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse customers list: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches a single customer by ID from WooCommerce:
  /// `GET /wp-json/wc/v3/customers/{{customerId}}`
  Future<GETSingleCustomersModel> fetchSingleCustomer(
    int customerId, {
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
            'WooCommerce Consumer Key or Consumer Secret is missing. Please configure credentials.',
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.customer(customerId)}';

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
            'Network connection failed while fetching customer #$customerId: ${e.toString()}',
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
        return GETSingleCustomersModel.fromJson(rawData);
      }

      throw const FormatException('Expected JSON object for customer response');
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse customer details: ${e.toString()}',
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
