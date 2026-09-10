import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/models/get_payment_gateways_model.dart';

void main() {
  group('GetPaymentGatewaysModel', () {
    final sampleJson = {
      'id': 'bacs',
      'title': 'Direct Bank Transfer',
      'description': 'Make your payment directly into our bank account.',
      'order': 1,
      'enabled': true,
      'method_title': 'Direct bank transfer (BACS)',
      'method_description': 'Allows payments by BACS, more commonly known as direct bank/wire transfer.',
      'method_supports': ['products'],
      'settings': {
        'title': {
          'id': 'title',
          'label': 'Title',
          'description': 'This controls the title which the user sees during checkout.',
          'type': 'text',
          'value': 'Direct Bank Transfer',
          'default': 'Direct bank transfer',
          'tip': 'Payment method title',
          'placeholder': 'Direct bank transfer'
        },
        'enabled': {
          'id': 'enabled',
          'label': 'Enable/Disable',
          'description': 'Enable direct bank transfer',
          'type': 'checkbox',
          'value': 'yes',
          'default': 'no',
          'tip': '',
          'placeholder': ''
        }
      },
      'needs_setup': false,
      'post_install_scripts': ['setup_bacs.js'],
      'settings_url': 'https://example.com/wp-admin/admin.php?page=wc-settings&tab=checkout&section=bacs',
      'connection_url': null,
      'setup_help_text': null,
      'required_settings_keys': ['title'],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/payment_gateways/bacs'}
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/payment_gateways'}
        ]
      }
    };

    test('fromJson parses WooCommerce payment gateway JSON correctly', () {
      final model = GetPaymentGatewaysModel.fromJson(sampleJson);

      expect(model.id, 'bacs');
      expect(model.title, 'Direct Bank Transfer');
      expect(model.description, 'Make your payment directly into our bank account.');
      expect(model.order, 1);
      expect(model.enabled, true);
      expect(model.methodTitle, 'Direct bank transfer (BACS)');
      expect(model.methodDescription,
          'Allows payments by BACS, more commonly known as direct bank/wire transfer.');
      expect(model.methodSupports, ['products']);
      expect(model.needsSetup, false);
      expect(model.postInstallScripts, ['setup_bacs.js']);
      expect(model.settingsUrl, contains('section=bacs'));
      expect(model.requiredSettingsKeys, ['title']);

      expect(model.settings, isNotNull);
      expect(model.settings!.length, 2);
      expect(model.settings!['title']?.label, 'Title');
      expect(model.settings!['title']?.value, 'Direct Bank Transfer');
      expect(model.settings!['enabled']?.value, 'yes');

      expect(model.displayTitle, 'Direct Bank Transfer');
      expect(model.displayMethodTitle, 'Direct bank transfer (BACS)');
      expect(model.formattedId, '#bacs');
      expect(model.isEnabled, true);
      expect(model.requiresSetup, false);
      expect(model.settingsList.length, 2);

      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/payment_gateways/bacs');
    });

    test('toJson serializes model back to Map', () {
      final model = GetPaymentGatewaysModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 'bacs');
      expect(json['title'], 'Direct Bank Transfer');
      expect(json['enabled'], true);
      expect(json['settings'], isNotNull);
      expect(json['settings']['title']['value'], 'Direct Bank Transfer');
    });

    test('handles nulls, missing fields, and default fallback getters gracefully', () {
      final emptyModel = GetPaymentGatewaysModel.fromJson({});

      expect(emptyModel.id, isNull);
      expect(emptyModel.displayTitle, 'Payment Gateway');
      expect(emptyModel.displayDescription, 'No gateway description provided.');
      expect(emptyModel.displayMethodTitle, '');
      expect(emptyModel.formattedId, '#--');
      expect(emptyModel.isEnabled, false);
      expect(emptyModel.requiresSetup, false);
      expect(emptyModel.settingsList, isEmpty);
    });

    test('getPaymentGatewaysModelFromJson and getPaymentGatewaysModelToJson work properly', () {
      final jsonListStr = '''
      [
        {"id": "cod", "title": "Cash on delivery", "enabled": false},
        {"id": "cheque", "title": "Check payments", "enabled": true}
      ]
      ''';

      final list = getPaymentGatewaysModelFromJson(jsonListStr);
      expect(list.length, 2);
      expect(list[0].id, 'cod');
      expect(list[0].enabled, false);
      expect(list[1].id, 'cheque');
      expect(list[1].enabled, true);

      final reEncoded = getPaymentGatewaysModelToJson(list);
      expect(reEncoded, contains('Cash on delivery'));
      expect(reEncoded, contains('Check payments'));
    });

    test('copyWith properly creates modified clone', () {
      final original = GetPaymentGatewaysModel(
        id: 'stripe',
        title: 'Stripe',
        enabled: false,
      );

      final updated = original.copyWith(
        title: 'Stripe Credit Card',
        enabled: true,
      );

      expect(updated.id, 'stripe');
      expect(updated.title, 'Stripe Credit Card');
      expect(updated.enabled, true);
    });
  });
}
