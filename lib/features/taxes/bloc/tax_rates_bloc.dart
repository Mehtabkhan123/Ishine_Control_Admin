import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_tax_rates_model.dart';
import '../data/repositories/taxes_repository.dart';
import 'tax_rates_event.dart';
import 'tax_rates_state.dart';

class TaxRatesBloc extends Bloc<TaxRatesEvent, TaxRatesState> {
  final TaxesRepository repository;

  TaxRatesBloc({required this.repository}) : super(const TaxRatesState()) {
    on<TaxRatesFetchStarted>(_onFetchStarted);
    on<TaxRatesLoadMore>(_onLoadMore);
    on<TaxRatesRefreshed>(_onRefreshed);
    on<TaxRatesSearchChanged>(_onSearchChanged);
    on<TaxRatesClassFilterChanged>(_onClassFilterChanged);
    on<TaxRatesRetryRequested>(_onRetryRequested);
    on<TaxRatesRateCreated>(_onRateCreated);
  }

  Future<void> _onFetchStarted(
    TaxRatesFetchStarted event,
    Emitter<TaxRatesState> emit,
  ) async {
    // Prevent duplicate initial loads if already loading and not a refresh
    if (!event.isRefresh && state.status == TaxRatesStatus.loading) {
      return;
    }

    if (!event.isRefresh) {
      emit(state.copyWith(
        status: TaxRatesStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        clearError: true,
      ));
    }

    try {
      final response = await repository.getTaxRates(
        page: 1,
        perPage: 50,
        taxClass: state.selectedClass != 'all' ? state.selectedClass : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        forceRefresh: event.isRefresh,
      );

      // Deduplicate tax rates by ID
      final uniqueRates = _deduplicateRates(response.taxRates);

      final hasReachedMax = uniqueRates.isEmpty ||
          uniqueRates.length < 50 ||
          1 >= response.totalPages;

      if (uniqueRates.isEmpty) {
        emit(state.copyWith(
          status: TaxRatesStatus.empty,
          taxRates: [],
          currentPage: 1,
          hasReachedMax: true,
          totalTaxRates: response.totalTaxRates,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: TaxRatesStatus.success,
          taxRates: uniqueRates,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalTaxRates: response.totalTaxRates > 0
              ? response.totalTaxRates
              : uniqueRates.length,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final (message, statusCode) = _extractErrorInfo(e);
      emit(state.copyWith(
        status: TaxRatesStatus.failure,
        errorMessage: message,
        errorStatusCode: statusCode,
      ));
    }
  }

  Future<void> _onLoadMore(
    TaxRatesLoadMore event,
    Emitter<TaxRatesState> emit,
  ) async {
    // Prevent duplicate pagination requests
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != TaxRatesStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final nextPage = state.currentPage + 1;

    try {
      final response = await repository.getTaxRates(
        page: nextPage,
        perPage: 50,
        taxClass: state.selectedClass != 'all' ? state.selectedClass : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      // Prevent duplicate tax rates when appending next page
      final existingIds =
          state.taxRates.map((r) => r.id).whereType<int>().toSet();
      final newUniqueRates = response.taxRates
          .where((r) => r.id == null || !existingIds.contains(r.id))
          .toList();

      final combined = List<GetTaxRatesModel>.from(state.taxRates)
        ..addAll(newUniqueRates);

      final hasReachedMax = response.taxRates.isEmpty ||
          response.taxRates.length < 50 ||
          nextPage >= response.totalPages;

      emit(state.copyWith(
        taxRates: combined,
        currentPage: nextPage,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
        totalTaxRates: response.totalTaxRates > 0
            ? response.totalTaxRates
            : combined.length,
        totalPages: response.totalPages,
        clearError: true,
      ));
    } catch (e) {
      final (message, statusCode) = _extractErrorInfo(e);
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: message,
        errorStatusCode: statusCode,
      ));
    }
  }

  Future<void> _onRefreshed(
    TaxRatesRefreshed event,
    Emitter<TaxRatesState> emit,
  ) async {
    repository.clearCache();
    add(const TaxRatesFetchStarted(isRefresh: true));
  }

  Future<void> _onRetryRequested(
    TaxRatesRetryRequested event,
    Emitter<TaxRatesState> emit,
  ) async {
    repository.clearCache();
    add(const TaxRatesFetchStarted(isRefresh: true));
  }

  void _onSearchChanged(
    TaxRatesSearchChanged event,
    Emitter<TaxRatesState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onClassFilterChanged(
    TaxRatesClassFilterChanged event,
    Emitter<TaxRatesState> emit,
  ) async {
    if (event.taxClass == state.selectedClass) return;

    emit(state.copyWith(
      selectedClass: event.taxClass,
      status: TaxRatesStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getTaxRates(
        page: 1,
        perPage: 50,
        taxClass: event.taxClass != 'all' ? event.taxClass : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final uniqueRates = _deduplicateRates(response.taxRates);
      final hasReachedMax = uniqueRates.isEmpty ||
          uniqueRates.length < 50 ||
          1 >= response.totalPages;

      if (uniqueRates.isEmpty) {
        emit(state.copyWith(
          status: TaxRatesStatus.empty,
          taxRates: [],
          currentPage: 1,
          hasReachedMax: true,
          totalTaxRates: response.totalTaxRates,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: TaxRatesStatus.success,
          taxRates: uniqueRates,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalTaxRates: response.totalTaxRates > 0
              ? response.totalTaxRates
              : uniqueRates.length,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final (message, statusCode) = _extractErrorInfo(e);
      emit(state.copyWith(
        status: TaxRatesStatus.failure,
        errorMessage: message,
        errorStatusCode: statusCode,
      ));
    }
  }

  void _onRateCreated(
    TaxRatesRateCreated event,
    Emitter<TaxRatesState> emit,
  ) {
    GetTaxRatesModel model;
    if (event.taxRate is GetTaxRatesModel) {
      model = event.taxRate as GetTaxRatesModel;
    } else {
      model = GetTaxRatesModel.fromJson((event.taxRate as dynamic).toJson());
    }

    final existingIds =
        state.taxRates.map((r) => r.id).whereType<int>().toSet();
    if (model.id != null && existingIds.contains(model.id)) {
      return;
    }

    final updated = [model, ...state.taxRates];
    emit(state.copyWith(
      taxRates: updated,
      totalTaxRates:
          state.totalTaxRates > 0 ? state.totalTaxRates + 1 : updated.length,
      status: TaxRatesStatus.success,
    ));
  }

  /// Removes any duplicate rates by ID while preserving order
  List<GetTaxRatesModel> _deduplicateRates(List<GetTaxRatesModel> raw) {
    final result = <GetTaxRatesModel>[];
    final seen = <int>{};
    for (final rate in raw) {
      if (rate.id != null) {
        if (seen.add(rate.id!)) {
          result.add(rate);
        }
      } else {
        result.add(rate);
      }
    }
    return result;
  }

  (String, int?) _extractErrorInfo(dynamic e) {
    if (e is WooCommerceException) {
      return (e.message, e.statusCode);
    }
    return (e.toString(), null);
  }
}
