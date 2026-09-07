import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/network_exceptions.dart';
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
      emit(currentState.copyWith(selectedCategory: event.category));
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
        searchQuery: state.searchQuery,
      ),
    );

    try {
      final productsFuture = repository.getProducts(
        perPage: 50,
        forceRefresh: forceRefresh,
      );
      final categoriesFuture = repository.getCategories(
        forceRefresh: forceRefresh,
      );

      final results = await Future.wait([productsFuture, categoriesFuture]);
      final products = results[0].cast<dynamic>();
      final categories = results[1].cast<dynamic>();

      if (products.isEmpty) {
        emit(
          ProductsEmpty(
            categories: categories.cast(),
            selectedCategory: state.selectedCategory,
            searchQuery: state.searchQuery,
          ),
        );
      } else {
        emit(
          ProductsSuccess(
            products: products.cast(),
            categories: categories.cast(),
            selectedCategory: state.selectedCategory,
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
          searchQuery: state.searchQuery,
        ),
      );
    } catch (e) {
      emit(
        ProductsFailure(
          errorMessage: 'Failed to load products: ${e.toString()}',
          selectedCategory: state.selectedCategory,
          searchQuery: state.searchQuery,
        ),
      );
    }
  }
}
