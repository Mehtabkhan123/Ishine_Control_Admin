import 'package:equatable/equatable.dart';

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
