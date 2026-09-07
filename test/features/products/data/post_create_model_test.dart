import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';

void main() {
  group('PostCreateModel', () {
    test('toCreatePayload includes only valid writeable fields and omits read-only fields', () {
      final model = PostCreateModel(
        id: 9999, // Read-only: should NOT be in create payload
        dateCreated: '2026-09-07T00:00:00', // Read-only: should NOT be in create payload
        price: '19.99', // Read-only: should NOT be in create payload
        totalSales: 150, // Read-only: should NOT be in create payload
        name: 'Wireless Bluetooth Earbuds Pro',
        sku: 'ISH-AUDIO-001',
        type: 'simple',
        status: 'publish',
        regularPrice: '89.99',
        salePrice: '69.99',
        description: '<p>High-fidelity audio with active noise cancellation.</p>',
        shortDescription: 'High-fidelity ANC earbuds.',
        manageStock: true,
        stockQuantity: 40,
        stockStatus: 'instock',
        backorders: 'no',
        lowStockAmount: 5,
        weight: '0.15',
        dimensions: Dimensions(length: '6', width: '4', height: '3'),
        shippingClass: 'small-parcels',
        reviewsAllowed: true,
        categories: [ProductCategoryRef(id: 12, name: 'Audio')],
        tags: [ProductTagRef(name: 'Wireless')],
        images: [ProductImageRef(src: 'https://example.com/earbuds.jpg')],
        attributes: [
          ProductAttributeRef(
            name: 'Color',
            options: ['Midnight Black', 'Pearl White'],
          ),
        ],
      );

      final payload = model.toCreatePayload();

      // Read-only fields MUST NOT be present in create payload
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('date_created'), isFalse);
      expect(payload.containsKey('price'), isFalse);
      expect(payload.containsKey('total_sales'), isFalse);
      expect(payload.containsKey('_links'), isFalse);

      // Writeable fields MUST be present
      expect(payload['name'], 'Wireless Bluetooth Earbuds Pro');
      expect(payload['sku'], 'ISH-AUDIO-001');
      expect(payload['regular_price'], '89.99');
      expect(payload['sale_price'], '69.99');
      expect(payload['manage_stock'], isTrue);
      expect(payload['stock_quantity'], 40);
      expect(payload['stock_status'], 'instock');
      expect(payload['dimensions']['length'], '6');
      expect(payload['shipping_class'], 'small-parcels');
      expect(payload['categories'], [
        {'id': 12}
      ]);
      expect(payload['tags'], [
        {'name': 'Wireless'}
      ]);
      expect(payload['images'], [
        {'src': 'https://example.com/earbuds.jpg'}
      ]);
      expect(payload['attributes'][0]['name'], 'Color');
      expect(payload['attributes'][0]['options'], ['Midnight Black', 'Pearl White']);
    });

    test('fromJson parses WooCommerce response JSON properly', () {
      final json = {
        'id': 12345,
        'name': 'Samsung Fast Charger 45W',
        'slug': 'samsung-fast-charger-45w',
        'status': 'publish',
        'sku': 'ISH-CHG-45',
        'price': '39.99',
        'regular_price': '39.99',
        'sale_price': '',
        'manage_stock': true,
        'stock_quantity': 18,
        'stock_status': 'instock',
        'categories': [
          {'id': 20, 'name': 'Accessories', 'slug': 'accessories'}
        ],
        'images': [
          {'id': 88, 'src': 'https://example.com/charger.jpg'}
        ],
      };

      final product = PostCreateModel.fromJson(json);

      expect(product.id, 12345);
      expect(product.name, 'Samsung Fast Charger 45W');
      expect(product.sku, 'ISH-CHG-45');
      expect(product.regularPrice, '39.99');
      expect(product.stockQuantity, 18);
      expect(product.categories?.first.name, 'Accessories');
      expect(product.images?.first.src, 'https://example.com/charger.jpg');
    });
  });
}
