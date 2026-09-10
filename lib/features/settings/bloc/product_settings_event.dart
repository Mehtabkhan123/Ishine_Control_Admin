import 'package:equatable/equatable.dart';

abstract class ProductSettingsEvent extends Equatable {
  const ProductSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Initiates fetching WooCommerce Product Settings
class ProductSettingsFetchStarted extends ProductSettingsEvent {
  final bool forceRefresh;

  const ProductSettingsFetchStarted({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Explicit pull-to-refresh or retry action by the Admin
class ProductSettingsRefreshRequested extends ProductSettingsEvent {
  const ProductSettingsRefreshRequested();
}

/// Search filter query changed in the settings search bar
class ProductSettingsSearchChanged extends ProductSettingsEvent {
  final String query;

  const ProductSettingsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Setting type filter changed (e.g. 'select', 'text', 'checkbox', 'number', or null for all)
class ProductSettingsTypeFilterChanged extends ProductSettingsEvent {
  final String? typeFilter;

  const ProductSettingsTypeFilterChanged(this.typeFilter);

  @override
  List<Object?> get props => [typeFilter];
}
