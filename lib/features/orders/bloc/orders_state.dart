import 'package:equatable/equatable.dart';
import '../data/models/get_orders_model.dart';

enum OrdersStatus { initial, loading, success, empty, failure }

class OrdersState extends Equatable {
  final OrdersStatus status;
  final List<GET_Orders_Model> orders;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? errorMessage;
  final String selectedStatus;
  final String searchQuery;
  final int totalOrders;
  final int totalPages;
  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.selectedStatus = 'all',
    this.searchQuery = '',
    this.totalOrders = 0,
    this.totalPages = 1,
  });

  bool get isLoading => status == OrdersStatus.loading;
  bool get isSuccess => status == OrdersStatus.success;
  bool get isFailure => status == OrdersStatus.failure;
  bool get isEmpty =>
      status == OrdersStatus.empty ||
      (status == OrdersStatus.success && orders.isEmpty);

  // Dynamic KPI counts computed from loaded orders
  int get processingCount => orders
      .where((o) => (o.status ?? '').toLowerCase() == 'processing')
      .length;

  int get completedCount =>
      orders.where((o) => (o.status ?? '').toLowerCase() == 'completed').length;

  int get onHoldCount =>
      orders.where((o) => (o.status ?? '').toLowerCase() == 'on-hold').length;

  int get pendingCount =>
      orders.where((o) => (o.status ?? '').toLowerCase() == 'pending').length;

  int get cancelledCount => orders
      .where(
        (o) =>
            (o.status ?? '').toLowerCase() == 'cancelled' ||
            (o.status ?? '').toLowerCase() == 'failed' ||
            (o.status ?? '').toLowerCase() == 'refunded',
      )
      .length;

  OrdersState copyWith({
    OrdersStatus? status,
    List<GET_Orders_Model>? orders,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    String? selectedStatus,
    String? searchQuery,
    int? totalOrders,
    int? totalPages,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      totalOrders: totalOrders ?? this.totalOrders,
      totalPages: totalPages ?? this.totalPages,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    currentPage,
    hasReachedMax,
    isLoadingMore,
    errorMessage,
    selectedStatus,
    searchQuery,
    totalOrders,
    totalPages,
  ];
}
