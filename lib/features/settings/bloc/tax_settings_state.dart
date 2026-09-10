import 'package:equatable/equatable.dart';
import '../data/models/get_tax_settings_model.dart';

enum TaxSettingsStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class TaxSettingsState extends Equatable {
  final TaxSettingsStatus status;
  final List<GetTextSettingsModel> allSettings;
  final List<GetTextSettingsModel> filteredSettings;
  final String searchQuery;
  final String? selectedTypeFilter;
  final String? errorMessage;
  final int? errorCode;
  final DateTime? lastUpdated;

  const TaxSettingsState({
    this.status = TaxSettingsStatus.initial,
    this.allSettings = const [],
    this.filteredSettings = const [],
    this.searchQuery = '',
    this.selectedTypeFilter,
    this.errorMessage,
    this.errorCode,
    this.lastUpdated,
  });

  bool get isInitial => status == TaxSettingsStatus.initial;
  bool get isLoading => status == TaxSettingsStatus.loading;
  bool get isSuccess => status == TaxSettingsStatus.success;
  bool get isEmpty => status == TaxSettingsStatus.empty;
  bool get isFailure => status == TaxSettingsStatus.failure;

  int get totalCount => allSettings.length;
  int get filteredCount => filteredSettings.length;

  /// Returns sorted unique setting types present in the current dataset
  List<String> get availableTypes {
    final types = allSettings
        .map((s) => s.type?.trim().toLowerCase())
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  TaxSettingsState copyWith({
    TaxSettingsStatus? status,
    List<GetTextSettingsModel>? allSettings,
    List<GetTextSettingsModel>? filteredSettings,
    String? searchQuery,
    String? selectedTypeFilter,
    bool clearTypeFilter = false,
    String? errorMessage,
    int? errorCode,
    DateTime? lastUpdated,
  }) {
    return TaxSettingsState(
      status: status ?? this.status,
      allSettings: allSettings ?? this.allSettings,
      filteredSettings: filteredSettings ?? this.filteredSettings,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTypeFilter: clearTypeFilter
          ? null
          : (selectedTypeFilter ?? this.selectedTypeFilter),
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allSettings,
        filteredSettings,
        searchQuery,
        selectedTypeFilter,
        errorMessage,
        errorCode,
        lastUpdated,
      ];
}
