import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/put_update_payment_gateways_model.dart';
import '../data/repositories/payment_gateways_repository.dart';
import 'update_payment_gateway_state.dart';

/// Cubit responsible for updating a payment gateway via WooCommerce REST API v3:
/// `PUT /wp-json/wc/v3/payment_gateways/{{paymentGatewayId}}`
///
/// Features:
/// - Duplicate submission prevention (guards while already submitting).
/// - Comprehensive error extraction (401 auth, 400 validation, timeouts, network).
/// - Dedicated toggle shortcut for quick enable/disable operations.
/// - Never logs WooCommerce credentials, consumer keys or secrets.
class UpdatePaymentGatewayCubit extends Cubit<UpdatePaymentGatewayState> {
  final PaymentGatewaysRepository repository;

  UpdatePaymentGatewayCubit({required this.repository})
      : super(const UpdatePaymentGatewayState());

  /// Updates a payment gateway by dynamic [gatewayId] with [updateData].
  /// Prevents duplicate requests while already in-flight.
  Future<PutUpdatePaymentGatewaysModel?> updatePaymentGateway({
    required String gatewayId,
    required Map<String, dynamic> updateData,
  }) async {
    // 1. Guard against duplicate concurrent requests
    if (state.isSubmitting) {
      return null;
    }

    emit(state.copyWith(
      status: UpdatePaymentGatewayStatus.submitting,
      submittingGatewayId: gatewayId,
      clearError: true,
      clearUpdatedGateway: true,
    ));

    try {
      final updated = await repository.updatePaymentGateway(
        id: gatewayId,
        data: updateData,
      );

      emit(state.copyWith(
        status: UpdatePaymentGatewayStatus.success,
        updatedGateway: updated,
        clearSubmittingGatewayId: true,
        clearError: true,
      ));

      return updated;
    } catch (e) {
      final (message, statusCode) = _extractErrorInfo(e);

      emit(state.copyWith(
        status: UpdatePaymentGatewayStatus.failure,
        errorMessage: message,
        errorStatusCode: statusCode,
        clearSubmittingGatewayId: true,
      ));

      return null;
    }
  }

  /// Convenience method to quickly toggle gateway enabled status
  Future<PutUpdatePaymentGatewaysModel?> toggleGatewayEnabled({
    required String gatewayId,
    required bool enabled,
  }) async {
    return updatePaymentGateway(
      gatewayId: gatewayId,
      updateData: {'enabled': enabled},
    );
  }

  void reset() {
    emit(const UpdatePaymentGatewayState());
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  (String, int?) _extractErrorInfo(dynamic error) {
    if (error is WooCommerceException) {
      return (error.message, error.statusCode);
    }
    if (error is DioException) {
      final wc = WooCommerceException.fromDioException(error);
      return (wc.message, wc.statusCode);
    }
    return (
      error.toString().replaceAll('Exception: ', '').trim(),
      null,
    );
  }
}
