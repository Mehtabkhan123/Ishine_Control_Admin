import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/shipping/data/models/shipping_zones_model.dart';

void main() {
  group('ShippingZonesModel', () {
    final sampleJson = {
      'id': 1,
      'name': 'United States (Domestic)',
      'order': 0,
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/shipping/zones/1',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'DELETE'],
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/shipping/zones'}
        ],
        'describedby': [
          {'href': 'https://example.com/wp-json/wc/v3/shipping/zones/schema'}
        ]
      }
    };

    test('fromJson parses standard WooCommerce JSON correctly', () {
      final model = ShippingZonesModel.fromJson(sampleJson);

      expect(model.id, 1);
      expect(model.name, 'United States (Domestic)');
      expect(model.order, 0);
      expect(model.formattedId, '#1');
      expect(model.displayName, 'United States (Domestic)');
      expect(model.formattedOrder, '0');
      expect(model.isDefaultZone, false);

      expect(model.lLinks, isNotNull);
      expect(model.lLinks?.self?.first.href,
          'https://example.com/wp-json/wc/v3/shipping/zones/1');
      expect(model.lLinks?.self?.first.targetHints?.allow,
          ['GET', 'POST', 'PUT', 'DELETE']);
      expect(model.lLinks?.collection?.first.href,
          'https://example.com/wp-json/wc/v3/shipping/zones');
      expect(model.lLinks?.describedby?.first.href,
          'https://example.com/wp-json/wc/v3/shipping/zones/schema');
    });

    test('toJson serializes model back to Map', () {
      final model = ShippingZonesModel.fromJson(sampleJson);
      final jsonMap = model.toJson();

      expect(jsonMap['id'], 1);
      expect(jsonMap['name'], 'United States (Domestic)');
      expect(jsonMap['order'], 0);
      expect(jsonMap['_links'], isNotNull);
    });

    test('handles Zone 0 (default fallback zone) correctly', () {
      final defaultZoneJson = {
        'id': 0,
        'name': 'Locations not covered by your other zones',
        'order': null,
      };

      final model = ShippingZonesModel.fromJson(defaultZoneJson);

      expect(model.id, 0);
      expect(model.isDefaultZone, true);
      expect(model.formattedId, '#0');
      expect(model.displayName, 'Locations not covered by your other zones');
      expect(model.formattedOrder, '0');
    });

    test('copyWith creates cloned model with overridden values', () {
      final model = ShippingZonesModel.fromJson(sampleJson);
      final updated = model.copyWith(name: 'Europe & UK', order: 2);

      expect(updated.id, 1);
      expect(updated.name, 'Europe & UK');
      expect(updated.order, 2);
      expect(updated.formattedOrder, '2');
    });
  });
}
