import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/coupons/data/models/delete_coupon_model.dart';

void main() {
  group('DeleteCouponModel', () {
    final sampleJson = {
      'id': 901,
      'code': 'DELETE_ME',
      'amount': '10.00',
      'status': 'publish',
      'date_created': '2026-05-01T12:00:00',
      'date_created_gmt': '2026-05-01T10:00:00',
      'date_modified': '2026-05-01T12:00:00',
      'date_modified_gmt': '2026-05-01T10:00:00',
      'discount_type': 'percent',
      'description': 'Temporary promotion to be deleted',
      'date_expires': '2026-06-01T23:59:59',
      'date_expires_gmt': '2026-06-01T21:59:59',
      'usage_count': 0,
      'individual_use': false,
      'product_ids': [10, 20],
      'excluded_product_ids': [30],
      'usage_limit': 50,
      'usage_limit_per_user': 1,
      'limit_usage_to_x_items': 2,
      'free_shipping': false,
      'product_categories': [1],
      'excluded_product_categories': [2],
      'exclude_sale_items': false,
      'minimum_amount': '25.00',
      'maximum_amount': '150.00',
      'email_restrictions': ['guest@example.com'],
      'used_by': <dynamic>[],
      'meta_data': [
        {'id': 1, 'key': 'test_key', 'value': 'test_val'},
      ],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons/901'},
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/coupons'},
        ],
      },
    };

    test('fromJson correctly parses complete WooCommerce coupon delete response', () {
      final model = DeleteCouponModel.fromJson(sampleJson);

      expect(model.id, 901);
      expect(model.code, 'DELETE_ME');
      expect(model.amount, '10.00');
      expect(model.discountType, 'percent');
      expect(model.description, 'Temporary promotion to be deleted');
      expect(model.dateExpires, '2026-06-01T23:59:59');
      expect(model.individualUse, isFalse);
      expect(model.freeShipping, isFalse);
      expect(model.minimumAmount, '25.00');
      expect(model.maximumAmount, '150.00');
      expect(model.productIds, [10, 20]);
      expect(model.excludedProductIds, [30]);
      expect(model.productCategories, [1]);
      expect(model.excludedProductCategories, [2]);
      expect(model.emailRestrictions, ['guest@example.com']);
      expect(model.usageLimit, 50);
      expect(model.usageLimitPerUser, 1);
      expect(model.limitUsageToXItems, 2);
      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/coupons/901');
    });

    test('toJson generates matching map representation', () {
      final model = DeleteCouponModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 901);
      expect(json['code'], 'DELETE_ME');
      expect(json['amount'], '10.00');
      expect(json['discount_type'], 'percent');
      expect(json['product_ids'], [10, 20]);
    });

    test('handles empty and null fields gracefully', () {
      final model = DeleteCouponModel.fromJson({});
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
