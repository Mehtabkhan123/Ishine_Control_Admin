import 'package:equatable/equatable.dart';

abstract class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to trigger initial loading or re-fetch of customers
class CustomersFetchStarted extends CustomersEvent {
  final bool isRefresh;

  const CustomersFetchStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Dispatched by infinite scrolling listener when user scrolls near the bottom
class CustomersLoadMore extends CustomersEvent {
  const CustomersLoadMore();
}

/// Dispatched when user changes customer role / segment filter
class CustomersRoleFilterChanged extends CustomersEvent {
  final String role;

  const CustomersRoleFilterChanged(this.role);

  @override
  List<Object?> get props => [role];
}

/// Dispatched when user enters or clears search query
class CustomersSearchChanged extends CustomersEvent {
  final String query;

  const CustomersSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched during pull-to-refresh to reset pagination and reload latest customers
class CustomersRefreshed extends CustomersEvent {
  const CustomersRefreshed();
}
