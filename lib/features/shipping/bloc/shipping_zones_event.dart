import 'package:equatable/equatable.dart';

abstract class ShippingZonesEvent extends Equatable {
  const ShippingZonesEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to trigger initial loading or re-fetch of shipping zones
class ShippingZonesFetchStarted extends ShippingZonesEvent {
  final bool isRefresh;

  const ShippingZonesFetchStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Dispatched by scroll listener when user reaches bottom for pagination
class ShippingZonesLoadMore extends ShippingZonesEvent {
  const ShippingZonesLoadMore();
}

/// Dispatched during pull-to-refresh to clear cache and reload fresh zones
class ShippingZonesRefreshed extends ShippingZonesEvent {
  const ShippingZonesRefreshed();
}

/// Dispatched when user enters a search query
class ShippingZonesSearchChanged extends ShippingZonesEvent {
  final String query;

  const ShippingZonesSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched to retry a failed fetch request
class ShippingZonesRetryRequested extends ShippingZonesEvent {
  const ShippingZonesRetryRequested();
}
