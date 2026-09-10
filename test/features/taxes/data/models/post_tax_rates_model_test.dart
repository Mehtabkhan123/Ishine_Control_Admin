import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/taxes/data/models/post_tax_rates_model.dart';

void main() {
  group('PostTaxRatesModel', () {
    final sampleJson = {
      'id': 105,
      'country': 'US',
      'state': 'CA',
      'postcode': '90210',
      'city': 'Beverly Hills',
      'rate': '9.5000',
      'name': 'California State Tax',
      'priority': 1,
      'compound': false,
      'shipping': true,
      'order': 2,
      'class': 'standard',
      'postcodes': ['90210', '90211'],
      'cities': ['Beverly Hills', 'Century City'],
      '_links': {
        'self': [
          {'href': 'https://example.com/wp-json/wc/v3/taxes/105'}
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/taxes'}
        ]
      }
    };

    test('fromJson parses WooCommerce tax rate JSON and maps "class" to taxClass', () {
      final model = PostTaxRatesModel.fromJson(sampleJson);

      expect(model.id, 105);
      expect(model.country, 'US');
      expect(model.state, 'CA');
      expect(model.postcode, '90210');
      expect(model.city, 'Beverly Hills');
      expect(model.rate, '9.5000');
      expect(model.name, 'California State Tax');
      expect(model.priority, 1);
      expect(model.compound, false);
      expect(model.shipping, true);
      expect(model.order, 2);
      expect(model.taxClass, 'standard');
      expect(model.postcodes, ['90210', '90211']);
      expect(model.cities, ['Beverly Hills', 'Century City']);
      expect(model.lLinks?.self?.first.href, 'https://example.com/wp-json/wc/v3/taxes/105');
      expect(model.lLinks?.collection?.first.href, 'https://example.com/wp-json/wc/v3/taxes');
    });

    test('toJson maps taxClass back to JSON key "class"', () {
      final model = PostTaxRatesModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 105);
      expect(json['class'], 'standard');
      expect(json.containsKey('taxClass'), isFalse);
      expect(json['name'], 'California State Tax');
      expect(json['rate'], '9.5000');
    });

    test('toCreateJson sends only writable WooCommerce fields and excludes id and _links', () {
      final model = PostTaxRatesModel(
        id: 999, // Should be ignored in POST payload
        country: 'US',
        state: 'NY',
        postcode: '10001',
        city: 'New York',
        rate: '8.8750',
        name: 'NY Sales Tax',
        priority: 1,
        compound: true,
        shipping: false,
        order: 1,
        taxClass: 'reduced-rate',
        postcodes: ['10001', '10002'],
        cities: ['New York', 'Brooklyn'],
        lLinks: Links(
          self: [Self(href: 'https://example.com')],
        ),
      );

      final createPayload = model.toCreateJson();

      expect(createPayload.containsKey('id'), isFalse);
      expect(createPayload.containsKey('_links'), isFalse);
      expect(createPayload['country'], 'US');
      expect(createPayload['state'], 'NY');
      expect(createPayload['postcode'], '10001');
      expect(createPayload['city'], 'New York');
      expect(createPayload['rate'], '8.8750');
      expect(createPayload['name'], 'NY Sales Tax');
      expect(createPayload['priority'], 1);
      expect(createPayload['compound'], true);
      expect(createPayload['shipping'], false);
      expect(createPayload['order'], 1);
      expect(createPayload['class'], 'reduced-rate');
      expect(createPayload['postcodes'], ['10001', '10002']);
      expect(createPayload['cities'], ['New York', 'Brooklyn']);
    });

    test('postTaxRatesModelFromJson and postTaxRatesModelToJson helper functions work correctly', () {
      final jsonStr = '{"name":"VAT","rate":"20.0000","class":"standard"}';
      final model = postTaxRatesModelFromJson(jsonStr);

      expect(model.name, 'VAT');
      expect(model.rate, '20.0000');
      expect(model.taxClass, 'standard');

      final serialized = postTaxRatesModelToJson(model);
      expect(serialized.contains('"class":"standard"'), isTrue);
    });

    test('copyWith properly duplicates and overrides fields', () {
      final original = PostTaxRatesModel(
        id: 1,
        name: 'Original Tax',
        rate: '10.0000',
        taxClass: 'standard',
      );

      final updated = original.copyWith(
        name: 'Updated Tax',
        rate: '15.0000',
      );

      expect(updated.id, 1);
      expect(updated.name, 'Updated Tax');
      expect(updated.rate, '15.0000');
      expect(updated.taxClass, 'standard');
    });
  });
}
