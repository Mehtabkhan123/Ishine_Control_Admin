import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_customers_model.dart';
import '../data/models/get_single_customers_model.dart';
import '../data/models/put_update_customer_model.dart';
import '../data/repositories/customers_repository.dart';
import 'single_customer_state.dart';

class SingleCustomerCubit extends Cubit<SingleCustomerState> {
  final CustomersRepository repository;

  SingleCustomerCubit({required this.repository})
      : super(const SingleCustomerState());

  /// Sets an already available customer item into state immediately to prevent jarring screen loads
  void setInitialCustomer(dynamic customer) {
    if (customer == null) return;
    GETSingleCustomersModel singleCustomer;

    if (customer is GETSingleCustomersModel) {
      singleCustomer = customer;
    } else if (customer is GETCustomersModel) {
      singleCustomer = GETSingleCustomersModel.fromCustomersModel(customer);
    } else {
      return;
    }

    final id = singleCustomer.id;
    if (id == null) return;

    final updatedCache =
        Map<int, GETSingleCustomersModel>.from(state.cachedCustomers)
          ..[id] = singleCustomer;

    emit(state.copyWith(
      status: SingleCustomerStatus.success,
      customer: singleCustomer,
      activeCustomerId: id,
      cachedCustomers: updatedCache,
      clearError: true,
    ));
  }

  /// Fetches single customer complete details from WooCommerce:
  /// `GET /wp-json/wc/v3/customers/{{customerId}}`
  ///
  /// Guarantees:
  /// - Prevents duplicate requests while the same customer is loading.
  /// - Keeps customer data available and cached while navigating.
  /// - Supports forceRefresh (e.g. pull-to-refresh or retry).
  Future<void> fetchSingleCustomer(
    int customerId, {
    bool forceRefresh = false,
  }) async {
    // 1. Prevent duplicate requests while the same customer is loading
    if (state.loadingCustomerIds.contains(customerId)) {
      return;
    }

    // 2. If cached and not forcing refresh, immediately display cached customer
    if (!forceRefresh && state.cachedCustomers.containsKey(customerId)) {
      final cached = state.cachedCustomers[customerId];
      if (cached != null) {
        emit(state.copyWith(
          status: SingleCustomerStatus.success,
          customer: cached,
          activeCustomerId: customerId,
          clearError: true,
        ));
        return;
      }
    }

    // 3. Begin loading
    final cachedForCustomer = state.cachedCustomers[customerId];
    final updatedLoading =
        Set<int>.from(state.loadingCustomerIds)..add(customerId);

    emit(state.copyWith(
      status: SingleCustomerStatus.loading,
      activeCustomerId: customerId,
      customer: cachedForCustomer,
      clearCustomer: cachedForCustomer == null,
      loadingCustomerIds: updatedLoading,
      clearError: true,
    ));

    try {
      final customer = await repository.getSingleCustomer(customerId);

      final finishLoading = Set<int>.from(state.loadingCustomerIds)
        ..remove(customerId);
      final updatedCache =
          Map<int, GETSingleCustomersModel>.from(state.cachedCustomers)
            ..[customerId] = customer;

      emit(state.copyWith(
        status: SingleCustomerStatus.success,
        customer: customer,
        activeCustomerId: customerId,
        cachedCustomers: updatedCache,
        loadingCustomerIds: finishLoading,
        clearError: true,
      ));
    } catch (e) {
      final finishLoading = Set<int>.from(state.loadingCustomerIds)
        ..remove(customerId);
      final message = _extractErrorMessage(e);

      emit(state.copyWith(
        status: SingleCustomerStatus.failure,
        errorMessage: message,
        loadingCustomerIds: finishLoading,
      ));
    }
  }

  void setActiveSection(int index) {
    if (index != state.activeSectionIndex) {
      emit(state.copyWith(activeSectionIndex: index));
    }
  }

  /// Updates the local cached and active customer representation with latest [PutUpdateCustomerModel]
  void customerUpdated(PutUpdateCustomerModel updatedCustomer) {
    final id = updatedCustomer.id;
    if (id == null) return;

    try {
      final newSingle =
          GETSingleCustomersModel.fromJson(updatedCustomer.toJson());
      final updatedCache =
          Map<int, GETSingleCustomersModel>.from(state.cachedCustomers)
            ..[id] = newSingle;

      emit(state.copyWith(
        customer: id == state.activeCustomerId ? newSingle : state.customer,
        cachedCustomers: updatedCache,
        clearError: true,
      ));
    } catch (_) {}
  }

  /// Clears customer from active state and cache when permanently deleted
  void customerDeleted(int customerId) {
    final updatedCache =
        Map<int, GETSingleCustomersModel>.from(state.cachedCustomers)
          ..remove(customerId);

    emit(state.copyWith(
      customer: state.activeCustomerId == customerId ? null : state.customer,
      clearCustomer: state.activeCustomerId == customerId,
      cachedCustomers: updatedCache,
      clearError: true,
    ));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
