import 'package:equatable/equatable.dart';
import '../data/models/get_general_settings_model.dart';

enum GeneralSettingsStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class GeneralSettingsState extends Equatable {
  final GeneralSettingsStatus status;
  final List<GetGeneralSettingsModel> allSettings;
  final List<GetGeneralSettingsModel> filteredSettings;
  final String searchQuery;
  final String? selectedTypeFilter;
  final String? errorMessage;
  final int? errorCode;
  final DateTime? lastUpdated;

  const GeneralSettingsState({
    this.status = GeneralSettingsStatus.initial,
    this.allSettings = const [],
    this.filteredSettings = const [],
    this.searchQuery = '',
    this.selectedTypeFilter,
    this.errorMessage,
    this.errorCode,
    this.lastUpdated,
  });

  bool get isInitial => status == GeneralSettingsStatus.initial;
  bool get isLoading => status == GeneralSettingsStatus.loading;
  bool get isSuccess => status == GeneralSettingsStatus.success;
  bool get isEmpty => status == GeneralSettingsStatus.empty;
  bool get isFailure => status == GeneralSettingsStatus.failure;

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

  GeneralSettingsState copyWith({
    GeneralSettingsStatus? status,
    List<GetGeneralSettingsModel>? allSettings,
    List<GetGeneralSettingsModel>? filteredSettings,
    String? searchQuery,
    String? selectedTypeFilter,
    bool clearTypeFilter = false,
    String? errorMessage,
    int? errorCode,
    DateTime? lastUpdated,
  }) {
    return GeneralSettingsState(
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
