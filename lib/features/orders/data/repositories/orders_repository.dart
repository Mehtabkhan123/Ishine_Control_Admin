import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_single_order_model.dart' show GetSingleOrderModel;
import '../models/put_update_order_model.dart' show PutUpdateOrderModel;
import '../models/delete_order_model.dart' show DeleteOrderModel;
import '../services/orders_service.dart';

/// Repository responsible for orders data fetching, pagination, and caching.
class OrdersRepository {
  final OrdersService _service;

  OrdersRepository({
    OrdersService? service,
    WooCommerceDioClient? dioClient,
  }) : _service = service ??
            (dioClient != null
                ? OrdersService(dio: dioClient.dioInstance)
                : OrdersService());

  OrdersService get service => _service;

  /// Fetches paginated orders from WooCommerce API.
  Future<OrdersResponse> getOrders({
    int page = 1,
    int perPage = 20,
    String orderby = 'date',
    String order = 'desc',
    String? status,
    String? search,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchOrders(
      page: page,
      perPage: perPage,
      orderby: orderby,
      order: order,
      status: status,
      search: search,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Fetches complete details of a single order by ID from WooCommerce API.
  Future<GetSingleOrderModel> getSingleOrder(
    int orderId, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchSingleOrder(
      orderId,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Updates an order by ID in WooCommerce:
  /// `PUT /wp-json/wc/v3/orders/{{orderId}}`
  Future<PutUpdateOrderModel> updateOrder(
    int orderId,
    Map<String, dynamic> updateData, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.updateOrder(
      orderId,
      updateData,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Deletes an order by ID from WooCommerce:
  /// `DELETE /wp-json/wc/v3/orders/{{orderId}}?force=true`
  Future<DeleteOrderModel> deleteOrder(
    int orderId, {
    bool force = true,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.deleteOrder(
      orderId,
      force: force,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }
}
