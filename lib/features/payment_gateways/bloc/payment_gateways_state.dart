import 'package:equatable/equatable.dart';
import '../data/models/get_payment_gateways_model.dart';

enum PaymentGatewaysStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class PaymentGatewaysState extends Equatable {
  final PaymentGatewaysStatus status;
  final List<GetPaymentGatewaysModel> gateways;
  final String searchQuery;
  final String selectedFilter; // 'all', 'enabled', 'disabled', 'needs_setup'
  final String? errorMessage;
  final int? errorStatusCode;

  const PaymentGatewaysState({
    this.status = PaymentGatewaysStatus.initial,
    this.gateways = const [],
    this.searchQuery = '',
    this.selectedFilter = 'all',
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get isLoading => status == PaymentGatewaysStatus.loading;
  bool get isSuccess => status == PaymentGatewaysStatus.success;
  bool get isEmpty => status == PaymentGatewaysStatus.empty;
  bool get isFailure => status == PaymentGatewaysStatus.failure;

  bool get isAuthError =>
      errorStatusCode == 401 || errorStatusCode == 403;

  bool get isNetworkError =>
      errorMessage != null &&
      (errorMessage!.contains('SocketException') ||
          errorMessage!.contains('timed out') ||
          errorMessage!.contains('Could not connect') ||
          errorMessage!.contains('network'));

  /// Returns filtered gateways matching current search and tab filter
  List<GetPaymentGatewaysModel> get displayGateways {
    var result = gateways;

    // Filter by status category
    if (selectedFilter == 'enabled') {
      result = result.where((g) => g.isEnabled).toList();
    } else if (selectedFilter == 'disabled') {
      result = result.where((g) => !g.isEnabled).toList();
    } else if (selectedFilter == 'needs_setup') {
      result = result.where((g) => g.requiresSetup).toList();
    }

    // Filter by search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      result = result.where((g) {
        final title = (g.title ?? '').toLowerCase();
        final desc = (g.description ?? '').toLowerCase();
        final method = (g.methodTitle ?? '').toLowerCase();
        final id = (g.id ?? '').toLowerCase();
        return title.contains(q) ||
            desc.contains(q) ||
            method.contains(q) ||
            id.contains(q);
      }).toList();
    }

    return result;
  }

  int get totalCount => gateways.length;
  int get enabledCount => gateways.where((g) => g.isEnabled).length;
  int get disabledCount => gateways.where((g) => !g.isEnabled).length;
  int get needsSetupCount => gateways.where((g) => g.requiresSetup).length;

  PaymentGatewaysState copyWith({
    PaymentGatewaysStatus? status,
    List<GetPaymentGatewaysModel>? gateways,
    String? searchQuery,
    String? selectedFilter,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
  }) {
    return PaymentGatewaysState(
      status: status ?? this.status,
      gateways: gateways ?? this.gateways,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorStatusCode:
          clearError ? null : (errorStatusCode ?? this.errorStatusCode),
    );
  }

  @override
  List<Object?> get props => [
        status,
        gateways,
        searchQuery,
        selectedFilter,
        errorMessage,
        errorStatusCode,
      ];
}
