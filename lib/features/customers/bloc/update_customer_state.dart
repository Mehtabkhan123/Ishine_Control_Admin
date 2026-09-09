import 'package:equatable/equatable.dart';
import '../data/models/put_update_customer_model.dart';

enum UpdateCustomerStatus {
  initial,
  submitting,
  success,
  failure,
}

class UpdateCustomerState extends Equatable {
  final UpdateCustomerStatus status;
  final PutUpdateCustomerModel? updatedCustomer;
  final int? submittingCustomerId;
  final String? errorMessage;

  const UpdateCustomerState({
    this.status = UpdateCustomerStatus.initial,
    this.updatedCustomer,
    this.submittingCustomerId,
    this.errorMessage,
  });

  bool get isSubmitting => status == UpdateCustomerStatus.submitting;
  bool get isSuccess => status == UpdateCustomerStatus.success;
  bool get isFailure => status == UpdateCustomerStatus.failure;

  UpdateCustomerState copyWith({
    UpdateCustomerStatus? status,
    PutUpdateCustomerModel? updatedCustomer,
    bool clearUpdatedCustomer = false,
    int? submittingCustomerId,
    bool clearSubmittingCustomerId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UpdateCustomerState(
      status: status ?? this.status,
      updatedCustomer: clearUpdatedCustomer
          ? null
          : (updatedCustomer ?? this.updatedCustomer),
      submittingCustomerId: clearSubmittingCustomerId
          ? null
          : (submittingCustomerId ?? this.submittingCustomerId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        updatedCustomer,
        submittingCustomerId,
        errorMessage,
      ];
}
