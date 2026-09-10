import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/products/data/models/get_categories_model.dart';

void main() {
  group('GetCategoriesModel', () {
    final sampleCategoryJson = {
      'id': 19,
      'name': 'Clothing',
      'slug': 'clothing',
      'parent': 0,
      'description': 'All clothing products',
      'display': 'default',
      'image': {
        'id': 730,
        'date_created': '2023-01-01T00:00:00',
        'date_created_gmt': '2023-01-01T00:00:00',
        'date_modified': '2023-01-01T00:00:00',
        'date_modified_gmt': '2023-01-01T00:00:00',
        'src': 'https://example.com/wp-content/uploads/clothing.jpg',
        'name': 'Clothing Banner',
        'alt': 'Clothing category'
      },
      'menu_order': 2,
      'count': 36,
      '_links': {
        'self': [
          {
            'href': 'https://example.com/wp-json/wc/v3/products/categories/19',
            'targetHints': {
              'allow': ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
            }
          }
        ],
        'collection': [
          {'href': 'https://example.com/wp-json/wc/v3/products/categories'}
        ],
        'up': [
          {'href': 'https://example.com/wp-json/wc/v3/products/categories/0'}
        ]
      }
    };

    test('fromJson parses WooCommerce Category JSON correctly', () {
      final model = GetCategoriesModel.fromJson(sampleCategoryJson);

      expect(model.id, 19);
      expect(model.name, 'Clothing');
      expect(model.slug, 'clothing');
      expect(model.parent, 0);
      expect(model.description, 'All clothing products');
      expect(model.display, 'default');
      expect(model.menuOrder, 2);
      expect(model.count, 36);
      expect(model.isMainCategory, isTrue);
      expect(model.imageUrl, 'https://example.com/wp-content/uploads/clothing.jpg');
      expect(model.productCount, 36);
      expect(model.sortOrder, 2);
      expect(model.displayName, 'Clothing');
      expect(model.displaySlug, 'clothing');

      // Links check
      expect(model.lLinks, isNotNull);
      expect(model.lLinks?.self?.first.href, contains('/products/categories/19'));
      expect(model.lLinks?.self?.first.targetHints?.allow, contains('GET'));
      expect(model.lLinks?.collection?.first.href, contains('/products/categories'));
      expect(model.lLinks?.up?.first.href, contains('/products/categories/0'));
    });

    test('toJson serializes model back to Map', () {
      final model = GetCategoriesModel.fromJson(sampleCategoryJson);
      final json = model.toJson();

      expect(json['id'], 19);
      expect(json['name'], 'Clothing');
      expect(json['slug'], 'clothing');
      expect(json['parent'], 0);
      expect(json['count'], 36);
      expect(json['_links'], isNotNull);
    });

    test('isMainCategory returns true when parent is 0 or null, false otherwise', () {
      final mainCat = GetCategoriesModel(id: 1, name: 'Main', parent: 0);
      expect(mainCat.isMainCategory, isTrue);

      final nullParentCat = GetCategoriesModel(id: 2, name: 'Null Parent', parent: null);
      expect(nullParentCat.isMainCategory, isTrue);

      final subCat = GetCategoriesModel(id: 3, name: 'Sub', parent: 1);
      expect(subCat.isMainCategory, isFalse);
    });

    test('imageUrl safely resolves map, string URL, and null image fields', () {
      final mapImageCat = GetCategoriesModel.fromJson({
        'id': 1,
        'name': 'Cat with Map Image',
        'image': {'src': 'https://example.com/test.jpg'}
      });
      expect(mapImageCat.imageUrl, 'https://example.com/test.jpg');

      final stringImageCat = GetCategoriesModel.fromJson({
        'id': 2,
        'name': 'Cat with String Image',
        'image': 'https://example.com/string_img.png'
      });
      expect(stringImageCat.imageUrl, 'https://example.com/string_img.png');

      final nullImageCat = GetCategoriesModel.fromJson({
        'id': 3,
        'name': 'Cat without Image',
        'image': null
      });
      expect(nullImageCat.imageUrl, isNull);
    });

    test('getCategoriesModelFromJson parses array string JSON', () {
      final jsonArray = jsonEncode([
        sampleCategoryJson,
        {
          'id': 20,
          'name': 'T-Shirts',
          'slug': 't-shirts',
          'parent': 19,
          'count': 12,
        }
      ]);

      final categories = getCategoriesModelFromJson(jsonArray);

      expect(categories.length, 2);
      expect(categories[0].name, 'Clothing');
      expect(categories[0].isMainCategory, isTrue);
      expect(categories[1].name, 'T-Shirts');
      expect(categories[1].isMainCategory, isFalse);
      expect(categories[1].parent, 19);

      final serialized = getCategoriesModelToJson(categories);
      expect(serialized, contains('Clothing'));
      expect(serialized, contains('T-Shirts'));
    });

    test('toCreatePayload and toUpdatePayload format payload correctly', () {
      final cat = GetCategoriesModel(
        id: 10,
        name: 'Accessories',
        slug: 'accessories',
        parent: 0,
        description: 'Bags, hats, etc.',
      );

      final createPayload = cat.toCreatePayload();
      expect(createPayload['name'], 'Accessories');
      expect(createPayload['slug'], 'accessories');
      expect(createPayload['parent'], 0);
      expect(createPayload['description'], 'Bags, hats, etc.');

      final updatePayload = cat.toUpdatePayload();
      expect(updatePayload['name'], 'Accessories');
      expect(updatePayload['slug'], 'accessories');
    });
  });
}
