import 'package:equatable/equatable.dart';
import '../data/models/get_single_order_model.dart';

enum SingleOrderStatus {
  initial,
  loading,
  success,
  empty,
  failure,
}

class SingleOrderState extends Equatable {
  final SingleOrderStatus status;
  final GetSingleOrderModel? order;
  final int? activeOrderId;
  final Map<int, GetSingleOrderModel> cachedOrders;
  final Set<int> loadingOrderIds;
  final String? errorMessage;
  final int activeSectionIndex;

  const SingleOrderState({
    this.status = SingleOrderStatus.initial,
    this.order,
    this.activeOrderId,
    this.cachedOrders = const {},
    this.loadingOrderIds = const {},
    this.errorMessage,
    this.activeSectionIndex = 0,
  });

  bool get isLoading => status == SingleOrderStatus.loading;
  bool get isSuccess => status == SingleOrderStatus.success;
  bool get isEmpty =>
      status == SingleOrderStatus.empty ||
      (status == SingleOrderStatus.success && order == null);
  bool get isFailure => status == SingleOrderStatus.failure;

  /// Checks if a specific order ID is currently being fetched
  bool isOrderLoading(int orderId) => loadingOrderIds.contains(orderId);

  SingleOrderState copyWith({
    SingleOrderStatus? status,
    GetSingleOrderModel? order,
    bool clearOrder = false,
    int? activeOrderId,
    bool clearActiveOrderId = false,
    Map<int, GetSingleOrderModel>? cachedOrders,
    Set<int>? loadingOrderIds,
    String? errorMessage,
    bool clearError = false,
    int? activeSectionIndex,
  }) {
    return SingleOrderState(
      status: status ?? this.status,
      order: clearOrder ? null : (order ?? this.order),
      activeOrderId:
          clearActiveOrderId ? null : (activeOrderId ?? this.activeOrderId),
      cachedOrders: cachedOrders ?? this.cachedOrders,
      loadingOrderIds: loadingOrderIds ?? this.loadingOrderIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeSectionIndex: activeSectionIndex ?? this.activeSectionIndex,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        activeOrderId,
        cachedOrders,
        loadingOrderIds,
        errorMessage,
        activeSectionIndex,
      ];
}
