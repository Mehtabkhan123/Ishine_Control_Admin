import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/customers/data/models/get_customers_model.dart';

void main() {
  group('GETCustomersModel', () {
    final sampleJson = {
      'id': 25,
      'date_created': '2025-10-15T14:30:00',
      'date_created_gmt': '2025-10-15T14:30:00',
      'date_modified': '2025-11-01T09:15:00',
      'date_modified_gmt': '2025-11-01T09:15:00',
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
        'address_2': 'Suite 400',
        'city': 'New York',
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
        'address_2': 'Suite 400',
        'city': 'New York',
        'postcode': '10001',
        'country': 'US',
        'state': 'NY',
        'phone': '+1 555-0199',
      },
      'is_paying_customer': true,
      'avatar_url': 'https://secure.gravatar.com/avatar/sample',
      'meta_data': [
        {'id': 101, 'key': 'vat_number', 'value': 'US123456789'},
      ],
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/customers/25',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'DELETE'],
            },
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/customers'}
        ],
      },
    };

    test('parses complete JSON correctly', () {
      final customer = GETCustomersModel.fromJson(sampleJson);

      expect(customer.id, 25);
      expect(customer.email, 'john.doe@example.com');
      expect(customer.firstName, 'John');
      expect(customer.lastName, 'Doe');
      expect(customer.role, 'customer');
      expect(customer.username, 'johndoe');
      expect(customer.isPayingCustomer, true);
      expect(customer.avatarUrl, 'https://secure.gravatar.com/avatar/sample');
      expect(customer.billing, isNotNull);
      expect(customer.billing?.city, 'New York');
      expect(customer.billing?.phone, '+1 555-0199');
      expect(customer.shipping, isNotNull);
      expect(customer.shipping?.city, 'New York');
      expect(customer.metaData?.length, 1);
      expect(customer.metaData?.first.key, 'vat_number');
      expect(customer.metaData?.first.value, 'US123456789');
      expect(customer.lLinks?.self?.first.href, contains('/customers/25'));
    });

    test('converts back to JSON cleanly (roundtrip)', () {
      final customer = GETCustomersModel.fromJson(sampleJson);
      final json = customer.toJson();

      expect(json['id'], 25);
      expect(json['email'], 'john.doe@example.com');
      expect(json['first_name'], 'John');
      expect(json['last_name'], 'Doe');
      expect(json['is_paying_customer'], true);
      expect(json['billing']['city'], 'New York');
      expect(json['shipping']['country'], 'US');
    });

    test('computes convenience getters correctly', () {
      final customer = GETCustomersModel.fromJson(sampleJson);

      expect(customer.displayName, 'John Doe');
      expect(customer.initials, 'JD');
      expect(customer.primaryPhone, '+1 555-0199');
      expect(customer.locationSummary, 'New York, US');
      expect(customer.roleDisplayName, 'Customer');
      expect(customer.parsedDateCreated, isNotNull);
      expect(customer.parsedDateCreated?.year, 2025);
    });

    test('handles fallback display name when first and last name are empty', () {
      final minimal = GETCustomersModel(
        id: 42,
        username: 'guest_user',
        email: 'guest@example.com',
      );

      expect(minimal.displayName, 'guest_user');
      expect(minimal.initials, 'G');
      expect(minimal.locationSummary, 'Location not provided');
      expect(minimal.roleDisplayName, 'Customer');
    });
  });
}
