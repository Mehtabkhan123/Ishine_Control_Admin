import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/post_create_coupon_model.dart';
import '../data/repositories/coupons_repository.dart';
import 'create_coupon_state.dart';

/// Cubit responsible for creating a new coupon via WooCommerce REST API v3:
/// `POST /wp-json/wc/v3/coupons`
///
/// Features:
/// - Prevents duplicate submissions while request is in-flight.
/// - Validates and handles API, auth, network, and format errors.
/// - Emits structured states for Samsung One UI forms and feedback.
class CreateCouponCubit extends Cubit<CreateCouponState> {
  final CouponsRepository repository;

  CreateCouponCubit({required this.repository})
      : super(const CreateCouponState());

  /// Creates a new coupon with the given writable fields [couponData].
  /// Prevents duplicate submissions if already in-flight.
  Future<PostCreateCouponModel?> createCoupon(
    Map<String, dynamic> couponData,
  ) async {
    if (state.isSubmitting) {
      return null;
    }

    emit(state.copyWith(
      status: CreateCouponStatus.submitting,
      clearError: true,
      clearCreatedCoupon: true,
    ));

    try {
      final created = await repository.createCoupon(couponData);

      emit(state.copyWith(
        status: CreateCouponStatus.success,
        createdCoupon: created,
        clearError: true,
      ));

      return created;
    } catch (e) {
      final message = _extractErrorMessage(e);

      emit(state.copyWith(
        status: CreateCouponStatus.failure,
        errorMessage: message,
      ));

      return null;
    }
  }

  void reset() {
    emit(const CreateCouponState());
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
