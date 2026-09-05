import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/network/network_exceptions.dart';
import '../data/repositories/reports_repository.dart';
import 'top_sellers_event.dart';
import 'top_sellers_state.dart';

/// BLoC orchestrating WooCommerce Top Sellers Report analytics.
class TopSellersBloc extends Bloc<TopSellersEvent, TopSellersState> {
  final ReportsRepository repository;

  TopSellersBloc({required this.repository}) : super(const TopSellersInitial()) {
    on<TopSellersFetchRequested>(_onFetchRequested);
    on<TopSellersRefreshRequested>(_onRefreshRequested);
    on<TopSellersPeriodChanged>(_onPeriodChanged);
  }

  Future<void> _onFetchRequested(
    TopSellersFetchRequested event,
    Emitter<TopSellersState> emit,
  ) async {
    // Prevent duplicate calls during rebuilds if currently loading or already loaded for the same period
    if (!event.forceRefresh &&
        state.period == event.period &&
        (state is TopSellersLoading || state is TopSellersSuccess)) {
      return;
    }

    await _loadTopSellers(
      emit,
      period: event.period,
      dateMin: event.dateMin,
      dateMax: event.dateMax,
      forceRefresh: event.forceRefresh,
    );
  }

  Future<void> _onRefreshRequested(
    TopSellersRefreshRequested event,
    Emitter<TopSellersState> emit,
  ) async {
    await _loadTopSellers(
      emit,
      period: state.period,
      forceRefresh: true,
    );
  }

  Future<void> _onPeriodChanged(
    TopSellersPeriodChanged event,
    Emitter<TopSellersState> emit,
  ) async {
    if (state.period == event.period && state is TopSellersSuccess) {
      return;
    }
    await _loadTopSellers(
      emit,
      period: event.period,
      forceRefresh: false,
    );
  }

  Future<void> _loadTopSellers(
    Emitter<TopSellersState> emit, {
    required String period,
    String? dateMin,
    String? dateMax,
    bool forceRefresh = false,
  }) async {
    if (!EnvConfig.isConfigured) {
      emit(
        TopSellersFailure(
          errorMessage: 'WooCommerce store configuration is missing.',
          period: period,
          items: state.items,
        ),
      );
      return;
    }

    emit(
      TopSellersLoading(
        period: period,
        items: state.items,
      ),
    );

    try {
      final items = await repository.getTopSellers(
        period: period,
        dateMin: dateMin,
        dateMax: dateMax,
        forceRefresh: forceRefresh,
      );

      if (items.isEmpty) {
        emit(TopSellersEmpty(period: period));
      } else {
        emit(
          TopSellersSuccess(
            items: items,
            period: period,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    } on WooCommerceException catch (e) {
      final isTimeout = e.statusCode == 408 || e.message.toLowerCase().contains('timed out');
      final isNetwork = !isTimeout &&
          (e.message.toLowerCase().contains('connect') || e.message.toLowerCase().contains('network'));

      emit(
        TopSellersFailure(
          errorMessage: e.message,
          statusCode: e.statusCode,
          period: period,
          isTimeout: isTimeout,
          isNetworkError: isNetwork,
          items: state.items,
        ),
      );
    } catch (e) {
      emit(
        TopSellersFailure(
          errorMessage: 'Failed to load top sellers: ${e.toString()}',
          period: period,
          items: state.items,
        ),
      );
    }
  }
}
