import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/customers/data/models/get_customers_model.dart';
import 'package:ishine_admin_app/features/customers/data/models/get_single_customers_model.dart';

void main() {
  group('GETSingleCustomersModel', () {
    final sampleJson = {
      'id': 42,
      'date_created': '2025-11-20T08:45:00',
      'date_created_gmt': '2025-11-20T08:45:00',
      'date_modified': '2026-01-10T11:20:00',
      'date_modified_gmt': '2026-01-10T11:20:00',
      'email': 'sarah.connor@example.com',
      'first_name': 'Sarah',
      'last_name': 'Connor',
      'role': 'customer',
      'username': 'sconnor',
      'billing': {
        'first_name': 'Sarah',
        'last_name': 'Connor',
        'company': 'Cyberdyne Resistance',
        'address_1': '742 Evergreen Terrace',
        'address_2': 'Apt 2B',
        'city': 'Los Angeles',
        'postcode': '90001',
        'country': 'US',
        'state': 'CA',
        'email': 'sarah.connor@example.com',
        'phone': '+1 310-555-0144',
      },
      'shipping': {
        'first_name': 'Sarah',
        'last_name': 'Connor',
        'company': 'Cyberdyne Resistance',
        'address_1': '742 Evergreen Terrace',
        'address_2': 'Apt 2B',
        'city': 'Los Angeles',
        'postcode': '90001',
        'country': 'US',
        'state': 'CA',
        'phone': '+1 310-555-0144',
      },
      'is_paying_customer': true,
      'avatar_url': 'https://secure.gravatar.com/avatar/sconnor_avatar',
      'meta_data': [
        {'id': 201, 'key': 'loyalty_tier', 'value': 'platinum'},
        {'id': 202, 'key': 'newsletter_opt_in', 'value': 'yes'},
      ],
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/customers/42',
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

    test('parses complete single customer response correctly', () {
      final customer = GETSingleCustomersModel.fromJson(sampleJson);

      expect(customer.id, 42);
      expect(customer.email, 'sarah.connor@example.com');
      expect(customer.firstName, 'Sarah');
      expect(customer.lastName, 'Connor');
      expect(customer.role, 'customer');
      expect(customer.username, 'sconnor');
      expect(customer.isPayingCustomer, true);
      expect(customer.avatarUrl, 'https://secure.gravatar.com/avatar/sconnor_avatar');
      expect(customer.billing, isNotNull);
      expect(customer.billing?.company, 'Cyberdyne Resistance');
      expect(customer.billing?.phone, '+1 310-555-0144');
      expect(customer.shipping, isNotNull);
      expect(customer.shipping?.city, 'Los Angeles');
      expect(customer.metaData?.length, 2);
      expect(customer.metaData?.first.key, 'loyalty_tier');
      expect(customer.metaData?.first.value, 'platinum');
      expect(customer.lLinks?.self?.first.href, contains('/customers/42'));
    });

    test('roundtrips to and from JSON cleanly', () {
      final customer = GETSingleCustomersModel.fromJson(sampleJson);
      final json = customer.toJson();

      expect(json['id'], 42);
      expect(json['email'], 'sarah.connor@example.com');
      expect(json['is_paying_customer'], true);
      expect(json['billing']['city'], 'Los Angeles');
      expect(json['shipping']['state'], 'CA');
    });

    test('fromCustomersModel factory converts seamlessly', () {
      final listModel = GETCustomersModel(
        id: 77,
        firstName: 'John',
        lastName: 'Wick',
        email: 'j.wick@continental.com',
        username: 'babayaga',
        role: 'customer',
        isPayingCustomer: true,
      );

      final singleModel = GETSingleCustomersModel.fromCustomersModel(listModel);

      expect(singleModel.id, 77);
      expect(singleModel.firstName, 'John');
      expect(singleModel.lastName, 'Wick');
      expect(singleModel.email, 'j.wick@continental.com');
      expect(singleModel.displayName, 'John Wick');
      expect(singleModel.initials, 'JW');
      expect(singleModel.isPayingCustomer, true);
    });

    test('computed convenience getters work as expected', () {
      final customer = GETSingleCustomersModel.fromJson(sampleJson);

      expect(customer.displayName, 'Sarah Connor');
      expect(customer.initials, 'SC');
      expect(customer.primaryPhone, '+1 310-555-0144');
      expect(customer.locationSummary, 'Los Angeles, US');
      expect(customer.roleDisplayName, 'Customer');
      expect(customer.parsedDateCreated, isNotNull);
      expect(customer.parsedDateCreated?.year, 2025);
      expect(customer.parsedDateModified, isNotNull);
      expect(customer.parsedDateModified?.year, 2026);
    });
  });
}
