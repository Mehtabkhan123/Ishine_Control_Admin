import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/system_status_model.dart';
import '../services/system_status_service.dart';

/// Repository responsible for checking store connection health and retrieving system status.
class SystemStatusRepository {
  final SystemStatusService _service;

  SystemStatusRepository({
    SystemStatusService? service,
    WooCommerceDioClient? dioClient,
  }) : _service = service ??
            (dioClient != null
                ? SystemStatusService(dio: dioClient.dioInstance)
                : SystemStatusService());

  /// Fetches complete raw [GETSystemStatusModel] from WooCommerce REST API.
  Future<GETSystemStatusModel> fetchSystemStatus({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchSystemStatus(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Fetches system status, measures response latency (ping), and maps to domain [SystemStatus].
  Future<SystemStatus> getSystemStatus({
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();
    final model = await _service.fetchSystemStatus(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
    stopwatch.stop();

    return model.toDomain(responseTimeMs: stopwatch.elapsedMilliseconds);
  }
}
