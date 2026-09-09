import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/coupons/data/models/put_update_coupon_model.dart';

void main() {
  group('PutUpdateCouponModel', () {
    final sampleJson = {
      'id': 801,
      'code': 'AUTUMN2026',
      'amount': '25.00',
      'status': 'publish',
      'date_created': '2026-09-01T12:00:00',
      'date_created_gmt': '2026-09-01T10:00:00',
      'date_modified': '2026-09-09T14:30:00',
      'date_modified_gmt': '2026-09-09T12:30:00',
      'discount_type': 'percent',
      'description': 'Autumn 25% updated discount',
      'date_expires': '2026-11-30T23:59:59',
      'date_expires_gmt': '2026-11-30T21:59:59',
      'usage_count': 5,
      'individual_use': true,
      'product_ids': [101, 102],
      'excluded_product_ids': [201],
      'usage_limit': 200,
      'usage_limit_per_user': 2,
      'limit_usage_to_x_items': 3,
      'free_shipping': true,
      'product_categories': [12, 14],
      'excluded_product_categories': [20],
      'exclude_sale_items': true,
      'minimum_amount': '60.00',
      'maximum_amount': '600.00',
      'email_restrictions': ['vip@example.com'],
      'used_by': ['user_1'],
      'meta_data': [
        {'id': 1, 'key': 'custom_rule', 'value': 'autumn'},
      ],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons/801'},
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons'},
        ],
      },
    };

    test('fromJson correctly parses complete WooCommerce coupon update response', () {
      final model = PutUpdateCouponModel.fromJson(sampleJson);

      expect(model.id, 801);
      expect(model.code, 'AUTUMN2026');
      expect(model.amount, '25.00');
      expect(model.discountType, 'percent');
      expect(model.description, 'Autumn 25% updated discount');
      expect(model.dateExpires, '2026-11-30T23:59:59');
      expect(model.individualUse, isTrue);
      expect(model.freeShipping, isTrue);
      expect(model.excludeSaleItems, isTrue);
      expect(model.minimumAmount, '60.00');
      expect(model.maximumAmount, '600.00');
      expect(model.productIds, [101, 102]);
      expect(model.excludedProductIds, [201]);
      expect(model.productCategories, [12, 14]);
      expect(model.excludedProductCategories, [20]);
      expect(model.emailRestrictions, ['vip@example.com']);
      expect(model.usageLimit, 200);
      expect(model.usageLimitPerUser, 2);
      expect(model.limitUsageToXItems, 3);
      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/coupons/801');
    });

    test('toJson generates matching map representation', () {
      final model = PutUpdateCouponModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 801);
      expect(json['code'], 'AUTUMN2026');
      expect(json['amount'], '25.00');
      expect(json['discount_type'], 'percent');
      expect(json['individual_use'], isTrue);
      expect(json['free_shipping'], isTrue);
      expect(json['minimum_amount'], '60.00');
      expect(json['product_ids'], [101, 102]);
    });

    test('toCouponReportModel seamlessly converts to GETCouponReportModel', () {
      final model = PutUpdateCouponModel.fromJson(sampleJson);
      final report = model.toCouponReportModel();

      expect(report.id, 801);
      expect(report.code, 'AUTUMN2026');
      expect(report.amount, '25.00');
      expect(report.formattedDiscount, '25%');
      expect(report.minSpendDisplay, '\$60.00 min spend');
    });

    test('toUpdatePayload outputs ONLY writable WooCommerce fields without response-only metadata', () {
      final payload = PutUpdateCouponModel.toUpdatePayload(
        code: 'PROMO2026',
        amount: '20',
        discountType: 'fixed_cart',
        description: 'Updated promo description',
        dateExpires: '2026-12-31',
        individualUse: true,
        freeShipping: false,
        excludeSaleItems: true,
        minimumAmount: '40.00',
        maximumAmount: '300.00',
        productIds: [15, 20],
        excludedProductIds: [99],
        productCategories: [5],
        excludedProductCategories: [8],
        emailRestrictions: ['test@example.com'],
        usageLimit: 50,
        usageLimitPerUser: 1,
        limitUsageToXItems: 2,
      );

      // Verify writable fields present
      expect(payload['code'], 'PROMO2026');
      expect(payload['amount'], '20');
      expect(payload['discount_type'], 'fixed_cart');
      expect(payload['description'], 'Updated promo description');
      expect(payload['date_expires'], '2026-12-31');
      expect(payload['individual_use'], isTrue);
      expect(payload['free_shipping'], isFalse);
      expect(payload['exclude_sale_items'], isTrue);
      expect(payload['minimum_amount'], '40.00');
      expect(payload['maximum_amount'], '300.00');
      expect(payload['product_ids'], [15, 20]);
      expect(payload['excluded_product_ids'], [99]);
      expect(payload['product_categories'], [5]);
      expect(payload['excluded_product_categories'], [8]);
      expect(payload['email_restrictions'], ['test@example.com']);
      expect(payload['usage_limit'], 50);
      expect(payload['usage_limit_per_user'], 1);
      expect(payload['limit_usage_to_x_items'], 2);

      // Strictly verify response-only fields are NOT present
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('date_created'), isFalse);
      expect(payload.containsKey('date_created_gmt'), isFalse);
      expect(payload.containsKey('date_modified'), isFalse);
      expect(payload.containsKey('date_modified_gmt'), isFalse);
      expect(payload.containsKey('usage_count'), isFalse);
      expect(payload.containsKey('used_by'), isFalse);
      expect(payload.containsKey('_links'), isFalse);
      expect(payload.containsKey('status'), isFalse);
    });

    test('handles empty and null fields gracefully', () {
      final model = PutUpdateCouponModel.fromJson({});
      expect(model.id, isNull);
      expect(model.code, isNull);
      expect(model.amount, isNull);
      expect(model.productIds, isNull);
      expect(model.lLinks, isNull);

      final json = model.toJson();
      expect(json['id'], isNull);
      expect(json['code'], isNull);
    });
  });
}
