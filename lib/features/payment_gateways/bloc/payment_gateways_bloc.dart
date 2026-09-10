import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_payment_gateways_model.dart';
import '../data/models/put_update_payment_gateways_model.dart';
import '../data/repositories/payment_gateways_repository.dart';
import 'payment_gateways_event.dart';
import 'payment_gateways_state.dart';

class PaymentGatewaysBloc
    extends Bloc<PaymentGatewaysEvent, PaymentGatewaysState> {
  final PaymentGatewaysRepository repository;

  PaymentGatewaysBloc({required this.repository})
      : super(const PaymentGatewaysState()) {
    on<PaymentGatewaysFetchStarted>(_onFetchStarted);
    on<PaymentGatewaysRefreshed>(_onRefreshed);
    on<PaymentGatewaysRetryRequested>(_onRetryRequested);
    on<PaymentGatewaysSearchChanged>(_onSearchChanged);
    on<PaymentGatewaysFilterChanged>(_onFilterChanged);
    on<PaymentGatewayUpdated>(_onGatewayUpdated);
  }

  Future<void> _onFetchStarted(
    PaymentGatewaysFetchStarted event,
    Emitter<PaymentGatewaysState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(
        status: PaymentGatewaysStatus.loading,
        clearError: true,
      ));
    }

    try {
      final gateways = await repository.getPaymentGateways(
        forceRefresh: event.isRefresh,
      );

      final uniqueGateways = _deduplicateGateways(gateways);

      if (uniqueGateways.isEmpty) {
        emit(state.copyWith(
          status: PaymentGatewaysStatus.empty,
          gateways: [],
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: PaymentGatewaysStatus.success,
          gateways: uniqueGateways,
          clearError: true,
        ));
      }
    } catch (e) {
      final (message, statusCode) = _extractErrorInfo(e);
      emit(state.copyWith(
        status: PaymentGatewaysStatus.failure,
        errorMessage: message,
        errorStatusCode: statusCode,
      ));
    }
  }

  Future<void> _onRefreshed(
    PaymentGatewaysRefreshed event,
    Emitter<PaymentGatewaysState> emit,
  ) async {
    repository.clearCache();
    add(const PaymentGatewaysFetchStarted(isRefresh: true));
  }

  Future<void> _onRetryRequested(
    PaymentGatewaysRetryRequested event,
    Emitter<PaymentGatewaysState> emit,
  ) async {
    repository.clearCache();
    add(const PaymentGatewaysFetchStarted(isRefresh: true));
  }

  void _onSearchChanged(
    PaymentGatewaysSearchChanged event,
    Emitter<PaymentGatewaysState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onFilterChanged(
    PaymentGatewaysFilterChanged event,
    Emitter<PaymentGatewaysState> emit,
  ) {
    emit(state.copyWith(selectedFilter: event.filter));
  }

  void _onGatewayUpdated(
    PaymentGatewayUpdated event,
    Emitter<PaymentGatewaysState> emit,
  ) {
    GetPaymentGatewaysModel updatedModel;
    if (event.gateway is PutUpdatePaymentGatewaysModel) {
      updatedModel =
          (event.gateway as PutUpdatePaymentGatewaysModel).toGetPaymentGatewaysModel();
    } else if (event.gateway is GetPaymentGatewaysModel) {
      updatedModel = event.gateway as GetPaymentGatewaysModel;
    } else {
      return;
    }

    final list = List<GetPaymentGatewaysModel>.from(state.gateways);
    final index = list.indexWhere((g) => g.id == updatedModel.id);
    if (index != -1) {
      list[index] = updatedModel;
    } else {
      list.add(updatedModel);
    }

    emit(state.copyWith(
      gateways: list,
      status: list.isEmpty
          ? PaymentGatewaysStatus.empty
          : PaymentGatewaysStatus.success,
      clearError: true,
    ));
  }

  /// Removes any duplicate payment gateways with identical IDs
  List<GetPaymentGatewaysModel> _deduplicateGateways(
      List<GetPaymentGatewaysModel> raw) {
    final result = <GetPaymentGatewaysModel>[];
    final seen = <String>{};
    for (final gateway in raw) {
      final id = gateway.id;
      if (id != null) {
        if (!seen.contains(id)) {
          seen.add(id);
          result.add(gateway);
        }
      } else {
        result.add(gateway);
      }
    }
    return result;
  }

  /// Extracts user-friendly error message and status code
  (String, int?) _extractErrorInfo(dynamic error) {
    if (error is WooCommerceException) {
      return (error.message, error.statusCode);
    }
    if (error is DioException) {
      final wc = WooCommerceException.fromDioException(error);
      return (wc.message, wc.statusCode);
    }
    return (
      error.toString().replaceAll('Exception: ', '').trim(),
      null,
    );
  }
}
