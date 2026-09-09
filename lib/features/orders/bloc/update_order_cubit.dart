import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/put_update_order_model.dart';
import '../data/repositories/orders_repository.dart';
import 'update_order_state.dart';

/// Cubit managing order updates:
/// `PUT /wp-json/wc/v3/orders/{{orderId}}`
///
/// Features:
/// - Duplicate request prevention (ignores if already submitting).
/// - Comprehensive error extraction (network, 401, 404, server error).
/// - State emission with [UpdateOrderStatus].
class UpdateOrderCubit extends Cubit<UpdateOrderState> {
  final OrdersRepository repository;

  UpdateOrderCubit({required this.repository}) : super(const UpdateOrderState());

  /// Updates an order by ID.
  /// Prevents duplicate requests while a request is already in-flight.
  Future<PutUpdateOrderModel?> updateOrder({
    required int orderId,
    required Map<String, dynamic> updateData,
  }) async {
    // 1. Guard against in-flight duplicate requests
    if (state.isSubmitting) {
      return null;
    }

    emit(state.copyWith(
      status: UpdateOrderStatus.submitting,
      submittingOrderId: orderId,
      clearError: true,
      clearUpdatedOrder: true,
    ));

    try {
      final updated = await repository.updateOrder(orderId, updateData);

      emit(state.copyWith(
        status: UpdateOrderStatus.success,
        updatedOrder: updated,
        clearSubmittingOrderId: true,
        clearError: true,
      ));

      return updated;
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: UpdateOrderStatus.failure,
        errorMessage: message,
        clearSubmittingOrderId: true,
      ));
      return null;
    }
  }

  void reset() {
    emit(const UpdateOrderState());
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
