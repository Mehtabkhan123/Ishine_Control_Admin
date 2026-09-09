import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/delete_customer_model.dart';
import '../data/repositories/customers_repository.dart';
import 'delete_customer_state.dart';

/// Cubit managing permanent customer deletion:
/// `DELETE /wp-json/wc/v3/customers/{{customerId}}?force=true`
/// Features:
/// - Duplicate request prevention (tracks in-flight deleting customer IDs).
/// - Comprehensive error extraction (network, 401, 404, server error).
/// - Clean state emissions for Samsung One UI confirmation dialogs and snackbars.
class DeleteCustomerCubit extends Cubit<DeleteCustomerState> {
  final CustomersRepository repository;

  DeleteCustomerCubit({required this.repository})
    : super(const DeleteCustomerState());

  /// Deletes a customer permanently from WooCommerce (force = true).
  /// Rejects duplicate delete calls if the customer is already in-flight.
  Future<DeleteCustomerModel?> deleteCustomer(
    int customerId, {
    bool force = true,
  }) async {
    if (state.isCustomerDeleting(customerId)) {
      return null;
    }

    final updatedDeleting = Set<int>.from(state.deletingCustomerIds)
      ..add(customerId);
    emit(
      state.copyWith(
        status: DeleteCustomerStatus.deleting,
        deletingCustomerIds: updatedDeleting,
        clearError: true,
        clearDeletedCustomer: true,
      ),
    );

    try {
      final deleted = await repository.deleteCustomer(customerId, force: force);
      final finishDeleting = Set<int>.from(state.deletingCustomerIds)
        ..remove(customerId);

      emit(
        state.copyWith(
          status: DeleteCustomerStatus.success,
          deletedCustomer: deleted,
          deletedCustomerId: customerId,
          deletingCustomerIds: finishDeleting,
          clearError: true,
        ),
      );

      return deleted;
    } catch (e) {
      final finishDeleting = Set<int>.from(state.deletingCustomerIds)
        ..remove(customerId);
      final message = _extractErrorMessage(e);

      emit(
        state.copyWith(
          status: DeleteCustomerStatus.failure,
          errorMessage: message,
          deletingCustomerIds: finishDeleting,
        ),
      );

      return null;
    }
  }

  void reset() {
    emit(const DeleteCustomerState());
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
