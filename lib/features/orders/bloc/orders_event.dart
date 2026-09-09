import 'package:equatable/equatable.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => [];
}

/// Initial fetch or refresh of the first page of orders.
class OrdersFetchStarted extends OrdersEvent {
  final bool isRefresh;

  const OrdersFetchStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Request to fetch the next page of orders (infinite scrolling).
class OrdersLoadMore extends OrdersEvent {
  const OrdersLoadMore();
}

/// Changes the active status filter (e.g. 'all', 'processing', 'completed', etc.).
class OrdersFilterChanged extends OrdersEvent {
  final String status;

  const OrdersFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Changes the search query string.
class OrdersSearchChanged extends OrdersEvent {
  final String query;

  const OrdersSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Pull-to-refresh event that reloads page 1.
class OrdersRefreshed extends OrdersEvent {
  const OrdersRefreshed();
}
