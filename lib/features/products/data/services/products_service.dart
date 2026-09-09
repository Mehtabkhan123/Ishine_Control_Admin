import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/post_create_model.dart';
import '../models/put_update_model.dart';

/// API Service responsible for WooCommerce Products REST API v3 operations:
/// - POST `/wp-json/wc/v3/products` (Create product)
/// - PUT `/wp-json/wc/v3/products/{{id}}` (Update product)
/// - GET `/wp-json/wc/v3/products/{{id}}` (Get single product)
/// - GET `/wp-json/wc/v3/products` (List / query products)
/// - GET `/wp-json/wc/v3/products/categories` (List product categories)
/// - GET `/wp-json/wc/v3/products/tags` (List product tags)

class ProductsService {
  final Dio _dio;

  ProductsService({Dio? dio}) : _dio = dio ?? Dio();

  /// Updates an existing product in WooCommerce:
  /// `PUT {{baseUrl}}/wp-json/wc/v3/products/{{productId}}`
  ///
  /// Sends only valid writable fields, omitting read-only response properties.
  Future<PutUpdateModel> updateProduct({
    required int productId,
    required PutUpdateModel product,
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
      'Content-Type': 'application/json; charset=utf-8',
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.product(productId)}';
    final payload = product.toUpdatePayload();

    Response response;
    try {
      if (kIsWeb) {
        final webParams = Map<String, dynamic>.from(queryParams);
        webParams['_method'] = 'PUT';
        response = await _dio.post(
          requestUri,
          data: payload,
          queryParameters: webParams,
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (status) => true,
            sendTimeout: null,
            receiveTimeout: const Duration(seconds: 30),
          ),
          cancelToken: cancelToken,
        );
      } else {
        response = await _dio.put(
          requestUri,
          data: payload,
          queryParameters: queryParams,
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (status) => true,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
          cancelToken: cancelToken,
        );
      }
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while updating product #$productId: ${e.toString()}',
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

      if (statusCode == 400) {
        throw WooCommerceException(
          message: 'Invalid update data: $errorMessage',
          statusCode: 400,
          errorData: errorData,
        );
      } else if (statusCode == 401) {
        throw WooCommerceException(
          message:
              'Authentication failed (401). Verify your Consumer Key and Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Write permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode == 404) {
        throw WooCommerceException(
          message: 'Product #$productId not found (404).',
          statusCode: 404,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message:
              'WooCommerce server error ($statusCode) while updating product.',
          statusCode: statusCode,
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

      if (rawData is Map<String, dynamic>) {
        return PutUpdateModel.fromJson(rawData);
      }

      throw WooCommerceParseException(
        message:
            'Unexpected response format from product update: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse updated product JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches a single product by ID:
  /// `GET {{baseUrl}}/wp-json/wc/v3/products/{{productId}}`
  Future<PutUpdateModel> fetchProductById({
    required int productId,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

    if (effectiveBaseUrl.isEmpty ||
        effectiveKey.isEmpty ||
        effectiveSecret.isEmpty) {
      throw const WooCommerceException(
        message: 'WooCommerce configuration is missing or incomplete.',
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.product(productId)}';

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
            'Network connection failed while fetching product #$productId: ${e.toString()}',
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
        return PutUpdateModel.fromJson(rawData);
      }

      throw WooCommerceParseException(
        message:
            'Unexpected payload format for product #$productId: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse product #$productId JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Creates a new product in WooCommerce:
  /// `POST {{baseUrl}}/wp-json/wc/v3/products`
  ///
  /// Sends only valid writable fields, omitting read-only response properties.
  Future<PostCreateModel> createProduct({
    required PostCreateModel product,
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
      'Content-Type': 'application/json; charset=utf-8',
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.products}';
    final payload = product.toCreatePayload();

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
          sendTimeout: kIsWeb ? null : const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while creating product: ${e.toString()}',
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

      if (statusCode == 400) {
        throw WooCommerceException(
          message: 'Invalid product data: $errorMessage',
          statusCode: 400,
          errorData: errorData,
        );
      } else if (statusCode == 401) {
        throw WooCommerceException(
          message:
              'Authentication failed (401). Verify your Consumer Key and Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Write permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message:
              'WooCommerce server error ($statusCode) while saving product.',
          statusCode: statusCode,
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

      if (rawData is Map<String, dynamic>) {
        return PostCreateModel.fromJson(rawData);
      }

      throw WooCommerceParseException(
        message:
            'Unexpected response format from product creation: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse created product JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches products list: `GET {{baseUrl}}/wp-json/wc/v3/products`
  Future<List<PostCreateModel>> fetchProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? status,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

    if (effectiveBaseUrl.isEmpty ||
        effectiveKey.isEmpty ||
        effectiveSecret.isEmpty) {
      throw const WooCommerceException(
        message: 'WooCommerce configuration is missing or incomplete.',
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
      'order': 'desc',
      'orderby': 'date',
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (category != null && category.trim().isNotEmpty && category != 'all') {
      queryParams['category'] = category.trim();
    }
    if (status != null && status.trim().isNotEmpty && status != 'all') {
      queryParams['status'] = status.trim();
    }

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.products}';

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
            'Network connection failed while fetching products: ${e.toString()}',
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

      if (rawData is List) {
        return rawData
            .whereType<Map<String, dynamic>>()
            .map((item) => PostCreateModel.fromJson(item))
            .toList();
      }

      return [];
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse products list JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches product categories: `GET {{baseUrl}}/wp-json/wc/v3/products/categories`
  Future<List<ProductCategoryRef>> fetchCategories({
    int perPage = 100,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

    if (effectiveBaseUrl.isEmpty ||
        effectiveKey.isEmpty ||
        effectiveSecret.isEmpty) {
      return [];
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
      'per_page': perPage,
      'hide_empty': false,
    };

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri =
        '$effectiveBaseUrl${ApiEndpoints.wcV3Prefix}/products/categories';

    try {
      final response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => ProductCategoryRef.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [ProductsService] Failed to load categories: $e');
      return [];
    }
  }

  /// Creates a new product category in WooCommerce:
  /// `POST {{baseUrl}}/wp-json/wc/v3/products/categories`
  Future<ProductCategoryRef> createCategory({
    required ProductCategoryRef category,
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
      'Content-Type': 'application/json; charset=utf-8',
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

    final requestUri =
        '$effectiveBaseUrl${ApiEndpoints.wcV3Prefix}/products/categories';
    final payload = category.toCreateCategoryPayload();

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
          sendTimeout: kIsWeb ? null : const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while creating category: ${e.toString()}',
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

      if (statusCode == 400) {
        throw WooCommerceException(
          message: 'Invalid category data: $errorMessage',
          statusCode: 400,
          errorData: errorData,
        );
      } else if (statusCode == 401) {
        throw WooCommerceException(
          message:
              'Authentication failed (401). Verify your Consumer Key and Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Write permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message:
              'WooCommerce server error ($statusCode) while creating category.',
          statusCode: statusCode,
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

      if (rawData is Map<String, dynamic>) {
        return ProductCategoryRef.fromJson(rawData);
      }

      throw WooCommerceParseException(
        message:
            'Unexpected response format from category creation: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse created category JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Updates an existing product category in WooCommerce:
  /// `PUT {{baseUrl}}/wp-json/wc/v3/products/categories/{{categoryId}}`
  Future<ProductCategoryModel> updateCategory({
    required int categoryId,
    required ProductCategoryModel category,
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
      'Content-Type': 'application/json; charset=utf-8',
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

    final requestUri =
        '$effectiveBaseUrl${ApiEndpoints.productCategory(categoryId)}';
    final payload = category.toUpdatePayload();

    Response response;
    try {
      response = await _dio.put(
        requestUri,
        data: payload,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
          sendTimeout: kIsWeb ? null : const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while updating category #$categoryId: ${e.toString()}',
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

      if (statusCode == 400) {
        throw WooCommerceException(
          message: 'Invalid category data: $errorMessage',
          statusCode: 400,
          errorData: errorData,
        );
      } else if (statusCode == 401) {
        throw WooCommerceException(
          message:
              'Authentication failed (401). Verify your Consumer Key and Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Write permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode == 404) {
        throw WooCommerceException(
          message: 'Category #$categoryId not found (404).',
          statusCode: 404,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message:
              'WooCommerce server error ($statusCode) while updating category.',
          statusCode: statusCode,
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

      if (rawData is Map<String, dynamic>) {
        return ProductCategoryModel.fromJson(rawData);
      }

      throw WooCommerceParseException(
        message:
            'Unexpected response format from category update: ${rawData.runtimeType}',
        statusCode: statusCode,
        originalData: rawData,
      );
    } on WooCommerceParseException {
      rethrow;
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse updated category JSON: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Deletes a product category in WooCommerce:
  /// `DELETE {{baseUrl}}/wp-json/wc/v3/products/categories/{{categoryId}}?force=true`
  Future<bool> deleteCategory({
    required int categoryId,
    bool force = true,
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
    final queryParams = <String, dynamic>{
      'force': force ? 'true' : 'false',
    };

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri =
        '$effectiveBaseUrl${ApiEndpoints.productCategory(categoryId)}';

    Response response;
    try {
      response = await _dio.delete(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
          sendTimeout: kIsWeb ? null : const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(
        message:
            'Network connection failed while deleting category #$categoryId: ${e.toString()}',
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
              'Authentication failed (401). Verify your Consumer Key and Secret.',
          statusCode: 401,
          errorData: errorData,
        );
      } else if (statusCode == 403) {
        throw WooCommerceException(
          message:
              'Access forbidden (403). Ensure the API key has Write permissions.',
          statusCode: 403,
          errorData: errorData,
        );
      } else if (statusCode == 404) {
        throw WooCommerceException(
          message: 'Category #$categoryId not found (404).',
          statusCode: 404,
          errorData: errorData,
        );
      } else if (statusCode >= 500) {
        throw WooCommerceException(
          message:
              'WooCommerce server error ($statusCode) while deleting category.',
          statusCode: statusCode,
          errorData: errorData,
        );
      }

      throw WooCommerceException(
        message: errorMessage,
        statusCode: statusCode,
        errorData: errorData,
      );
    }

    return true;
  }

  /// Fetches product tags: `GET {{baseUrl}}/wp-json/wc/v3/products/tags`
  Future<List<ProductTagRef>> fetchTags({
    int perPage = 100,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final effectiveBaseUrl = _sanitizeBaseUrl(baseUrl ?? EnvConfig.baseUrl);
    final effectiveKey = (consumerKey ?? EnvConfig.consumerKey).trim();
    final effectiveSecret = (consumerSecret ?? EnvConfig.consumerSecret).trim();

    if (effectiveBaseUrl.isEmpty ||
        effectiveKey.isEmpty ||
        effectiveSecret.isEmpty) {
      return [];
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
      'per_page': perPage,
      'hide_empty': false,
    };

    if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
      final credentials = '$effectiveKey:$effectiveSecret';
      final encodedAuth = base64Encode(utf8.encode(credentials));
      headers['Authorization'] = 'Basic $encodedAuth';
    } else {
      queryParams['consumer_key'] = effectiveKey;
      queryParams['consumer_secret'] = effectiveSecret;
    }

    final requestUri =
        '$effectiveBaseUrl${ApiEndpoints.wcV3Prefix}/products/tags';

    try {
      final response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => ProductTagRef.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [ProductsService] Failed to load tags: $e');
      return [];
    }
  }

  /// Fetches media items from the WordPress/WooCommerce media library:
  /// `GET /wp-json/wp/v2/media`
  Future<List<ProductImageRef>> fetchMediaLibrary({
    int page = 1,
    int perPage = 30,
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
      'media_type': 'image',
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (effectiveKey.isNotEmpty && effectiveSecret.isNotEmpty) {
      if (resolvedAuthMode == WooCommerceAuthMode.header && !kIsWeb) {
        final credentials = '$effectiveKey:$effectiveSecret';
        final encodedAuth = base64Encode(utf8.encode(credentials));
        headers['Authorization'] = 'Basic $encodedAuth';
      } else {
        queryParams['consumer_key'] = effectiveKey;
        queryParams['consumer_secret'] = effectiveSecret;
      }
    }

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.media}';

    try {
      final response = await _dio.get(
        requestUri,
        queryParameters: queryParams,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.whereType<Map<String, dynamic>>().map((item) {
          final id = item['id'] is int
              ? item['id'] as int
              : int.tryParse(item['id']?.toString() ?? '');
          final sourceUrl = item['source_url']?.toString() ??
              (item['guid'] is Map
                  ? item['guid']['rendered']?.toString()
                  : null);
          final title = item['title'] is Map
              ? item['title']['rendered']?.toString()
              : item['title']?.toString();
          final alt = item['alt_text']?.toString();

          return ProductImageRef(
            id: id,
            src: sourceUrl,
            name: title,
            alt: alt,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [ProductsService] Failed to load media library: $e');
      return [];
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

