import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_tax_settings_model.dart';
import '../services/tax_settings_service.dart';

/// Repository responsible for tax settings data fetching, in-flight deduplication, and caching.
class TaxSettingsRepository {
  final TaxSettingsService _service;

  // In-memory cache for the tax settings list
  List<GetTextSettingsModel>? _cachedSettings;
  DateTime? _cacheTimestamp;
  Future<List<GetTextSettingsModel>>? _inFlightSettingsRequest;

  // Single setting cache by ID
  final Map<String, GetTextSettingsModel> _settingCache = {};
  final Map<String, DateTime> _settingCacheTimestamps = {};
  final Map<String, Future<GetTextSettingsModel>> _inFlightSettingRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  TaxSettingsRepository({
    TaxSettingsService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? TaxSettingsService(dio: dioClient.dioInstance)
                : TaxSettingsService());

  TaxSettingsService get service => _service;

  /// Fetches tax settings with in-flight deduplication and caching:
  /// `GET /wp-json/wc/v3/settings/tax`
  Future<List<GetTextSettingsModel>> getTaxSettings({
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Return from cache if fresh and not force-refreshing
    if (!forceRefresh && _cachedSettings != null) {
      final cachedAt = _cacheTimestamp;
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _cachedSettings!;
      }
    }

    // 2. Prevent duplicate network calls for in-flight requests
    if (_inFlightSettingsRequest != null) {
      return _inFlightSettingsRequest!;
    }

    // 3. Initiate request and deduplicate
    final future = _service.fetchTaxSettings(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightSettingsRequest = future;

    try {
      final result = await future;
      _cachedSettings = List<GetTextSettingsModel>.unmodifiable(result);
      _cacheTimestamp = DateTime.now();

      // Pre-populate individual cache
      for (final setting in result) {
        if (setting.id != null) {
          _settingCache[setting.id!] = setting;
          _settingCacheTimestamps[setting.id!] = DateTime.now();
        }
      }

      return result;
    } finally {
      _inFlightSettingsRequest = null;
    }
  }

  /// Retrieves a single tax setting by ID:
  /// `GET /wp-json/wc/v3/settings/tax/<id>`
  Future<GetTextSettingsModel> getTaxSetting(
    String id, {
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Return from cache if fresh
    if (!forceRefresh && _settingCache.containsKey(id)) {
      final cachedAt = _settingCacheTimestamps[id];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _settingCache[id]!;
      }
    }

    // 2. In-flight request deduplication
    if (_inFlightSettingRequests.containsKey(id)) {
      return _inFlightSettingRequests[id]!;
    }

    // 3. Fetch from network
    final future = _service.fetchTaxSetting(
      id: id,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightSettingRequests[id] = future;

    try {
      final setting = await future;
      _settingCache[id] = setting;
      _settingCacheTimestamps[id] = DateTime.now();
      return setting;
    } finally {
      _inFlightSettingRequests.remove(id);
    }
  }

  /// Invalidates all in-memory caches
  void clearCache() {
    _cachedSettings = null;
    _cacheTimestamp = null;
    _settingCache.clear();
    _settingCacheTimestamps.clear();
  }
}
