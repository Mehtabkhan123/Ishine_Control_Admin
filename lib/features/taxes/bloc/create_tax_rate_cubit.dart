import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/post_tax_rates_model.dart';
import '../data/repositories/taxes_repository.dart';
import 'create_tax_rate_state.dart';

/// Cubit responsible for creating a new tax rate via WooCommerce REST API v3:
/// `POST /wp-json/wc/v3/taxes`
///
/// Features:
/// - Prevents duplicate submissions while request is in-flight.
/// - Validates and handles API, auth, network, and format errors.
/// - Emits structured states for Samsung One UI forms and feedback.
class CreateTaxRateCubit extends Cubit<CreateTaxRateState> {
  final TaxesRepository repository;

  CreateTaxRateCubit({required this.repository})
      : super(const CreateTaxRateState());

  /// Creates a new tax rate with the given [taxRate] payload.
  /// Prevents duplicate submissions if already in-flight.
  Future<PostTaxRatesModel?> createTaxRate(
    PostTaxRatesModel taxRate,
  ) async {
    if (state.isSubmitting) {
      return null;
    }

    emit(state.copyWith(
      status: CreateTaxRateStatus.submitting,
      clearError: true,
      clearCreatedTaxRate: true,
    ));

    try {
      final created = await repository.createTaxRate(taxRate);

      emit(state.copyWith(
        status: CreateTaxRateStatus.success,
        createdTaxRate: created,
        clearError: true,
      ));

      return created;
    } catch (e) {
      final message = _extractErrorMessage(e);

      emit(state.copyWith(
        status: CreateTaxRateStatus.failure,
        errorMessage: message,
      ));

      return null;
    }
  }

  void reset() {
    emit(const CreateTaxRateState());
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
