import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_categories_model.dart';
import '../data/models/post_create_model.dart';
import '../data/repositories/products_repository.dart';
import 'products_event.dart';
import 'products_state.dart';

/// BLoC managing product catalog fetching, live filtering, KPI calculation, and cache refresh.
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductsRepository repository;

  ProductsBloc({required this.repository}) : super(const ProductsInitial()) {
    on<ProductsFetchRequested>(_onFetchRequested);
    on<ProductsRefreshRequested>(_onRefreshRequested);
    on<ProductsSearchChanged>(_onSearchChanged);
    on<ProductsCategoryChanged>(_onCategoryChanged);
    on<ProductsCategoryAdded>(_onCategoryAdded);
    on<ProductsCategoryUpdated>(_onCategoryUpdated);
    on<ProductsCategoryDeleted>(_onCategoryDeleted);
    on<ProductsCategoriesRefreshRequested>(_onCategoriesRefreshRequested);
  }

  Future<void> _onFetchRequested(
    ProductsFetchRequested event,
    Emitter<ProductsState> emit,
  ) async {
    await _loadProducts(emit, forceRefresh: event.forceRefresh);
  }

  Future<void> _onRefreshRequested(
    ProductsRefreshRequested event,
    Emitter<ProductsState> emit,
  ) async {
    await _loadProducts(emit, forceRefresh: true);
  }

  void _onSearchChanged(
    ProductsSearchChanged event,
    Emitter<ProductsState> emit,
  ) {
    if (state is ProductsSuccess) {
      final currentState = state as ProductsSuccess;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  void _onCategoryChanged(
    ProductsCategoryChanged event,
    Emitter<ProductsState> emit,
  ) {
    if (state is ProductsSuccess) {
      final currentState = state as ProductsSuccess;
      emit(currentState.copyWith(
        selectedCategory: event.category,
        selectedCategoryId: event.categoryId,
        clearCategoryId: event.categoryId == null,
      ));
    } else if (state is ProductsEmpty) {
      final currentState = state as ProductsEmpty;
      emit(ProductsEmpty(
        categories: currentState.categories,
        selectedCategory: event.category,
        selectedCategoryId: event.categoryId,
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  void _onCategoryAdded(
    ProductsCategoryAdded event,
    Emitter<ProductsState> emit,
  ) {
    if (state is ProductsSuccess) {
      final currentState = state as ProductsSuccess;
      final existing = currentState.categories;
      final alreadyExists = existing.any((c) =>
          (c.id != null && event.category.id != null && c.id == event.category.id) ||
          (c.slug != null && event.category.slug != null && c.slug == event.category.slug) ||
          (c.name != null && event.category.name != null && c.name?.toLowerCase() == event.category.name?.toLowerCase()));

      if (!alreadyExists) {
        final updated = List<GetCategoriesModel>.from(existing)..add(event.category);
        emit(currentState.copyWith(categories: updated));
      }
    } else if (state is ProductsEmpty) {
      final currentState = state as ProductsEmpty;
      final existing = currentState.categories;
      final alreadyExists = existing.any((c) =>
          (c.id != null && event.category.id != null && c.id == event.category.id) ||
          (c.slug != null && event.category.slug != null && c.slug == event.category.slug) ||
          (c.name != null && event.category.name != null && c.name?.toLowerCase() == event.category.name?.toLowerCase()));

      if (!alreadyExists) {
        final updated = List<GetCategoriesModel>.from(existing)..add(event.category);
        emit(ProductsEmpty(
          categories: updated,
          selectedCategory: currentState.selectedCategory,
          selectedCategoryId: currentState.selectedCategoryId,
          searchQuery: currentState.searchQuery,
        ));
      }
    }
  }

  void _onCategoryUpdated(
    ProductsCategoryUpdated event,
    Emitter<ProductsState> emit,
  ) {
    if (state is ProductsSuccess) {
      final currentState = state as ProductsSuccess;
      final updatedCategories = currentState.categories.map((c) {
        if ((c.id != null && event.category.id != null && c.id == event.category.id) ||
            (c.slug != null && event.category.slug != null && c.slug == event.category.slug)) {
          return event.category;
        }
        return c;
      }).toList();

      emit(currentState.copyWith(categories: updatedCategories));
    } else if (state is ProductsEmpty) {
      final currentState = state as ProductsEmpty;
      final updatedCategories = currentState.categories.map((c) {
        if ((c.id != null && event.category.id != null && c.id == event.category.id) ||
            (c.slug != null && event.category.slug != null && c.slug == event.category.slug)) {
          return event.category;
        }
        return c;
      }).toList();

      emit(ProductsEmpty(
        categories: updatedCategories,
        selectedCategory: currentState.selectedCategory,
        selectedCategoryId: currentState.selectedCategoryId,
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  void _onCategoryDeleted(
    ProductsCategoryDeleted event,
    Emitter<ProductsState> emit,
  ) {
    if (state is ProductsSuccess) {
      final currentState = state as ProductsSuccess;
      final deletedCat = currentState.categories.firstWhere(
        (c) => c.id == event.categoryId,
        orElse: () => GetCategoriesModel(id: event.categoryId),
      );
      final updatedCategories = currentState.categories
          .where((c) => c.id != event.categoryId)
          .toList();

      var newSelectedCat = currentState.selectedCategory;
      int? newSelectedCatId = currentState.selectedCategoryId;
      if (newSelectedCat == deletedCat.slug || newSelectedCat == deletedCat.name || newSelectedCatId == event.categoryId) {
        newSelectedCat = 'all';
        newSelectedCatId = null;
      }

      emit(currentState.copyWith(
        categories: updatedCategories,
        selectedCategory: newSelectedCat,
        selectedCategoryId: newSelectedCatId,
        clearCategoryId: newSelectedCatId == null,
      ));
    } else if (state is ProductsEmpty) {
      final currentState = state as ProductsEmpty;
      final deletedCat = currentState.categories.firstWhere(
        (c) => c.id == event.categoryId,
        orElse: () => GetCategoriesModel(id: event.categoryId),
      );
      final updatedCategories = currentState.categories
          .where((c) => c.id != event.categoryId)
          .toList();

      var newSelectedCat = currentState.selectedCategory;
      int? newSelectedCatId = currentState.selectedCategoryId;
      if (newSelectedCat == deletedCat.slug || newSelectedCat == deletedCat.name || newSelectedCatId == event.categoryId) {
        newSelectedCat = 'all';
        newSelectedCatId = null;
      }

      emit(ProductsEmpty(
        categories: updatedCategories,
        selectedCategory: newSelectedCat,
        selectedCategoryId: newSelectedCatId,
        searchQuery: currentState.searchQuery,
      ));
    }
  }

  Future<void> _onCategoriesRefreshRequested(
    ProductsCategoriesRefreshRequested event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      final freshCategories = await repository.getCategories(
        page: 1,
        perPage: 50,
        forceRefresh: true,
      );
      if (state is ProductsSuccess) {
        final currentState = state as ProductsSuccess;
        emit(currentState.copyWith(categories: freshCategories));
      } else if (state is ProductsEmpty) {
        final currentState = state as ProductsEmpty;
        emit(ProductsEmpty(
          categories: freshCategories,
          selectedCategory: currentState.selectedCategory,
          selectedCategoryId: currentState.selectedCategoryId,
          searchQuery: currentState.searchQuery,
        ));
      }
    } catch (_) {
      // Non-fatal; preserve existing categories
    }
  }

  Future<void> _loadProducts(
    Emitter<ProductsState> emit, {
    bool forceRefresh = false,
  }) async {
    if (!EnvConfig.isConfigured) {
      emit(
        ProductsFailure(
          errorMessage: 'WooCommerce credentials missing in .env file.',
          selectedCategory: state.selectedCategory,
          selectedCategoryId: state.selectedCategoryId,
          searchQuery: state.searchQuery,
        ),
      );
      return;
    }

    final previousProducts = (state is ProductsSuccess)
        ? (state as ProductsSuccess).products
        : null;

    emit(
      ProductsLoading(
        previousProducts: previousProducts,
        selectedCategory: state.selectedCategory,
        selectedCategoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
      ),
    );

    try {
      final productsFuture = repository.getProducts(
        perPage: 50,
        forceRefresh: forceRefresh,
      );
      final categoriesFuture = repository.getCategories(
        page: 1,
        perPage: 50,
        forceRefresh: forceRefresh,
      );

      final products = await productsFuture;
      final categories = await categoriesFuture;

      if (products.isEmpty) {
        emit(
          ProductsEmpty(
            categories: categories,
            selectedCategory: state.selectedCategory,
            selectedCategoryId: state.selectedCategoryId,
            searchQuery: state.searchQuery,
          ),
        );
      } else {
        emit(
          ProductsSuccess(
            products: products,
            categories: categories,
            selectedCategory: state.selectedCategory,
            selectedCategoryId: state.selectedCategoryId,
            searchQuery: state.searchQuery,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    } on WooCommerceException catch (e) {
      final isTimeout = e.statusCode == 408 || e.message.toLowerCase().contains('timed out');
      final isNetwork = !isTimeout &&
          (e.message.toLowerCase().contains('connect') || e.message.toLowerCase().contains('network'));

      emit(
        ProductsFailure(
          errorMessage: e.message,
          statusCode: e.statusCode,
          isTimeout: isTimeout,
          isNetworkError: isNetwork,
          selectedCategory: state.selectedCategory,
          selectedCategoryId: state.selectedCategoryId,
          searchQuery: state.searchQuery,
        ),
      );
    } catch (e) {
      emit(
        ProductsFailure(
          errorMessage: 'Failed to load WooCommerce catalog: ${e.toString()}',
          selectedCategory: state.selectedCategory,
          selectedCategoryId: state.selectedCategoryId,
          searchQuery: state.searchQuery,
        ),
      );
    }
  }
}
