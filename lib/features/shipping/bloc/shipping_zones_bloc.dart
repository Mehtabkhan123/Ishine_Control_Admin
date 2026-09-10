import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/models/shipping_zones_model.dart';
import '../data/repositories/shipping_repository.dart';
import 'shipping_zones_event.dart';
import 'shipping_zones_state.dart';

class ShippingZonesBloc extends Bloc<ShippingZonesEvent, ShippingZonesState> {
  final ShippingRepository repository;

  ShippingZonesBloc({required this.repository})
      : super(const ShippingZonesState()) {
    on<ShippingZonesFetchStarted>(_onFetchStarted);
    on<ShippingZonesLoadMore>(_onLoadMore);
    on<ShippingZonesRefreshed>(_onRefreshed);
    on<ShippingZonesSearchChanged>(_onSearchChanged);
    on<ShippingZonesRetryRequested>(_onRetryRequested);
  }

  Future<void> _onFetchStarted(
    ShippingZonesFetchStarted event,
    Emitter<ShippingZonesState> emit,
  ) async {
    // Prevent duplicate initial loads if already loading and not a refresh
    if (!event.isRefresh && state.status == ShippingZonesStatus.loading) {
      return;
    }

    if (!event.isRefresh) {
      emit(state.copyWith(
        status: ShippingZonesStatus.loading,
        currentPage: 1,
        hasReachedMax: false,
        clearError: true,
      ));
    }

    try {
      final response = await repository.getShippingZones(
        page: 1,
        perPage: 50,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        forceRefresh: event.isRefresh,
      );

      // Deduplicate zones by ID to prevent any duplicate entries
      final uniqueZones = _deduplicateZones(response.zones);

      final hasReachedMax = uniqueZones.isEmpty ||
          uniqueZones.length < 50 ||
          1 >= response.totalPages;

      if (uniqueZones.isEmpty) {
        emit(state.copyWith(
          status: ShippingZonesStatus.empty,
          zones: [],
          currentPage: 1,
          hasReachedMax: true,
          totalZones: response.totalZones,
          totalPages: response.totalPages,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: ShippingZonesStatus.success,
          zones: uniqueZones,
          currentPage: 1,
          hasReachedMax: hasReachedMax,
          totalZones: response.totalZones > 0
              ? response.totalZones
              : uniqueZones.length,
          totalPages: response.totalPages,
          clearError: true,
        ));
      }
    } catch (e) {
      final (message, statusCode) = _extractErrorInfo(e);
      emit(state.copyWith(
        status: ShippingZonesStatus.failure,
        errorMessage: message,
        errorStatusCode: statusCode,
      ));
    }
  }

  Future<void> _onLoadMore(
    ShippingZonesLoadMore event,
    Emitter<ShippingZonesState> emit,
  ) async {
    // Prevent duplicate pagination requests
    if (state.hasReachedMax ||
        state.isLoadingMore ||
        state.status != ShippingZonesStatus.success) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    final nextPage = state.currentPage + 1;

    try {
      final response = await repository.getShippingZones(
        page: nextPage,
        perPage: 50,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      // Prevent duplicate zones when appending next page
      final existingIds =
          state.zones.map((z) => z.id).whereType<int>().toSet();
      final newUniqueZones = response.zones
          .where((z) => z.id == null || !existingIds.contains(z.id))
          .toList();

      final combined = List<ShippingZonesModel>.from(state.zones)
        ..addAll(newUniqueZones);

      final hasReachedMax = response.zones.isEmpty ||
          response.zones.length < 50 ||
          nextPage >= response.totalPages;

      emit(state.copyWith(
        zones: combined,
        currentPage: nextPage,
        hasReachedMax: hasReachedMax,
        isLoadingMore: false,
        totalZones: response.totalZones > 0
            ? response.totalZones
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
    ShippingZonesRefreshed event,
    Emitter<ShippingZonesState> emit,
  ) async {
    repository.clearCache();
    add(const ShippingZonesFetchStarted(isRefresh: true));
  }

  Future<void> _onRetryRequested(
    ShippingZonesRetryRequested event,
    Emitter<ShippingZonesState> emit,
  ) async {
    repository.clearCache();
    add(const ShippingZonesFetchStarted(isRefresh: true));
  }

  void _onSearchChanged(
    ShippingZonesSearchChanged event,
    Emitter<ShippingZonesState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  /// Removes any duplicate zones by ID while preserving order
  List<ShippingZonesModel> _deduplicateZones(List<ShippingZonesModel> raw) {
    final result = <ShippingZonesModel>[];
    final seen = <int>{};
    for (final zone in raw) {
      if (zone.id != null) {
        if (seen.add(zone.id!)) {
          result.add(zone);
        }
      } else {
        result.add(zone);
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
