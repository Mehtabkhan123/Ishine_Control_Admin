import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/put_update_customer_model.dart';
import '../data/repositories/customers_repository.dart';
import 'update_customer_state.dart';

/// Cubit managing customer updates:
/// `PUT /wp-json/wc/v3/customers/{{customerId}}`
///
/// Features:
/// - Duplicate request prevention (ignores if already submitting).
/// - Comprehensive error extraction (network, 401, 404, 400 validation, server errors).
/// - State emission with [UpdateCustomerStatus].
class UpdateCustomerCubit extends Cubit<UpdateCustomerState> {
  final CustomersRepository repository;

  UpdateCustomerCubit({required this.repository})
      : super(const UpdateCustomerState());

  /// Updates a customer by ID.
  /// Prevents duplicate requests while a request is already in-flight.
  Future<PutUpdateCustomerModel?> updateCustomer({
    required int customerId,
    required Map<String, dynamic> updateData,
  }) async {
    // 1. Guard against in-flight duplicate requests
    if (state.isSubmitting) {
      return null;
    }

    emit(state.copyWith(
      status: UpdateCustomerStatus.submitting,
      submittingCustomerId: customerId,
      clearError: true,
      clearUpdatedCustomer: true,
    ));

    try {
      final updated = await repository.updateCustomer(customerId, updateData);

      emit(state.copyWith(
        status: UpdateCustomerStatus.success,
        updatedCustomer: updated,
        clearSubmittingCustomerId: true,
        clearError: true,
      ));

      return updated;
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: UpdateCustomerStatus.failure,
        errorMessage: message,
        clearSubmittingCustomerId: true,
      ));
      return null;
    }
  }

  void reset() {
    emit(const UpdateCustomerState());
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
