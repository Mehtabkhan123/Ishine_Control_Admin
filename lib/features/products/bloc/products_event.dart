import 'package:equatable/equatable.dart';
import '../data/models/post_create_model.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class ProductsFetchRequested extends ProductsEvent {
  final bool forceRefresh;

  const ProductsFetchRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class ProductsRefreshRequested extends ProductsEvent {
  const ProductsRefreshRequested();
}

class ProductsSearchChanged extends ProductsEvent {
  final String query;

  const ProductsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ProductsCategoryChanged extends ProductsEvent {
  final String category;

  const ProductsCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class ProductsCategoryAdded extends ProductsEvent {
  final ProductCategoryRef category;

  const ProductsCategoryAdded(this.category);

  @override
  List<Object?> get props => [category];
}

class ProductsCategoryUpdated extends ProductsEvent {
  final ProductCategoryRef category;

  const ProductsCategoryUpdated(this.category);

  @override
  List<Object?> get props => [category];
}

class ProductsCategoryDeleted extends ProductsEvent {
  final int categoryId;

  const ProductsCategoryDeleted(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class ProductsCategoriesRefreshRequested extends ProductsEvent {
  const ProductsCategoriesRefreshRequested();
}

