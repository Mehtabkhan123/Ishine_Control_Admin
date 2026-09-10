import 'package:equatable/equatable.dart';
import '../data/models/shipping_zones_model.dart';

enum ShippingZonesStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class ShippingZonesState extends Equatable {
  final ShippingZonesStatus status;
  final List<ShippingZonesModel> zones;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final int totalZones;
  final int totalPages;
  final String searchQuery;
  final String? errorMessage;
  final int? errorStatusCode;

  const ShippingZonesState({
    this.status = ShippingZonesStatus.initial,
    this.zones = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.totalZones = 0,
    this.totalPages = 1,
    this.searchQuery = '',
    this.errorMessage,
    this.errorStatusCode,
  });

  bool get isLoading => status == ShippingZonesStatus.loading;
  bool get isSuccess => status == ShippingZonesStatus.success;
  bool get isEmpty => status == ShippingZonesStatus.empty;
  bool get isFailure => status == ShippingZonesStatus.failure;

  /// Returns zones filtered by the local search query if present
  List<ShippingZonesModel> get displayZones {
    if (searchQuery.trim().isEmpty) return zones;
    final q = searchQuery.trim().toLowerCase();
    return zones.where((zone) {
      final nameMatches = (zone.name ?? '').toLowerCase().contains(q);
      final idMatches = (zone.id?.toString() ?? '').contains(q);
      final orderMatches = (zone.order?.toString() ?? '').contains(q);
      return nameMatches || idMatches || orderMatches;
    }).toList();
  }

  /// Whether current failure is authentication-related (401 / 403)
  bool get isAuthError =>
      errorStatusCode == 401 ||
      errorStatusCode == 403 ||
      (errorMessage != null &&
          (errorMessage!.toLowerCase().contains('authenticat') ||
              errorMessage!.toLowerCase().contains('consumer key') ||
              errorMessage!.toLowerCase().contains('forbidden')));

  /// Whether current failure is network/connectivity-related
  bool get isNetworkError =>
      errorStatusCode == 408 ||
      (errorMessage != null &&
          (errorMessage!.toLowerCase().contains('connect') ||
              errorMessage!.toLowerCase().contains('timeout') ||
              errorMessage!.toLowerCase().contains('socket') ||
              errorMessage!.toLowerCase().contains('network')));

  /// Count of custom shipping zones (excluding fallback default if id=0)
  int get customZonesCount => zones.where((z) => z.id != 0).length;

  /// Default fallback zone (id == 0) if present
  ShippingZonesModel? get defaultZone {
    final idx = zones.indexWhere((z) => z.id == 0);
    return idx != -1 ? zones[idx] : null;
  }

  ShippingZonesState copyWith({
    ShippingZonesStatus? status,
    List<ShippingZonesModel>? zones,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? totalZones,
    int? totalPages,
    String? searchQuery,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
  }) {
    return ShippingZonesState(
      status: status ?? this.status,
      zones: zones ?? this.zones,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalZones: totalZones ?? this.totalZones,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorStatusCode:
          clearError ? null : (errorStatusCode ?? this.errorStatusCode),
    );
  }

  @override
  List<Object?> get props => [
        status,
        zones,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        totalZones,
        totalPages,
        searchQuery,
        errorMessage,
        errorStatusCode,
      ];
}
