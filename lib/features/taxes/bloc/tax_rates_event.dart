import 'package:equatable/equatable.dart';

abstract class TaxRatesEvent extends Equatable {
  const TaxRatesEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to trigger initial loading or re-fetch of tax rates
class TaxRatesFetchStarted extends TaxRatesEvent {
  final bool isRefresh;

  const TaxRatesFetchStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Dispatched by infinite scrolling listener when user scrolls near the bottom
class TaxRatesLoadMore extends TaxRatesEvent {
  const TaxRatesLoadMore();
}

/// Dispatched during pull-to-refresh to reset pagination and reload latest tax rates
class TaxRatesRefreshed extends TaxRatesEvent {
  const TaxRatesRefreshed();
}

/// Dispatched when user enters or clears search query
class TaxRatesSearchChanged extends TaxRatesEvent {
  final String query;

  const TaxRatesSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched when user filters by tax class (e.g., 'all', 'standard', 'reduced-rate', 'zero-rate')
class TaxRatesClassFilterChanged extends TaxRatesEvent {
  final String taxClass;

  const TaxRatesClassFilterChanged(this.taxClass);

  @override
  List<Object?> get props => [taxClass];
}

/// Dispatched to retry a failed fetch request
class TaxRatesRetryRequested extends TaxRatesEvent {
  const TaxRatesRetryRequested();
}

/// Dispatched when a new tax rate is created in WooCommerce
class TaxRatesRateCreated extends TaxRatesEvent {
  final dynamic taxRate;

  const TaxRatesRateCreated(this.taxRate);

  @override
  List<Object?> get props => [taxRate];
}
