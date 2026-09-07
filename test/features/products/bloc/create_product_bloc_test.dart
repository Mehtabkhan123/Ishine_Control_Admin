import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/products/bloc/create_product_bloc.dart';
import 'package:ishine_admin_app/features/products/bloc/create_product_event.dart';
import 'package:ishine_admin_app/features/products/bloc/create_product_state.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}
class FakePostCreateModel extends Fake implements PostCreateModel {}

void main() {
  late MockProductsRepository mockRepository;
  late PostCreateModel validProduct;

  setUpAll(() {
    registerFallbackValue(FakePostCreateModel());
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockProductsRepository();
    validProduct = PostCreateModel(
      name: 'Wireless Ergonomic Keyboard',
      sku: 'ISH-KB-01',
      regularPrice: '79.99',
      manageStock: true,
      stockQuantity: 15,
      status: 'publish',
    );
  });

  group('CreateProductBloc', () {
    test('initial state is default CreateProductState', () {
      final bloc = CreateProductBloc(repository: mockRepository);
      expect(bloc.state.status, CreateProductStatus.initial);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.createdProduct, isNull);
      bloc.close();
    });

    blocTest<CreateProductBloc, CreateProductState>(
      'emits failure when product name is empty without calling repository',
      build: () => CreateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        CreateProductSubmitted(
          PostCreateModel(name: '   ', regularPrice: '19.99'),
        ),
      ),
      expect: () => [
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Product name is required.')
            .having((s) => s.statusCode, 'statusCode', 400),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.createProduct(any()));
      },
    );

    blocTest<CreateProductBloc, CreateProductState>(
      'emits [submitting, success] on successful product creation',
      setUp: () {
        when(() => mockRepository.createProduct(any())).thenAnswer(
          (_) async => PostCreateModel(
            id: 101,
            name: validProduct.name,
            sku: validProduct.sku,
            regularPrice: validProduct.regularPrice,
          ),
        );
      },
      build: () => CreateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(CreateProductSubmitted(validProduct)),
      expect: () => [
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.submitting),
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.success)
            .having((s) => s.createdProduct?.id, 'createdProduct.id', 101)
            .having((s) => s.createdProduct?.name, 'createdProduct.name', validProduct.name),
      ],
      verify: (_) {
        verify(() => mockRepository.createProduct(any())).called(1);
      },
    );

    blocTest<CreateProductBloc, CreateProductState>(
      'prevents rapid duplicate submission of the exact same product',
      setUp: () {
        when(() => mockRepository.createProduct(any())).thenAnswer(
          (_) async => PostCreateModel(id: 102, name: validProduct.name, sku: validProduct.sku),
        );
      },
      build: () => CreateProductBloc(repository: mockRepository),
      act: (bloc) async {
        bloc.add(CreateProductSubmitted(validProduct));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(CreateProductSubmitted(validProduct));
      },
      expect: () => [
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.submitting),
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.success),
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.failure)
            .having((s) => s.isDuplicateBlocked, 'isDuplicateBlocked', isTrue)
            .having((s) => s.errorMessage, 'errorMessage', contains('Duplicate submission prevented')),
      ],
      verify: (_) {
        // Repository createProduct should only be called once, not twice
        verify(() => mockRepository.createProduct(any())).called(1);
      },
    );

    blocTest<CreateProductBloc, CreateProductState>(
      'emits [submitting, failure] with isTimeout=true on connection timeout (408)',
      setUp: () {
        when(() => mockRepository.createProduct(any())).thenThrow(
          const WooCommerceException(
            message: 'Connection timed out while reaching the WooCommerce store.',
            statusCode: 408,
          ),
        );
      },
      build: () => CreateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(CreateProductSubmitted(validProduct)),
      expect: () => [
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.submitting),
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.failure)
            .having((s) => s.isTimeout, 'isTimeout', isTrue)
            .having((s) => s.statusCode, 'statusCode', 408),
      ],
    );

    blocTest<CreateProductBloc, CreateProductState>(
      'emits [submitting, failure] with isNetworkError=true on connection error',
      setUp: () {
        when(() => mockRepository.createProduct(any())).thenThrow(
          const WooCommerceException(
            message: 'Could not connect to the WooCommerce store. Verify network connectivity.',
          ),
        );
      },
      build: () => CreateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(CreateProductSubmitted(validProduct)),
      expect: () => [
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.submitting),
        isA<CreateProductState>()
            .having((s) => s.status, 'status', CreateProductStatus.failure)
            .having((s) => s.isNetworkError, 'isNetworkError', isTrue),
      ],
    );
  });
}
