import 'package:equatable/equatable.dart';
import '../data/models/get_customers_model.dart';

enum CustomersStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class CustomersState extends Equatable {
  final CustomersStatus status;
  final List<GETCustomersModel> customers;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final int totalCustomers;
  final int totalPages;
  final String selectedRole;
  final String searchQuery;
  final String? errorMessage;

  const CustomersState({
    this.status = CustomersStatus.initial,
    this.customers = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.totalCustomers = 0,
    this.totalPages = 1,
    this.selectedRole = 'all',
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == CustomersStatus.loading;
  bool get isSuccess => status == CustomersStatus.success;
  bool get isEmpty => status == CustomersStatus.empty;
  bool get isFailure => status == CustomersStatus.failure;

  /// Count of paying customers in loaded list
  int get payingCustomersCount =>
      customers.where((c) => c.isPayingCustomer == true).length;

  /// Count of non-paying customers in loaded list
  int get nonPayingCustomersCount =>
      customers.where((c) => c.isPayingCustomer != true).length;

  CustomersState copyWith({
    CustomersStatus? status,
    List<GETCustomersModel>? customers,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? totalCustomers,
    int? totalPages,
    String? selectedRole,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalPages: totalPages ?? this.totalPages,
      selectedRole: selectedRole ?? this.selectedRole,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        customers,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        totalCustomers,
        totalPages,
        selectedRole,
        searchQuery,
        errorMessage,
      ];
}
