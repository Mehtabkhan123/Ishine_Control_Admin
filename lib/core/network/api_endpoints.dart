/// API Endpoint constants for WooCommerce REST API v3.
class ApiEndpoints {
  ApiEndpoints._();

  /// Root prefix for WooCommerce v3 REST API
  static const String wcV3Prefix = '/wp-json/wc/v3';

  /// System Status
  static const String systemStatus = '$wcV3Prefix/system_status';

  /// Orders
  static const String orders = '$wcV3Prefix/orders';

  /// Products
  static const String products = '$wcV3Prefix/products';

  /// Specific Product by ID
  static String product(int id) => '$products/$id';

  /// Customers
  static const String customers = '$wcV3Prefix/customers';

  /// Reports
  static const String reports = '$wcV3Prefix/reports';

  /// Sales Report
  static const String reportsSales = '$reports/sales';

  /// Top Sellers Report
  static const String reportsTopSellers = '$reports/top_sellers';

  /// Settings
  static const String settings = '$wcV3Prefix/settings';

  /// Root prefix for WordPress v2 REST API
  static const String wpV2Prefix = '/wp-json/wp/v2';

  /// Media Endpoint for uploading and managing attachments
  static const String media = '$wpV2Prefix/media';

  /// Specific Media item by ID
  static String mediaItem(int id) => '$media/$id';
}
