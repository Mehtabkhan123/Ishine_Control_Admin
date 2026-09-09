import 'package:equatable/equatable.dart';
import '../data/models/post_create_coupon_model.dart';

enum CreateCouponStatus {
  initial,
  submitting,
  success,
  failure,
}

class CreateCouponState extends Equatable {
  final CreateCouponStatus status;
  final PostCreateCouponModel? createdCoupon;
  final String? errorMessage;

  const CreateCouponState({
    this.status = CreateCouponStatus.initial,
    this.createdCoupon,
    this.errorMessage,
  });

  bool get isSubmitting => status == CreateCouponStatus.submitting;
  bool get isSuccess => status == CreateCouponStatus.success;
  bool get isFailure => status == CreateCouponStatus.failure;

  CreateCouponState copyWith({
    CreateCouponStatus? status,
    PostCreateCouponModel? createdCoupon,
    bool clearCreatedCoupon = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateCouponState(
      status: status ?? this.status,
      createdCoupon: clearCreatedCoupon
          ? null
          : (createdCoupon ?? this.createdCoupon),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        createdCoupon,
        errorMessage,
      ];
}
