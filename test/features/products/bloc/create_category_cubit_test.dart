import 'dart:typed_data';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/core/network/network_exceptions.dart';
import 'package:ishine_admin_app/features/products/bloc/create_category_cubit.dart';
import 'package:ishine_admin_app/features/products/bloc/create_category_state.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}
class FakeProductCategoryRef extends Fake implements ProductCategoryRef {}

void main() {
  late MockProductsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeProductCategoryRef());
    registerFallbackValue(Uint8List(0));
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockProductsRepository();
  });

  group('CreateCategoryCubit', () {
    test('initial state is default CreateCategoryState', () {
      final cubit = CreateCategoryCubit(repository: mockRepository);
      expect(cubit.state.status, CreateCategoryStatus.initial);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.createdCategory, isNull);
      cubit.close();
    });

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'loadParentCategories loads parent categories from repository',
      build: () {
        when(() => mockRepository.getCategories()).thenAnswer(
          (_) async => [
            ProductCategoryRef(id: 1, name: 'Clothing'),
            ProductCategoryRef(id: 2, name: 'Electronics'),
          ],
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.loadParentCategories(),
      expect: () => [
        const CreateCategoryState(status: CreateCategoryStatus.loadingParents),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.initial)
            .having((s) => s.parentCategories.length, 'parentCategories.length', 2),
      ],
      verify: (_) {
        verify(() => mockRepository.getCategories()).called(1);
      },
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'submitCategory emits failure when name is empty without calling repository',
      build: () => CreateCategoryCubit(repository: mockRepository),
      act: (cubit) => cubit.submitCategory(name: '   '),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Category name is required.'),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.createCategory(any()));
      },
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'submitCategory succeeds and emits [submitting, success]',
      build: () {
        when(() => mockRepository.createCategory(any())).thenAnswer(
          (invocation) async {
            final category = invocation.positionalArguments[0] as ProductCategoryRef;
            return ProductCategoryRef(
              id: 99,
              name: category.name,
              slug: category.slug ?? 'smartphones',
              parent: category.parent,
              description: category.description,
              display: category.display,
            );
          },
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.submitCategory(
        name: 'Smartphones',
        slug: 'smartphones',
        description: 'Flagship mobile devices',
        parentId: 5,
        display: 'products',
      ),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.submitting),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.success)
            .having((s) => s.createdCategory?.id, 'id', 99)
            .having((s) => s.createdCategory?.name, 'name', 'Smartphones'),
      ],
      verify: (_) {
        verify(() => mockRepository.createCategory(any())).called(1);
      },
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'submitCategory converts term_exists error into user-friendly message',
      build: () {
        when(() => mockRepository.createCategory(any())).thenThrow(
          const WooCommerceException(
            message: 'An item with this name already exists in this taxonomy.',
            statusCode: 400,
            errorData: {'code': 'term_exists'},
          ),
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.submitCategory(name: 'Existing Category'),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.submitting),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                'A category with this name or slug already exists in WooCommerce.'),
      ],
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'submitCategory handles 401 permission denied gracefully',
      build: () {
        when(() => mockRepository.createCategory(any())).thenThrow(
          const WooCommerceException(
            message: 'Sorry, you cannot create resources.',
            statusCode: 401,
          ),
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.submitCategory(name: 'Forbidden Category'),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.submitting),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.failure)
            .having((s) => s.errorMessage?.contains('Permission denied'), 'contains', true),
      ],
    );

    test('submitCategory prevents duplicate submission within debounce cooldown window', () async {
      when(() => mockRepository.createCategory(any())).thenAnswer(
        (_) async => ProductCategoryRef(id: 10, name: 'Cool Category'),
      );

      final cubit = CreateCategoryCubit(repository: mockRepository);

      final firstCall = cubit.submitCategory(name: 'Cool Category');
      final secondCall = cubit.submitCategory(name: 'Cool Category');

      final results = await Future.wait([firstCall, secondCall]);
      expect(results[0], isNotNull);
      // Second call was blocked by duplicate protection
      expect(results[1], isNull);

      cubit.close();
    });

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'uploadImage uploads image and updates selectedImage',
      build: () {
        when(() => mockRepository.uploadMedia(
              bytes: any(named: 'bytes'),
              filename: any(named: 'filename'),
              onProgress: any(named: 'onProgress'),
            )).thenAnswer(
          (_) async => ProductImageRef(id: 55, src: 'https://example.com/cat.jpg'),
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.uploadImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        filename: 'category.jpg',
      ),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.uploadingImage),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.initial)
            .having((s) => s.selectedImage?.id, 'id', 55)
            .having((s) => s.selectedImage?.src, 'src', 'https://example.com/cat.jpg'),
      ],
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'updateCategory validates empty name without calling repository',
      build: () => CreateCategoryCubit(repository: mockRepository),
      act: (cubit) => cubit.updateCategory(
        categoryId: 12,
        name: '   ',
      ),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'Category name is required.'),
      ],
      verify: (_) {
        verifyNever(() => mockRepository.updateCategory(
              categoryId: any(named: 'categoryId'),
              category: any(named: 'category'),
            ));
      },
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'updateCategory rejects setting category as its own parent',
      build: () => CreateCategoryCubit(repository: mockRepository),
      act: (cubit) => cubit.updateCategory(
        categoryId: 12,
        name: 'Gadgets',
        parentId: 12,
      ),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', 'A category cannot be its own parent.'),
      ],
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'updateCategory succeeds and emits [submitting, success]',
      build: () {
        when(() => mockRepository.updateCategory(
              categoryId: any(named: 'categoryId'),
              category: any(named: 'category'),
            )).thenAnswer(
          (invocation) async => ProductCategoryRef(
            id: 12,
            name: 'Updated Gadgets',
            slug: 'updated-gadgets',
          ),
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.updateCategory(
        categoryId: 12,
        name: 'Updated Gadgets',
        slug: 'updated-gadgets',
      ),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.submitting),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.success)
            .having((s) => s.updatedCategory?.id, 'updatedCategory.id', 12)
            .having((s) => s.updatedCategory?.name, 'updatedCategory.name', 'Updated Gadgets'),
      ],
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'deleteCategory emits [deleting, deleteSuccess]',
      build: () {
        when(() => mockRepository.deleteCategory(
              categoryId: any(named: 'categoryId'),
              force: any(named: 'force'),
            )).thenAnswer((_) async => true);
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCategory(12),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.deleting),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.deleteSuccess)
            .having((s) => s.deletedCategoryId, 'deletedCategoryId', 12),
      ],
      verify: (_) {
        verify(() => mockRepository.deleteCategory(
              categoryId: 12,
              force: true,
            )).called(1);
      },
    );

    blocTest<CreateCategoryCubit, CreateCategoryState>(
      'deleteCategory emits failure on WooCommerceException',
      build: () {
        when(() => mockRepository.deleteCategory(
              categoryId: any(named: 'categoryId'),
              force: any(named: 'force'),
            )).thenThrow(
          const WooCommerceException(
            message: 'Permission denied',
            statusCode: 403,
          ),
        );
        return CreateCategoryCubit(repository: mockRepository);
      },
      act: (cubit) => cubit.deleteCategory(12),
      expect: () => [
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.deleting),
        isA<CreateCategoryState>()
            .having((s) => s.status, 'status', CreateCategoryStatus.failure)
            .having((s) => s.errorMessage?.contains('Permission denied'), 'contains', true),
      ],
    );
  });
}

