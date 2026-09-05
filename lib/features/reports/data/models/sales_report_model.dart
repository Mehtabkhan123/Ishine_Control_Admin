import 'dart:convert';

List<GetSalesReportModel> getSalesReportModelFromJson(String str) =>
    List<GetSalesReportModel>.from(
      (json.decode(str) as List).map(
        (x) => GetSalesReportModel.fromJson(x as Map<String, dynamic>),
      ),
    );

String getSalesReportModelToJson(List<GetSalesReportModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetSalesReportModel {
  String? totalSales;
  String? netSales;
  String? averageSales;
  int? totalOrders;
  int? totalItems;
  String? totalTax;
  String? totalShipping;
  int? totalRefunds;
  String? totalDiscount;
  String? totalsGroupedBy;
  Map<String, DailyTotal>? totals;
  int? totalCustomers;
  Links? lLinks;

  GetSalesReportModel({
    this.totalSales,
    this.netSales,
    this.averageSales,
    this.totalOrders,
    this.totalItems,
    this.totalTax,
    this.totalShipping,
    this.totalRefunds,
    this.totalDiscount,
    this.totalsGroupedBy,
    this.totals,
    this.totalCustomers,
    this.lLinks,
  });

  GetSalesReportModel.fromJson(Map<String, dynamic> json) {
    totalSales = json['total_sales']?.toString();
    netSales = json['net_sales']?.toString();
    averageSales = json['average_sales']?.toString();
    totalOrders = json['total_orders'] is num ? (json['total_orders'] as num).toInt() : null;
    totalItems = json['total_items'] is num ? (json['total_items'] as num).toInt() : null;
    totalTax = json['total_tax']?.toString();
    totalShipping = json['total_shipping']?.toString();
    totalRefunds = json['total_refunds'] is num ? (json['total_refunds'] as num).toInt() : null;
    totalDiscount = json['total_discount']?.toString();
    totalsGroupedBy = json['totals_grouped_by']?.toString();
    if (json['totals'] != null && json['totals'] is Map) {
      totals = (json['totals'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          DailyTotal.fromJson(value is Map<String, dynamic> ? value : {}),
        ),
      );
    }
    totalCustomers = json['total_customers'] is num ? (json['total_customers'] as num).toInt() : null;
    lLinks = json['_links'] != null && json['_links'] is Map<String, dynamic>
        ? Links.fromJson(json['_links'] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_sales'] = totalSales;
    data['net_sales'] = netSales;
    data['average_sales'] = averageSales;
    data['total_orders'] = totalOrders;
    data['total_items'] = totalItems;
    data['total_tax'] = totalTax;
    data['total_shipping'] = totalShipping;
    data['total_refunds'] = totalRefunds;
    data['total_discount'] = totalDiscount;
    data['totals_grouped_by'] = totalsGroupedBy;
    if (totals != null) {
      data['totals'] = totals!.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
    }
    data['total_customers'] = totalCustomers;
    if (lLinks != null) {
      data['_links'] = lLinks!.toJson();
    }
    return data;
  }

  // Safe numerical accessor helpers for analytics & charts
  static double _parseDouble(String? val) {
    if (val == null) return 0.0;
    final cleaned = val.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  double get totalSalesValue => _parseDouble(totalSales);
  double get netSalesValue => _parseDouble(netSales);
  double get averageSalesValue => _parseDouble(averageSales);
  double get totalTaxValue => _parseDouble(totalTax);
  double get totalShippingValue => _parseDouble(totalShipping);
  double get totalDiscountValue => _parseDouble(totalDiscount);

  bool get isEmptyReport =>
      totalSalesValue == 0 &&
      (totalOrders ?? 0) == 0 &&
      (totalItems ?? 0) == 0 &&
      (totals == null || totals!.isEmpty);

}

class DailyTotal {
  String? sales;
  int? orders;
  int? items;
  String? tax;
  String? shipping;
  String? discount;
  int? customers;

  DailyTotal({
    this.sales,
    this.orders,
    this.items,
    this.tax,
    this.shipping,
    this.discount,
    this.customers,
  });

  DailyTotal.fromJson(Map<String, dynamic> json) {
    sales = json['sales']?.toString();
    orders = json['orders'] is num ? (json['orders'] as num).toInt() : null;
    items = json['items'] is num ? (json['items'] as num).toInt() : null;
    tax = json['tax']?.toString();
    shipping = json['shipping']?.toString();
    discount = json['discount']?.toString();
    customers = json['customers'] is num ? (json['customers'] as num).toInt() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sales'] = sales;
    data['orders'] = orders;
    data['items'] = items;
    data['tax'] = tax;
    data['shipping'] = shipping;
    data['discount'] = discount;
    data['customers'] = customers;
    return data;
  }

  // Safe numerical accessor helpers
  double get salesValue => double.tryParse(sales ?? '0') ?? 0.0;
  double get taxValue => double.tryParse(tax ?? '0') ?? 0.0;
  double get shippingValue => double.tryParse(shipping ?? '0') ?? 0.0;
  double get discountValue => double.tryParse(discount ?? '0') ?? 0.0;
}

class Links {
  List<About>? about;

  Links({this.about});

  Links.fromJson(Map<String, dynamic> json) {
    if (json['about'] != null && json['about'] is List) {
      about = <About>[];
      for (final v in (json['about'] as List)) {
        if (v is Map<String, dynamic>) {
          about!.add(About.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (about != null) {
      data['about'] = about!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class About {
  String? href;

  About({this.href});

  About.fromJson(Map<String, dynamic> json) {
    href = json['href']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['href'] = href;
    return data;
  }
}
