import 'package:equatable/equatable.dart';
import '../data/models/put_update_payment_gateways_model.dart';

enum UpdatePaymentGatewayStatus {
  initial,
  submitting,
  success,
  failure,
}

class UpdatePaymentGatewayState extends Equatable {
  final UpdatePaymentGatewayStatus status;
  final PutUpdatePaymentGatewaysModel? updatedGateway;
  final String? submittingGatewayId;
  final String? errorMessage;
  final int? errorStatusCode;

  const UpdatePaymentGatewayState({
    this.status = UpdatePaymentGatewayStatus.initial,
    this.updatedGateway,
    this.submittingGatewayId,
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get isSubmitting => status == UpdatePaymentGatewayStatus.submitting;
  bool get isSuccess => status == UpdatePaymentGatewayStatus.success;
  bool get isFailure => status == UpdatePaymentGatewayStatus.failure;

  UpdatePaymentGatewayState copyWith({
    UpdatePaymentGatewayStatus? status,
    PutUpdatePaymentGatewaysModel? updatedGateway,
    bool clearUpdatedGateway = false,
    String? submittingGatewayId,
    bool clearSubmittingGatewayId = false,
    String? errorMessage,
    bool clearError = false,
    int? errorStatusCode,
  }) {
    return UpdatePaymentGatewayState(
      status: status ?? this.status,
      updatedGateway: clearUpdatedGateway
          ? null
          : (updatedGateway ?? this.updatedGateway),
      submittingGatewayId: clearSubmittingGatewayId
          ? null
          : (submittingGatewayId ?? this.submittingGatewayId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorStatusCode:
          clearError ? null : (errorStatusCode ?? this.errorStatusCode),
    );
  }

  @override
  List<Object?> get props => [
        status,
        updatedGateway,
        submittingGatewayId,
        errorMessage,
        errorStatusCode,
      ];
}
