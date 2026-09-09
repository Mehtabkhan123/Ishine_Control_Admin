import 'package:equatable/equatable.dart';
import '../data/models/put_update_coupon_model.dart';

enum UpdateCouponStatus {
  initial,
  submitting,
  success,
  failure,
}

class UpdateCouponState extends Equatable {
  final UpdateCouponStatus status;
  final PutUpdateCouponModel? updatedCoupon;
  final int? submittingCouponId;
  final String? errorMessage;

  const UpdateCouponState({
    this.status = UpdateCouponStatus.initial,
    this.updatedCoupon,
    this.submittingCouponId,
    this.errorMessage,
  });

  bool get isSubmitting => status == UpdateCouponStatus.submitting;
  bool get isSuccess => status == UpdateCouponStatus.success;
  bool get isFailure => status == UpdateCouponStatus.failure;

  UpdateCouponState copyWith({
    UpdateCouponStatus? status,
    PutUpdateCouponModel? updatedCoupon,
    bool clearUpdatedCoupon = false,
    int? submittingCouponId,
    bool clearSubmittingCouponId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UpdateCouponState(
      status: status ?? this.status,
      updatedCoupon:
          clearUpdatedCoupon ? null : (updatedCoupon ?? this.updatedCoupon),
      submittingCouponId: clearSubmittingCouponId
          ? null
          : (submittingCouponId ?? this.submittingCouponId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        updatedCoupon,
        submittingCouponId,
        errorMessage,
      ];
}
