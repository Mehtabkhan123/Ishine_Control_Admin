import 'package:equatable/equatable.dart';
import '../data/models/get_product_settings_model.dart';

enum ProductSettingsStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class ProductSettingsState extends Equatable {
  final ProductSettingsStatus status;
  final List<GetProductSettingsModel> allSettings;
  final List<GetProductSettingsModel> filteredSettings;
  final String searchQuery;
  final String? selectedTypeFilter;
  final String? errorMessage;
  final int? errorCode;
  final DateTime? lastUpdated;

  const ProductSettingsState({
    this.status = ProductSettingsStatus.initial,
    this.allSettings = const [],
    this.filteredSettings = const [],
    this.searchQuery = '',
    this.selectedTypeFilter,
    this.errorMessage,
    this.errorCode,
    this.lastUpdated,
  });

  bool get isInitial => status == ProductSettingsStatus.initial;
  bool get isLoading => status == ProductSettingsStatus.loading;
  bool get isSuccess => status == ProductSettingsStatus.success;
  bool get isEmpty => status == ProductSettingsStatus.empty;
  bool get isFailure => status == ProductSettingsStatus.failure;

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

  ProductSettingsState copyWith({
    ProductSettingsStatus? status,
    List<GetProductSettingsModel>? allSettings,
    List<GetProductSettingsModel>? filteredSettings,
    String? searchQuery,
    String? selectedTypeFilter,
    bool clearTypeFilter = false,
    String? errorMessage,
    int? errorCode,
    DateTime? lastUpdated,
  }) {
    return ProductSettingsState(
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
