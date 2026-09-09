import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/customers/data/models/delete_customer_model.dart';

void main() {
  group('DeleteCustomerModel', () {
    final sampleJson = {
      'id': 105,
      'date_created': '2023-01-15T12:00:00',
      'date_created_gmt': '2023-01-15T10:00:00',
      'date_modified': '2023-06-20T14:30:00',
      'date_modified_gmt': '2023-06-20T12:30:00',
      'email': 'john.doe@example.com',
      'first_name': 'John',
      'last_name': 'Doe',
      'role': 'customer',
      'username': 'johndoe',
      'billing': {
        'first_name': 'John',
        'last_name': 'Doe',
        'company': 'Acme Corp',
        'address_1': '123 Main St',
        'address_2': 'Apt 4B',
        'city': 'Metropolis',
        'postcode': '10001',
        'country': 'US',
        'state': 'NY',
        'email': 'john.doe@example.com',
        'phone': '+1 555-0199',
      },
      'shipping': {
        'first_name': 'John',
        'last_name': 'Doe',
        'company': 'Acme Corp',
        'address_1': '123 Main St',
        'address_2': 'Apt 4B',
        'city': 'Metropolis',
        'postcode': '10001',
        'country': 'US',
        'state': 'NY',
        'phone': '+1 555-0199',
      },
      'is_paying_customer': true,
      'avatar_url': 'https://secure.gravatar.com/avatar/test.jpg',
      'meta_data': [
        {'id': 1, 'key': 'test_key', 'value': 'test_value'},
      ],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/customers/105'},
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/customers'},
        ],
      },
    };

    test('fromJson creates a valid DeleteCustomerModel', () {
      final model = DeleteCustomerModel.fromJson(sampleJson);

      expect(model.id, 105);
      expect(model.firstName, 'John');
      expect(model.lastName, 'Doe');
      expect(model.email, 'john.doe@example.com');
      expect(model.role, 'customer');
      expect(model.username, 'johndoe');
      expect(model.isPayingCustomer, isTrue);
      expect(model.billing?.city, 'Metropolis');
      expect(model.billing?.phone, '+1 555-0199');
      expect(model.shipping?.city, 'Metropolis');
      expect(model.metaData?.length, 1);
      expect(model.metaData?.first.key, 'test_key');
      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/customers/105');
    });

    test('toJson produces equivalent map representation', () {
      final model = DeleteCustomerModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 105);
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['billing']['city'], 'Metropolis');
      expect(json['shipping']['city'], 'Metropolis');
      expect(json['is_paying_customer'], isTrue);
      expect(json['meta_data'], isA<List>());
      expect(json['_links']['self'], isA<List>());
    });

    test('handles empty or null fields gracefully', () {
      final model = DeleteCustomerModel.fromJson({});

      expect(model.id, isNull);
      expect(model.email, isNull);
      expect(model.billing, isNull);
      expect(model.shipping, isNull);
      expect(model.metaData, isNull);
      expect(model.lLinks, isNull);

      final json = model.toJson();
      expect(json['id'], isNull);
    });
  });
}
