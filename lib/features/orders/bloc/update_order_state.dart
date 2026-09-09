import 'package:equatable/equatable.dart';
import '../data/models/put_update_order_model.dart';

enum UpdateOrderStatus {
  initial,
  submitting,
  success,
  failure,
}

class UpdateOrderState extends Equatable {
  final UpdateOrderStatus status;
  final PutUpdateOrderModel? updatedOrder;
  final String? errorMessage;
  final int? submittingOrderId;

  const UpdateOrderState({
    this.status = UpdateOrderStatus.initial,
    this.updatedOrder,
    this.errorMessage,
    this.submittingOrderId,
  });

  bool get isSubmitting => status == UpdateOrderStatus.submitting;
  bool get isSuccess => status == UpdateOrderStatus.success;
  bool get isFailure => status == UpdateOrderStatus.failure;

  UpdateOrderState copyWith({
    UpdateOrderStatus? status,
    PutUpdateOrderModel? updatedOrder,
    bool clearUpdatedOrder = false,
    String? errorMessage,
    bool clearError = false,
    int? submittingOrderId,
    bool clearSubmittingOrderId = false,
  }) {
    return UpdateOrderState(
      status: status ?? this.status,
      updatedOrder: clearUpdatedOrder ? null : (updatedOrder ?? this.updatedOrder),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submittingOrderId:
          clearSubmittingOrderId ? null : (submittingOrderId ?? this.submittingOrderId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        updatedOrder,
        errorMessage,
        submittingOrderId,
      ];
}
