import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/sales_report_model.dart';
import '../models/top_seller_model.dart';
import '../services/reports_service.dart';

/// Repository managing sales report and top sellers analytics, caching, and deduplication.
class ReportsRepository {
  final ReportsService _service;

  // In-memory cache by query key (period + date range) for sales report
  final Map<String, GetSalesReportModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Future<GetSalesReportModel?>> _inFlightRequests = {};

  // In-memory cache for top sellers report
  final Map<String, List<TopSellerModel>> _topSellersCache = {};
  final Map<String, DateTime> _topSellersTimestamps = {};
  final Map<String, Future<List<TopSellerModel>>> _inFlightTopSellersRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  ReportsRepository({
    ReportsService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? ReportsService(dio: dioClient.dioInstance)
                : ReportsService());

  /// Retrieves the WooCommerce sales report with caching and deduplication to prevent redundant network calls.
  Future<GetSalesReportModel?> getSalesReport({
    String period = 'month',
    String? dateMin,
    String? dateMax,
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = '$period:${dateMin ?? ""}:${dateMax ?? ""}';

    // 1. Return from cache if fresh and not force-refreshing
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cachedAt = _cacheTimestamps[cacheKey];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _cache[cacheKey];
      }
    }

    // 2. Prevent duplicate network calls for in-flight requests
    if (_inFlightRequests.containsKey(cacheKey)) {
      return _inFlightRequests[cacheKey]!;
    }

    // 3. Dispatch request and register in-flight tracker
    final requestFuture = _service.fetchSalesReport(
      period: period,
      dateMin: dateMin,
      dateMax: dateMax,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightRequests[cacheKey] = requestFuture;

    try {
      final report = await requestFuture;
      if (report != null) {
        _cache[cacheKey] = report;
        _cacheTimestamps[cacheKey] = DateTime.now();
      }
      return report;
    } finally {
      _inFlightRequests.remove(cacheKey);
    }
  }

  /// Retrieves the WooCommerce top sellers report with caching and deduplication.
  Future<List<TopSellerModel>> getTopSellers({
    String period = 'month',
    String? dateMin,
    String? dateMax,
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    final cacheKey = '$period:${dateMin ?? ""}:${dateMax ?? ""}';

    // 1. Return from cache if fresh and not force-refreshing
    if (!forceRefresh && _topSellersCache.containsKey(cacheKey)) {
      final cachedAt = _topSellersTimestamps[cacheKey];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _topSellersCache[cacheKey]!;
      }
    }

    // 2. Prevent duplicate network calls for in-flight requests
    if (_inFlightTopSellersRequests.containsKey(cacheKey)) {
      return _inFlightTopSellersRequests[cacheKey]!;
    }

    // 3. Dispatch request and register in-flight tracker
    final requestFuture = _service.fetchTopSellers(
      period: period,
      dateMin: dateMin,
      dateMax: dateMax,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightTopSellersRequests[cacheKey] = requestFuture;

    try {
      final items = await requestFuture;
      _topSellersCache[cacheKey] = items;
      _topSellersTimestamps[cacheKey] = DateTime.now();
      return items;
    } finally {
      _inFlightTopSellersRequests.remove(cacheKey);
    }
  }

  /// Clears the memory cache for sales reports and top sellers
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _inFlightRequests.clear();
    _topSellersCache.clear();
    _topSellersTimestamps.clear();
    _inFlightTopSellersRequests.clear();
  }
}

