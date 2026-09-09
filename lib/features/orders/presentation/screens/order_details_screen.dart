import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/single_order_cubit.dart';
import '../../bloc/single_order_state.dart';
import '../../data/models/get_single_order_model.dart';
import '../../data/repositories/orders_repository.dart';

/// Premium Samsung One UI 9-inspired Order Details Screen.
/// Powered by WooCommerce GET /wp-json/wc/v3/orders/{{orderId}}
/// via [SingleOrderCubit] and [GetSingleOrderModel].
class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String? initialOrderNumber;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.initialOrderNumber,
  });

  static Route<void> route({
    required int orderId,
    String? initialOrderNumber,
  }) {
    return MaterialPageRoute(
      builder: (context) {
        // Ensure SingleOrderCubit is available
        try {
          context.read<SingleOrderCubit>();
        } catch (_) {
          final repo = context.read<OrdersRepository>();
          return BlocProvider<SingleOrderCubit>(
            create: (_) => SingleOrderCubit(repository: repo),
            child: OrderDetailScreen(
              orderId: orderId,
              initialOrderNumber: initialOrderNumber,
            ),
          );
        }
        return OrderDetailScreen(
          orderId: orderId,
          initialOrderNumber: initialOrderNumber,
        );
      },
    );
  }

  /// Opens Order Details modal or full-screen depending on screen constraints
  static Future<void> show(
    BuildContext context, {
    required int orderId,
    String? initialOrderNumber,
  }) async {
    await Navigator.of(context).push(
      route(orderId: orderId, initialOrderNumber: initialOrderNumber),
    );
  }

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Map<String, dynamic>> _sections = [
    {'title': 'Overview', 'icon': Icons.dashboard_outlined},
    {'title': 'Products', 'icon': Icons.shopping_bag_outlined},
    {'title': 'Customer & Shipping', 'icon': Icons.person_pin_circle_outlined},
    {'title': 'Payment & Taxes', 'icon': Icons.receipt_long_outlined},
    {'title': 'Notes & Details', 'icon': Icons.info_outline_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);

    // Sync tab changes with SingleOrderCubit to persist active section
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        context.read<SingleOrderCubit>().changeSection(_tabController.index);
      }
    });

    final cubit = context.read<SingleOrderCubit>();
    // Restore tab index if section was previously selected
    if (cubit.state.activeSectionIndex < _tabController.length) {
      _tabController.index = cubit.state.activeSectionIndex;
    }
    cubit.fetchSingleOrder(widget.orderId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<SingleOrderCubit, SingleOrderState>(
      listener: (context, state) {
        if (state.isFailure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      builder: (context, state) {
        final isMatchingOrder = state.activeOrderId == widget.orderId;
        final order = isMatchingOrder
            ? state.order
            : state.cachedOrders[widget.orderId];
        final displayTitle = order?.displayOrderNumber ??
            (widget.initialOrderNumber != null
                ? '#${widget.initialOrderNumber}'
                : '#${widget.orderId}');

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: _buildOneUiAppBar(context, displayTitle, order, state, isDark),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await context
                  .read<SingleOrderCubit>()
                  .fetchSingleOrder(widget.orderId, forceRefresh: true);
            },
            child: _buildBodyContent(context, state, isDark),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildOneUiAppBar(
    BuildContext context,
    String displayTitle,
    GetSingleOrderModel? order,
    SingleOrderState state,
    bool isDark,
  ) {
    final isFetching = state.isOrderLoading(widget.orderId);

    return PreferredSize(
      preferredSize: const Size.fromHeight(116),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar Row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // One UI Squircle Back Button
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Order Number & Quick Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order $displayTitle',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              if (order?.status != null) ...[
                                const SizedBox(width: 10),
                                _buildStatusPill(order!.status!, isDark),
                              ],
                            ],
                          ),
                          if (order != null)
                            Text(
                              'Created ${DateFormat("MMM d, yyyy • h:mm a").format(order.orderDateTime)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Refresh Button (with spinner if loading)
                    InkWell(
                      onTap: isFetching
                          ? null
                          : () {
                              context.read<SingleOrderCubit>().fetchSingleOrder(
                                    widget.orderId,
                                    forceRefresh: true,
                                  );
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isFetching)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              Icon(
                                Icons.refresh_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              isFetching ? 'Fetching...' : 'Refresh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Segmented Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: _sections.map((s) {
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s['icon'] as IconData, size: 16),
                        const SizedBox(width: 6),
                        Text(s['title'] as String),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context,
    SingleOrderState state,
    bool isDark,
  ) {
    final isMatchingOrder = state.activeOrderId == widget.orderId;
    final order = isMatchingOrder
        ? state.order
        : state.cachedOrders[widget.orderId];

    // 1. Order data is not yet available or loading
    if (order == null) {
      if (state.isFailure && isMatchingOrder) {
        return _buildErrorView(context, state.errorMessage, isDark);
      }
      if (state.isEmpty && isMatchingOrder) {
        return _buildEmptyView(context, isDark);
      }
      return _buildLoadingShimmer(isDark);
    }

    // 4. Success State with Section Views
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(context, order, isDark),
        _buildProductsTab(context, order, isDark),
        _buildCustomerTab(context, order, isDark),
        _buildPaymentAndTaxesTab(context, order, isDark),
        _buildNotesAndMetadataTab(context, order, isDark),
      ],
    );
  }

  // ==========================================
  // SECTION 1: OVERVIEW TAB
  // ==========================================
  Widget _buildOverviewTab(
    BuildContext context,
    GetSingleOrderModel order,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  final itemWidth = isWide
                      ? (constraints.maxWidth - (3 * 14)) / 4
                      : (constraints.maxWidth - 14) / 2;

                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      _buildKpiCard(
                        title: 'Grand Total',
                        value: order.formattedTotal,
                        subtitle: order.currency ?? 'USD',
                        icon: Icons.payments_rounded,
                        color: AppColors.primary,
                        gradient: AppColors.brandGradient,
                        width: itemWidth,
                        isDark: isDark,
                      ),
                      _buildKpiCard(
                        title: 'Status',
                        value: (order.status ?? 'Pending').toUpperCase(),
                        subtitle: 'Order condition',
                        icon: Icons.flag_rounded,
                        color: _getStatusColor(order.status),
                        gradient: _getStatusGradient(order.status),
                        width: itemWidth,
                        isDark: isDark,
                      ),
                      _buildKpiCard(
                        title: 'Items Count',
                        value: '${order.totalItemCount} items',
                        subtitle: '${order.lineItems?.length ?? 0} line items',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.secondary,
                        gradient: AppColors.skyGradient,
                        width: itemWidth,
                        isDark: isDark,
                      ),
                      _buildKpiCard(
                        title: 'Payment Method',
                        value: order.paymentMethodDisplay,
                        subtitle: order.transactionId?.isNotEmpty == true
                            ? 'Txn: ${order.transactionId}'
                            : 'Standard',
                        icon: Icons.credit_card_rounded,
                        color: AppColors.success,
                        gradient: AppColors.emeraldGradient,
                        width: itemWidth,
                        isDark: isDark,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Customer & Delivery Snapshot
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Card
                  Expanded(
                    child: _buildOneUiCard(
                      title: 'Customer Summary',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerDisplayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (order.customerEmailAddress.isNotEmpty)
                            _buildClickableCopyRow(
                              icon: Icons.email_outlined,
                              text: order.customerEmailAddress,
                              label: 'Email',
                              isDark: isDark,
                            ),
                          if (order.customerPhone.isNotEmpty)
                            _buildClickableCopyRow(
                              icon: Icons.phone_outlined,
                              text: order.customerPhone,
                              label: 'Phone',
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Shipping Snapshot Card
                  Expanded(
                    child: _buildOneUiCard(
                      title: 'Delivery Details',
                      icon: Icons.local_shipping_outlined,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatFullAddress(order.shipping),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                          if (order.shippingLines?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Shipping: ${order.shippingLines!.first["method_title"] ?? "Standard"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Items Quick Preview
              _buildOneUiCard(
                title: 'Order Products Preview (${order.totalItemCount} Units)',
                icon: Icons.shopping_basket_outlined,
                action: TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('View All Items',
                      style: TextStyle(fontSize: 12)),
                ),
                isDark: isDark,
                child: _buildLineItemsList(
                    order.lineItems?.take(3).toList() ?? [], order, isDark),
              ),
              const SizedBox(height: 20),

              // Financial Breakdown Quick View
              _buildOneUiCard(
                title: 'Financial Breakdown',
                icon: Icons.account_balance_wallet_outlined,
                isDark: isDark,
                child: _buildFinancialSummary(order, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 2: PRODUCTS / ITEMS TAB
  // ==========================================
  Widget _buildProductsTab(
    BuildContext context,
    GetSingleOrderModel order,
    bool isDark,
  ) {
    final items = order.lineItems ?? [];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Line Items (${items.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Total Units: ${order.totalItemCount}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                _buildEmptySectionMessage(
                    'No line items found for this order.', isDark)
              else
                _buildOneUiCard(
                  title: 'Purchased Products',
                  icon: Icons.inventory_outlined,
                  isDark: isDark,
                  child: _buildLineItemsList(items, order, isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 3: CUSTOMER & SHIPPING TAB
  // ==========================================
  Widget _buildCustomerTab(
    BuildContext context,
    GetSingleOrderModel order,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Profile Card
              _buildOneUiCard(
                title: 'Customer Details',
                icon: Icons.badge_outlined,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Customer ID',
                      order.customerId != null && order.customerId != 0
                          ? '#${order.customerId}'
                          : 'Guest Checkout',
                      isDark,
                    ),
                    _buildDetailRow(
                      'Full Name',
                      order.customerDisplayName,
                      isDark,
                    ),
                    if (order.customerEmailAddress.isNotEmpty)
                      _buildDetailRowWithAction(
                        'Email Address',
                        order.customerEmailAddress,
                        Icons.copy_rounded,
                        () => _copyToClipboard(
                            context, order.customerEmailAddress, 'Email'),
                        isDark,
                      ),
                    if (order.customerPhone.isNotEmpty)
                      _buildDetailRowWithAction(
                        'Phone Number',
                        order.customerPhone,
                        Icons.copy_rounded,
                        () => _copyToClipboard(
                            context, order.customerPhone, 'Phone number'),
                        isDark,
                      ),
                    if (order.customerIpAddress?.isNotEmpty == true)
                      _buildDetailRow(
                        'IP Address',
                        order.customerIpAddress!,
                        isDark,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Addresses Grid (Billing + Shipping)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Billing Address
                  Expanded(
                    child: _buildOneUiCard(
                      title: 'Billing Address',
                      icon: Icons.receipt_outlined,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatBillingName(order.billing),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatAddressLines(
                              address1: order.billing?.address1,
                              address2: order.billing?.address2,
                              city: order.billing?.city,
                              state: order.billing?.state,
                              postcode: order.billing?.postcode,
                              country: order.billing?.country,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                          if (order.billing?.company?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Company: ${order.billing!.company}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Shipping Address
                  Expanded(
                    child: _buildOneUiCard(
                      title: 'Shipping Address',
                      icon: Icons.local_shipping_outlined,
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatShippingName(order.shipping),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatAddressLines(
                              address1: order.shipping?.address1,
                              address2: order.shipping?.address2,
                              city: order.shipping?.city,
                              state: order.shipping?.state,
                              postcode: order.shipping?.postcode,
                              country: order.shipping?.country,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              height: 1.4,
                            ),
                          ),
                          if (order.shipping?.company?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Company: ${order.shipping!.company}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 4: PAYMENT & TAXES TAB
  // ==========================================
  Widget _buildPaymentAndTaxesTab(
    BuildContext context,
    GetSingleOrderModel order,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Information Card
              _buildOneUiCard(
                title: 'Payment Method & Gateway',
                icon: Icons.credit_card_outlined,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Payment Method',
                      order.paymentMethodDisplay,
                      isDark,
                      isBold: true,
                    ),
                    if (order.paymentMethod?.isNotEmpty == true)
                      _buildDetailRow(
                        'Gateway Slug',
                        order.paymentMethod!,
                        isDark,
                      ),
                    if (order.transactionId?.isNotEmpty == true)
                      _buildDetailRowWithAction(
                        'Transaction ID',
                        order.transactionId!,
                        Icons.copy_rounded,
                        () => _copyToClipboard(
                            context, order.transactionId!, 'Transaction ID'),
                        isDark,
                      ),
                    _buildDetailRow(
                      'Paid Date',
                      order.datePaid != null
                          ? DateFormat('MMM d, yyyy • h:mm a').format(
                              DateTime.tryParse(order.datePaid!) ??
                                  DateTime.now())
                          : 'Awaiting Payment',
                      isDark,
                    ),
                    _buildDetailRow(
                      'Prices Include Tax',
                      order.pricesIncludeTax == true ? 'Yes' : 'No',
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Taxes Breakdown Card
              _buildOneUiCard(
                title: 'Tax Lines (${order.taxLines?.length ?? 0})',
                icon: Icons.percent_rounded,
                isDark: isDark,
                child: Column(
                  children: [
                    if (order.taxLines?.isNotEmpty == true) ...[
                      ...order.taxLines!.map((tax) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tax.label ?? tax.rateCode ?? 'Tax',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (tax.ratePercent != null)
                                    Text(
                                      'Rate: ${tax.ratePercent}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${order.displayCurrencySymbol}${tax.taxTotal ?? "0.00"}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        height: 18,
                      ),
                    ],
                    _buildDetailRow(
                      'Cart Tax',
                      '${order.displayCurrencySymbol}${order.cartTax ?? "0.00"}',
                      isDark,
                    ),
                    _buildDetailRow(
                      'Shipping Tax',
                      '${order.displayCurrencySymbol}${order.shippingTax ?? "0.00"}',
                      isDark,
                    ),
                    _buildDetailRow(
                      'Total Taxes',
                      order.formattedTax,
                      isDark,
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Comprehensive Financial Statement
              _buildOneUiCard(
                title: 'Order Financial Totals',
                icon: Icons.summarize_outlined,
                isDark: isDark,
                child: _buildFinancialSummary(order, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: NOTES & METADATA TAB
  // ==========================================
  Widget _buildNotesAndMetadataTab(
    BuildContext context,
    GetSingleOrderModel order,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Note
              if (order.customerNote?.isNotEmpty == true) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.comment_outlined,
                              size: 16, color: AppColors.warning),
                          SizedBox(width: 8),
                          Text(
                            'Customer Note',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.customerNote!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Technical Metadata Card
              _buildOneUiCard(
                title: 'WooCommerce Order Metadata',
                icon: Icons.code_rounded,
                isDark: isDark,
                child: Column(
                  children: [
                    _buildDetailRow('Order Key', order.orderKey ?? '—', isDark),
                    _buildDetailRow(
                        'Created Via', order.createdVia ?? 'storefront', isDark),
                    _buildDetailRow('WooCommerce Version',
                        order.version ?? 'Unknown', isDark),
                    _buildDetailRow('Currency Symbol',
                        order.currencySymbol ?? order.currency ?? '—', isDark),
                    _buildDetailRow(
                      'Date Modified',
                      order.dateModified != null
                          ? DateFormat('MMM d, yyyy • h:mm a').format(
                              DateTime.tryParse(order.dateModified!) ??
                                  DateTime.now())
                          : '—',
                      isDark,
                    ),
                    _buildDetailRow(
                      'Date Completed',
                      order.dateCompleted != null
                          ? DateFormat('MMM d, yyyy • h:mm a').format(
                              DateTime.tryParse(order.dateCompleted!) ??
                                  DateTime.now())
                          : 'Not yet completed',
                      isDark,
                    ),
                    if (order.customerUserAgent?.isNotEmpty == true)
                      _buildDetailRow(
                        'User Agent',
                        order.customerUserAgent!,
                        isDark,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SHARED REUSABLE COMPONENTS
  // ==========================================

  Widget _buildLineItemsList(
    List<LineItems> items,
    GetSingleOrderModel order,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        height: 16,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final imgSrc = item.image?.src;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: imgSrc != null && imgSrc.isNotEmpty
                    ? SafeNetworkImage(
                        imageUrl: imgSrc,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.image_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Name, SKU, variation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? 'Product #${item.productId ?? item.id}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.sku?.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'SKU: ${item.sku}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      if (item.variationId != null &&
                          item.variationId != 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Var #${item.variationId}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Quantity & Pricing
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${order.displayCurrencySymbol}${item.total ?? (item.price != null ? (item.price! * (item.quantity ?? 1)).toStringAsFixed(2) : "0.00")}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity ?? 1} × ${order.displayCurrencySymbol}${item.price?.toStringAsFixed(2) ?? "0.00"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinancialSummary(GetSingleOrderModel order, bool isDark) {
    return Column(
      children: [
        _buildCostLine(
          'Products Subtotal',
          order.formattedSubtotal,
          isDark,
        ),
        _buildCostLine(
          'Shipping Cost',
          order.formattedShipping,
          isDark,
        ),
        _buildCostLine(
          'Tax Total',
          order.formattedTax,
          isDark,
        ),
        if (order.discountTotalDouble > 0)
          _buildCostLine(
            'Discounts Applied',
            '-${order.formattedDiscount}',
            isDark,
            valueColor: AppColors.success,
          ),
        Divider(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          height: 20,
        ),
        _buildCostLine(
          'Order Grand Total',
          order.formattedTotal,
          isDark,
          isGrandTotal: true,
          valueColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildCostLine(
    String label,
    String value,
    bool isDark, {
    bool isGrandTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isGrandTotal ? 14 : 12,
              fontWeight: isGrandTotal ? FontWeight.w800 : FontWeight.w500,
              color: isDark
                  ? (isGrandTotal
                      ? AppColors.darkTextPrimary
                      : AppColors.darkTextSecondary)
                  : (isGrandTotal
                      ? AppColors.lightTextPrimary
                      : AppColors.lightTextSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isGrandTotal ? 16 : 13,
              fontWeight: isGrandTotal ? FontWeight.w900 : FontWeight.w700,
              color: valueColor ??
                  (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOneUiCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithAction(
    String label,
    String value,
    IconData icon,
    VoidCallback onAction,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(icon, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClickableCopyRow({
    required IconData icon,
    required String text,
    required String label,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _copyToClipboard(context, text, label),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded,
                size: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    final color = _getStatusColor(status);
    final bg = color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10), // One UI Squircle Pill
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'processing':
        return AppColors.warning;
      case 'on-hold':
        return AppColors.info;
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  LinearGradient _getStatusGradient(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppColors.emeraldGradient;
      case 'processing':
        return AppColors.amberGradient;
      case 'on-hold':
        return AppColors.skyGradient;
      case 'cancelled':
      case 'failed':
        return AppColors.roseGradient;
      default:
        return AppColors.brandGradient;
    }
  }

  Widget _buildEmptySectionMessage(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // LOADING / EMPTY / ERROR STATES
  // ==========================================

  Widget _buildLoadingShimmer(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // KPI Skeleton
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      height: 80,
                      margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Big Card Skeleton
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(height: 20),

              // Items Skeleton
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    String? message,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Failed to Load Order Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message ??
                  'Could not fetch order from WooCommerce. Please check credentials or network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<SingleOrderCubit>().fetchSingleOrder(
                      widget.orderId,
                      forceRefresh: true,
                    );
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Order Not Found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'The requested order #${widget.orderId} does not exist or has been removed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Go Back'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatBillingName(Billing? b) {
    if (b == null) return 'No billing contact';
    final name = '${b.firstName ?? ""} ${b.lastName ?? ""}'.trim();
    return name.isNotEmpty ? name : 'Guest';
  }

  String _formatShippingName(Shipping? s) {
    if (s == null) return 'No shipping recipient';
    final name = '${s.firstName ?? ""} ${s.lastName ?? ""}'.trim();
    return name.isNotEmpty ? name : 'Same as billing';
  }

  String _formatFullAddress(Shipping? s) {
    if (s == null) return 'No shipping address provided';
    return _formatAddressLines(
      address1: s.address1,
      address2: s.address2,
      city: s.city,
      state: s.state,
      postcode: s.postcode,
      country: s.country,
    );
  }

  String _formatAddressLines({
    String? address1,
    String? address2,
    String? city,
    String? state,
    String? postcode,
    String? country,
  }) {
    final parts = [
      if (address1 != null && address1.isNotEmpty) address1,
      if (address2 != null && address2.isNotEmpty) address2,
      if (city != null && city.isNotEmpty) city,
      if (state != null && state.isNotEmpty) state,
      if (postcode != null && postcode.isNotEmpty) postcode,
      if (country != null && country.isNotEmpty) country.toUpperCase(),
    ];
    return parts.isNotEmpty ? parts.join(', ') : 'No address on file';
  }
}
