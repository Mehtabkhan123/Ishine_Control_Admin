import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/reports/data/models/sales_report_model.dart';

void main() {
  group('GetSalesReportModel', () {
    const rawJsonString = '''
[
  {
    "total_sales": "12500.50",
    "net_sales": "11200.00",
    "average_sales": "416.68",
    "total_orders": 30,
    "total_items": 58,
    "total_tax": "850.25",
    "total_shipping": "450.25",
    "total_refunds": 2,
    "total_discount": "150.00",
    "totals_grouped_by": "day",
    "totals": {
      "2026-09-01": {
        "sales": "450.00",
        "orders": 2,
        "items": 3,
        "tax": "30.00",
        "shipping": "15.00",
        "discount": "0.00",
        "customers": 2
      },
      "2026-09-02": {
        "sales": "820.50",
        "orders": 3,
        "items": 5,
        "tax": "65.00",
        "shipping": "25.00",
        "discount": "10.00",
        "customers": 3
      }
    },
    "total_customers": 28,
    "_links": {
      "about": [
        {
          "href": "https://example.com/wp-json/wc/v3/reports/sales"
        }
      ]
    }
  }
]
''';

    test('parses from JSON array correctly using getSalesReportModelFromJson', () {
      final reports = getSalesReportModelFromJson(rawJsonString);
      expect(reports.length, 1);

      final report = reports.first;
      expect(report.totalSales, '12500.50');
      expect(report.netSales, '11200.00');
      expect(report.averageSales, '416.68');
      expect(report.totalOrders, 30);
      expect(report.totalItems, 58);
      expect(report.totalTax, '850.25');
      expect(report.totalShipping, '450.25');
      expect(report.totalRefunds, 2);
      expect(report.totalDiscount, '150.00');
      expect(report.totalsGroupedBy, 'day');
      expect(report.totalCustomers, 28);
      expect(report.totals?.length, 2);

      // Verify daily total
      final day1 = report.totals?['2026-09-01'];
      expect(day1, isNotNull);
      expect(day1?.sales, '450.00');
      expect(day1?.orders, 2);
      expect(day1?.items, 3);
      expect(day1?.tax, '30.00');
      expect(day1?.shipping, '15.00');
      expect(day1?.discount, '0.00');
      expect(day1?.customers, 2);

      // Verify links
      expect(report.lLinks?.about?.first.href, 'https://example.com/wp-json/wc/v3/reports/sales');
    });

    test('serializes to JSON correctly using getSalesReportModelToJson', () {
      final reports = getSalesReportModelFromJson(rawJsonString);
      final jsonOutput = getSalesReportModelToJson(reports);
      final redecoded = json.decode(jsonOutput) as List;

      expect(redecoded.length, 1);
      final first = redecoded.first as Map<String, dynamic>;
      expect(first['total_sales'], '12500.50');
      expect(first['total_orders'], 30);
      expect(first['totals_grouped_by'], 'day');
    });

    test('safe numeric getters convert strings and nulls safely', () {
      final report = GetSalesReportModel(
        totalSales: '1,500.75',
        netSales: '1200.50',
        averageSales: 'null',
        totalTax: '85.20',
        totalShipping: null,
        totalDiscount: '0.00',
        totalOrders: 10,
      );

      expect(report.totalSalesValue, 1500.75);
      expect(report.netSalesValue, 1200.50);
      expect(report.averageSalesValue, 0.0);
      expect(report.totalTaxValue, 85.20);
      expect(report.totalShippingValue, 0.0);
      expect(report.totalDiscountValue, 0.0);
      expect(report.isEmptyReport, isFalse);
    });

    test('detects empty report when orders and sales are zero', () {
      final emptyReport = GetSalesReportModel(
        totalSales: '0.00',
        totalOrders: 0,
        totals: {},
      );

      expect(emptyReport.isEmptyReport, isTrue);

      final zeroDataReport = GetSalesReportModel();
      expect(zeroDataReport.isEmptyReport, isTrue);
    });

    test('DailyTotal handles nulls gracefully', () {
      final daily = DailyTotal.fromJson({});
      expect(daily.sales, isNull);
      expect(daily.orders, isNull);
      expect(daily.items, isNull);

      final jsonMap = daily.toJson();
      expect(jsonMap['sales'], isNull);
    });
  });
}
