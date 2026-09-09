import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/delete_coupon_model.dart';
import '../data/repositories/coupons_repository.dart';
import 'delete_coupon_state.dart';

/// Cubit managing permanent coupon deletion:
/// `DELETE /wp-json/wc/v3/coupons/{{couponId}}?force=true`
/// Features:
/// - Duplicate request prevention (tracks in-flight deleting coupon IDs).
/// - Comprehensive error extraction (network, 401, 404, server error).
/// - Clean state emissions for Samsung One UI confirmation dialogs and snackbars.
class DeleteCouponCubit extends Cubit<DeleteCouponState> {
  final CouponsRepository repository;

  DeleteCouponCubit({required this.repository})
      : super(const DeleteCouponState());

  /// Deletes a coupon permanently from WooCommerce (force = true).
  /// Rejects duplicate delete calls if the coupon is already in-flight.
  Future<DeleteCouponModel?> deleteCoupon(
    int couponId, {
    bool force = true,
  }) async {
    if (state.isCouponDeleting(couponId)) {
      return null;
    }

    final updatedDeleting = Set<int>.from(state.deletingCouponIds)
      ..add(couponId);
    emit(
      state.copyWith(
        status: DeleteCouponStatus.deleting,
        deletingCouponIds: updatedDeleting,
        clearError: true,
        clearDeletedCoupon: true,
      ),
    );

    try {
      final deleted = await repository.deleteCoupon(couponId, force: force);
      final finishDeleting = Set<int>.from(state.deletingCouponIds)
        ..remove(couponId);

      emit(
        state.copyWith(
          status: DeleteCouponStatus.success,
          deletedCoupon: deleted,
          deletedCouponId: couponId,
          deletingCouponIds: finishDeleting,
          clearError: true,
        ),
      );

      return deleted;
    } catch (e) {
      final finishDeleting = Set<int>.from(state.deletingCouponIds)
        ..remove(couponId);
      final message = _extractErrorMessage(e);

      emit(
        state.copyWith(
          status: DeleteCouponStatus.failure,
          errorMessage: message,
          deletingCouponIds: finishDeleting,
        ),
      );

      return null;
    }
  }

  void reset() {
    emit(const DeleteCouponState());
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
