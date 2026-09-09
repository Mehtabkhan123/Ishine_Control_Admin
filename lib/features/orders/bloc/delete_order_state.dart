import 'package:equatable/equatable.dart';
import '../data/models/delete_order_model.dart';

enum DeleteOrderStatus {
  initial,
  deleting,
  success,
  failure,
}

class DeleteOrderState extends Equatable {
  final DeleteOrderStatus status;
  final DeleteOrderModel? deletedOrder;
  final int? deletedOrderId;
  final Set<int> deletingOrderIds;
  final String? errorMessage;

  const DeleteOrderState({
    this.status = DeleteOrderStatus.initial,
    this.deletedOrder,
    this.deletedOrderId,
    this.deletingOrderIds = const {},
    this.errorMessage,
  });

  bool get isDeleting => status == DeleteOrderStatus.deleting;
  bool get isSuccess => status == DeleteOrderStatus.success;
  bool get isFailure => status == DeleteOrderStatus.failure;

  /// Whether a specific order is currently being deleted
  bool isOrderDeleting(int orderId) => deletingOrderIds.contains(orderId);

  DeleteOrderState copyWith({
    DeleteOrderStatus? status,
    DeleteOrderModel? deletedOrder,
    bool clearDeletedOrder = false,
    int? deletedOrderId,
    bool clearDeletedOrderId = false,
    Set<int>? deletingOrderIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeleteOrderState(
      status: status ?? this.status,
      deletedOrder: clearDeletedOrder ? null : (deletedOrder ?? this.deletedOrder),
      deletedOrderId:
          clearDeletedOrderId ? null : (deletedOrderId ?? this.deletedOrderId),
      deletingOrderIds: deletingOrderIds ?? this.deletingOrderIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        deletedOrder,
        deletedOrderId,
        deletingOrderIds,
        errorMessage,
      ];
}
