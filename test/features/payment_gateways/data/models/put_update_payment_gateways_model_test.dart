import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/payment_gateways/data/models/put_update_payment_gateways_model.dart';

void main() {
  group('PutUpdatePaymentGatewaysModel', () {
    final sampleJson = {
      'id': 'bacs',
      'title': 'Direct Bank Transfer',
      'description': 'Make your payment directly into our bank account.',
      'order': 1,
      'enabled': true,
      'method_title': 'Direct bank transfer (BACS)',
      'method_description': 'Allows payments by BACS.',
      'method_supports': ['products'],
      'settings': {
        'title': {
          'id': 'title',
          'label': 'Title',
          'description': 'This controls the title during checkout.',
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
        }
      },
      'needs_setup': false,
      'post_install_scripts': ['setup_bacs.js'],
      'settings_url': 'https://example.com/wp-admin/admin.php',
      'connection_url': 'https://example.com/connect',
      'setup_help_text': 'Help text for setup',
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

    test('fromJson parses WooCommerce payment gateway update response correctly', () {
      final model = PutUpdatePaymentGatewaysModel.fromJson(sampleJson);

      expect(model.id, 'bacs');
      expect(model.title, 'Direct Bank Transfer');
      expect(model.description, 'Make your payment directly into our bank account.');
      expect(model.order, 1);
      expect(model.enabled, true);
      expect(model.methodTitle, 'Direct bank transfer (BACS)');
      expect(model.methodDescription, 'Allows payments by BACS.');
      expect(model.methodSupports, ['products']);
      expect(model.settings, isNotNull);
      expect(model.settings!['title']?.value, 'Direct Bank Transfer');
      expect(model.settings!['enabled']?.value, 'yes');
      expect(model.needsSetup, false);
      expect(model.postInstallScripts, ['setup_bacs.js']);
      expect(model.settingsUrl, 'https://example.com/wp-admin/admin.php');
      expect(model.connectionUrl, 'https://example.com/connect');
      expect(model.setupHelpText, 'Help text for setup');
      expect(model.requiredSettingsKeys, ['title']);
      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/payment_gateways/bacs');
    });

    test('toJson serializes model back to matching map', () {
      final model = PutUpdatePaymentGatewaysModel.fromJson(sampleJson);
      final jsonMap = model.toJson();

      expect(jsonMap['id'], 'bacs');
      expect(jsonMap['title'], 'Direct Bank Transfer');
      expect(jsonMap['enabled'], true);
      expect(jsonMap['settings'], isNotNull);
    });

    test('toUpdatePayload only sends writable fields and excludes read-only fields', () {
      final model = PutUpdatePaymentGatewaysModel.fromJson(sampleJson);
      final payload = model.toUpdatePayload();

      // Writable fields should be present
      expect(payload['title'], 'Direct Bank Transfer');
      expect(payload['description'], 'Make your payment directly into our bank account.');
      expect(payload['order'], 1);
      expect(payload['enabled'], true);
      expect(payload['settings'], isNotNull);
      expect(payload['settings']['title'], 'Direct Bank Transfer');
      expect(payload['settings']['enabled'], 'yes');

      // Read-only fields MUST be excluded
      expect(payload.containsKey('id'), false);
      expect(payload.containsKey('method_title'), false);
      expect(payload.containsKey('method_description'), false);
      expect(payload.containsKey('method_supports'), false);
      expect(payload.containsKey('needs_setup'), false);
      expect(payload.containsKey('post_install_scripts'), false);
      expect(payload.containsKey('settings_url'), false);
      expect(payload.containsKey('connection_url'), false);
      expect(payload.containsKey('setup_help_text'), false);
      expect(payload.containsKey('required_settings_keys'), false);
      expect(payload.containsKey('_links'), false);
    });

    test('toUpdatePayloadMap creates clean map with provided values', () {
      final payload = PutUpdatePaymentGatewaysModel.toUpdatePayloadMap(
        title: 'New Title',
        description: 'New Description',
        order: 5,
        enabled: true,
        settings: {'title': 'New Title', 'enabled': 'yes'},
      );

      expect(payload['title'], 'New Title');
      expect(payload['description'], 'New Description');
      expect(payload['order'], 5);
      expect(payload['enabled'], true);
      expect(payload['settings']['title'], 'New Title');
    });

    test('toGetPaymentGatewaysModel converts into GetPaymentGatewaysModel correctly', () {
      final model = PutUpdatePaymentGatewaysModel.fromJson(sampleJson);
      final getModel = model.toGetPaymentGatewaysModel();

      expect(getModel.id, model.id);
      expect(getModel.title, model.title);
      expect(getModel.description, model.description);
      expect(getModel.order, model.order);
      expect(getModel.enabled, model.enabled);
      expect(getModel.settings?['title']?.value, 'Direct Bank Transfer');
    });

    test('putUpdatePaymentGatewaysModelFromJson & ToJson helpers work correctly', () {
      final model = PutUpdatePaymentGatewaysModel.fromJson(sampleJson);
      final jsonString = putUpdatePaymentGatewaysModelToJson(model);
      final parsed = putUpdatePaymentGatewaysModelFromJson(jsonString);

      expect(parsed.id, model.id);
      expect(parsed.title, model.title);
      expect(parsed.enabled, model.enabled);
    });
  });
}
