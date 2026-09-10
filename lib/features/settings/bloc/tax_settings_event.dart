import 'package:equatable/equatable.dart';

abstract class TaxSettingsEvent extends Equatable {
  const TaxSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Initiates fetching WooCommerce Tax Settings
class TaxSettingsFetchStarted extends TaxSettingsEvent {
  final bool forceRefresh;

  const TaxSettingsFetchStarted({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Explicit pull-to-refresh or retry action by the Admin
class TaxSettingsRefreshRequested extends TaxSettingsEvent {
  const TaxSettingsRefreshRequested();
}

/// Search filter query changed in the settings search bar
class TaxSettingsSearchChanged extends TaxSettingsEvent {
  final String query;

  const TaxSettingsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Setting type filter changed (e.g. 'select', 'text', 'checkbox', 'number', 'textarea', or null for all)
class TaxSettingsTypeFilterChanged extends TaxSettingsEvent {
  final String? typeFilter;

  const TaxSettingsTypeFilterChanged(this.typeFilter);

  @override
  List<Object?> get props => [typeFilter];
}
