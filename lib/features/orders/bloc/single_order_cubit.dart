import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_single_order_model.dart';
import '../data/repositories/orders_repository.dart';
import 'single_order_state.dart';

class SingleOrderCubit extends Cubit<SingleOrderState> {
  final OrdersRepository repository;

  SingleOrderCubit({required this.repository})
      : super(const SingleOrderState());

  /// Fetches single order complete details from WooCommerce:
  /// `GET /wp-json/wc/v3/orders/{{orderId}}`
  ///
  /// Guarantees:
  /// - Deduplicates requests: ignores request if orderId is already in-flight.
  /// - Keeps order data cached so navigating sections never loses state.
  /// - Supports forceRefresh (e.g. pull-to-refresh or retry).
  Future<void> fetchSingleOrder(
    int orderId, {
    bool forceRefresh = false,
  }) async {
    // 1. Prevent duplicate requests while the same order is loading
    if (state.loadingOrderIds.contains(orderId)) {
      return;
    }

    // 2. If cached and not forcing refresh, immediately display cached order
    if (!forceRefresh && state.cachedOrders.containsKey(orderId)) {
      final cached = state.cachedOrders[orderId];
      if (cached != null) {
        emit(state.copyWith(
          status: SingleOrderStatus.success,
          order: cached,
          activeOrderId: orderId,
          clearError: true,
        ));
        return;
      }
    }

    // 3. Begin loading
    final cachedForOrder = state.cachedOrders[orderId];
    final updatedLoading = Set<int>.from(state.loadingOrderIds)..add(orderId);
    emit(state.copyWith(
      status: SingleOrderStatus.loading,
      activeOrderId: orderId,
      order: cachedForOrder,
      clearOrder: cachedForOrder == null,
      loadingOrderIds: updatedLoading,
      clearError: true,
    ));

    try {
      final order = await repository.getSingleOrder(orderId);

      final finishLoading = Set<int>.from(state.loadingOrderIds)
        ..remove(orderId);
      final updatedCache =
          Map<int, GetSingleOrderModel>.from(state.cachedOrders)
            ..[orderId] = order;

      if (order.id == null) {
        emit(state.copyWith(
          status: SingleOrderStatus.empty,
          order: null,
          loadingOrderIds: finishLoading,
          cachedOrders: updatedCache,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: SingleOrderStatus.success,
          order: order,
          loadingOrderIds: finishLoading,
          cachedOrders: updatedCache,
          clearError: true,
        ));
      }
    } catch (e) {
      final finishLoading = Set<int>.from(state.loadingOrderIds)
        ..remove(orderId);
      final message = _extractErrorMessage(e);

      emit(state.copyWith(
        status: SingleOrderStatus.failure,
        loadingOrderIds: finishLoading,
        errorMessage: message,
      ));
    }
  }

  /// Changes the active section tab (Overview, Items, Customer/Shipping, Payment/Taxes)
  /// without re-fetching or clearing existing order data.
  void changeSection(int index) {
    emit(state.copyWith(activeSectionIndex: index));
  }

  /// Refreshes the currently selected order if present
  Future<void> refreshCurrentOrder() async {
    if (state.activeOrderId != null) {
      await fetchSingleOrder(state.activeOrderId!, forceRefresh: true);
    }
  }

  /// Resets active order selection
  void clearSelectedOrder() {
    emit(state.copyWith(
      status: SingleOrderStatus.initial,
      clearOrder: true,
      clearActiveOrderId: true,
      clearError: true,
      activeSectionIndex: 0,
    ));
  }

  /// Removes deleted order from cache and resets if it is currently active.
  void orderDeleted(int orderId) {
    final updatedCache = Map<int, GetSingleOrderModel>.from(state.cachedOrders)
      ..remove(orderId);
    final isActive = state.activeOrderId == orderId;

    emit(state.copyWith(
      cachedOrders: updatedCache,
      clearOrder: isActive,
      clearActiveOrderId: isActive,
      status: isActive ? SingleOrderStatus.initial : state.status,
    ));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
