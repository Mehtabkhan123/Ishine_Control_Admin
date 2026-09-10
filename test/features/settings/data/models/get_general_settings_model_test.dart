import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_general_settings_model.dart';

void main() {
  group('GetGeneralSettingsModel', () {
    final sampleJson = {
      'id': 'woocommerce_default_country',
      'label': 'Country / State',
      'description':
          'The country and state or province in which your business is located.',
      'type': 'select',
      'default': 'US:CA',
      'tip': 'Select the country and state for your store.',
      'value': 'US:CA',
      'options': {
        'US:CA': 'California, United States',
        'US:NY': 'New York, United States',
      },
      '_links': {
        'self': [
          {
            'href':
                'https://example.com/wp-json/wc/v3/settings/general/woocommerce_default_country',
            'targetHints': {
              'allow': ['GET', 'PUT']
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/settings/general'}
        ]
      }
    };

    test('fromJson parses WooCommerce general setting correctly', () {
      final model = GetGeneralSettingsModel.fromJson(sampleJson);

      expect(model.id, 'woocommerce_default_country');
      expect(model.label, 'Country / State');
      expect(model.type, 'select');
      expect(model.defaultValue, 'US:CA');
      expect(model.tip, 'Select the country and state for your store.');
      expect(model.value, 'US:CA');
      expect(model.options?['US:CA'], 'California, United States');
      expect(model.lLinks?.self?.first.href, contains('woocommerce_default_country'));
      expect(model.lLinks?.self?.first.targetHints?.allow, contains('GET'));
      expect(model.lLinks?.collection?.first.href, contains('/settings/general'));
    });

    test('toJson serializes model back to Map', () {
      final model = GetGeneralSettingsModel.fromJson(sampleJson);
      final jsonOutput = model.toJson();

      expect(jsonOutput['id'], 'woocommerce_default_country');
      expect(jsonOutput['label'], 'Country / State');
      expect(jsonOutput['type'], 'select');
      expect(jsonOutput['default'], 'US:CA');
      expect(jsonOutput['value'], 'US:CA');
      expect(jsonOutput['_links'], isNotNull);
    });

    test('handles boolean and checkbox settings correctly', () {
      final checkboxJson = {
        'id': 'woocommerce_calc_taxes',
        'label': 'Enable taxes',
        'description': 'Enable tax rates and calculations',
        'type': 'checkbox',
        'default': 'no',
        'tip': '',
        'value': 'yes',
      };

      final model = GetGeneralSettingsModel.fromJson(checkboxJson);

      expect(model.isCheckbox, isTrue);
      expect(model.boolValue, isTrue);
      expect(model.defaultBoolValue, isFalse);
      expect(model.stringValue, 'yes');
      expect(model.stringDefaultValue, 'no');
    });

    test('handles numeric settings correctly', () {
      final numberJson = {
        'id': 'woocommerce_price_num_decimals',
        'label': 'Number of decimals',
        'description': 'This sets the number of decimal points.',
        'type': 'number',
        'default': 2,
        'tip': null,
        'value': 2,
      };

      final model = GetGeneralSettingsModel.fromJson(numberJson);

      expect(model.isNumber, isTrue);
      expect(model.value, 2);
      expect(model.stringValue, '2');
      expect(model.defaultValue, 2);
      expect(model.stringDefaultValue, '2');
    });

    test('displayOptionLabel returns mapped option or fallback', () {
      final selectModel = GetGeneralSettingsModel(
        id: 'currency',
        type: 'select',
        value: 'USD',
        options: {'USD': 'US Dollar (\$)', 'EUR': 'Euro (€)'},
      );

      expect(selectModel.displayOptionLabel, 'US Dollar (\$)');

      final unknownSelect = GetGeneralSettingsModel(
        id: 'currency',
        type: 'select',
        value: 'GBP',
        options: {'USD': 'US Dollar (\$)'},
      );

      expect(unknownSelect.displayOptionLabel, 'GBP');
    });

    test('getGeneralSettingsModelFromJson and ToJson work for lists', () {
      const jsonStr = '''[
        {
          "id": "woocommerce_store_address",
          "label": "Address line 1",
          "type": "text",
          "default": "",
          "value": "123 Main St"
        },
        {
          "id": "woocommerce_store_city",
          "label": "City",
          "type": "text",
          "default": "",
          "value": "San Francisco"
        }
      ]''';

      final list = getGeneralSettingsModelFromJson(jsonStr);
      expect(list.length, 2);
      expect(list[0].id, 'woocommerce_store_address');
      expect(list[1].value, 'San Francisco');

      final encoded = getGeneralSettingsModelToJson(list);
      expect(encoded, contains('woocommerce_store_address'));
      expect(encoded, contains('San Francisco'));
    });

    test('copyWith creates modified clone properly', () {
      final original = GetGeneralSettingsModel(
        id: 'currency',
        label: 'Currency',
        value: 'USD',
      );

      final cloned = original.copyWith(value: 'EUR');

      expect(cloned.id, 'currency');
      expect(cloned.label, 'Currency');
      expect(cloned.value, 'EUR');
      expect(original.value, 'USD');
    });
  });
}
