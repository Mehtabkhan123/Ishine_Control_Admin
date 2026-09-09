import 'package:equatable/equatable.dart';
import '../data/models/get_coupon_report_model.dart';

enum CouponsStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class CouponsState extends Equatable {
  final CouponsStatus status;
  final List<GETCouponReportModel> coupons;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final int totalCoupons;
  final int totalPages;
  final String searchQuery;
  final String selectedType;
  final String? errorMessage;

  const CouponsState({
    this.status = CouponsStatus.initial,
    this.coupons = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.totalCoupons = 0,
    this.totalPages = 1,
    this.searchQuery = '',
    this.selectedType = 'all',
    this.errorMessage,
  });

  bool get isLoading => status == CouponsStatus.loading;
  bool get isSuccess => status == CouponsStatus.success;
  bool get isEmpty => status == CouponsStatus.empty;
  bool get isFailure => status == CouponsStatus.failure;

  /// Count of active (non-expired) coupons in current list
  int get activeCouponsCount =>
      coupons.where((c) => !c.isExpired && c.status?.toLowerCase() != 'draft').length;

  /// Count of expired coupons in current list
  int get expiredCouponsCount =>
      coupons.where((c) => c.isExpired).length;

  /// Count of coupons that grant free shipping
  int get freeShippingCount =>
      coupons.where((c) => c.freeShipping == true).length;

  CouponsState copyWith({
    CouponsStatus? status,
    List<GETCouponReportModel>? coupons,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? totalCoupons,
    int? totalPages,
    String? searchQuery,
    String? selectedType,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CouponsState(
      status: status ?? this.status,
      coupons: coupons ?? this.coupons,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalCoupons: totalCoupons ?? this.totalCoupons,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        coupons,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        totalCoupons,
        totalPages,
        searchQuery,
        selectedType,
        errorMessage,
      ];
}
