import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/get_system_status_tools_model.dart';
import '../models/system_status_model.dart';
import '../services/system_status_service.dart';

/// Repository responsible for checking store connection health, retrieving system status,
/// and managing WooCommerce system status tools.
class SystemStatusRepository {
  final SystemStatusService _service;

  // In-memory cache for system status tools
  List<GetSystemStatusToolsModel>? _cachedTools;
  DateTime? _toolsCacheTimestamp;
  Future<List<GetSystemStatusToolsModel>>? _inFlightToolsRequest;

  // Single tool cache by ID
  final Map<String, GetSystemStatusToolsModel> _toolCache = {};
  final Map<String, DateTime> _toolCacheTimestamps = {};
  final Map<String, Future<GetSystemStatusToolsModel>> _inFlightToolRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  SystemStatusRepository({
    SystemStatusService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? SystemStatusService(dio: dioClient.dioInstance)
                : SystemStatusService());

  SystemStatusService get service => _service;

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

  /// Fetches system status tools with in-flight deduplication and caching:
  /// `GET /wp-json/wc/v3/system_status/tools`
  Future<List<GetSystemStatusToolsModel>> getSystemStatusTools({
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Return from cache if fresh and not force-refreshing
    if (!forceRefresh && _cachedTools != null) {
      final cachedAt = _toolsCacheTimestamp;
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _cachedTools!;
      }
    }

    // 2. Prevent duplicate network calls for in-flight requests
    if (_inFlightToolsRequest != null) {
      return _inFlightToolsRequest!;
    }

    // 3. Initiate request and deduplicate
    final future = _service.fetchSystemStatusTools(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightToolsRequest = future;

    try {
      final result = await future;
      _cachedTools = List<GetSystemStatusToolsModel>.unmodifiable(result);
      _toolsCacheTimestamp = DateTime.now();

      // Pre-populate individual cache
      for (final tool in result) {
        if (tool.id != null) {
          _toolCache[tool.id!] = tool;
          _toolCacheTimestamps[tool.id!] = DateTime.now();
        }
      }

      return result;
    } finally {
      _inFlightToolsRequest = null;
    }
  }

  /// Retrieves a single system status tool by ID:
  /// `GET /wp-json/wc/v3/system_status/tools/<id>`
  Future<GetSystemStatusToolsModel> getSystemStatusTool(
    String id, {
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Return from cache if fresh
    if (!forceRefresh && _toolCache.containsKey(id)) {
      final cachedAt = _toolCacheTimestamps[id];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _toolCache[id]!;
      }
    }

    // 2. Deduplicate in-flight requests
    if (_inFlightToolRequests.containsKey(id)) {
      return _inFlightToolRequests[id]!;
    }

    final future = _service.fetchSystemStatusTool(
      id: id,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightToolRequests[id] = future;

    try {
      final result = await future;
      _toolCache[id] = result;
      _toolCacheTimestamps[id] = DateTime.now();

      // Update in cached list if exists
      if (_cachedTools != null) {
        final list = List<GetSystemStatusToolsModel>.from(_cachedTools!);
        final index = list.indexWhere((t) => t.id == id);
        if (index != -1) {
          list[index] = result;
          _cachedTools = List<GetSystemStatusToolsModel>.unmodifiable(list);
        }
      }

      return result;
    } finally {
      _inFlightToolRequests.remove(id);
    }
  }

  /// Executes a system status tool action:
  /// `PUT /wp-json/wc/v3/system_status/tools/<id>`
  ///
  /// Clears the tools cache so subsequent fetches pull the latest state.
  Future<GetSystemStatusToolsModel> executeSystemStatusTool({
    required String id,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final result = await _service.executeSystemStatusTool(
      id: id,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    // Update individual cache and update cached list
    _toolCache[id] = result;
    _toolCacheTimestamps[id] = DateTime.now();

    if (_cachedTools != null) {
      final list = List<GetSystemStatusToolsModel>.from(_cachedTools!);
      final index = list.indexWhere((t) => t.id == id);
      if (index != -1) {
        list[index] = result;
        _cachedTools = List<GetSystemStatusToolsModel>.unmodifiable(list);
      }
    }

    return result;
  }

  /// Clears all tools cache entries.
  void clearToolsCache() {
    _cachedTools = null;
    _toolsCacheTimestamp = null;
    _toolCache.clear();
    _toolCacheTimestamps.clear();
  }
}
