import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/orders/data/models/delete_order_model.dart';

void main() {
  group('DeleteOrderModel', () {
    final sampleJson = {
      'id': 789,
      'parent_id': 0,
      'status': 'cancelled',
      'currency': 'USD',
      'version': '9.2.0',
      'prices_include_tax': false,
      'date_created': '2026-05-01T10:00:00',
      'date_modified': '2026-05-01T10:05:00',
      'discount_total': '0.00',
      'discount_tax': '0.00',
      'shipping_total': '15.00',
      'shipping_tax': '1.50',
      'cart_tax': '5.00',
      'total': '215.00',
      'total_tax': '6.50',
      'customer_id': 88,
      'order_key': 'wc_order_del123',
      'billing': {
        'first_name': 'Bruce',
        'last_name': 'Wayne',
        'company': 'Wayne Enterprises',
        'address_1': '1007 Mountain Drive',
        'address_2': 'Suite 1',
        'city': 'Gotham',
        'state': 'NJ',
        'postcode': '07001',
        'country': 'US',
        'email': 'bruce@waynecorp.com',
        'phone': '+1 555-0199',
      },
      'shipping': {
        'first_name': 'Bruce',
        'last_name': 'Wayne',
        'company': 'Wayne Enterprises',
        'address_1': '1007 Mountain Drive',
        'address_2': 'Suite 1',
        'city': 'Gotham',
        'state': 'NJ',
        'postcode': '07001',
        'country': 'US',
        'phone': '+1 555-0199',
      },
      'payment_method': 'cod',
      'payment_method_title': 'Cash on delivery',
      'transaction_id': 'txn_delete_456',
      'customer_ip_address': '127.0.0.1',
      'customer_user_agent': 'Mozilla/5.0',
      'created_via': 'admin',
      'customer_note': 'Delete me test',
      'date_completed': null,
      'date_paid': null,
      'cart_hash': 'carthash789',
      'number': '789',
      'meta_data': [],
      'line_items': [
        {
          'id': 101,
          'name': 'Batmobile Tire',
          'product_id': 202,
          'variation_id': 0,
          'quantity': 2,
          'tax_class': '',
          'subtotal': '200.00',
          'subtotal_tax': '5.00',
          'total': '200.00',
          'total_tax': '5.00',
          'taxes': [
            {'id': 1, 'total': '5.00', 'subtotal': '5.00'}
          ],
          'meta_data': [],
          'sku': 'BAT-TIRE-01',
          'global_unique_id': 'uuid-tire',
          'price': 100.0,
          'image': {'id': 'img_1', 'src': 'https://example.com/tire.png'},
          'parent_name': null,
        }
      ],
      'tax_lines': [
        {
          'id': 1,
          'rate_code': 'US-NJ-TAX',
          'rate_id': 10,
          'label': 'State Tax',
          'compound': false,
          'tax_total': '6.50',
          'shipping_tax_total': '1.50',
          'rate_percent': 6.625,
          'meta_data': [],
        }
      ],
      'shipping_lines': [],
      'fee_lines': [],
      'coupon_lines': [],
      'refunds': [],
      'payment_url': 'https://example.com/pay',
      'is_editable': false,
      'needs_payment': false,
      'needs_processing': false,
      'date_created_gmt': '2026-05-01T14:00:00',
      'date_modified_gmt': '2026-05-01T14:05:00',
      'date_completed_gmt': null,
      'date_paid_gmt': null,
      'currency_symbol': '\$',
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/orders/789',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'DELETE']
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/orders'}
        ],
        'email_templates': [
          {'embeddable': true, 'href': 'https://example.com/email'}
        ]
      }
    };

    test('fromJson correctly parses all fields', () {
      final model = DeleteOrderModel.fromJson(sampleJson);

      expect(model.id, 789);
      expect(model.parentId, 0);
      expect(model.status, 'cancelled');
      expect(model.currency, 'USD');
      expect(model.total, '215.00');
      expect(model.customerId, 88);
      expect(model.billing?.firstName, 'Bruce');
      expect(model.billing?.lastName, 'Wayne');
      expect(model.billing?.city, 'Gotham');
      expect(model.shipping?.address1, '1007 Mountain Drive');
      expect(model.lineItems?.length, 1);
      expect(model.lineItems?.first.name, 'Batmobile Tire');
      expect(model.lineItems?.first.price, 100.0);
      expect(model.lineItems?.first.image?.src, 'https://example.com/tire.png');
      expect(model.taxLines?.length, 1);
      expect(model.taxLines?.first.label, 'State Tax');
      expect(model.lLinks?.self?.first.href, 'https://example.com/wp-json/wc/v3/orders/789');
      expect(model.lLinks?.self?.first.targetHints?.allow, contains('DELETE'));
      expect(model.displayOrderNumber, '#789');
      expect(model.statusDisplayName, 'Cancelled');
    });

    test('toJson serializes correctly and roundtrips', () {
      final model = DeleteOrderModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 789);
      expect(json['status'], 'cancelled');
      expect(json['total'], '215.00');
      expect(json['billing']['first_name'], 'Bruce');
      expect(json['shipping']['city'], 'Gotham');
      expect((json['line_items'] as List).length, 1);
      expect((json['tax_lines'] as List).length, 1);
      expect(json['_links'], isNotNull);
    });

    test('fromJson handles null/empty json safely', () {
      final model = DeleteOrderModel.fromJson({});

      expect(model.id, isNull);
      expect(model.status, isNull);
      expect(model.billing, isNull);
      expect(model.shipping, isNull);
      expect(model.lineItems, isNull);
      expect(model.taxLines, isNull);
      expect(model.displayOrderNumber, '');
      expect(model.statusDisplayName, 'Unknown');
    });

    test('displayOrderNumber falls back to id when number is null', () {
      final model = DeleteOrderModel(id: 42, number: null);
      expect(model.displayOrderNumber, '#42');
    });

    test('statusDisplayName formats lowercase or mixed status correctly', () {
      final model1 = DeleteOrderModel(status: 'processing');
      expect(model1.statusDisplayName, 'Processing');

      final model2 = DeleteOrderModel(status: 'ON-HOLD');
      expect(model2.statusDisplayName, 'On-hold');
    });

    test('submodels serialization and deserialization', () {
      final billing = Billing(
        firstName: 'Diana',
        lastName: 'Prince',
        city: 'Themyscira',
        email: 'diana@amazon.com',
      );
      final billingJson = billing.toJson();
      final parsedBilling = Billing.fromJson(billingJson);
      expect(parsedBilling.firstName, 'Diana');
      expect(parsedBilling.city, 'Themyscira');

      final shipping = Shipping(
        firstName: 'Diana',
        lastName: 'Prince',
        city: 'Themyscira',
      );
      final shippingJson = shipping.toJson();
      final parsedShipping = Shipping.fromJson(shippingJson);
      expect(parsedShipping.firstName, 'Diana');

      final lineItem = LineItems(
        id: 1,
        name: 'Lasso of Truth',
        price: 999.99,
        quantity: 1,
      );
      final itemJson = lineItem.toJson();
      final parsedItem = LineItems.fromJson(itemJson);
      expect(parsedItem.name, 'Lasso of Truth');
      expect(parsedItem.price, 999.99);

      final taxes = Taxes(id: 1, total: '10.00', subtotal: '10.00');
      final taxesJson = taxes.toJson();
      final parsedTaxes = Taxes.fromJson(taxesJson);
      expect(parsedTaxes.total, '10.00');

      final taxLine = TaxLines(
        id: 2,
        rateCode: 'VAT',
        rateId: 5,
        label: 'VAT 20%',
        ratePercent: 20.0,
      );
      final taxLineJson = taxLine.toJson();
      final parsedTaxLine = TaxLines.fromJson(taxLineJson);
      expect(parsedTaxLine.label, 'VAT 20%');
      expect(parsedTaxLine.ratePercent, 20.0);

      final links = Links.fromJson({
        'self': [
          {
            'href': 'https://api.test',
            'targetHints': {
              'allow': ['DELETE']
            }
          }
        ],
        'collection': [
          {'href': 'https://api.test/collection'}
        ],
        'email_templates': [
          {'embeddable': false, 'href': 'https://api.test/email'}
        ]
      });
      final linksJson = links.toJson();
      expect(linksJson['self'], isNotEmpty);
      expect(linksJson['collection'], isNotEmpty);
      expect(linksJson['email_templates'], isNotEmpty);
    });
  });
}
