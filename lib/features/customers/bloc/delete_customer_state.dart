import 'package:equatable/equatable.dart';
import '../data/models/delete_customer_model.dart';

enum DeleteCustomerStatus {
  initial,
  deleting,
  success,
  failure,
}

class DeleteCustomerState extends Equatable {
  final DeleteCustomerStatus status;
  final DeleteCustomerModel? deletedCustomer;
  final int? deletedCustomerId;
  final Set<int> deletingCustomerIds;
  final String? errorMessage;

  const DeleteCustomerState({
    this.status = DeleteCustomerStatus.initial,
    this.deletedCustomer,
    this.deletedCustomerId,
    this.deletingCustomerIds = const {},
    this.errorMessage,
  });

  bool get isDeleting => status == DeleteCustomerStatus.deleting;
  bool get isSuccess => status == DeleteCustomerStatus.success;
  bool get isFailure => status == DeleteCustomerStatus.failure;

  /// Whether a specific customer is currently in-flight being deleted
  bool isCustomerDeleting(int customerId) =>
      deletingCustomerIds.contains(customerId);

  DeleteCustomerState copyWith({
    DeleteCustomerStatus? status,
    DeleteCustomerModel? deletedCustomer,
    bool clearDeletedCustomer = false,
    int? deletedCustomerId,
    bool clearDeletedCustomerId = false,
    Set<int>? deletingCustomerIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeleteCustomerState(
      status: status ?? this.status,
      deletedCustomer:
          clearDeletedCustomer ? null : (deletedCustomer ?? this.deletedCustomer),
      deletedCustomerId: clearDeletedCustomerId
          ? null
          : (deletedCustomerId ?? this.deletedCustomerId),
      deletingCustomerIds: deletingCustomerIds ?? this.deletingCustomerIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        deletedCustomer,
        deletedCustomerId,
        deletingCustomerIds,
        errorMessage,
      ];
}
