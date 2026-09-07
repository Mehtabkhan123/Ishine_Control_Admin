import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/products/bloc/update_product_bloc.dart';
import 'package:ishine_admin_app/features/products/bloc/update_product_event.dart';
import 'package:ishine_admin_app/features/products/bloc/update_product_state.dart';
import 'package:ishine_admin_app/features/products/data/models/put_update_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}
class FakePutUpdateModel extends Fake implements PutUpdateModel {}

void main() {
  late MockProductsRepository mockRepository;
  late PutUpdateModel validProduct;

  setUpAll(() {
    registerFallbackValue(FakePutUpdateModel());
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockProductsRepository();
    validProduct = PutUpdateModel(
      id: 42,
      name: 'Wireless Ergonomic Keyboard V2',
      sku: 'ISH-KB-02',
      regularPrice: '89.99',
      manageStock: true,
      stockQuantity: 20,
      status: 'publish',
    );
  });

  group('UpdateProductBloc', () {
    test('initial state is default UpdateProductState', () {
      final bloc = UpdateProductBloc(repository: mockRepository);
      expect(bloc.state.status, UpdateProductStatus.initial);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.updatedProduct, isNull);
      bloc.close();
    });

    blocTest<UpdateProductBloc, UpdateProductState>(
      'emits failure when productId <= 0 without invoking repository',
      build: () => UpdateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        UpdateProductSubmitted(
          productId: 0,
          product: validProduct,
        ),
      ),
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Invalid product ID for update.')
            .having((s) => s.statusCode, 'statusCode', 400),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.updateProduct(
              productId: any(named: 'productId'),
              product: any(named: 'product'),
            ));
      },
    );

    blocTest<UpdateProductBloc, UpdateProductState>(
      'emits failure when product name is empty without invoking repository',
      build: () => UpdateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        UpdateProductSubmitted(
          productId: 42,
          product: PutUpdateModel(name: '   ', regularPrice: '49.99'),
        ),
      ),
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Product name cannot be empty.')
            .having((s) => s.statusCode, 'statusCode', 400),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.updateProduct(
              productId: any(named: 'productId'),
              product: any(named: 'product'),
            ));
      },
    );

    blocTest<UpdateProductBloc, UpdateProductState>(
      'emits [submitting, success] on successful product update',
      setUp: () {
        when(() => mockRepository.updateProduct(
              productId: 42,
              product: any(named: 'product'),
            )).thenAnswer((_) async => validProduct);
      },
      build: () => UpdateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        UpdateProductSubmitted(
          productId: 42,
          product: validProduct,
        ),
      ),
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.submitting)
            .having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.success)
            .having((s) => s.isSuccess, 'isSuccess', isTrue)
            .having((s) => s.updatedProduct?.name, 'product name', 'Wireless Ergonomic Keyboard V2'),
      ],
      verify: (_) {
        verify(() => mockRepository.updateProduct(
              productId: 42,
              product: any(named: 'product'),
            )).called(1);
      },
    );

    blocTest<UpdateProductBloc, UpdateProductState>(
      'blocks rapid identical duplicate update submissions',
      setUp: () {
        when(() => mockRepository.updateProduct(
              productId: 42,
              product: any(named: 'product'),
            )).thenAnswer((_) async => validProduct);
      },
      build: () => UpdateProductBloc(repository: mockRepository),
      act: (bloc) async {
        bloc.add(UpdateProductSubmitted(productId: 42, product: validProduct));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(UpdateProductSubmitted(productId: 42, product: validProduct));
      },
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.submitting),
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.success),
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.failure)
            .having((s) => s.isDuplicateBlocked, 'isDuplicateBlocked', isTrue)
            .having((s) => s.errorMessage, 'errorMessage', contains('Duplicate update prevented')),
      ],
    );

    blocTest<UpdateProductBloc, UpdateProductState>(
      'emits failure on WooCommerceException (e.g. 404 Not Found)',
      setUp: () {
        when(() => mockRepository.updateProduct(
              productId: 42,
              product: any(named: 'product'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Product #42 not found (404).',
            statusCode: 404,
          ),
        );
      },
      build: () => UpdateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        UpdateProductSubmitted(productId: 42, product: validProduct),
      ),
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.submitting),
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.failure)
            .having((s) => s.statusCode, 'statusCode', 404)
            .having((s) => s.errorMessage, 'errorMessage', 'Product #42 not found (404).'),
      ],
    );

    blocTest<UpdateProductBloc, UpdateProductState>(
      'emits failure with timeout indicator on timeout error',
      setUp: () {
        when(() => mockRepository.updateProduct(
              productId: 42,
              product: any(named: 'product'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Connection timed out',
            statusCode: 408,
          ),
        );
      },
      build: () => UpdateProductBloc(repository: mockRepository),
      act: (bloc) => bloc.add(
        UpdateProductSubmitted(productId: 42, product: validProduct),
      ),
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.submitting),
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.failure)
            .having((s) => s.isTimeout, 'isTimeout', isTrue),
      ],
    );

    blocTest<UpdateProductBloc, UpdateProductState>(
      'resets state cleanly when UpdateProductReset is dispatched',
      build: () => UpdateProductBloc(repository: mockRepository),
      seed: () => const UpdateProductState(
        status: UpdateProductStatus.failure,
        errorMessage: 'Some past error',
        statusCode: 500,
        isTimeout: true,
      ),
      act: (bloc) => bloc.add(const UpdateProductReset()),
      expect: () => [
        isA<UpdateProductState>()
            .having((s) => s.status, 'status', UpdateProductStatus.initial)
            .having((s) => s.errorMessage, 'errorMessage', isNull)
            .having((s) => s.statusCode, 'statusCode', isNull)
            .having((s) => s.isTimeout, 'isTimeout', isFalse),
      ],
    );
  });
}
