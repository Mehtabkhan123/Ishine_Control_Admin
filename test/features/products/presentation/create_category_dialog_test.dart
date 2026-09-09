import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ishine_admin_app/features/products/bloc/create_category_cubit.dart';
import 'package:ishine_admin_app/features/products/data/models/post_create_model.dart';
import 'package:ishine_admin_app/features/products/data/repositories/products_repository.dart';
import 'package:ishine_admin_app/features/products/presentation/widgets/create_category_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}
class FakeProductCategoryRef extends Fake implements ProductCategoryRef {}

void main() {
  late MockProductsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeProductCategoryRef());
    dotenv.testLoad(mergeWith: {
      'WOOCOMMERCE_BASE_URL': 'https://example.com',
      'WOOCOMMERCE_CONSUMER_KEY': 'ck_test',
      'WOOCOMMERCE_CONSUMER_SECRET': 'cs_test',
    });
  });

  setUp(() {
    mockRepository = MockProductsRepository();
    when(() => mockRepository.getCategories()).thenAnswer(
      (_) async => [
        ProductCategoryRef(id: 1, name: 'Computers'),
        ProductCategoryRef(id: 2, name: 'Audio'),
      ],
    );
  });

  Widget createTestWidget({
    CreateCategoryCubit? cubit,
    ProductCategoryRef? categoryToEdit,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<CreateCategoryCubit>(
          create: (_) =>
              cubit ??
              (CreateCategoryCubit(repository: mockRepository)
                ..loadParentCategories()),
          child: CreateCategoryDialog(categoryToEdit: categoryToEdit),
        ),
      ),
    );
  }

  group('CreateCategoryDialog Widget Tests', () {
    testWidgets('renders all essential One UI form fields and buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Add New Category'), findsOneWidget);
      expect(find.text('POST /wp-json/wc/v3/products/categories'), findsOneWidget);

      // Section Titles
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Hierarchy & Display'), findsOneWidget);
      expect(find.text('Description (Optional)'), findsOneWidget);
      expect(find.text('Category Thumbnail'), findsOneWidget);

      // Buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create Category'), findsOneWidget);
      expect(find.text('Device Gallery'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
    });

    testWidgets('shows validation error when creating category with empty name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final createBtn = find.text('Create Category');
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Category name cannot be empty'), findsOneWidget);
    });

    testWidgets('auto-generates slug when typing category name', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Category Name *');
      await tester.enterText(nameField, 'Smart Home Devices');
      await tester.pumpAndSettle();

      expect(find.text('smart-home-devices'), findsOneWidget);
    });

    testWidgets('renders Edit mode and pre-populates category data', (tester) async {
      final category = ProductCategoryRef(
        id: 77,
        name: 'Gaming Laptops',
        slug: 'gaming-laptops',
        description: 'RTX 4090 gaming notebooks',
        parent: 1,
        display: 'products',
      );

      await tester.pumpWidget(createTestWidget(categoryToEdit: category));
      await tester.pumpAndSettle();

      // Header in edit mode
      expect(find.text('Edit Category'), findsOneWidget);
      expect(find.text('PUT /wp-json/wc/v3/products/categories/77'), findsOneWidget);

      // Populated fields
      expect(find.text('Gaming Laptops'), findsOneWidget);
      expect(find.text('gaming-laptops'), findsOneWidget);
      expect(find.text('RTX 4090 gaming notebooks'), findsOneWidget);

      // Buttons
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping Delete shows One UI confirmation dialog', (tester) async {
      final category = ProductCategoryRef(
        id: 77,
        name: 'Gaming Laptops',
        slug: 'gaming-laptops',
      );

      await tester.pumpWidget(createTestWidget(categoryToEdit: category));
      await tester.pumpAndSettle();

      final deleteBtn = find.text('Delete');
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Delete Category'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to permanently delete'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
      expect(find.text('Cancel'), findsWidgets);
    });
  });
}

