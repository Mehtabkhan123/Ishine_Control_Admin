import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/settings/data/models/get_product_settings_model.dart';

void main() {
  group('GetProductSettingsModel', () {
    final sampleJson = {
      'id': 'woocommerce_weight_unit',
      'label': 'Weight unit',
      'description': 'This controls what unit you define weights in.',
      'type': 'select',
      'default': 'kg',
      'tip': 'Select weight measurement unit.',
      'value': 'kg',
      'options': {
        'kg': 'kg',
        'g': 'g',
        'lbs': 'lbs',
        'oz': 'oz',
      },
      '_links': {
        'self': [
          {
            'href':
                'https://example.com/wp-json/wc/v3/settings/products/woocommerce_weight_unit',
            'targetHints': {
              'allow': ['GET', 'PUT']
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/settings/products'}
        ]
      }
    };

    test('fromJson parses WooCommerce product setting correctly', () {
      final model = GetProductSettingsModel.fromJson(sampleJson);

      expect(model.id, 'woocommerce_weight_unit');
      expect(model.label, 'Weight unit');
      expect(model.type, 'select');
      expect(model.defaultValue, 'kg');
      expect(model.tip, 'Select weight measurement unit.');
      expect(model.value, 'kg');
      expect(model.options?['kg'], 'kg');
      expect(model.lLinks?.self?.first.href, contains('woocommerce_weight_unit'));
      expect(model.lLinks?.self?.first.targetHints?.allow, contains('GET'));
      expect(model.lLinks?.collection?.first.href, contains('/settings/products'));
    });

    test('toJson serializes model back to Map', () {
      final model = GetProductSettingsModel.fromJson(sampleJson);
      final jsonOutput = model.toJson();

      expect(jsonOutput['id'], 'woocommerce_weight_unit');
      expect(jsonOutput['label'], 'Weight unit');
      expect(jsonOutput['type'], 'select');
      expect(jsonOutput['default'], 'kg');
      expect(jsonOutput['value'], 'kg');
      expect(jsonOutput['_links'], isNotNull);
    });

    test('handles boolean and checkbox settings correctly', () {
      final checkboxJson = {
        'id': 'woocommerce_manage_stock',
        'label': 'Manage stock',
        'description': 'Enable stock management',
        'type': 'checkbox',
        'default': 'no',
        'tip': '',
        'value': 'yes',
      };

      final model = GetProductSettingsModel.fromJson(checkboxJson);

      expect(model.isCheckbox, isTrue);
      expect(model.boolValue, isTrue);
      expect(model.defaultBoolValue, isFalse);
      expect(model.stringValue, 'yes');
      expect(model.stringDefaultValue, 'no');
    });

    test('handles numeric settings correctly', () {
      final numberJson = {
        'id': 'woocommerce_hold_stock_minutes',
        'label': 'Hold stock (minutes)',
        'description': 'Hold stock for unpaid orders.',
        'type': 'number',
        'default': 60,
        'tip': null,
        'value': 60,
      };

      final model = GetProductSettingsModel.fromJson(numberJson);

      expect(model.isNumber, isTrue);
      expect(model.value, 60);
      expect(model.stringValue, '60');
      expect(model.defaultValue, 60);
      expect(model.stringDefaultValue, '60');
    });

    test('displayOptionLabel returns mapped option or fallback', () {
      final selectModel = GetProductSettingsModel(
        id: 'woocommerce_weight_unit',
        type: 'select',
        value: 'kg',
        options: {'kg': 'Kilograms (kg)', 'lbs': 'Pounds (lbs)'},
      );

      expect(selectModel.displayOptionLabel, 'Kilograms (kg)');

      final unknownSelect = GetProductSettingsModel(
        id: 'woocommerce_weight_unit',
        type: 'select',
        value: 'oz',
        options: {'kg': 'Kilograms (kg)'},
      );

      expect(unknownSelect.displayOptionLabel, 'oz');
    });

    test('getProductSettingsModelFromJson and ToJson work for lists', () {
      const jsonStr = '''[
        {
          "id": "woocommerce_weight_unit",
          "label": "Weight unit",
          "type": "select",
          "default": "kg",
          "value": "kg"
        },
        {
          "id": "woocommerce_dimension_unit",
          "label": "Dimension unit",
          "type": "select",
          "default": "cm",
          "value": "cm"
        }
      ]''';

      final list = getProductSettingsModelFromJson(jsonStr);
      expect(list.length, 2);
      expect(list[0].id, 'woocommerce_weight_unit');
      expect(list[1].value, 'cm');

      final encoded = getProductSettingsModelToJson(list);
      expect(encoded, contains('woocommerce_weight_unit'));
      expect(encoded, contains('woocommerce_dimension_unit'));
    });

    test('copyWith creates modified clone properly', () {
      final original = GetProductSettingsModel(
        id: 'woocommerce_manage_stock',
        label: 'Manage stock',
        value: 'no',
      );

      final cloned = original.copyWith(value: 'yes');

      expect(cloned.id, 'woocommerce_manage_stock');
      expect(cloned.label, 'Manage stock');
      expect(cloned.value, 'yes');
      expect(original.value, 'no');
    });
  });
}
