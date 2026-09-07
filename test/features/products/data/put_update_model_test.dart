import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/models/put_update_model.dart';

void main() {
  group('PutUpdateModel', () {
    test('toUpdatePayload includes only valid writeable fields and omits read-only fields', () {
      final model = PutUpdateModel(
        id: 1234, // Read-only: should NOT be in update payload
        permalink: 'https://example.com/product/1234', // Read-only: should NOT be in update payload
        dateCreated: '2026-09-07T00:00:00', // Read-only: should NOT be in update payload
        dateModified: '2026-09-07T01:00:00', // Read-only: should NOT be in update payload
        price: '49.99', // Read-only: should NOT be in update payload
        totalSales: 200, // Read-only: should NOT be in update payload
        priceHtml: '<span class="amount">\$49.99</span>', // Read-only: should NOT be in update payload
        lLinks: Links(
          self: [Self(href: 'https://example.com/wp-json/wc/v3/products/1234')],
        ), // Read-only: should NOT be in update payload
        name: 'Ergonomic Desk Chair Pro',
        sku: 'ISH-CHAIR-002',
        type: 'simple',
        status: 'publish',
        featured: true,
        catalogVisibility: 'visible',
        description: '<p>Ergonomic mesh chair with adjustable lumbar support.</p>',
        shortDescription: 'Adjustable mesh chair.',
        regularPrice: '149.99',
        salePrice: '129.99',
        virtual: false,
        downloadable: false,
        taxStatus: 'taxable',
        taxClass: 'standard',
        manageStock: true,
        stockQuantity: 25,
        stockStatus: 'instock',
        backorders: 'notify',
        lowStockAmount: 4,
        soldIndividually: false,
        weight: '12.5',
        dimensions: Dimensions(length: '65', width: '65', height: '110'),
        shippingClass: 'heavy-freight',
        reviewsAllowed: true,
        purchaseNote: 'Thank you for choosing our ergonomic chair!',
        categories: [ProductCategoryRef(id: 15, name: 'Furniture')],
        tags: [ProductTagRef(name: 'Office'), ProductTagRef(name: 'Ergonomic')],
        images: [ProductImageRef(src: 'https://example.com/chair-pro.jpg')],
        attributes: [
          ProductAttributeRef(
            name: 'Color',
            options: ['Charcoal Gray', 'Jet Black'],
          ),
        ],
      );

      final payload = model.toUpdatePayload();

      // Read-only response fields MUST NOT be present in PUT update payload
      expect(payload.containsKey('id'), isFalse);
      expect(payload.containsKey('permalink'), isFalse);
      expect(payload.containsKey('date_created'), isFalse);
      expect(payload.containsKey('date_modified'), isFalse);
      expect(payload.containsKey('price'), isFalse);
      expect(payload.containsKey('total_sales'), isFalse);
      expect(payload.containsKey('price_html'), isFalse);
      expect(payload.containsKey('_links'), isFalse);

      // Writeable fields MUST be present and correctly formatted
      expect(payload['name'], 'Ergonomic Desk Chair Pro');
      expect(payload['sku'], 'ISH-CHAIR-002');
      expect(payload['type'], 'simple');
      expect(payload['status'], 'publish');
      expect(payload['featured'], isTrue);
      expect(payload['catalog_visibility'], 'visible');
      expect(payload['regular_price'], '149.99');
      expect(payload['sale_price'], '129.99');
      expect(payload['manage_stock'], isTrue);
      expect(payload['stock_quantity'], 25);
      expect(payload['stock_status'], 'instock');
      expect(payload['backorders'], 'notify');
      expect(payload['low_stock_amount'], 4);
      expect(payload['weight'], '12.5');
      expect(payload['dimensions']['length'], '65');
      expect(payload['dimensions']['width'], '65');
      expect(payload['dimensions']['height'], '110');
      expect(payload['shipping_class'], 'heavy-freight');
      expect(payload['reviews_allowed'], isTrue);
      expect(payload['purchase_note'], 'Thank you for choosing our ergonomic chair!');
      expect(payload['categories'], [
        {'id': 15}
      ]);
      expect(payload['tags'], [
        {'name': 'Office'},
        {'name': 'Ergonomic'}
      ]);
      expect(payload['images'], [
        {'src': 'https://example.com/chair-pro.jpg'}
      ]);
      expect(payload['attributes'], [
        {
          'name': 'Color',
          'position': 0,
          'visible': true,
          'variation': false,
          'options': ['Charcoal Gray', 'Jet Black'],
        }
      ]);
    });

    test('fromJson parses WooCommerce product update response cleanly', () {
      final jsonResponse = {
        'id': 5678,
        'name': 'Mechanical Gaming Keyboard',
        'slug': 'mechanical-gaming-keyboard',
        'permalink': 'https://example.com/product/mechanical-gaming-keyboard',
        'date_created': '2026-09-01T12:00:00',
        'date_modified': '2026-09-07T14:30:00',
        'type': 'simple',
        'status': 'publish',
        'featured': true,
        'catalog_visibility': 'visible',
        'description': '<p>RGB tactile switches.</p>',
        'short_description': 'RGB Keyboard',
        'sku': 'ISH-KB-RGB',
        'price': '89.99',
        'regular_price': '99.99',
        'sale_price': '89.99',
        'manage_stock': true,
        'stock_quantity': 18,
        'stock_status': 'instock',
        'weight': '0.95',
        'dimensions': {
          'length': '44',
          'width': '13',
          'height': '3.5',
        },
        'categories': [
          {'id': 20, 'name': 'Peripherals', 'slug': 'peripherals'}
        ],
        'tags': [
          {'id': 101, 'name': 'RGB', 'slug': 'rgb'}
        ],
        'images': [
          {'id': 301, 'src': 'https://example.com/kb1.jpg', 'alt': 'Keyboard'}
        ],
        'attributes': [
          {
            'id': 1,
            'name': 'Switch Type',
            'position': 0,
            'visible': true,
            'variation': false,
            'options': ['Cherry MX Blue', 'Cherry MX Red']
          }
        ],
        'meta_data': [
          {'id': 99, 'key': '_custom_field', 'value': 'custom_val'}
        ],
        '_links': {
          'self': [
            {'href': 'https://example.com/wp-json/wc/v3/products/5678'}
          ]
        }
      };

      final model = PutUpdateModel.fromJson(jsonResponse);

      expect(model.id, 5678);
      expect(model.name, 'Mechanical Gaming Keyboard');
      expect(model.slug, 'mechanical-gaming-keyboard');
      expect(model.sku, 'ISH-KB-RGB');
      expect(model.regularPrice, '99.99');
      expect(model.salePrice, '89.99');
      expect(model.manageStock, isTrue);
      expect(model.stockQuantity, 18);
      expect(model.dimensions?.length, '44');
      expect(model.categories?.length, 1);
      expect(model.categories?.first.id, 20);
      expect(model.tags?.length, 1);
      expect(model.tags?.first.name, 'RGB');
      expect(model.images?.length, 1);
      expect(model.images?.first.src, 'https://example.com/kb1.jpg');
      expect(model.attributes?.length, 1);
      expect(model.attributes?.first.options, ['Cherry MX Blue', 'Cherry MX Red']);
      expect(model.metaData?.length, 1);
      expect(model.metaData?.first.key, '_custom_field');
      expect(model.metaData?.first.value, 'custom_val');
      expect(model.lLinks?.self?.first.href, 'https://example.com/wp-json/wc/v3/products/5678');
    });

    test('bidirectional conversion between PutUpdateModel and PostCreateModel preserves all values', () {
      final postModel = PostCreateModel(
        id: 777,
        name: 'Smart Fitness Tracker',
        sku: 'ISH-FIT-07',
        regularPrice: '59.99',
        salePrice: '49.99',
        manageStock: true,
        stockQuantity: 30,
        status: 'publish',
        categories: [ProductCategoryRef(id: 8, name: 'Wearables')],
      );

      final putModel = PutUpdateModel.fromPostCreateModel(postModel);
      expect(putModel.id, 777);
      expect(putModel.name, 'Smart Fitness Tracker');
      expect(putModel.sku, 'ISH-FIT-07');
      expect(putModel.regularPrice, '59.99');
      expect(putModel.salePrice, '49.99');
      expect(putModel.manageStock, isTrue);
      expect(putModel.stockQuantity, 30);
      expect(putModel.categories?.first.id, 8);

      final convertedBack = putModel.toPostCreateModel();
      expect(convertedBack.id, 777);
      expect(convertedBack.name, 'Smart Fitness Tracker');
      expect(convertedBack.sku, 'ISH-FIT-07');
      expect(convertedBack.categories?.first.id, 8);
    });
  });
}
