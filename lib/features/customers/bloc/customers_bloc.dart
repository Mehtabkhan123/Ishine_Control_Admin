import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_customers_model.dart';
import '../data/repositories/customers_repository.dart';
import 'customers_event.dart';
import 'customers_state.dart';

class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final CustomersRepository repository;

  CustomersBloc({required this.repository}) : super(const CustomersState()) {
    on<CustomersFetchStarted>(_onFetchStarted);
    on<CustomersLoadMore>(_onLoadMore);
    on<CustomersRoleFilterChanged>(_onRoleFilterChanged);
    on<CustomersSearchChanged>(_onSearchChanged);
    on<CustomersRefreshed>(_onRefreshed);
    on<CustomersCustomerUpdated>(_onCustomerUpdated);
    on<CustomersCustomerDeleted>(_onCustomerDeleted);
  }

  Future<void> _onFetchStarted(
    CustomersFetchStarted event,
    Emitter<CustomersState> emit,
  ) async {
    // If not pull-to-refresh, display main loading state
    if (!event.isRefresh) {
      emit(state.copyWith(
        status: CustomersStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        clearError: true,
      ));
    }

    try {
      final response = await repository.getCustomers(
        page: 1,
        perPage: 20,
        orderby: 'registered_date',
        order: 'desc',
        role: state.selectedRole != 'all' ? state.selectedRole : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final hasReachedMax = response.customers.isEmpty ||
          response.customers.length < 20 ||
          1 >= response.totalPages;

      if (response.customers.isEmpty) {
        emit(state.copyWith(
          status: CustomersStatus.empty,
          customers: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: response.totalCustomers,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CustomersStatus.success,
          customers: response.customers,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalCustomers: response.totalCustomers,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: CustomersStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onLoadMore(
    CustomersLoadMore event,
    Emitter<CustomersState> emit,
  ) async {
    // Prevent duplicate API requests and unnecessary calls
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != CustomersStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final nextPage = state.currentPage + 1;

    try {
      final response = await repository.getCustomers(
        page: nextPage,
        perPage: 20,
        orderby: 'registered_date',
        order: 'desc',
        role: state.selectedRole != 'all' ? state.selectedRole : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      // Prevent duplicate customers when loading additional pages
      final existingIds =
          state.customers.map((c) => c.id).whereType<int>().toSet();
      final newUniqueCustomers = response.customers
          .where((c) => c.id == null || !existingIds.contains(c.id))
          .toList();

      final combined = List<GETCustomersModel>.from(state.customers)
        ..addAll(newUniqueCustomers);

      // Stop pagination when no more customers are available
      final hasReachedMax = response.customers.isEmpty ||
          response.customers.length < 20 ||
          nextPage >= response.totalPages;

      emit(state.copyWith(
        customers: combined,
        currentPage: nextPage,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
        totalCustomers: response.totalCustomers > 0
            ? response.totalCustomers
            : combined.length,
        totalPages: response.totalPages,
        clearError: true,
      ));
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onRoleFilterChanged(
    CustomersRoleFilterChanged event,
    Emitter<CustomersState> emit,
  ) async {
    if (event.role == state.selectedRole) return;

    emit(state.copyWith(
      selectedRole: event.role,
      status: CustomersStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getCustomers(
        page: 1,
        perPage: 20,
        orderby: 'registered_date',
        order: 'desc',
        role: event.role != 'all' ? event.role : null,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final hasReachedMax = response.customers.isEmpty ||
          response.customers.length < 20 ||
          1 >= response.totalPages;

      if (response.customers.isEmpty) {
        emit(state.copyWith(
          status: CustomersStatus.empty,
          customers: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: response.totalCustomers,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CustomersStatus.success,
          customers: response.customers,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalCustomers: response.totalCustomers,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: CustomersStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onSearchChanged(
    CustomersSearchChanged event,
    Emitter<CustomersState> emit,
  ) async {
    final trimmedQuery = event.query.trim();
    if (trimmedQuery == state.searchQuery) return;

    emit(state.copyWith(
      searchQuery: trimmedQuery,
      status: CustomersStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getCustomers(
        page: 1,
        perPage: 20,
        orderby: 'registered_date',
        order: 'desc',
        role: state.selectedRole != 'all' ? state.selectedRole : null,
        search: trimmedQuery.isNotEmpty ? trimmedQuery : null,
      );

      final hasReachedMax = response.customers.isEmpty ||
          response.customers.length < 20 ||
          1 >= response.totalPages;

      if (response.customers.isEmpty) {
        emit(state.copyWith(
          status: CustomersStatus.empty,
          customers: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCustomers: response.totalCustomers,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CustomersStatus.success,
          customers: response.customers,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalCustomers: response.totalCustomers,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: CustomersStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onRefreshed(
    CustomersRefreshed event,
    Emitter<CustomersState> emit,
  ) async {
    add(const CustomersFetchStarted(isRefresh: true));
  }

  void _onCustomerUpdated(
    CustomersCustomerUpdated event,
    Emitter<CustomersState> emit,
  ) {
    final updatedList = state.customers.map((c) {
      if (c.id == event.updatedCustomer.id) {
        return GETCustomersModel.fromJson(event.updatedCustomer.toJson());
      }
      return c;
    }).toList();

    emit(state.copyWith(customers: updatedList));
  }

  void _onCustomerDeleted(
    CustomersCustomerDeleted event,
    Emitter<CustomersState> emit,
  ) {
    final updatedList =
        state.customers.where((c) => c.id != event.customerId).toList();
    final updatedTotal =
        state.totalCustomers > 0 ? state.totalCustomers - 1 : 0;

    emit(state.copyWith(
      customers: updatedList,
      totalCustomers: updatedTotal,
      status: updatedList.isEmpty && state.status == CustomersStatus.success
          ? CustomersStatus.empty
          : state.status,
    ));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
