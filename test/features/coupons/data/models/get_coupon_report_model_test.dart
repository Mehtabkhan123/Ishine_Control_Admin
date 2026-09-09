import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/coupons/data/models/get_coupon_report_model.dart';

void main() {
  group('GETCouponReportModel', () {
    final sampleJson = {
      'id': 105,
      'code': 'SUMMER2026',
      'amount': '15.00',
      'status': 'publish',
      'date_created': '2026-06-01T08:00:00',
      'date_created_gmt': '2026-06-01T08:00:00',
      'date_modified': '2026-06-05T12:00:00',
      'date_modified_gmt': '2026-06-05T12:00:00',
      'discount_type': 'percent',
      'description': 'Summer season 15% discount for loyal members',
      'date_expires': '2026-08-31T23:59:59',
      'date_expires_gmt': '2026-08-31T23:59:59',
      'usage_count': 42,
      'individual_use': true,
      'product_ids': [12, 14],
      'excluded_product_ids': [99],
      'usage_limit': 100,
      'usage_limit_per_user': 2,
      'limit_usage_to_x_items': 5,
      'free_shipping': true,
      'product_categories': [3, 7],
      'excluded_product_categories': [9],
      'exclude_sale_items': true,
      'minimum_amount': '50.00',
      'maximum_amount': '500.00',
      'email_restrictions': ['vip@example.com'],
      'used_by': ['1', '2', '3'],
      'meta_data': [
        {
          'id': 501,
          'key': '_coupon_custom_rule',
          'value': {
            'address': 'billing',
            'type': 'conditional',
            'condition': 'cart_minimum',
            'values': {
              'cart': {
                'min': '50',
                'max': '500',
              },
              'product': [],
              'product_category': [],
            },
          },
        },
      ],
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/coupons/105',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'DELETE'],
            },
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons'}
        ],
      },
    };

    test('parses full JSON into GETCouponReportModel correctly', () {
      final coupon = GETCouponReportModel.fromJson(sampleJson);

      expect(coupon.id, 105);
      expect(coupon.code, 'SUMMER2026');
      expect(coupon.amount, '15.00');
      expect(coupon.status, 'publish');
      expect(coupon.discountType, 'percent');
      expect(coupon.description, 'Summer season 15% discount for loyal members');
      expect(coupon.usageCount, 42);
      expect(coupon.individualUse, true);
      expect(coupon.freeShipping, true);
      expect(coupon.excludeSaleItems, true);
      expect(coupon.minimumAmount, '50.00');
      expect(coupon.maximumAmount, '500.00');
      expect(coupon.usageLimit, 100);
      expect(coupon.usageLimitPerUser, 2);
      expect(coupon.limitUsageToXItems, 5);
      expect(coupon.productIds, [12, 14]);
      expect(coupon.excludedProductIds, [99]);
      expect(coupon.productCategories, [3, 7]);
      expect(coupon.excludedProductCategories, [9]);
      expect(coupon.emailRestrictions, ['vip@example.com']);
      expect(coupon.usedBy, ['1', '2', '3']);
      expect(coupon.metaData, isNotNull);
      expect(coupon.metaData!.length, 1);
      expect(coupon.metaData!.first.key, '_coupon_custom_rule');
      expect(coupon.metaData!.first.value?.values?.cart?.min, '50');
      expect(coupon.lLinks?.self?.first.href, contains('/coupons/105'));
    });

    test('roundtrips to and from JSON cleanly', () {
      final coupon = GETCouponReportModel.fromJson(sampleJson);
      final json = coupon.toJson();

      expect(json['id'], 105);
      expect(json['code'], 'SUMMER2026');
      expect(json['amount'], '15.00');
      expect(json['status'], 'publish');
      expect(json['discount_type'], 'percent');
      expect(json['free_shipping'], true);
      expect(json['individual_use'], true);
      expect(json['exclude_sale_items'], true);
      expect(json['product_ids'], [12, 14]);
      expect(json['meta_data'], isA<List>());
      expect(json['_links'], isA<Map>());
    });

    test('handles empty and partial JSON gracefully', () {
      final emptyCoupon = GETCouponReportModel.fromJson({});
      expect(emptyCoupon.id, isNull);
      expect(emptyCoupon.code, isNull);
      expect(emptyCoupon.amount, isNull);
      expect(emptyCoupon.freeShipping, isNull);
      expect(emptyCoupon.formattedDiscount, '\$0');
      expect(emptyCoupon.isExpired, false);
      expect(emptyCoupon.usageDisplay, '0 used');
    });

    test('formats percentage discount correctly', () {
      final coupon = GETCouponReportModel(
        code: 'PERC20',
        amount: '20.00',
        discountType: 'percent',
      );
      expect(coupon.formattedDiscount, '20%');
      expect(coupon.discountTypeDisplayName, 'Percentage Discount');
    });

    test('formats fixed cart discount correctly', () {
      final coupon = GETCouponReportModel(
        code: 'CART10',
        amount: '10.00',
        discountType: 'fixed_cart',
      );
      expect(coupon.formattedDiscount, '\$10');
      expect(coupon.discountTypeDisplayName, 'Fixed Cart Discount');
    });

    test('formats fixed product discount correctly', () {
      final coupon = GETCouponReportModel(
        code: 'PROD5',
        amount: '5.00',
        discountType: 'fixed_product',
      );
      expect(coupon.formattedDiscount, '\$5 / item');
      expect(coupon.discountTypeDisplayName, 'Fixed Product Discount');
    });

    test('status display name maps correctly', () {
      expect(GETCouponReportModel(status: 'publish').statusDisplayName, 'Active');
      expect(GETCouponReportModel(status: 'draft').statusDisplayName, 'Draft');
      expect(GETCouponReportModel(status: 'pending').statusDisplayName, 'Pending');
      expect(GETCouponReportModel(status: 'trash').statusDisplayName, 'Trash');
      expect(GETCouponReportModel(status: 'other').statusDisplayName, 'Other');
    });

    test('calculates isExpired correctly based on dateExpires', () {
      final futureCoupon = GETCouponReportModel(dateExpires: '2099-12-31T23:59:59');
      expect(futureCoupon.isExpired, false);

      final expiredCoupon = GETCouponReportModel(dateExpires: '2020-01-01T00:00:00');
      expect(expiredCoupon.isExpired, true);

      final noExpiryCoupon = GETCouponReportModel(dateExpires: null);
      expect(noExpiryCoupon.isExpired, false);
    });

    test('computes usageDisplay with usage limit', () {
      final limitedCoupon = GETCouponReportModel(usageCount: 15, usageLimit: 50);
      expect(limitedCoupon.usageDisplay, '15 / 50');

      final unlimitedCoupon = GETCouponReportModel(usageCount: 7, usageLimit: null);
      expect(unlimitedCoupon.usageDisplay, '7 used');
    });

    test('computes minSpendDisplay and maxSpendDisplay', () {
      final spendCoupon = GETCouponReportModel(minimumAmount: '25.00', maximumAmount: '200.00');
      expect(spendCoupon.minSpendDisplay, '\$25.00 min spend');
      expect(spendCoupon.maxSpendDisplay, '\$200.00 max spend');

      final noSpendCoupon = GETCouponReportModel(minimumAmount: null, maximumAmount: '');
      expect(noSpendCoupon.minSpendDisplay, 'No minimum');
      expect(noSpendCoupon.maxSpendDisplay, 'No maximum');
    });
  });
}
