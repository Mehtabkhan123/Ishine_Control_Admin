import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/delete_order_model.dart';
import '../data/repositories/orders_repository.dart';
import 'delete_order_state.dart';

/// Cubit managing permanent order deletion:
/// `DELETE /wp-json/wc/v3/orders/{{orderId}}?force=true`
///
/// Features:
/// - Duplicate request prevention (tracks in-flight deleting order IDs).
/// - Comprehensive error extraction (including already deleted/not found 404).
/// - Clean state emissions for One UI confirmation dialogs and snackbars.
class DeleteOrderCubit extends Cubit<DeleteOrderState> {
  final OrdersRepository repository;

  DeleteOrderCubit({required this.repository}) : super(const DeleteOrderState());

  /// Deletes an order permanently from WooCommerce (force = true).
  /// Rejects duplicate delete calls if the order is already in-flight.
  Future<DeleteOrderModel?> deleteOrder(int orderId, {bool force = true}) async {
    if (state.isOrderDeleting(orderId)) {
      return null;
    }

    final updatedDeleting = Set<int>.from(state.deletingOrderIds)..add(orderId);
    emit(state.copyWith(
      status: DeleteOrderStatus.deleting,
      deletingOrderIds: updatedDeleting,
      clearError: true,
      clearDeletedOrder: true,
    ));

    try {
      final deleted = await repository.deleteOrder(orderId, force: force);
      final finishDeleting = Set<int>.from(state.deletingOrderIds)..remove(orderId);

      emit(state.copyWith(
        status: DeleteOrderStatus.success,
        deletedOrder: deleted,
        deletedOrderId: orderId,
        deletingOrderIds: finishDeleting,
        clearError: true,
      ));

      return deleted;
    } catch (e) {
      final finishDeleting = Set<int>.from(state.deletingOrderIds)..remove(orderId);
      final message = _extractErrorMessage(e);

      emit(state.copyWith(
        status: DeleteOrderStatus.failure,
        errorMessage: message,
        deletingOrderIds: finishDeleting,
      ));

      return null;
    }
  }

  void reset() {
    emit(const DeleteOrderState());
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
