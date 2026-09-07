import 'package:dio/dio.dart';

/// Base exception class for WooCommerce API failures.
class WooCommerceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errorData;

  const WooCommerceException({
    required this.message,
    this.statusCode,
    this.errorData,
  });

  factory WooCommerceException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const WooCommerceException(
          message: 'Connection timed out while reaching the WooCommerce store. Please check your network or server URL.',
          statusCode: 408,
        );
      case DioExceptionType.sendTimeout:
        return const WooCommerceException(
          message: 'Send request timed out. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.receiveTimeout:
        return const WooCommerceException(
          message: 'Server took too long to respond. The store may be experiencing high load.',
          statusCode: 408,
        );
      case DioExceptionType.badCertificate:
        return const WooCommerceException(
          message: 'SSL certificate validation failed. Ensure your store has a valid HTTPS certificate.',
        );
      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        final data = dioException.response?.data;
        String errorMessage = 'Unexpected server response ($statusCode)';

        if (data is Map<String, dynamic>) {
          if (data['message'] != null) {
            errorMessage = data['message'].toString();
          } else if (data['code'] != null) {
            errorMessage = 'Error: ${data['code']}';
          }
        }

        if (statusCode == 401) {
          return WooCommerceException(
            message: 'Authentication failed (401). Verify your Consumer Key and Consumer Secret.',
            statusCode: statusCode,
            errorData: data,
          );
        } else if (statusCode == 403) {
          return WooCommerceException(
            message: 'Access forbidden (403). Ensure the API key has Read/Write permissions.',
            statusCode: statusCode,
            errorData: data,
          );
        } else if (statusCode == 404) {
          return WooCommerceException(
            message: 'Resource not found (404). Check if WooCommerce REST API is enabled on this store.',
            statusCode: statusCode,
            errorData: data,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return WooCommerceException(
            message: 'WordPress/WooCommerce server error ($statusCode). Check server logs and PHP memory limit.',
            statusCode: statusCode,
            errorData: data,
          );
        }

        return WooCommerceException(
          message: errorMessage,
          statusCode: statusCode,
          errorData: data,
        );
      case DioExceptionType.cancel:
        return const WooCommerceException(
          message: 'Request was cancelled.',
        );
      case DioExceptionType.connectionError:
        return const WooCommerceException(
          message: 'Could not connect to the WooCommerce store. Verify the store URL and internet connectivity.',
        );
      case DioExceptionType.unknown:
      default:
        return WooCommerceException(
          message: dioException.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  @override
  String toString() => 'WooCommerceException(statusCode: $statusCode, message: $message)';
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
