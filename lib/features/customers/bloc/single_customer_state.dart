import 'package:equatable/equatable.dart';
import '../data/models/get_single_customers_model.dart';

enum SingleCustomerStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class SingleCustomerState extends Equatable {
  final SingleCustomerStatus status;
  final GETSingleCustomersModel? customer;
  final int? activeCustomerId;
  final Map<int, GETSingleCustomersModel> cachedCustomers;
  final Set<int> loadingCustomerIds;
  final String? errorMessage;
  final int activeSectionIndex;

  const SingleCustomerState({
    this.status = SingleCustomerStatus.initial,
    this.customer,
    this.activeCustomerId,
    this.cachedCustomers = const {},
    this.loadingCustomerIds = const {},
    this.errorMessage,
    this.activeSectionIndex = 0,
  });

  bool get isLoading => status == SingleCustomerStatus.loading;
  bool get isSuccess => status == SingleCustomerStatus.success;
  bool get isEmpty =>
      status == SingleCustomerStatus.empty ||
      (status == SingleCustomerStatus.success && customer == null);
  bool get isFailure => status == SingleCustomerStatus.failure;

  bool isCustomerLoading(int customerId) =>
      loadingCustomerIds.contains(customerId);

  SingleCustomerState copyWith({
    SingleCustomerStatus? status,
    GETSingleCustomersModel? customer,
    bool clearCustomer = false,
    int? activeCustomerId,
    bool clearActiveCustomerId = false,
    Map<int, GETSingleCustomersModel>? cachedCustomers,
    Set<int>? loadingCustomerIds,
    String? errorMessage,
    bool clearError = false,
    int? activeSectionIndex,
  }) {
    return SingleCustomerState(
      status: status ?? this.status,
      customer: clearCustomer ? null : (customer ?? this.customer),
      activeCustomerId: clearActiveCustomerId
          ? null
          : (activeCustomerId ?? this.activeCustomerId),
      cachedCustomers: cachedCustomers ?? this.cachedCustomers,
      loadingCustomerIds: loadingCustomerIds ?? this.loadingCustomerIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeSectionIndex: activeSectionIndex ?? this.activeSectionIndex,
    );
  }

  @override
  List<Object?> get props => [
        status,
        customer,
        activeCustomerId,
        cachedCustomers,
        loadingCustomerIds,
        errorMessage,
        activeSectionIndex,
      ];
}
