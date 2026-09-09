import 'package:equatable/equatable.dart';
import '../data/models/delete_coupon_model.dart';

enum DeleteCouponStatus {
  initial,
  deleting,
  success,
  failure,
}

class DeleteCouponState extends Equatable {
  final DeleteCouponStatus status;
  final DeleteCouponModel? deletedCoupon;
  final int? deletedCouponId;
  final Set<int> deletingCouponIds;
  final String? errorMessage;

  const DeleteCouponState({
    this.status = DeleteCouponStatus.initial,
    this.deletedCoupon,
    this.deletedCouponId,
    this.deletingCouponIds = const {},
    this.errorMessage,
  });

  bool get isDeleting => status == DeleteCouponStatus.deleting;
  bool get isSuccess => status == DeleteCouponStatus.success;
  bool get isFailure => status == DeleteCouponStatus.failure;

  /// Whether a specific coupon is currently in-flight being deleted
  bool isCouponDeleting(int couponId) => deletingCouponIds.contains(couponId);

  DeleteCouponState copyWith({
    DeleteCouponStatus? status,
    DeleteCouponModel? deletedCoupon,
    bool clearDeletedCoupon = false,
    int? deletedCouponId,
    bool clearDeletedCouponId = false,
    Set<int>? deletingCouponIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeleteCouponState(
      status: status ?? this.status,
      deletedCoupon:
          clearDeletedCoupon ? null : (deletedCoupon ?? this.deletedCoupon),
      deletedCouponId: clearDeletedCouponId
          ? null
          : (deletedCouponId ?? this.deletedCouponId),
      deletingCouponIds: deletingCouponIds ?? this.deletingCouponIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        deletedCoupon,
        deletedCouponId,
        deletingCouponIds,
        errorMessage,
      ];
}
