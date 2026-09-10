import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_tax_rates_model.dart';
import '../models/post_tax_rates_model.dart';
import '../services/taxes_service.dart';

/// Repository responsible for tax rates data fetching, in-flight deduplication, and caching.
class TaxesRepository {
  final TaxesService _service;

  // In-memory cache by query key (page + perPage + taxClass + search)
  final Map<String, TaxRatesResponse> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<TaxRatesResponse>> _inFlightRequests = {};

  // Single tax rate cache by ID
  final Map<int, GetTaxRatesModel> _taxRateCache = {};
  final Map<int, DateTime> _taxRateCacheTimestamps = {};
  final Map<int, Future<GetTaxRatesModel>> _inFlightTaxRateRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  TaxesRepository({
    TaxesService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? TaxesService(dio: dioClient.dioInstance)
                : TaxesService());

  TaxesService get service => _service;

  /// Fetches paginated tax rates with in-flight deduplication and caching:
  /// `GET /wp-json/wc/v3/taxes?per_page=50&page=1`
  Future<TaxRatesResponse> getTaxRates({
    int page = 1,
    int perPage = 50,
    String? taxClass,
    String? search,
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = '$page:$perPage:${taxClass ?? ""}:${search ?? ""}';

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
    final requestFuture = _service.fetchTaxRates(
      page: page,
      perPage: perPage,
      taxClass: taxClass,
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

      // Pre-seed individual tax rate cache
      for (final rate in response.taxRates) {
        if (rate.id != null) {
          _taxRateCache[rate.id!] = rate;
          _taxRateCacheTimestamps[rate.id!] = DateTime.now();
        }
      }

      return response;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Fetches single tax rate details by ID with caching & deduplication:
  /// `GET /wp-json/wc/v3/taxes/{{taxRateId}}`
  Future<GetTaxRatesModel> getTaxRate(
    int taxRateId, {
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    if (!forceRefresh && _taxRateCache.containsKey(taxRateId)) {
      final cachedAt = _taxRateCacheTimestamps[taxRateId];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _taxRateCache[taxRateId]!;
      }
    }

    if (_inFlightTaxRateRequests.containsKey(taxRateId)) {
      return _inFlightTaxRateRequests[taxRateId]!;
    }

    final requestFuture = _service.fetchTaxRate(
      taxRateId,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightTaxRateRequests[taxRateId] = requestFuture;

    try {
      final rate = await requestFuture;
      _taxRateCache[taxRateId] = rate;
      _taxRateCacheTimestamps[taxRateId] = DateTime.now();
      return rate;
    } finally {
      _inFlightTaxRateRequests.remove(taxRateId);
    }
  }

  /// Creates a new tax rate via WooCommerce REST API v3:
  /// `POST /wp-json/wc/v3/taxes`
  Future<PostTaxRatesModel> createTaxRate(
    PostTaxRatesModel taxRate, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final created = await _service.createTaxRate(
      taxRate,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    // Invalidate/clear tax rates cache so the new rate is fetched fresh
    clearCache();

    return created;
  }

  /// Clears in-memory caches
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _taxRateCache.clear();
    _taxRateCacheTimestamps.clear();
  }
}
