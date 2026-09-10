import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/taxes/data/models/get_tax_rates_model.dart';

void main() {
  group('GetTaxRatesModel', () {
    final sampleJson = {
      'id': 14,
      'country': 'US',
      'state': 'CA',
      'postcode': '90210',
      'city': 'Beverly Hills',
      'rate': '9.5000',
      'name': 'State & District Tax',
      'priority': 1,
      'compound': false,
      'shipping': true,
      'order': 0,
      'class': 'standard',
      'postcodes': ['90210', '90211'],
      'cities': ['Beverly Hills'],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/taxes/14'}
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/taxes'}
        ]
      }
    };

    test('fromJson parses standard WooCommerce Tax Rate JSON correctly', () {
      final model = GetTaxRatesModel.fromJson(sampleJson);

      expect(model.id, 14);
      expect(model.country, 'US');
      expect(model.state, 'CA');
      expect(model.postcode, '90210');
      expect(model.city, 'Beverly Hills');
      expect(model.rate, '9.5000');
      expect(model.name, 'State & District Tax');
      expect(model.priority, 1);
      expect(model.compound, false);
      expect(model.shipping, true);
      expect(model.order, 0);
      expect(model.taxClass, 'standard');
      expect(model.postcodes, ['90210', '90211']);
      expect(model.cities, ['Beverly Hills']);

      expect(model.formattedId, '#14');
      expect(model.displayName, 'State & District Tax');
      expect(model.formattedRate, '9.50%');
      expect(model.taxClassDisplay, 'Standard');
      expect(model.locationSummary, 'US • CA • Beverly Hills • 90210');
      expect(model.priorityDisplay, '1');

      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/taxes/14');
      expect(model.lLinks?.collection?.first.href,
          'https://example.com/wp-json/wc/v3/taxes');
    });

    test('toJson serializes model back to Map with class key', () {
      final model = GetTaxRatesModel.fromJson(sampleJson);
      final jsonMap = model.toJson();

      expect(jsonMap['id'], 14);
      expect(jsonMap['country'], 'US');
      expect(jsonMap['class'], 'standard');
      expect(jsonMap['rate'], '9.5000');
      expect(jsonMap['postcodes'], ['90210', '90211']);
    });

    test('handles wildcard global tax rates correctly', () {
      final wildcardJson = {
        'id': 1,
        'country': '*',
        'state': '*',
        'postcode': '*',
        'city': '*',
        'rate': '20.0000',
        'name': 'Standard VAT',
        'priority': 1,
        'compound': true,
        'shipping': false,
        'class': 'standard',
      };

      final model = GetTaxRatesModel.fromJson(wildcardJson);

      expect(model.id, 1);
      expect(model.locationSummary, 'All Countries (*)');
      expect(model.formattedRate, '20%');
      expect(model.compound, true);
      expect(model.shipping, false);
    });

    test('copyWith creates cloned model with modified attributes', () {
      final model = GetTaxRatesModel.fromJson(sampleJson);
      final updated = model.copyWith(
        name: 'Updated VAT',
        rate: '10.0000',
        compound: true,
      );

      expect(updated.id, 14);
      expect(updated.name, 'Updated VAT');
      expect(updated.rate, '10.0000');
      expect(updated.compound, true);
      expect(updated.country, 'US');
    });
  });
}
