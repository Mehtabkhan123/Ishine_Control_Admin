import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_orders_model.dart';
import '../models/get_single_order_model.dart' show GetSingleOrderModel;

/// Response wrapper containing parsed orders list and pagination headers metadata.
class OrdersResponse {
  final List<GET_Orders_Model> orders;
  final int totalOrders;
  final int totalPages;

  const OrdersResponse({
    required this.orders,
    this.totalOrders = 0,
    this.totalPages = 1,
  });
}

/// Service responsible for WooCommerce Orders REST API v3 operations:
/// `GET {{baseUrl}}/wp-json/wc/v3/orders?per_page=20&page=1&orderby=date&order=desc`
class OrdersService {
  final Dio _dio;

  OrdersService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Fetches a paginated list of orders from WooCommerce:
  /// `GET /wp-json/wc/v3/orders`
  ///
  /// - [page]: Dynamic page index (1-based).
  /// - [perPage]: Items per page (default: 20).
  /// - [orderby]: Sort field (default: `'date'`).
  /// - [order]: Sort direction (default: `'desc'`).
  /// - [status]: Optional status filter (e.g. `'processing'`, `'completed'`, etc.).
  /// - [search]: Optional search query string.
  Future<OrdersResponse> fetchOrders({
    int page = 1,
    int perPage = 20,
    String orderby = 'date',
    String order = 'desc',
    String? status,
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

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toLowerCase();
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.orders}';

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
        message: 'Network connection failed while fetching orders: ${e.toString()}',
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

      final List<GET_Orders_Model> orders = [];
      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map<String, dynamic>) {
            orders.add(GET_Orders_Model.fromJson(item));
          }
        }
      }

      final totalOrdersStr = response.headers.value('x-wp-total');
      final totalPagesStr = response.headers.value('x-wp-totalpages');

      final totalOrders = int.tryParse(totalOrdersStr ?? '') ?? orders.length;
      final totalPages = int.tryParse(totalPagesStr ?? '') ?? 1;

      return OrdersResponse(
        orders: orders,
        totalOrders: totalOrders,
        totalPages: totalPages,
      );
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse orders list: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches a single order by ID from WooCommerce:
  /// `GET /wp-json/wc/v3/orders/{{orderId}}`
  Future<GetSingleOrderModel> fetchSingleOrder(
    int orderId, {
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.order(orderId)}';

    Response response;
    try {
      response = await _dio.get(
        requestUri,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
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
            'Network connection failed while fetching order #$orderId: ${e.toString()}',
      );
    }

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      final errorData = response.data;
      String errorMessage = 'Server responded with HTTP $statusCode';
      if (statusCode == 404) {
        errorMessage = 'Order #$orderId was not found on your WooCommerce store.';
      } else if (errorData is Map<String, dynamic> &&
          errorData['message'] != null) {
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
        return GetSingleOrderModel.fromJson(rawData);
      } else {
        throw const FormatException(
            'Expected JSON object response for single order');
      }
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse order #$orderId response: ${e.toString()}',
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
