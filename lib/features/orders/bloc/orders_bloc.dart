import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_orders_model.dart';
import '../data/repositories/orders_repository.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository repository;

  OrdersBloc({required this.repository}) : super(const OrdersState()) {
    on<OrdersFetchStarted>(_onFetchStarted);
    on<OrdersLoadMore>(_onLoadMore);
    on<OrdersFilterChanged>(_onFilterChanged);
    on<OrdersSearchChanged>(_onSearchChanged);
    on<OrdersRefreshed>(_onRefreshed);
    on<OrdersOrderDeleted>(_onOrderDeleted);
  }

  Future<void> _onFetchStarted(
    OrdersFetchStarted event,
    Emitter<OrdersState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(
        status: OrdersStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        clearError: true,
      ));
    }

    try {
      final response = await repository.getOrders(
        page: 1,
        perPage: 20,
        orderby: 'date',
        order: 'desc',
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final hasReachedMax = response.orders.isEmpty ||
          response.orders.length < 20 ||
          1 >= response.totalPages;

      if (response.orders.isEmpty) {
        emit(state.copyWith(
          status: OrdersStatus.empty,
          orders: [],
          currentPage: 1,
          hasReachedMax: true,
          totalOrders: response.totalOrders,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: OrdersStatus.success,
          orders: response.orders,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalOrders: response.totalOrders,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onLoadMore(
    OrdersLoadMore event,
    Emitter<OrdersState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != OrdersStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final nextPage = state.currentPage + 1;

    try {
      final response = await repository.getOrders(
        page: nextPage,
        perPage: 20,
        orderby: 'date',
        order: 'desc',
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      // Prevent duplicate orders when loading additional pages
      final existingIds = state.orders.map((o) => o.id).whereType<int>().toSet();
      final newUniqueOrders = response.orders
          .where((o) => o.id == null || !existingIds.contains(o.id))
          .toList();

      final combined = List<GET_Orders_Model>.from(state.orders)
        ..addAll(newUniqueOrders);

      final hasReachedMax = response.orders.isEmpty ||
          response.orders.length < 20 ||
          nextPage >= response.totalPages;

      emit(state.copyWith(
        orders: combined,
        currentPage: nextPage,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
        totalOrders: response.totalOrders > 0 ? response.totalOrders : combined.length,
        totalPages: response.totalPages,
        clearError: true,
      ));
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onFilterChanged(
    OrdersFilterChanged event,
    Emitter<OrdersState> emit,
  ) async {
    if (event.status == state.selectedStatus) return;

    emit(state.copyWith(
      selectedStatus: event.status,
      status: OrdersStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getOrders(
        page: 1,
        perPage: 20,
        orderby: 'date',
        order: 'desc',
        status: event.status != 'all' ? event.status : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final hasReachedMax = response.orders.isEmpty ||
          response.orders.length < 20 ||
          1 >= response.totalPages;

      if (response.orders.isEmpty) {
        emit(state.copyWith(
          status: OrdersStatus.empty,
          orders: [],
          currentPage: 1,
          hasReachedMax: true,
          totalOrders: response.totalOrders,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: OrdersStatus.success,
          orders: response.orders,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalOrders: response.totalOrders,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onSearchChanged(
    OrdersSearchChanged event,
    Emitter<OrdersState> emit,
  ) async {
    final trimmedQuery = event.query.trim();
    if (trimmedQuery == state.searchQuery) return;

    emit(state.copyWith(
      searchQuery: trimmedQuery,
      status: OrdersStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getOrders(
        page: 1,
        perPage: 20,
        orderby: 'date',
        order: 'desc',
        status: state.selectedStatus != 'all' ? state.selectedStatus : null,
        search: trimmedQuery.isNotEmpty ? trimmedQuery : null,
      );

      final hasReachedMax = response.orders.isEmpty ||
          response.orders.length < 20 ||
          1 >= response.totalPages;

      if (response.orders.isEmpty) {
        emit(state.copyWith(
          status: OrdersStatus.empty,
          orders: [],
          currentPage: 1,
          hasReachedMax: true,
          totalOrders: response.totalOrders,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: OrdersStatus.success,
          orders: response.orders,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalOrders: response.totalOrders,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: OrdersStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onRefreshed(
    OrdersRefreshed event,
    Emitter<OrdersState> emit,
  ) async {
    add(const OrdersFetchStarted(isRefresh: true));
  }

  void _onOrderDeleted(
    OrdersOrderDeleted event,
    Emitter<OrdersState> emit,
  ) {
    final updatedList =
        state.orders.where((o) => o.id != event.orderId).toList();
    final updatedTotal = state.totalOrders > 0 ? state.totalOrders - 1 : 0;

    emit(state.copyWith(
      orders: updatedList,
      totalOrders: updatedTotal,
      status: updatedList.isEmpty && state.status == OrdersStatus.success
          ? OrdersStatus.empty
          : state.status,
    ));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
