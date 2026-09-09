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
class FakeProductCategoryRef extends Fake implements ProductCategoryRef {}

void main() {
  late MockDio mockDio;
  late ProductsService service;

  setUpAll(() {
    registerFallbackValue(FakeProductCategoryRef());
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

  group('ProductsService - createCategory', () {
    test('successfully sends POST request and parses created ProductCategoryRef', () async {
      final inputCategory = ProductCategoryRef(
        name: 'Headphones',
        slug: 'headphones',
        description: 'Audio gear and noise-cancelling headphones',
        parent: 0,
        display: 'default',
        image: ProductImageRef(id: 101, src: 'https://example.com/headphones.jpg'),
      );

      final responseJson = {
        'id': 78,
        'name': 'Headphones',
        'slug': 'headphones',
        'parent': 0,
        'description': 'Audio gear and noise-cancelling headphones',
        'display': 'default',
        'image': {
          'id': 101,
          'src': 'https://example.com/headphones.jpg',
        },
        'count': 0,
      };

      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories'),
          statusCode: 201,
          data: responseJson,
        ),
      );

      final result = await service.createCategory(category: inputCategory);

      expect(result.id, 78);
      expect(result.name, 'Headphones');
      expect(result.slug, 'headphones');
      expect(result.image?.id, 101);
      expect(result.count, 0);

      verify(() => mockDio.post(
            'https://example.com/wp-json/wc/v3/products/categories',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).called(1);
    });

    test('throws WooCommerceException on HTTP 400 term_exists', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories'),
          statusCode: 400,
          data: {
            'code': 'term_exists',
            'message': 'An item with this name already exists in this taxonomy.',
            'data': {'resource_id': 12},
          },
        ),
      );

      expect(
        () => service.createCategory(
          category: ProductCategoryRef(name: 'Existing Category'),
        ),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          400,
        )),
      );
    });

    test('throws WooCommerceException on HTTP 401 Unauthorized', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/wp-json/wc/v3/products/categories'),
          statusCode: 401,
          data: {
            'code': 'woocommerce_rest_cannot_create',
            'message': 'Sorry, you cannot create resources.',
          },
        ),
      );

      expect(
        () => service.createCategory(
          category: ProductCategoryRef(name: 'New Category'),
        ),
        throwsA(isA<WooCommerceException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );
    });
  });

  group('ProductsRepository - createCategory', () {
    late MockProductsService mockService;
    late ProductsRepository repository;

    setUp(() {
      mockService = MockProductsService();
      repository = ProductsRepository(service: mockService);
    });

    test('delegates to service and returns created category', () async {
      final input = ProductCategoryRef(name: 'Smart Watches');
      final returned = ProductCategoryRef(id: 33, name: 'Smart Watches', slug: 'smart-watches');

      when(() => mockService.createCategory(
            category: any(named: 'category'),
            baseUrl: any(named: 'baseUrl'),
            consumerKey: any(named: 'consumerKey'),
            consumerSecret: any(named: 'consumerSecret'),
            authMode: any(named: 'authMode'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => returned);

      final result = await repository.createCategory(input);

      expect(result.id, 33);
      expect(result.name, 'Smart Watches');
      verify(() => mockService.createCategory(
            category: input,
            baseUrl: null,
            consumerKey: null,
            consumerSecret: null,
            authMode: any(named: 'authMode'),
            cancelToken: null,
          )).called(1);
    });
  });
}
