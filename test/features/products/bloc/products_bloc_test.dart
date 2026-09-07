import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/products/bloc/products_bloc.dart';
import 'package:ishine_admin_app/features/products/bloc/products_event.dart';
import 'package:ishine_admin_app/features/products/bloc/products_state.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository mockRepository;
  late List<PostCreateModel> sampleProducts;
  late List<ProductCategoryRef> sampleCategories;

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockProductsRepository();

    sampleCategories = [
      ProductCategoryRef(id: 1, name: 'Audio', slug: 'audio'),
      ProductCategoryRef(id: 2, name: 'Accessories', slug: 'accessories'),
    ];

    sampleProducts = [
      PostCreateModel(
        id: 1,
        name: 'Wireless Headphones Pro',
        sku: 'ISH-AUD-01',
        regularPrice: '149.99',
        manageStock: true,
        stockQuantity: 20,
        lowStockAmount: 5,
        status: 'publish',
        categories: [ProductCategoryRef(id: 1, name: 'Audio', slug: 'audio')],
      ),
      PostCreateModel(
        id: 2,
        name: 'USB-C Fast Charging Cable',
        sku: 'ISH-ACC-02',
        regularPrice: '19.99',
        manageStock: true,
        stockQuantity: 3, // Low stock <= 5
        lowStockAmount: 5,
        status: 'publish',
        categories: [ProductCategoryRef(id: 2, name: 'Accessories', slug: 'accessories')],
      ),
      PostCreateModel(
        id: 3,
        name: 'Bluetooth Speaker Mini',
        sku: 'ISH-AUD-03',
        regularPrice: '49.99',
        manageStock: true,
        stockQuantity: 0, // Out of stock
        lowStockAmount: 5,
        status: 'publish',
        categories: [ProductCategoryRef(id: 1, name: 'Audio', slug: 'audio')],
      ),
    ];
  });

  group('ProductsBloc', () {
    test('initial state is ProductsInitial', () {
      final bloc = ProductsBloc(repository: mockRepository);
      expect(bloc.state, const ProductsInitial());
      expect(bloc.state.selectedCategory, 'all');
      expect(bloc.state.searchQuery, '');
      bloc.close();
    });

    blocTest<ProductsBloc, ProductsState>(
      'emits [ProductsLoading, ProductsSuccess] on ProductsFetchRequested',
      setUp: () {
        when(() => mockRepository.getProducts(
              perPage: any(named: 'perPage'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleProducts);
        when(() => mockRepository.getCategories(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleCategories);
      },
      build: () => ProductsBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const ProductsFetchRequested()),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsSuccess>()
            .having((s) => s.products.length, 'products.length', 3)
            .having((s) => s.categories.length, 'categories.length', 2)
            .having((s) => s.totalCount, 'totalCount', 3)
            .having((s) => s.inStockCount, 'inStockCount', 2)
            .having((s) => s.lowStockCount, 'lowStockCount', 1)
            .having((s) => s.outOfStockCount, 'outOfStockCount', 1),
      ],
    );

    blocTest<ProductsBloc, ProductsState>(
      'filters products correctly when search and category change',
      setUp: () {
        when(() => mockRepository.getProducts(
              perPage: any(named: 'perPage'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleProducts);
        when(() => mockRepository.getCategories(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => sampleCategories);
      },
      build: () => ProductsBloc(repository: mockRepository),
      seed: () => ProductsSuccess(
        products: sampleProducts,
        categories: sampleCategories,
        lastUpdated: DateTime.now(),
      ),
      act: (bloc) {
        bloc.add(const ProductsCategoryChanged('audio'));
        bloc.add(const ProductsSearchChanged('Headphones'));
      },
      expect: () => [
        isA<ProductsSuccess>()
            .having((s) => s.selectedCategory, 'selectedCategory', 'audio')
            .having((s) => s.filteredProducts.length, 'audio filtered count', 2),
        isA<ProductsSuccess>()
            .having((s) => s.searchQuery, 'searchQuery', 'Headphones')
            .having((s) => s.filteredProducts.length, 'filteredProducts.length', 1)
            .having((s) => s.filteredProducts.first.name, 'first product name', 'Wireless Headphones Pro'),
      ],
    );

    blocTest<ProductsBloc, ProductsState>(
      'emits [ProductsLoading, ProductsFailure] when network fails',
      setUp: () {
        when(() => mockRepository.getProducts(
              perPage: any(named: 'perPage'),
              forceRefresh: any(named: 'forceRefresh'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Server error: could not fetch products.',
            statusCode: 500,
          ),
        );
        when(() => mockRepository.getCategories(
              forceRefresh: any(named: 'forceRefresh'),
            )).thenAnswer((_) async => []);
      },
      build: () => ProductsBloc(repository: mockRepository),
      act: (bloc) => bloc.add(const ProductsFetchRequested()),
      expect: () => [
        isA<ProductsLoading>(),
        isA<ProductsFailure>()
            .having((s) => s.errorMessage, 'errorMessage', contains('Server error'))
            .having((s) => s.statusCode, 'statusCode', 500),
      ],
    );
  });
}
