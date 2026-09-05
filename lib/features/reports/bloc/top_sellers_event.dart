import 'package:equatable/equatable.dart';

abstract class TopSellersEvent extends Equatable {
  const TopSellersEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load top selling products report.
class TopSellersFetchRequested extends TopSellersEvent {
  final String period;
  final String? dateMin;
  final String? dateMax;
  final bool forceRefresh;

  const TopSellersFetchRequested({
    this.period = 'month',
    this.dateMin,
    this.dateMax,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [period, dateMin, dateMax, forceRefresh];
}

/// Dispatched to bypass cache and re-fetch live data.
class TopSellersRefreshRequested extends TopSellersEvent {
  const TopSellersRefreshRequested();
}

/// Dispatched when the admin switches the time period.
class TopSellersPeriodChanged extends TopSellersEvent {
  final String period;

  const TopSellersPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}
