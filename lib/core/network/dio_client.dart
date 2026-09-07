import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import 'network_exceptions.dart';

/// Configured Dio client that handles Basic Auth for WooCommerce REST API v3.
class WooCommerceDioClient {
  late final Dio _dio;

  WooCommerceDioClient({Dio? dio}) {
    _dio = dio ?? Dio();
    _configureDio();
  }

  Dio get dioInstance => _dio;

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: EnvConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: kIsWeb ? null : const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
      },
      responseType: ResponseType.json,
    );

    // Basic Auth & Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final uri = Uri.tryParse(options.path);
          final isExternal = uri != null &&
              uri.hasScheme &&
              EnvConfig.baseUrl.isNotEmpty &&
              !options.path.startsWith(EnvConfig.baseUrl);
          if (isExternal) {
            return handler.next(options);
          }

          // If the request already has an explicit Authorization header
          // (such as WordPress Application Password credentials for /wp/v2/media),
          // preserve it and do not overwrite or strip it.
          if (options.headers.containsKey('Authorization')) {
            return handler.next(options);
          }

          final consumerKey = EnvConfig.consumerKey;
          final consumerSecret = EnvConfig.consumerSecret;

          if (consumerKey.isNotEmpty && consumerSecret.isNotEmpty) {
            if (kIsWeb) {
              // On Flutter Web, use query parameter authentication and avoid custom headers
              // on GET requests to preserve CORS "simple request" status and avoid OPTIONS preflight.
              options.queryParameters['consumer_key'] ??= consumerKey;
              options.queryParameters['consumer_secret'] ??= consumerSecret;
              options.headers.remove('Authorization');
              if (options.method.toUpperCase() == 'GET') {
                options.headers.remove('Content-Type');
              }
              options.sendTimeout = null;
            } else {
              if (!options.queryParameters.containsKey('consumer_key')) {
                final authString = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
                options.headers['Authorization'] = 'Basic $authString';
              }
            }
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [WooCommerceDioClient Error]: ${e.type} - ${e.message}');
            if (e.response != null) {
              debugPrint('   Status: ${e.response?.statusCode}');
              debugPrint('   Data: ${e.response?.data}');
            }
          }
          return handler.next(e);
        },
      ),
    );

    // Logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (obj) => debugPrint('🌐 [Dio] $obj'),
        ),
      );
    }
  }

  /// Sends a GET request and maps responses/exceptions.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(message: e.toString());
    }
  }

  /// Sends a POST request and maps responses/exceptions.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(message: e.toString());
    }
  }

  /// Sends a PUT request and maps responses/exceptions.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      if (kIsWeb) {
        final webParams = Map<String, dynamic>.from(queryParameters ?? {});
        webParams['_method'] = 'PUT';
        final response = await _dio.post<T>(
          path,
          data: data,
          queryParameters: webParams,
          options: options,
          cancelToken: cancelToken,
        );
        return response;
      }
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(message: e.toString());
    }
  }

  /// Sends a DELETE request and maps responses/exceptions.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw WooCommerceException.fromDioException(e);
    } catch (e) {
      throw WooCommerceException(message: e.toString());
    }
  }
}
