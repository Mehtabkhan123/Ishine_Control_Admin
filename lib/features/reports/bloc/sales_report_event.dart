import 'package:equatable/equatable.dart';

abstract class SalesReportEvent extends Equatable {
  const SalesReportEvent();

  @override
  List<Object?> get props => [];
}

/// Request to fetch the sales report, optionally specifying period and force-refresh.
class SalesReportFetchRequested extends SalesReportEvent {
  final String period;
  final String? dateMin;
  final String? dateMax;
  final bool forceRefresh;

  const SalesReportFetchRequested({
    this.period = 'month',
    this.dateMin,
    this.dateMax,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [period, dateMin, dateMax, forceRefresh];
}

/// User requested manual refresh (pull to refresh or retry button).
class SalesReportRefreshRequested extends SalesReportEvent {
  const SalesReportRefreshRequested();
}

/// User toggled period tab (e.g. week, month, last_month, year).
class SalesReportPeriodChanged extends SalesReportEvent {
  final String period;

  const SalesReportPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}
