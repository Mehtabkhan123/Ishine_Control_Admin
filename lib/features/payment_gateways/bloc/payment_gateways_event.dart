import 'package:equatable/equatable.dart';

abstract class PaymentGatewaysEvent extends Equatable {
  const PaymentGatewaysEvent();

  @override
  List<Object?> get props => [];
}

/// Initial fetch or explicit refresh trigger
class PaymentGatewaysFetchStarted extends PaymentGatewaysEvent {
  final bool isRefresh;

  const PaymentGatewaysFetchStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// User pull-to-refresh or tap refresh button
class PaymentGatewaysRefreshed extends PaymentGatewaysEvent {
  const PaymentGatewaysRefreshed();
}

/// User tapped Retry Connection on error view
class PaymentGatewaysRetryRequested extends PaymentGatewaysEvent {
  const PaymentGatewaysRetryRequested();
}

/// Search filter query changed
class PaymentGatewaysSearchChanged extends PaymentGatewaysEvent {
  final String query;

  const PaymentGatewaysSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Status filter changed ('all', 'enabled', 'disabled', 'needs_setup')
class PaymentGatewaysFilterChanged extends PaymentGatewaysEvent {
  final String filter;

  const PaymentGatewaysFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Dispatched when a payment gateway has been updated via PUT API
class PaymentGatewayUpdated extends PaymentGatewaysEvent {
  final dynamic gateway;

  const PaymentGatewayUpdated(this.gateway);

  @override
  List<Object?> get props => [gateway];
}
