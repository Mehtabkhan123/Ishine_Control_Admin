import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/reports/data/models/top_seller_model.dart';

void main() {
  group('TopSellerModel', () {
    const rawJson = '''
[
  {
    "name": "USB To Lightning AAA 1M Data Cable",
    "product_id": 51768,
    "quantity": 5463,
    "_links": {
      "about": [
        {
          "href": "https://example.com/wp-json/wc/v3/reports"
        }
      ],
      "product": [
        {
          "href": "https://example.com/wp-json/wc/v3/products/51768"
        }
      ]
    }
  },
  {
    "title": "ANG TC15A Single USB Power Adaptor 1A",
    "product_id": "36197",
    "quantity": "2417"
  }
]
''';

    test('parses from raw JSON array with topSellerModelListFromJson', () {
      final items = topSellerModelListFromJson(rawJson);
      expect(items.length, 2);

      final item1 = items[0];
      expect(item1.name, 'USB To Lightning AAA 1M Data Cable');
      expect(item1.productId, 51768);
      expect(item1.quantity, 5463);
      expect(item1.links?.about?.first.href, 'https://example.com/wp-json/wc/v3/reports');

      final item2 = items[1];
      expect(item2.name, 'ANG TC15A Single USB Power Adaptor 1A');
      expect(item2.productId, 36197);
      expect(item2.quantity, 2417);
      expect(item2.links, isNull);
    });

    test('serializes to JSON correctly with topSellerModelListToJson', () {
      final items = topSellerModelListFromJson(rawJson);
      final jsonOutput = topSellerModelListToJson(items);

      expect(jsonOutput, contains('USB To Lightning AAA 1M Data Cable'));
      expect(jsonOutput, contains('51768'));
      expect(jsonOutput, contains('5463'));
    });

    test('handles missing or malformed fields gracefully', () {
      final item = TopSellerModel.fromJson({});
      expect(item.name, contains('Product #Unknown'));
      expect(item.productId, 0);
      expect(item.quantity, 0);
    });

    test('copyWith updates fields correctly', () {
      final item = TopSellerModel(
        name: 'Test Product',
        productId: 100,
        quantity: 50,
      );

      final updated = item.copyWith(quantity: 75);
      expect(updated.name, 'Test Product');
      expect(updated.productId, 100);
      expect(updated.quantity, 75);
    });
  });
}
