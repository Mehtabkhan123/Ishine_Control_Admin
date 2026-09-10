import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/shipping_zones_model.dart';

/// Response wrapper containing parsed shipping zones list and pagination metadata.
class ShippingZonesResponse {
  final List<ShippingZonesModel> zones;
  final int totalZones;
  final int totalPages;

  const ShippingZonesResponse({
    required this.zones,
    this.totalZones = 0,
    this.totalPages = 1,
  });
}

/// Service responsible for WooCommerce Shipping Zones REST API v3 operations:
/// `GET {{baseUrl}}/wp-json/wc/v3/shipping/zones`
class ShippingService {
  final Dio _dio;

  ShippingService({Dio? dio}) : _dio = dio ?? Dio();

  Dio get dio => _dio;

  /// Fetches a list of WooCommerce shipping zones:
  /// `GET /wp-json/wc/v3/shipping/zones`
  ///
  /// - [page]: Dynamic page index (1-based, default: 1).
  /// - [perPage]: Items per page (default: 50).
  /// - [search]: Optional search query string.
  Future<ShippingZonesResponse> fetchShippingZones({
    int page = 1,
    int perPage = 50,
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.shippingZones}';

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
            'Network connection failed while fetching shipping zones: ${e.toString()}',
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

      final List<ShippingZonesModel> zones = [];
      if (rawData is List) {
        for (final item in rawData) {
          if (item is Map<String, dynamic>) {
            zones.add(ShippingZonesModel.fromJson(item));
          }
        }
      }

      // WooCommerce pagination metadata from headers
      final totalZonesStr = response.headers.value('x-wp-total');
      final totalPagesStr = response.headers.value('x-wp-totalpages');

      final totalZones = int.tryParse(totalZonesStr ?? '') ?? zones.length;
      final totalPages = int.tryParse(totalPagesStr ?? '') ?? 1;

      return ShippingZonesResponse(
        zones: zones,
        totalZones: totalZones,
        totalPages: totalPages,
      );
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse shipping zones: ${e.toString()}',
        statusCode: statusCode,
        originalData: response.data,
        stackTrace: stackTrace,
      );
    }
  }

  /// Fetches a specific shipping zone by ID:
  /// `GET /wp-json/wc/v3/shipping/zones/{{zoneId}}`
  Future<ShippingZonesModel> fetchShippingZone(
    int zoneId, {
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

    final requestUri = '$effectiveBaseUrl${ApiEndpoints.shippingZone(zoneId)}';

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
            'Network connection failed while fetching shipping zone #$zoneId: ${e.toString()}',
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
        return ShippingZonesModel.fromJson(rawData);
      } else {
        throw const FormatException('Expected JSON object for shipping zone');
      }
    } catch (e, stackTrace) {
      throw WooCommerceParseException(
        message: 'Failed to parse shipping zone #$zoneId: ${e.toString()}',
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
