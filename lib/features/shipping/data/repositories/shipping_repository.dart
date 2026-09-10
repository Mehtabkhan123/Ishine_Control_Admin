import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/shipping_zones_model.dart';
import '../services/shipping_service.dart';

/// Repository responsible for shipping zones data operations, in-flight deduplication, and caching.
class ShippingRepository {
  final ShippingService _service;

  // In-memory cache by query key (page + perPage + search)
  final Map<String, ShippingZonesResponse> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<ShippingZonesResponse>> _inFlightRequests = {};

  // Single zone cache by zone ID
  final Map<int, ShippingZonesModel> _zoneCache = {};
  final Map<int, DateTime> _zoneCacheTimestamps = {};
  final Map<int, Future<ShippingZonesModel>> _inFlightZoneRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  ShippingRepository({
    ShippingService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? ShippingService(dio: dioClient.dioInstance)
                : ShippingService());

  ShippingService get service => _service;

  /// Fetches WooCommerce shipping zones with in-flight deduplication and caching:
  /// `GET /wp-json/wc/v3/shipping/zones`
  Future<ShippingZonesResponse> getShippingZones({
    int page = 1,
    int perPage = 50,
    String? search,
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = '$page:$perPage:${search ?? ""}';

    // 1. Return from cache if fresh and not force-refreshing
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedAt = _cacheTimestamps[cacheKey];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _cache[cacheKey]!;
      }
    }

    // 2. Prevent duplicate network calls for in-flight requests
    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    // 3. Initiate request with in-flight tracking
    final requestFuture = _service.fetchShippingZones(
      page: page,
      perPage: perPage,
      search: search,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightRequests[cacheKey] = requestFuture;

    try {
      final response = await requestFuture;
      _cache[cacheKey] = response;
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Pre-seed individual zone cache
      for (final zone in response.zones) {
        if (zone.id != null) {
          _zoneCache[zone.id!] = zone;
          _zoneCacheTimestamps[zone.id!] = DateTime.now();
        }
      }

      return response;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Fetches single shipping zone details by zone ID with caching & deduplication:
  /// `GET /wp-json/wc/v3/shipping/zones/{{zoneId}}`
  Future<ShippingZonesModel> getShippingZone(
    int zoneId, {
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    if (!forceRefresh && _zoneCache.containsKey(zoneId)) {
      final cachedAt = _zoneCacheTimestamps[zoneId];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _zoneCache[zoneId]!;
      }
    }

    if (_inFlightZoneRequests.containsKey(zoneId)) {
      return _inFlightZoneRequests[zoneId]!;
    }

    final requestFuture = _service.fetchShippingZone(
      zoneId,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightZoneRequests[zoneId] = requestFuture;

    try {
      final zone = await requestFuture;
      _zoneCache[zoneId] = zone;
      _zoneCacheTimestamps[zoneId] = DateTime.now();
      return zone;
    } finally {
      _inFlightZoneRequests.remove(zoneId);
    }
  }

  /// Clears in-memory caches
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _zoneCache.clear();
    _zoneCacheTimestamps.clear();
  }
}
