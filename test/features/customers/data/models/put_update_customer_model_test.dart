import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/customers/data/models/put_update_customer_model.dart';

void main() {
  group('PutUpdateCustomerModel', () {
    final sampleJson = {
      'id': 123,
      'date_created': '2026-03-01T10:00:00',
      'date_created_gmt': '2026-03-01T14:00:00',
      'date_modified': '2026-03-02T12:30:00',
      'date_modified_gmt': '2026-03-02T16:30:00',
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
        'address_2': 'Apt 4B',
        'city': 'Los Angeles',
        'postcode': '90001',
        'country': 'US',
        'state': 'CA',
        'email': 'sarah.connor@example.com',
        'phone': '+1 555-0199',
      },
      'shipping': {
        'first_name': 'Sarah',
        'last_name': 'Connor',
        'company': 'Cyberdyne Resistance',
        'address_1': '742 Evergreen Terrace',
        'address_2': 'Apt 4B',
        'city': 'Los Angeles',
        'postcode': '90001',
        'country': 'US',
        'state': 'CA',
        'phone': '+1 555-0199',
      },
      'is_paying_customer': true,
      'avatar_url': 'https://example.com/avatar.jpg',
      'meta_data': [
        {'id': 1, 'key': 'loyalty_level', 'value': 'platinum'}
      ],
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/customers/123',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'DELETE']
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/customers'}
        ]
      }
    };

    test('parses full JSON into PutUpdateCustomerModel correctly', () {
      final model = PutUpdateCustomerModel.fromJson(sampleJson);

      expect(model.id, 123);
      expect(model.email, 'sarah.connor@example.com');
      expect(model.firstName, 'Sarah');
      expect(model.lastName, 'Connor');
      expect(model.role, 'customer');
      expect(model.username, 'sconnor');
      expect(model.isPayingCustomer, isTrue);
      expect(model.avatarUrl, 'https://example.com/avatar.jpg');

      // Billing
      expect(model.billing?.firstName, 'Sarah');
      expect(model.billing?.lastName, 'Connor');
      expect(model.billing?.city, 'Los Angeles');
      expect(model.billing?.state, 'CA');
      expect(model.billing?.phone, '+1 555-0199');
      expect(model.billing?.fullName, 'Sarah Connor');
      expect(model.billing?.fullAddress, contains('742 Evergreen Terrace'));

      // Shipping
      expect(model.shipping?.firstName, 'Sarah');
      expect(model.shipping?.city, 'Los Angeles');
      expect(model.shipping?.fullName, 'Sarah Connor');

      // Metadata & Links
      expect(model.metaData?.length, 1);
      expect(model.metaData?.first.key, 'loyalty_level');
      expect(model.metaData?.first.value, 'platinum');
      expect(model.lLinks?.self?.first.href, contains('/customers/123'));
      expect(model.lLinks?.self?.first.targetHints?.allow, contains('PUT'));

      // Getters
      expect(model.displayName, 'Sarah Connor');
      expect(model.roleDisplayName, 'Customer');
    });

    test('round-trips to and from JSON cleanly', () {
      final model = PutUpdateCustomerModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 123);
      expect(json['first_name'], 'Sarah');
      expect(json['billing']['city'], 'Los Angeles');
      expect(json['shipping']['state'], 'CA');
      expect(json['meta_data'], isNotEmpty);
      expect(json['_links'], isNotNull);
    });

    test('handles empty and null JSON gracefully', () {
      final model = PutUpdateCustomerModel.fromJson({});

      expect(model.id, isNull);
      expect(model.email, isNull);
      expect(model.firstName, isNull);
      expect(model.lastName, isNull);
      expect(model.billing, isNull);
      expect(model.shipping, isNull);
      expect(model.metaData, isNull);
      expect(model.lLinks, isNull);
      expect(model.displayName, 'Customer #null');
      expect(model.roleDisplayName, 'Customer');
    });

    test('computes displayName fallbacks correctly', () {
      final modelWithUsername = PutUpdateCustomerModel(
        id: 456,
        username: 'tech_guru',
      );
      expect(modelWithUsername.displayName, 'tech_guru');

      final modelWithEmailOnly = PutUpdateCustomerModel(
        id: 789,
        email: 'user@domain.com',
      );
      expect(modelWithEmailOnly.displayName, 'user@domain.com');
    });

    test('computes roleDisplayName with mixed case roles', () {
      final admin = PutUpdateCustomerModel(role: 'ADMINISTRATOR');
      expect(admin.roleDisplayName, 'Administrator');

      final shopManager = PutUpdateCustomerModel(role: 'shop_manager');
      expect(shopManager.roleDisplayName, 'Shop_manager');
    });

    test('submodels serialization and deserialization', () {
      final billing = Billing(
        firstName: 'John',
        lastName: 'Rambo',
        city: 'Hope',
        state: 'WA',
      );
      final bJson = billing.toJson();
      final parsedB = Billing.fromJson(bJson);
      expect(parsedB.fullName, 'John Rambo');
      expect(parsedB.city, 'Hope');

      final shipping = Shipping(
        firstName: 'John',
        lastName: 'Rambo',
        country: 'US',
      );
      final sJson = shipping.toJson();
      final parsedS = Shipping.fromJson(sJson);
      expect(parsedS.fullName, 'John Rambo');
      expect(parsedS.country, 'US');

      final meta = MetaData(id: 10, key: 'source', value: 'mobile_app');
      final mJson = meta.toJson();
      final parsedM = MetaData.fromJson(mJson);
      expect(parsedM.key, 'source');
      expect(parsedM.value, 'mobile_app');
    });
  });
}
