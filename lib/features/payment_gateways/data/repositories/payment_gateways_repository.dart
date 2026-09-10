import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_payment_gateways_model.dart';
import '../models/put_update_payment_gateways_model.dart';
import '../services/payment_gateways_service.dart';

/// Repository responsible for payment gateways data fetching, in-flight deduplication, and caching.
class PaymentGatewaysRepository {
  final PaymentGatewaysService _service;

  // In-memory cache for the gateways list
  List<GetPaymentGatewaysModel>? _cachedGateways;
  DateTime? _cacheTimestamp;
  Future<List<GetPaymentGatewaysModel>>? _inFlightGatewaysRequest;

  // Single gateway cache by ID
  final Map<String, GetPaymentGatewaysModel> _gatewayCache = {};
  final Map<String, DateTime> _gatewayCacheTimestamps = {};
  final Map<String, Future<GetPaymentGatewaysModel>> _inFlightGatewayRequests = {};

  // In-flight update request tracking by gateway ID
  final Map<String, Future<PutUpdatePaymentGatewaysModel>> _inFlightUpdateRequests = {};

  /// Cache validity duration before auto-refresh
  final Duration cacheTtl;

  PaymentGatewaysRepository({
    PaymentGatewaysService? service,
    WooCommerceDioClient? dioClient,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _service = service ??
            (dioClient != null
                ? PaymentGatewaysService(dio: dioClient.dioInstance)
                : PaymentGatewaysService());

  PaymentGatewaysService get service => _service;

  /// Fetches payment gateways with in-flight deduplication and caching:
  /// `GET /wp-json/wc/v3/payment_gateways`
  Future<List<GetPaymentGatewaysModel>> getPaymentGateways({
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Return from cache if fresh and not force-refreshing
    if (!forceRefresh && _cachedGateways != null) {
      final cachedAt = _cacheTimestamp;
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _cachedGateways!;
      }
    }

    // 2. Prevent duplicate network calls for in-flight requests
    if (_inFlightGatewaysRequest != null) {
      return _inFlightGatewaysRequest!;
    }

    // 3. Initiate request and deduplicate
    final future = _service.fetchPaymentGateways(
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightGatewaysRequest = future;

    try {
      final result = await future;
      _cachedGateways = List<GetPaymentGatewaysModel>.unmodifiable(result);
      _cacheTimestamp = DateTime.now();

      // Pre-populate individual cache
      for (final gateway in result) {
        if (gateway.id != null) {
          _gatewayCache[gateway.id!] = gateway;
          _gatewayCacheTimestamps[gateway.id!] = DateTime.now();
        }
      }

      return result;
    } finally {
      _inFlightGatewaysRequest = null;
    }
  }

  /// Fetches a single payment gateway by ID with caching:
  /// `GET /wp-json/wc/v3/payment_gateways/<id>`
  Future<GetPaymentGatewaysModel> getPaymentGateway(
    String id, {
    bool forceRefresh = false,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    if (!forceRefresh && _gatewayCache.containsKey(id)) {
      final cachedAt = _gatewayCacheTimestamps[id];
      if (cachedAt != null && DateTime.now().difference(cachedAt) < cacheTtl) {
        return _gatewayCache[id]!;
      }
    }

    if (_inFlightGatewayRequests.containsKey(id)) {
      return _inFlightGatewayRequests[id]!;
    }

    final future = _service.fetchPaymentGateway(
      id,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightGatewayRequests[id] = future;

    try {
      final result = await future;
      _gatewayCache[id] = result;
      _gatewayCacheTimestamps[id] = DateTime.now();
      return result;
    } finally {
      _inFlightGatewayRequests.remove(id);
    }
  }

  /// Updates a payment gateway by dynamic ID:
  /// `PUT /wp-json/wc/v3/payment_gateways/<id>`
  Future<PutUpdatePaymentGatewaysModel> updatePaymentGateway({
    required String id,
    required Map<String, dynamic> data,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    // 1. Deduplicate concurrent in-flight updates for the same gateway
    if (_inFlightUpdateRequests.containsKey(id)) {
      return _inFlightUpdateRequests[id]!;
    }

    final future = _service.updatePaymentGateway(
      id: id,
      data: data,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );

    _inFlightUpdateRequests[id] = future;

    try {
      final updated = await future;

      // 2. Synchronize local caches
      final getModel = updated.toGetPaymentGatewaysModel();
      _gatewayCache[id] = getModel;
      _gatewayCacheTimestamps[id] = DateTime.now();

      if (_cachedGateways != null) {
        final list = List<GetPaymentGatewaysModel>.from(_cachedGateways!);
        final index = list.indexWhere((g) => g.id == id);
        if (index != -1) {
          list[index] = getModel;
        } else {
          list.add(getModel);
        }
        _cachedGateways = List<GetPaymentGatewaysModel>.unmodifiable(list);
      }

      return updated;
    } finally {
      _inFlightUpdateRequests.remove(id);
    }
  }

  /// Clears in-memory caches
  void clearCache() {
    _cachedGateways = null;
    _cacheTimestamp = null;
    _gatewayCache.clear();
    _gatewayCacheTimestamps.clear();
    _inFlightUpdateRequests.clear();
  }
}
