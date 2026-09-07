import 'package:equatable/equatable.dart';
import '../data/models/post_create_model.dart';

abstract class ProductsState extends Equatable {
  final String selectedCategory;
  final String searchQuery;

  const ProductsState({
    this.selectedCategory = 'all',
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [selectedCategory, searchQuery];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial() : super();
}

class ProductsLoading extends ProductsState {
  final List<PostCreateModel>? previousProducts;

  const ProductsLoading({
    this.previousProducts,
    super.selectedCategory,
    super.searchQuery,
  });

  @override
  List<Object?> get props => [previousProducts, selectedCategory, searchQuery];
}

class ProductsSuccess extends ProductsState {
  final List<PostCreateModel> products;
  final List<ProductCategoryRef> categories;
  final DateTime lastUpdated;

  const ProductsSuccess({
    required this.products,
    this.categories = const [],
    super.selectedCategory = 'all',
    super.searchQuery = '',
    required this.lastUpdated,
  });

  List<PostCreateModel> get filteredProducts {
    return products.where((p) {
      if (selectedCategory != 'all') {
        final matchesCat = p.categories?.any(
              (c) =>
                  c.slug?.toLowerCase() == selectedCategory.toLowerCase() ||
                  c.name?.toLowerCase() == selectedCategory.toLowerCase(),
            ) ??
            false;
        if (!matchesCat) return false;
      }

      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final nameMatch = (p.name ?? '').toLowerCase().contains(query);
        final skuMatch = (p.sku ?? '').toLowerCase().contains(query);
        final descMatch = (p.shortDescription ?? '').toLowerCase().contains(query);
        final catMatch = p.categories?.any((c) => (c.name ?? '').toLowerCase().contains(query)) ?? false;
        if (!nameMatch && !skuMatch && !descMatch && !catMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int get totalCount => products.length;

  int get inStockCount => products.where((p) {
        if (p.manageStock == true) {
          return (p.stockQuantity ?? 0) > 0;
        }
        return p.stockStatus != 'outofstock';
      }).length;

  int get lowStockCount => products.where((p) {
        if (p.manageStock == true) {
          final qty = p.stockQuantity ?? 0;
          final threshold = p.lowStockAmount ?? 5;
          return qty > 0 && qty <= threshold;
        }
        return false;
      }).length;

  int get outOfStockCount => products.where((p) {
        if (p.manageStock == true) {
          return (p.stockQuantity ?? 0) <= 0;
        }
        return p.stockStatus == 'outofstock';
      }).length;

  ProductsSuccess copyWith({
    List<PostCreateModel>? products,
    List<ProductCategoryRef>? categories,
    String? selectedCategory,
    String? searchQuery,
    DateTime? lastUpdated,
  }) {
    return ProductsSuccess(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        products,
        categories,
        selectedCategory,
        searchQuery,
        lastUpdated,
      ];
}

class ProductsEmpty extends ProductsState {
  final List<ProductCategoryRef> categories;

  const ProductsEmpty({
    this.categories = const [],
    super.selectedCategory,
    super.searchQuery,
  });

  @override
  List<Object?> get props => [categories, selectedCategory, searchQuery];
}

class ProductsFailure extends ProductsState {
  final String errorMessage;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;

  const ProductsFailure({
    required this.errorMessage,
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
    super.selectedCategory,
    super.searchQuery,
  });

  @override
  List<Object?> get props => [
        errorMessage,
        statusCode,
        isTimeout,
        isNetworkError,
        selectedCategory,
        searchQuery,
      ];
}
