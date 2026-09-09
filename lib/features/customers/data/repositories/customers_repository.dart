import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../system_status/data/services/system_status_service.dart';
import '../models/get_single_customers_model.dart';
import '../models/put_update_customer_model.dart';
import '../models/delete_customer_model.dart';
import '../services/customers_service.dart';

/// Repository responsible for customers data fetching, pagination, and caching.
class CustomersRepository {
  final CustomersService _service;

  CustomersRepository({
    CustomersService? service,
    WooCommerceDioClient? dioClient,
  }) : _service = service ??
            (dioClient != null
                ? CustomersService(dio: dioClient.dioInstance)
                : CustomersService());

  CustomersService get service => _service;

  /// Fetches paginated customers from WooCommerce API:
  /// `GET /wp-json/wc/v3/customers?per_page=20&page=1&orderby=registered_date&order=desc`
  Future<CustomersResponse> getCustomers({
    int page = 1,
    int perPage = 20,
    String orderby = 'registered_date',
    String order = 'desc',
    String? role,
    String? search,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchCustomers(
      page: page,
      perPage: perPage,
      orderby: orderby,
      order: order,
      role: role,
      search: search,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Fetches complete details of a single customer by ID from WooCommerce API:
  /// `GET /wp-json/wc/v3/customers/{{customerId}}`
  Future<GETSingleCustomersModel> getSingleCustomer(
    int customerId, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.fetchSingleCustomer(
      customerId,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Updates a customer by ID in WooCommerce API:
  /// `PUT /wp-json/wc/v3/customers/{{customerId}}`
  Future<PutUpdateCustomerModel> updateCustomer(
    int customerId,
    Map<String, dynamic> updateData, {
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.updateCustomer(
      customerId,
      updateData,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }

  /// Permanently deletes a customer by ID in WooCommerce API:
  /// `DELETE /wp-json/wc/v3/customers/{{customerId}}?force=true`
  Future<DeleteCustomerModel> deleteCustomer(
    int customerId, {
    bool force = true,
    String? baseUrl,
    String? consumerKey,
    String? consumerSecret,
    WooCommerceAuthMode authMode = WooCommerceAuthMode.auto,
    CancelToken? cancelToken,
  }) async {
    return _service.deleteCustomer(
      customerId,
      force: force,
      baseUrl: baseUrl,
      consumerKey: consumerKey,
      consumerSecret: consumerSecret,
      authMode: authMode,
      cancelToken: cancelToken,
    );
  }
}
