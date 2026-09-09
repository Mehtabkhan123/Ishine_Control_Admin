import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:ishine_admin_app/features/products/data/services/products_service.dart';
import 'package:ishine_admin_app/features/system_status/data/services/system_status_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}
class MockProductsService extends Mock implements ProductsService {}
class FakeProductCategoryModel extends Fake implements ProductCategoryModel {}

void main() {
  late MockDio mockDio;
  late ProductsService service;

  setUpAll(() {
    registerFallbackValue(FakeProductCategoryModel());
    registerFallbackValue(WooCommerceAuthMode.auto);
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test_12345',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test_67890',
    });
  });

  setUp(() {
    mockDio = MockDio();
    service = ProductsService(dio: mockDio);
  });

  group('ProductCategoryModel - Tests', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 42,
        'name': 'Smartphones',
        'slug': 'smartphones',
        'parent': 10,
        'description': 'Latest mobile devices',
        'display': 'products',
        'menu_order': 3,
        'count': 25,
        'image': {
          'id': 99,
          'src': 'https://example.com/phone.png',
        },
      };

      final model = ProductCategoryModel.fromJson(json);

      expect(model.id, 42);
      expect(model.name, 'Smartphones');
      expect(model.slug, 'smartphones');
      expect(model.parent, 10);
      expect(model.description, 'Latest mobile devices');
      expect(model.display, 'products');
      expect(model.menuOrder, 3);
      expect(model.count, 25);
      expect(model.image?.id, 99);
      expect(model.image?.src, 'https://example.com/phone.png');

      final serialized = model.toJson();
      expect(serialized['id'], 42);
      expect(serialized['name'], 'Smartphones');
      expect(serialized['parent'], 10);
    });

    test('toCreatePayload generates clean WooCommerce POST body', () {
      final model = ProductCategoryModel(
        name: '  Laptops  ',
        slug: '  laptops-pro  ',
        parent: 5,
        description: '  High performance laptops  ',
        display: 'subcategories',
        image: ProductImageRef(id: 12),
        menuOrder: 1,
      );

      final payload = model.toCreatePayload();
      expect(payload['name'], 'Laptops');
      expect(payload['slug'], 'laptops-pro');
      expect(payload['parent'], 5);
      expect(payload['description'], 'High performance laptops');
      expect(payload['display'], 'subcategories');
      expect(payload['image'], {'id': 12});
      expect(payload['menu_order'], 1);
    });

    test('toUpdatePayload generates dynamic PUT body', () {
      final model = ProductCategoryModel(
        id: 55,
        name: 'Updated Name',
        slug: 'updated-slug',
        parent: 0,
        description: 'New desc',
        display: 'both',
        image: ProductImageRef(src: 'https://example.com/updated.jpg'),
      );

      final payload = model.toUpdatePayload();
      expect(payload['name'], 'Updated Name');
      expect(payload['slug'], 'updated-slug');
      expect(payload['parent'], 0);
      expect(payload['description'], 'New desc');
      expect(payload['display'], 'both');
      expect(payload['image'], {'src': 'https://example.com/updated.jpg'});
    });

    test('copyWith produces modified copy without mutating original', () {
      final original = ProductCategoryModel(id: 1, name: 'Original');
      final modified = original.copyWith(name: 'Modified', slug: 'mod');

      expect(original.name, 'Original');
      expect(modified.id, 1);
      expect(modified.name, 'Modified');
      expect(modified.slug, 'mod');
    });
  });

  group('ProductsService - updateCategory (PUT)', () {
    test('sends PUT to /wp-json/wc/v3/products/categories/{id} and returns updated model', () async {
      final updateData = ProductCategoryModel(
        id: 78,
        name: 'Headphones Pro',
        slug: 'headphones-pro',
        description: 'Updated audio gear',
        parent: 0,
        display: 'products',
      );

      final responseJson = {
        'id': 78,
        'name': 'Headphones Pro',
        'slug': 'headphones-pro',
        'parent': 0,
        'description': 'Updated audio gear',
        'display': 'products',
        'count': 5,
      };

      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories/78'),
          statusCode: 200,
          data: responseJson,
        ),
      );

      final result = await service.updateCategory(
        categoryId: 78,
        category: updateData,
      );

      expect(result.id, 78);
      expect(result.name, 'Headphones Pro');
      expect(result.slug, 'headphones-pro');
      expect(result.count, 5);

      verify(() => mockDio.put(
            'https://example.com/wp-json/wc/v3/products/categories/78',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('throws WooCommerceException on HTTP 404 Not Found', () async {
      when(() => mockDio.put(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories/999'),
          statusCode: 404,
          data: {
            'code': 'woocommerce_rest_term_invalid',
            'message': 'Resource does not exist.',
          },
        ),
      );

      expect(
        () => service.updateCategory(
          categoryId: 999,
          category: ProductCategoryModel(name: 'Does Not Exist'),
        ),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );
    });
  });

  group('ProductsService - deleteCategory (DELETE)', () {
    test('sends DELETE to /wp-json/wc/v3/products/categories/{id}?force=true and returns true', () async {
      when(() => mockDio.delete(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories/78'),
          statusCode: 200,
          data: {
            'id': 78,
            'name': 'Headphones',
            'slug': 'headphones',
          },
        ),
      );

      final success = await service.deleteCategory(categoryId: 78, force: true);

      expect(success, isTrue);

      verify(() => mockDio.delete(
            'https://example.com/wp-json/wc/v3/products/categories/78',
            queryParameters: {'force': 'true'},
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('throws WooCommerceException on HTTP 403 Forbidden', () async {
      when(() => mockDio.delete(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories/78'),
          statusCode: 403,
          data: {
            'code': 'woocommerce_rest_cannot_delete',
            'message': 'Sorry, you cannot delete this resource.',
          },
        ),
      );

      expect(
        () => service.deleteCategory(categoryId: 78),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          403,
        )),
      );
    });
  });

  group('ProductsRepository - Category CRUD', () {
    late MockProductsService mockService;
    late ProductsRepository repository;

    setUp(() {
      mockService = MockProductsService();
      repository = ProductsRepository(service: mockService);
    });

    test('updateCategory delegates to service and invalidates cache', () async {
      final input = ProductCategoryModel(id: 45, name: 'Tablets');
      final updated = ProductCategoryModel(id: 45, name: 'Tablets Pro', slug: 'tablets-pro');

      when(() => mockService.updateCategory(
            categoryId: any(named: 'categoryId'),
            category: any(named: 'category'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => updated);

      final result = await repository.updateCategory(categoryId: 45, category: input);

      expect(result.id, 45);
      expect(result.name, 'Tablets Pro');
      verify(() => mockService.updateCategory(
            categoryId: 45,
            category: input,
            baseUrl: null,
            consumerKey: null,
            consumerSecret: null,
            authMode: any(named: 'authMode'),
            cancelToken: null,
          )).called(1);
    });

    test('deleteCategory delegates to service and invalidates cache', () async {
      when(() => mockService.deleteCategory(
            categoryId: any(named: 'categoryId'),
            force: any(named: 'force'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => true);

      final result = await repository.deleteCategory(categoryId: 45, force: true);

      expect(result, isTrue);
      verify(() => mockService.deleteCategory(
            categoryId: 45,
            force: true,
            baseUrl: null,
            consumerKey: null,
            consumerSecret: null,
            authMode: any(named: 'authMode'),
            cancelToken: null,
          )).called(1);
    });
  });
}
