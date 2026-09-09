import 'package:equatable/equatable.dart';

import '../data/models/get_coupon_report_model.dart';

abstract class CouponsEvent extends Equatable {
  const CouponsEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to trigger initial loading or re-fetch of coupons
class CouponsFetchStarted extends CouponsEvent {
  final bool isRefresh;

  const CouponsFetchStarted({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

/// Dispatched by infinite scrolling listener when user scrolls near the bottom
class CouponsLoadMore extends CouponsEvent {
  const CouponsLoadMore();
}

/// Dispatched when user enters or clears search query
class CouponsSearchChanged extends CouponsEvent {
  final String query;

  const CouponsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Dispatched when user selects discount type filter
class CouponsTypeFilterChanged extends CouponsEvent {
  final String discountType;

  const CouponsTypeFilterChanged(this.discountType);

  @override
  List<Object?> get props => [discountType];
}

/// Dispatched during pull-to-refresh to reset pagination and reload latest coupons
class CouponsRefreshed extends CouponsEvent {
  const CouponsRefreshed();
}

/// Dispatched when a new coupon is created in WooCommerce
class CouponsCouponCreated extends CouponsEvent {
  final GETCouponReportModel coupon;

  const CouponsCouponCreated(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

/// Dispatched when an existing coupon is updated in WooCommerce
class CouponsCouponUpdated extends CouponsEvent {
  final GETCouponReportModel coupon;

  const CouponsCouponUpdated(this.coupon);

  @override
  List<Object?> get props => [coupon];
}

/// Dispatched when a coupon is permanently deleted in WooCommerce
class CouponsCouponDeleted extends CouponsEvent {
  final int couponId;

  const CouponsCouponDeleted(this.couponId);

  @override
  List<Object?> get props => [couponId];
}


