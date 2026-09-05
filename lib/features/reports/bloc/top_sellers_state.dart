import 'package:equatable/equatable.dart';
import '../data/models/top_seller_model.dart';

abstract class TopSellersState extends Equatable {
  final String period;
  final List<TopSellerModel>? items;

  const TopSellersState({
    this.period = 'month',
    this.items,
  });

  @override
  List<Object?> get props => [period, items];
}

class TopSellersInitial extends TopSellersState {
  const TopSellersInitial({super.period = 'month'});
}

class TopSellersLoading extends TopSellersState {
  const TopSellersLoading({
    super.period = 'month',
    super.items,
  });
}

class TopSellersSuccess extends TopSellersState {
  @override
  List<TopSellerModel> get items => super.items!;
  final DateTime lastUpdated;

  const TopSellersSuccess({
    required List<TopSellerModel> items,
    required super.period,
    required this.lastUpdated,
  }) : super(items: items);

  int get totalQuantitySold =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  int get maxQuantity =>
      items.isEmpty ? 1 : items.map((e) => e.quantity).reduce((a, b) => a > b ? a : b);

  @override
  List<Object?> get props => [period, items, lastUpdated];
}

class TopSellersEmpty extends TopSellersState {
  const TopSellersEmpty({required super.period});
}

class TopSellersFailure extends TopSellersState {
  final String errorMessage;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;

  const TopSellersFailure({
    required this.errorMessage,
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
    required super.period,
    super.items,
  });

  @override
  List<Object?> get props => [
        period,
        items,
        errorMessage,
        statusCode,
        isTimeout,
        isNetworkError,
      ];
}
