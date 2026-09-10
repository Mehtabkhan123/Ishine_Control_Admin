import 'package:equatable/equatable.dart';

abstract class GeneralSettingsEvent extends Equatable {
  const GeneralSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Initiates fetching WooCommerce General Settings
class GeneralSettingsFetchStarted extends GeneralSettingsEvent {
  final bool forceRefresh;

  const GeneralSettingsFetchStarted({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Explicit pull-to-refresh or retry action by the Admin
class GeneralSettingsRefreshRequested extends GeneralSettingsEvent {
  const GeneralSettingsRefreshRequested();
}

/// Search filter query changed in the settings search bar
class GeneralSettingsSearchChanged extends GeneralSettingsEvent {
  final String query;

  const GeneralSettingsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Setting type filter changed (e.g. 'select', 'text', 'checkbox', or null for all)
class GeneralSettingsTypeFilterChanged extends GeneralSettingsEvent {
  final String? typeFilter;

  const GeneralSettingsTypeFilterChanged(this.typeFilter);

  @override
  List<Object?> get props => [typeFilter];
}
