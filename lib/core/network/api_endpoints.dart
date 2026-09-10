/// API Endpoint constants for WooCommerce REST API v3.
class ApiEndpoints {
  ApiEndpoints._();

  /// Root prefix for WooCommerce v3 REST API
  static const String wcV3Prefix = '/wp-json/wc/v3';

  /// System Status
  static const String systemStatus = '$wcV3Prefix/system_status';

  /// System Status Tools (`GET /wp-json/wc/v3/system_status/tools`)
  static const String systemStatusTools = '$systemStatus/tools';

  /// Specific System Status Tool by ID (`GET /wp-json/wc/v3/system_status/tools/<id>`)
  static String systemStatusTool(String id) => '$systemStatusTools/$id';

  /// Orders
  static const String orders = '$wcV3Prefix/orders';

  /// Specific Order by ID
  static String order(int id) => '$orders/$id';

  /// Products
  static const String products = '$wcV3Prefix/products';

  /// Specific Product by ID
  static String product(int id) => '$products/$id';

  /// Product Categories
  static const String productCategories = '$wcV3Prefix/products/categories';

  /// Specific Product Category by ID
  static String productCategory(int id) => '$productCategories/$id';

  /// Customers
  static const String customers = '$wcV3Prefix/customers';

  /// Specific Customer by ID
  static String customer(int id) => '$customers/$id';

  /// Coupons
  static const String coupons = '$wcV3Prefix/coupons';

  /// Specific Coupon by ID
  static String coupon(int id) => '$coupons/$id';

  /// Reports
  static const String reports = '$wcV3Prefix/reports';

  /// Sales Report
  static const String reportsSales = '$reports/sales';

  /// Top Sellers Report
  static const String reportsTopSellers = '$reports/top_sellers';

  /// Settings
  static const String settings = '$wcV3Prefix/settings';

  /// General Settings (`GET /wp-json/wc/v3/settings/general`)
  static const String generalSettings = '$settings/general';

  /// Specific General Setting by ID (`GET /wp-json/wc/v3/settings/general/<id>`)
  static String generalSetting(String id) => '$generalSettings/$id';

  /// Product Settings (`GET /wp-json/wc/v3/settings/products`)
  static const String productSettings = '$settings/products';

  /// Specific Product Setting by ID (`GET /wp-json/wc/v3/settings/products/<id>`)
  static String productSetting(String id) => '$productSettings/$id';

  /// Tax Settings (`GET /wp-json/wc/v3/settings/tax`)
  static const String taxSettings = '$settings/tax';

  /// Specific Tax Setting by ID (`GET /wp-json/wc/v3/settings/tax/<id>`)
  static String taxSetting(String id) => '$taxSettings/$id';

  /// Specific Settings Group by ID (`GET /wp-json/wc/v3/settings/<group>`)
  static String settingsGroup(String group) => '$settings/$group';

  /// Shipping Zones
  static const String shippingZones = '$wcV3Prefix/shipping/zones';

  /// Specific Shipping Zone by ID
  static String shippingZone(int id) => '$shippingZones/$id';

  /// Tax Rates
  static const String taxes = '$wcV3Prefix/taxes';

  /// Specific Tax Rate by ID
  static String tax(int id) => '$taxes/$id';

  /// Payment Gateways
  static const String paymentGateways = '$wcV3Prefix/payment_gateways';

  /// Specific Payment Gateway by ID
  static String paymentGateway(String id) => '$paymentGateways/$id';

  /// Root prefix for WordPress v2 REST API
  static const String wpV2Prefix = '/wp-json/wp/v2';

  /// Media Endpoint for uploading and managing attachments
  static const String media = '$wpV2Prefix/media';

  /// Specific Media item by ID
  static String mediaItem(int id) => '$media/$id';
}
