import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/coupons/data/models/post_create_coupon_model.dart';

void main() {
  group('PostCreateCouponModel', () {
    final sampleJson = {
      'id': 701,
      'code': 'SUMMER2026',
      'amount': '15.00',
      'status': 'publish',
      'date_created': '2026-06-01T12:00:00',
      'date_created_gmt': '2026-06-01T10:00:00',
      'date_modified': '2026-06-01T12:00:00',
      'date_modified_gmt': '2026-06-01T10:00:00',
      'discount_type': 'percent',
      'description': 'Summer 15% discount',
      'date_expires': '2026-08-31T23:59:59',
      'date_expires_gmt': '2026-08-31T21:59:59',
      'usage_count': 0,
      'individual_use': true,
      'product_ids': [101, 102],
      'excluded_product_ids': [201],
      'usage_limit': 100,
      'usage_limit_per_user': 1,
      'limit_usage_to_x_items': 5,
      'free_shipping': true,
      'product_categories': [12, 14],
      'excluded_product_categories': [20],
      'exclude_sale_items': true,
      'minimum_amount': '50.00',
      'maximum_amount': '500.00',
      'email_restrictions': ['vip@example.com'],
      'used_by': <dynamic>[],
      'meta_data': [
        {'id': 1, 'key': 'custom_rule', 'value': 'summer'},
      ],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons/701'},
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons'},
        ],
      },
    };

    test('fromJson correctly parses complete WooCommerce coupon response', () {
      final model = PostCreateCouponModel.fromJson(sampleJson);

      expect(model.id, 701);
      expect(model.code, 'SUMMER2026');
      expect(model.amount, '15.00');
      expect(model.discountType, 'percent');
      expect(model.description, 'Summer 15% discount');
      expect(model.dateExpires, '2026-08-31T23:59:59');
      expect(model.individualUse, isTrue);
      expect(model.freeShipping, isTrue);
      expect(model.excludeSaleItems, isTrue);
      expect(model.minimumAmount, '50.00');
      expect(model.maximumAmount, '500.00');
      expect(model.productIds, [101, 102]);
      expect(model.excludedProductIds, [201]);
      expect(model.productCategories, [12, 14]);
      expect(model.excludedProductCategories, [20]);
      expect(model.emailRestrictions, ['vip@example.com']);
      expect(model.usageLimit, 100);
      expect(model.usageLimitPerUser, 1);
      expect(model.limitUsageToXItems, 5);
      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/coupons/701');
    });

    test('toJson generates matching map representation', () {
      final model = PostCreateCouponModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 701);
      expect(json['code'], 'SUMMER2026');
      expect(json['amount'], '15.00');
      expect(json['discount_type'], 'percent');
      expect(json['individual_use'], isTrue);
      expect(json['free_shipping'], isTrue);
      expect(json['minimum_amount'], '50.00');
      expect(json['product_ids'], [101, 102]);
    });

    test('toCreatePayload outputs ONLY writable WooCommerce fields without response-only metadata', () {
      final payload = PostCreateCouponModel.toCreatePayload(
        code: 'WELCOME10',
        amount: '10',
        discountType: 'fixed_cart',
        description: 'Welcome bonus',
        dateExpires: '2026-12-31',
        individualUse: true,
        freeShipping: false,
        excludeSaleItems: true,
        minimumAmount: '30.00',
        maximumAmount: '200.00',
        productIds: [15, 20],
        excludedProductIds: [99],
        productCategories: [5],
        excludedProductCategories: [8],
        emailRestrictions: ['newuser@example.com'],
        usageLimit: 50,
        usageLimitPerUser: 1,
        limitUsageToXItems: 2,
      );

      // Verify writable fields
      expect(payload['code'], 'WELCOME10');
      expect(payload['amount'], '10');
      expect(payload['discount_type'], 'fixed_cart');
      expect(payload['description'], 'Welcome bonus');
      expect(payload['date_expires'], '2026-12-31');
      expect(payload['individual_use'], isTrue);
      expect(payload['free_shipping'], isFalse);
      expect(payload['exclude_sale_items'], isTrue);
      expect(payload['minimum_amount'], '30.00');
      expect(payload['maximum_amount'], '200.00');
      expect(payload['product_ids'], [15, 20]);
      expect(payload['excluded_product_ids'], [99]);
      expect(payload['product_categories'], [5]);
      expect(payload['excluded_product_categories'], [8]);
      expect(payload['email_restrictions'], ['newuser@example.com']);
      expect(payload['usage_limit'], 50);
      expect(payload['usage_limit_per_user'], 1);
      expect(payload['limit_usage_to_x_items'], 2);

      // Verify response-only fields are NOT present in create payload
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('date_created'), isFalse);
      expect(payload.containsKey('date_created_gmt'), isFalse);
      expect(payload.containsKey('date_modified'), isFalse);
      expect(payload.containsKey('date_modified_gmt'), isFalse);
      expect(payload.containsKey('usage_count'), isFalse);
      expect(payload.containsKey('_links'), isFalse);
      expect(payload.containsKey('used_by'), isFalse);
    });

    test('handles empty and null fields gracefully', () {
      final model = PostCreateCouponModel.fromJson({});

      expect(model.id, isNull);
      expect(model.code, isNull);
      expect(model.amount, isNull);
      expect(model.productIds, isNull);
      expect(model.lLinks, isNull);

      final json = model.toJson();
      expect(json['id'], isNull);
    });
  });
}
