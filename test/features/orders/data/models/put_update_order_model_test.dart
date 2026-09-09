import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/orders/data/models/put_update_order_model.dart';

void main() {
  group('PutUpdateOrderModel', () {
    final sampleJson = {
      'id': 723,
      'parent_id': 0,
      'status': 'completed',
      'currency': 'USD',
      'version': '9.0.0',
      'prices_include_tax': false,
      'date_created': '2026-04-10T12:00:00',
      'date_modified': '2026-04-11T15:30:00',
      'discount_total': '10.00',
      'discount_tax': '0.00',
      'shipping_total': '5.00',
      'shipping_tax': '0.00',
      'cart_tax': '2.50',
      'total': '147.50',
      'total_tax': '2.50',
      'customer_id': 45,
      'order_key': 'wc_order_abc123',
      'billing': {
        'first_name': 'John',
        'last_name': 'Doe',
        'company': 'Acme Corp',
        'address_1': '123 Main St',
        'address_2': 'Suite 100',
        'city': 'New York',
        'state': 'NY',
        'postcode': '10001',
        'country': 'US',
        'email': 'john.doe@example.com',
        'phone': '+1 555-0100',
      },
      'shipping': {
        'first_name': 'Jane',
        'last_name': 'Doe',
        'company': 'Acme Corp',
        'address_1': '456 Elm St',
        'address_2': '',
        'city': 'Brooklyn',
        'state': 'NY',
        'postcode': '11201',
        'country': 'US',
        'phone': '+1 555-0200',
      },
      'payment_method': 'bacs',
      'payment_method_title': 'Direct Bank Transfer',
      'transaction_id': 'txn_98765',
      'customer_ip_address': '192.168.1.1',
      'customer_user_agent': 'Mozilla/5.0',
      'created_via': 'checkout',
      'customer_note': 'Please leave at front door',
      'date_completed': '2026-04-11T15:30:00',
      'date_paid': '2026-04-10T12:05:00',
      'cart_hash': 'hash_xyz',
      'number': '723',
      'meta_data': [
        {'id': 101, 'key': 'priority', 'value': 'high'},
      ],
      'line_items': [
        {
          'id': 15,
          'name': 'Premium Leather Case',
          'product_id': 88,
          'variation_id': 0,
          'quantity': 2,
          'tax_class': '',
          'subtotal': '100.00',
          'subtotal_tax': '0.00',
          'total': '100.00',
          'total_tax': '0.00',
          'taxes': [
            {'id': 1, 'total': '0.00', 'subtotal': '0.00'},
          ],
          'meta_data': [],
          'sku': 'CASE-LTH-01',
          'global_unique_id': 'guid-123',
          'price': 50.0,
          'image': {
            'id': '99',
            'src': 'https://example.com/item.jpg',
          },
          'parent_name': null,
        }
      ],
      'tax_lines': [
        {
          'id': 1,
          'rate_code': 'US-NY-TAX',
          'rate_id': 1,
          'label': 'State Tax',
          'compound': false,
          'tax_total': '2.50',
          'shipping_tax_total': '0.00',
          'rate_percent': 4.0,
          'meta_data': [],
        }
      ],
      'shipping_lines': [],
      'fee_lines': [],
      'coupon_lines': [],
      'refunds': [],
      'payment_url': 'https://example.com/checkout/order-pay/723',
      'is_editable': true,
      'needs_payment': false,
      'needs_processing': false,
      'date_created_gmt': '2026-04-10T12:00:00',
      'date_modified_gmt': '2026-04-11T15:30:00',
      'date_completed_gmt': '2026-04-11T15:30:00',
      'date_paid_gmt': '2026-04-10T12:05:00',
      'currency_symbol': '\$',
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/orders/723',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'DELETE'],
            },
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/orders'}
        ],
        'email_templates': [
          {
            'embeddable': true,
            'href': 'https://example.com/email-template',
          }
        ],
      },
    };

    test('parses full JSON into PutUpdateOrderModel correctly', () {
      final order = PutUpdateOrderModel.fromJson(sampleJson);

      expect(order.id, 723);
      expect(order.status, 'completed');
      expect(order.currency, 'USD');
      expect(order.total, '147.50');
      expect(order.customerNote, 'Please leave at front door');
      expect(order.paymentMethod, 'bacs');
      expect(order.paymentMethodTitle, 'Direct Bank Transfer');
      expect(order.transactionId, 'txn_98765');
      expect(order.billing?.firstName, 'John');
      expect(order.billing?.lastName, 'Doe');
      expect(order.billing?.city, 'New York');
      expect(order.billing?.email, 'john.doe@example.com');
      expect(order.shipping?.city, 'Brooklyn');
      expect(order.lineItems?.length, 1);
      expect(order.lineItems?.first.name, 'Premium Leather Case');
      expect(order.lineItems?.first.quantity, 2);
      expect(order.taxLines?.length, 1);
      expect(order.taxLines?.first.rateCode, 'US-NY-TAX');
      expect(order.lLinks?.self?.first.href, contains('/orders/723'));
      expect(order.lLinks?.emailTemplates?.first.href, contains('/email-template'));
    });

    test('round-trips to and from JSON cleanly', () {
      final order = PutUpdateOrderModel.fromJson(sampleJson);
      final json = order.toJson();

      expect(json['id'], 723);
      expect(json['status'], 'completed');
      expect(json['total'], '147.50');
      expect(json['billing']['first_name'], 'John');
      expect(json['shipping']['first_name'], 'Jane');
      expect(json['line_items'], isA<List>());
      expect(json['tax_lines'], isA<List>());
      expect(json['_links'], isA<Map>());
    });

    test('handles empty and null JSON gracefully', () {
      final emptyOrder = PutUpdateOrderModel.fromJson({});

      expect(emptyOrder.id, isNull);
      expect(emptyOrder.status, isNull);
      expect(emptyOrder.billing, isNull);
      expect(emptyOrder.shipping, isNull);
      expect(emptyOrder.lineItems, isNull);
      expect(emptyOrder.displayOrderNumber, '');
      expect(emptyOrder.statusDisplayName, 'Unknown');
    });

    test('computes displayOrderNumber and statusDisplayName correctly', () {
      final orderWithNumber = PutUpdateOrderModel(number: '999', status: 'processing');
      expect(orderWithNumber.displayOrderNumber, '#999');
      expect(orderWithNumber.statusDisplayName, 'Processing');

      final orderWithIdOnly = PutUpdateOrderModel(id: 123, status: 'on-hold');
      expect(orderWithIdOnly.displayOrderNumber, '#123');
      expect(orderWithIdOnly.statusDisplayName, 'On-hold');
    });
  });
}
