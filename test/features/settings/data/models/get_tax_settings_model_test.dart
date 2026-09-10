import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_tax_settings_model.dart';

void main() {
  group('GetTextSettingsModel / GetTaxSettingsModel', () {
    final sampleJson = {
      'id': 'woocommerce_tax_based_on',
      'label': 'Calculate tax based on',
      'description':
          'This option determines which address is used to calculate tax.',
      'type': 'select',
      'default': 'shipping',
      'tip': 'Select customer address for tax calculation.',
      'value': 'shipping',
      'options': {
        'shipping': 'Customer shipping address',
        'billing': 'Customer billing address',
        'base': 'Shop base address',
      },
      '_links': {
        'self': [
          {
            'href':
                'https://example.com/wp-json/wc/v3/settings/tax/woocommerce_tax_based_on',
            'targetHints': {
              'allow': ['GET', 'PUT']
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/settings/tax'}
        ]
      }
    };

    test('fromJson parses WooCommerce tax setting correctly', () {
      final model = GetTextSettingsModel.fromJson(sampleJson);

      expect(model.id, 'woocommerce_tax_based_on');
      expect(model.label, 'Calculate tax based on');
      expect(model.type, 'select');
      expect(model.defaultValue, 'shipping');
      expect(model.tip, 'Select customer address for tax calculation.');
      expect(model.value, 'shipping');
      expect(model.options?['shipping'], 'Customer shipping address');
      expect(model.lLinks?.self?.first.href,
          contains('woocommerce_tax_based_on'));
      expect(model.lLinks?.self?.first.targetHints?.allow, contains('GET'));
      expect(model.lLinks?.collection?.first.href, contains('/settings/tax'));
    });

    test('toJson serializes model back to Map', () {
      final model = GetTextSettingsModel.fromJson(sampleJson);
      final jsonOutput = model.toJson();

      expect(jsonOutput['id'], 'woocommerce_tax_based_on');
      expect(jsonOutput['label'], 'Calculate tax based on');
      expect(jsonOutput['type'], 'select');
      expect(jsonOutput['default'], 'shipping');
      expect(jsonOutput['value'], 'shipping');
      expect(jsonOutput['_links'], isNotNull);
    });

    test('handles boolean and checkbox settings correctly', () {
      final checkboxJson = {
        'id': 'woocommerce_prices_include_tax',
        'label': 'Prices entered with tax',
        'description': 'This option specifies if prices include tax.',
        'type': 'checkbox',
        'default': 'no',
        'tip': '',
        'value': 'yes',
      };

      final model = GetTextSettingsModel.fromJson(checkboxJson);

      expect(model.isCheckbox, isTrue);
      expect(model.boolValue, isTrue);
      expect(model.defaultBoolValue, isFalse);
      expect(model.stringValue, 'yes');
      expect(model.stringDefaultValue, 'no');
    });

    test('handles numeric settings correctly', () {
      final numberJson = {
        'id': 'woocommerce_tax_round_at_subtotal',
        'label': 'Round tax at subtotal level',
        'description': 'Round tax at subtotal level.',
        'type': 'number',
        'default': 0,
        'tip': null,
        'value': 1,
      };

      final model = GetTextSettingsModel.fromJson(numberJson);

      expect(model.isNumber, isTrue);
      expect(model.value, 1);
      expect(model.stringValue, '1');
      expect(model.defaultValue, 0);
      expect(model.stringDefaultValue, '0');
    });

    test('displayOptionLabel returns mapped option or fallback', () {
      final model = GetTextSettingsModel.fromJson(sampleJson);
      expect(model.displayOptionLabel, 'Customer shipping address');

      final unmapped = model.copyWith(value: 'unknown_option');
      expect(unmapped.displayOptionLabel, 'unknown_option');
    });

    test('getTextSettingsModelFromJson and ToJson work for lists', () {
      final listJsonStr = '''[
        {
          "id": "woocommerce_calc_taxes",
          "label": "Enable taxes",
          "type": "checkbox",
          "default": "no",
          "value": "yes"
        }
      ]''';

      final list = getTextSettingsModelFromJson(listJsonStr);
      expect(list.length, 1);
      expect(list.first.id, 'woocommerce_calc_taxes');
      expect(list.first.boolValue, isTrue);

      final encoded = getTextSettingsModelToJson(list);
      expect(encoded, contains('woocommerce_calc_taxes'));
    });

    test('copyWith creates modified clone properly', () {
      final model = GetTextSettingsModel(
        id: 'tax_1',
        label: 'Original Tax',
        value: 'yes',
      );

      final modified = model.copyWith(label: 'Updated Tax', value: 'no');

      expect(modified.id, 'tax_1');
      expect(modified.label, 'Updated Tax');
      expect(modified.value, 'no');
      expect(model.label, 'Original Tax'); // Original unchanged
    });

    test('GetTaxSettingsModel alias works identically', () {
      final GetTaxSettingsModel taxModel = GetTaxSettingsModel(
        id: 'woocommerce_calc_taxes',
        label: 'Enable tax rates and calculations',
        type: 'checkbox',
        value: 'yes',
      );

      expect(taxModel.displayLabel, 'Enable tax rates and calculations');
      expect(taxModel.boolValue, isTrue);
    });
  });
}
