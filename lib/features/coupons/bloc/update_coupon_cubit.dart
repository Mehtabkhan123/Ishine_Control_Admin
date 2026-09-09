import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/put_update_coupon_model.dart';
import '../data/repositories/coupons_repository.dart';
import 'update_coupon_state.dart';

/// Cubit managing coupon updates:
/// `PUT /wp-json/wc/v3/coupons/{{couponId}}`
///
/// Features:
/// - Duplicate request prevention (ignores if already submitting).
/// - Comprehensive error extraction (network, 401, 400 validation, server errors).
/// - State emission with [UpdateCouponStatus].
class UpdateCouponCubit extends Cubit<UpdateCouponState> {
  final CouponsRepository repository;

  UpdateCouponCubit({required this.repository})
      : super(const UpdateCouponState());

  /// Updates a coupon by dynamic [couponId].
  /// Prevents duplicate requests while a request is already in-flight.
  Future<PutUpdateCouponModel?> updateCoupon({
    required int couponId,
    required Map<String, dynamic> updateData,
  }) async {
    // 1. Guard against in-flight duplicate requests
    if (state.isSubmitting) {
      return null;
    }

    emit(state.copyWith(
      status: UpdateCouponStatus.submitting,
      submittingCouponId: couponId,
      clearError: true,
      clearUpdatedCoupon: true,
    ));

    try {
      final updated = await repository.updateCoupon(couponId, updateData);

      emit(state.copyWith(
        status: UpdateCouponStatus.success,
        updatedCoupon: updated,
        clearSubmittingCouponId: true,
        clearError: true,
      ));

      return updated;
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: UpdateCouponStatus.failure,
        errorMessage: message,
        clearSubmittingCouponId: true,
      ));
      return null;
    }
  }

  void reset() {
    emit(const UpdateCouponState());
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
