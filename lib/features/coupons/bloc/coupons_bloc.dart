import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/get_coupon_report_model.dart';
import '../data/repositories/coupons_repository.dart';
import 'coupons_event.dart';
import 'coupons_state.dart';

class CouponsBloc extends Bloc<CouponsEvent, CouponsState> {
  final CouponsRepository repository;

  CouponsBloc({required this.repository}) : super(const CouponsState()) {
    on<CouponsFetchStarted>(_onFetchStarted);
    on<CouponsLoadMore>(_onLoadMore);
    on<CouponsSearchChanged>(_onSearchChanged);
    on<CouponsTypeFilterChanged>(_onTypeFilterChanged);
    on<CouponsRefreshed>(_onRefreshed);
  }

  Future<void> _onFetchStarted(
    CouponsFetchStarted event,
    Emitter<CouponsState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(
        status: CouponsStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        clearError: true,
      ));
    }

    try {
      final response = await repository.getCoupons(
        page: 1,
        perPage: 50,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        discountType: state.selectedType != 'all' ? state.selectedType : null,
      );

      final hasReachedMax = response.coupons.isEmpty ||
          response.coupons.length < 50 ||
          1 >= response.totalPages;

      if (response.coupons.isEmpty) {
        emit(state.copyWith(
          status: CouponsStatus.empty,
          coupons: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCoupons: response.totalCoupons,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CouponsStatus.success,
          coupons: response.coupons,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalCoupons: response.totalCoupons,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: CouponsStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onLoadMore(
    CouponsLoadMore event,
    Emitter<CouponsState> emit,
  ) async {
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != CouponsStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final nextPage = state.currentPage + 1;

    try {
      final response = await repository.getCoupons(
        page: nextPage,
        perPage: 50,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        discountType: state.selectedType != 'all' ? state.selectedType : null,
      );

      // Prevent duplicate coupons when loading additional pages
      final existingIds =
          state.coupons.map((c) => c.id).whereType<int>().toSet();
      final newUniqueCoupons = response.coupons
          .where((c) => c.id == null || !existingIds.contains(c.id))
          .toList();

      final combined = List<GETCouponReportModel>.from(state.coupons)
        ..addAll(newUniqueCoupons);

      // Stop pagination when no more coupons are available
      final hasReachedMax = response.coupons.isEmpty ||
          response.coupons.length < 50 ||
          nextPage >= response.totalPages;

      emit(state.copyWith(
        coupons: combined,
        currentPage: nextPage,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
        totalCoupons: response.totalCoupons > 0
            ? response.totalCoupons
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

  Future<void> _onSearchChanged(
    CouponsSearchChanged event,
    Emitter<CouponsState> emit,
  ) async {
    final trimmedQuery = event.query.trim();
    if (trimmedQuery == state.searchQuery) return;

    emit(state.copyWith(
      searchQuery: trimmedQuery,
      status: CouponsStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getCoupons(
        page: 1,
        perPage: 50,
        search: trimmedQuery.isNotEmpty ? trimmedQuery : null,
        discountType: state.selectedType != 'all' ? state.selectedType : null,
      );

      final hasReachedMax = response.coupons.isEmpty ||
          response.coupons.length < 50 ||
          1 >= response.totalPages;

      if (response.coupons.isEmpty) {
        emit(state.copyWith(
          status: CouponsStatus.empty,
          coupons: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCoupons: response.totalCoupons,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CouponsStatus.success,
          coupons: response.coupons,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalCoupons: response.totalCoupons,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: CouponsStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onTypeFilterChanged(
    CouponsTypeFilterChanged event,
    Emitter<CouponsState> emit,
  ) async {
    if (event.discountType == state.selectedType) return;

    emit(state.copyWith(
      selectedType: event.discountType,
      status: CouponsStatus.loading,
      currentPage: 1,
      hasReachedMax: false,
      clearError: true,
    ));

    try {
      final response = await repository.getCoupons(
        page: 1,
        perPage: 50,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        discountType:
            event.discountType != 'all' ? event.discountType : null,
      );

      final hasReachedMax = response.coupons.isEmpty ||
          response.coupons.length < 50 ||
          1 >= response.totalPages;

      if (response.coupons.isEmpty) {
        emit(state.copyWith(
          status: CouponsStatus.empty,
          coupons: [],
          currentPage: 1,
          hasReachedMax: true,
          totalCoupons: response.totalCoupons,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: CouponsStatus.success,
          coupons: response.coupons,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalCoupons: response.totalCoupons,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final message = _extractErrorMessage(e);
      emit(state.copyWith(
        status: CouponsStatus.failure,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onRefreshed(
    CouponsRefreshed event,
    Emitter<CouponsState> emit,
  ) async {
    add(const CouponsFetchStarted(isRefresh: true));
  }

  String _extractErrorMessage(dynamic e) {
    if (e is WooCommerceException) {
      return e.message;
    }
    return e.toString();
  }
}
