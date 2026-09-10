import 'package:equatable/equatable.dart';
import '../data/models/post_tax_rates_model.dart';

enum CreateTaxRateStatus {
  initial,
  submitting,
  success,
  failure,
}

class CreateTaxRateState extends Equatable {
  final CreateTaxRateStatus status;
  final PostTaxRatesModel? createdTaxRate;
  final String? errorMessage;

  const CreateTaxRateState({
    this.status = CreateTaxRateStatus.initial,
    this.createdTaxRate,
    this.errorMessage,
  });

  bool get isSubmitting => status == CreateTaxRateStatus.submitting;
  bool get isSuccess => status == CreateTaxRateStatus.success;
  bool get isFailure => status == CreateTaxRateStatus.failure;

  CreateTaxRateState copyWith({
    CreateTaxRateStatus? status,
    PostTaxRatesModel? createdTaxRate,
    bool clearCreatedTaxRate = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CreateTaxRateState(
      status: status ?? this.status,
      createdTaxRate: clearCreatedTaxRate
          ? null
          : (createdTaxRate ?? this.createdTaxRate),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        createdTaxRate,
        errorMessage,
      ];
}
