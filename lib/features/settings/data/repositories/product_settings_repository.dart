import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_product_settings_model.dart';
import '../services/product_settings_service.dart';

/// Repository responsible for product settings data fetching, in-flight deduplication, and caching.
class ProductSettingsRepository {
  final ProductSettingsService _service;

  // In-memory cache for the product settings list
  List<GetProductSettingsModel>? _cachedSettings;
  DateTime? _cacheTimestamp;
  Future<List<GetProductSettingsModel>>? _inFlightSettingsRequest;

  // Single setting cache by ID
  final Map<String, GetProductSettingsModel> _settingCache = {};
  final Map<String, DateTime> _settingCacheTimestamps = {};
  final Map<String, Future<GetProductSettingsModel>> _inFlightSettingRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  ProductSettingsRepository({
    ProductSettingsService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? ProductSettingsService(dio: dioClient.dioInstance)
                : ProductSettingsService());

  ProductSettingsService get service => _service;

  /// Fetches product settings with in-flight deduplication and caching:
  /// `GET /wp-json/wc/v3/settings/products`
  Future<List<GetProductSettingsModel>> getProductSettings({
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
    final future = _service.fetchProductSettings(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightSettingsRequest = future;

    try {
      final result = await future;
      _cachedSettings = List<GetProductSettingsModel>.unmodifiable(result);
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

  /// Retrieves a single product setting by ID:
  /// `GET /wp-json/wc/v3/settings/products/<id>`
  Future<GetProductSettingsModel> getProductSetting(
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
    final future = _service.fetchProductSetting(
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
