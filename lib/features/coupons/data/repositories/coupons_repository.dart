import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_coupon_report_model.dart';
import '../services/coupons_service.dart';

/// Repository responsible for coupons data fetching, pagination, and caching.
class CouponsRepository {
  final CouponsService _service;

  CouponsRepository({
    CouponsService? service,
    WooCommerceDioClient? dioClient,
  }) : _service = service ??
            (dioClient != null
                ? CouponsService(dio: dioClient.dioInstance)
                : CouponsService());

  CouponsService get service => _service;

  /// Fetches paginated coupons from WooCommerce API:
  /// `GET /wp-json/wc/v3/coupons?per_page=50&page=1`
  Future<CouponsResponse> getCoupons({
    int page = 1,
    int perPage = 50,
    String? search,
    String? discountType,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchCoupons(
      page: page,
      perPage: perPage,
      search: search,
      discountType: discountType,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Fetches complete details of a single coupon by ID from WooCommerce API:
  /// `GET /wp-json/wc/v3/coupons/{{couponId}}`
  Future<GETCouponReportModel> getSingleCoupon(
    int couponId, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchSingleCoupon(
      couponId,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }
}
