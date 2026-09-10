import 'package:equatable/equatable.dart';
import '../data/models/get_tax_rates_model.dart';

enum TaxRatesStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class TaxRatesState extends Equatable {
  final TaxRatesStatus status;
  final List<GetTaxRatesModel> taxRates;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final int totalTaxRates;
  final int totalPages;
  final String searchQuery;
  final String selectedClass;
  final String? errorMessage;
  final int? errorStatusCode;

  const TaxRatesState({
    this.status = TaxRatesStatus.initial,
    this.taxRates = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.totalTaxRates = 0,
    this.totalPages = 1,
    this.searchQuery = '',
    this.selectedClass = 'all',
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get isLoading => status == TaxRatesStatus.loading;
  bool get isSuccess => status == TaxRatesStatus.success;
  bool get isEmpty => status == TaxRatesStatus.empty;
  bool get isFailure => status == TaxRatesStatus.failure;

  /// Returns tax rates filtered by current search query and class selection
  List<GetTaxRatesModel> get displayRates {
    return taxRates.where((rate) {
      // 1. Class filter
      if (selectedClass != 'all') {
        final rateClass = (rate.taxClass == null || rate.taxClass!.isEmpty)
            ? 'standard'
            : rate.taxClass!.toLowerCase();
        if (rateClass != selectedClass.toLowerCase()) {
          return false;
        }
      }

      // 2. Search query filter
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final nameMatch = (rate.name ?? '').toLowerCase().contains(q);
        final idMatch = (rate.id?.toString() ?? '').contains(q);
        final countryMatch = (rate.country ?? '').toLowerCase().contains(q);
        final stateMatch = (rate.state ?? '').toLowerCase().contains(q);
        final cityMatch = (rate.city ?? '').toLowerCase().contains(q);
        final rateMatch = (rate.rate ?? '').contains(q);
        return nameMatch || idMatch || countryMatch || stateMatch || cityMatch || rateMatch;
      }

      return true;
    }).toList();
  }

  /// Count of compound tax rates in the current dataset
  int get compoundRatesCount =>
      taxRates.where((r) => r.compound == true).length;

  /// Count of tax rates that apply to shipping
  int get shippingRatesCount =>
      taxRates.where((r) => r.shipping == true).length;

  /// Count of standard tax rates
  int get standardRatesCount => taxRates.where((r) {
        final c = r.taxClass?.toLowerCase();
        return c == null || c.isEmpty || c == 'standard';
      }).length;

  /// Whether current failure is authentication-related (401 / 403)
  bool get isAuthError =>
      errorStatusCode == 401 ||
      errorStatusCode == 403 ||
      (errorMessage != null &&
          (errorMessage!.toLowerCase().contains('authenticat') ||
              errorMessage!.toLowerCase().contains('consumer key') ||
              errorMessage!.toLowerCase().contains('forbidden')));

  /// Whether current failure is network/connectivity-related
  bool get isNetworkError =>
      errorStatusCode == 408 ||
      (errorMessage != null &&
          (errorMessage!.toLowerCase().contains('connect') ||
              errorMessage!.toLowerCase().contains('timeout') ||
              errorMessage!.toLowerCase().contains('socket') ||
              errorMessage!.toLowerCase().contains('network')));

  TaxRatesState copyWith({
    TaxRatesStatus? status,
    List<GetTaxRatesModel>? taxRates,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? totalTaxRates,
    int? totalPages,
    String? searchQuery,
    String? selectedClass,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
  }) {
    return TaxRatesState(
      status: status ?? this.status,
      taxRates: taxRates ?? this.taxRates,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalTaxRates: totalTaxRates ?? this.totalTaxRates,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedClass: selectedClass ?? this.selectedClass,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorStatusCode:
          clearError ? null : (errorStatusCode ?? this.errorStatusCode),
    );
  }

  @override
  List<Object?> get props => [
        status,
        taxRates,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        totalTaxRates,
        totalPages,
        searchQuery,
        selectedClass,
        errorMessage,
        errorStatusCode,
      ];
}
