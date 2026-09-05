import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class OrderItemData {
  final String orderNumber;
  final String customerName;
  final String customerEmail;
  final DateTime date;
  final String status;
  final double total;
  final int itemsCount;
  final String paymentMethod;

  const OrderItemData({
    required this.orderNumber,
    required this.customerName,
    required this.customerEmail,
    required this.date,
    required this.status,
    required this.total,
    required this.itemsCount,
    required this.paymentMethod,
  });
}

/// Redesigned Orders Screen with Samsung One UI aesthetics.
/// Features KPI stat cards, search & filter pills, order status badges,
/// and interactive order management.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static final List<OrderItemData> _allOrders = [
    OrderItemData(
      orderNumber: '#10852',
      customerName: 'Sarah Jenkins',
      customerEmail: 'sarah.j@example.com',
      date: DateTime.now().subtract(const Duration(minutes: 24)),
      status: 'processing',
      total: 349.50,
      itemsCount: 3,
      paymentMethod: 'Stripe (Credit Card)',
    ),
    OrderItemData(
      orderNumber: '#10851',
      customerName: 'Michael Chen',
      customerEmail: 'mchen.tech@gmail.com',
      date: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      status: 'processing',
      total: 189.00,
      itemsCount: 1,
      paymentMethod: 'PayPal',
    ),
    OrderItemData(
      orderNumber: '#10850',
      customerName: 'David Miller',
      customerEmail: 'david.m@outlook.com',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'completed',
      total: 540.20,
      itemsCount: 4,
      paymentMethod: 'Apple Pay',
    ),
    OrderItemData(
      orderNumber: '#10849',
      customerName: 'Emma Watson',
      customerEmail: 'emma.w@icloud.com',
      date: DateTime.now().subtract(const Duration(hours: 5, minutes: 40)),
      status: 'completed',
      total: 89.90,
      itemsCount: 2,
      paymentMethod: 'Stripe',
    ),
    OrderItemData(
      orderNumber: '#10848',
      customerName: 'Lucas Rodriguez',
      customerEmail: 'lucas.rod@domain.co',
      date: DateTime.now().subtract(const Duration(hours: 8)),
      status: 'on_hold',
      total: 420.00,
      itemsCount: 2,
      paymentMethod: 'Direct Bank Transfer',
    ),
    OrderItemData(
      orderNumber: '#10847',
      customerName: 'Jessica Taylor',
      customerEmail: 'jess.taylor@gmail.com',
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'completed',
      total: 215.40,
      itemsCount: 1,
      paymentMethod: 'Stripe',
    ),
    OrderItemData(
      orderNumber: '#10846',
      customerName: 'Alexander Wright',
      customerEmail: 'a.wright@enterprise.com',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      status: 'cancelled',
      total: 150.00,
      itemsCount: 1,
      paymentMethod: 'Credit Card',
    ),
    OrderItemData(
      orderNumber: '#10845',
      customerName: 'Olivia Davis',
      customerEmail: 'olivia.d@webmail.org',
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: 'completed',
      total: 678.90,
      itemsCount: 5,
      paymentMethod: 'PayPal',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderItemData> get _filteredOrders {
    return _allOrders.where((order) {
      if (_selectedFilter != 'all' && order.status != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesNum = order.orderNumber.toLowerCase().contains(query);
        final matchesName = order.customerName.toLowerCase().contains(query);
        final matchesEmail = order.customerEmail.toLowerCase().contains(query);
        if (!matchesNum && !matchesName && !matchesEmail) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Summary Cards
          _buildKpiGrid(context, isDark),
          const SizedBox(height: 24),

          // Main Orders Card Container
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24), // One UI Squircle
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar & Filter Pills
                _buildFilterBar(context, isDark),
                const SizedBox(height: 20),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 16),

                // Orders List
                _buildOrdersList(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, bool isDark) {
    final kpis = [
      {
        'title': 'Total Orders',
        'value': '1,284',
        'subtitle': '+14.2% vs last month',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.primary,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Processing',
        'value': '38',
        'subtitle': 'Awaiting fulfillment',
        'icon': Icons.pending_actions_rounded,
        'color': AppColors.warning,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'Completed',
        'value': '1,192',
        'subtitle': 'Delivered successfully',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Cancelled / Returned',
        'value': '54',
        'subtitle': '3.8% return rate',
        'icon': Icons.remove_circle_outline_rounded,
        'color': AppColors.error,
        'gradient': AppColors.roseGradient,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final itemWidth = isWide ? (constraints.maxWidth - (3 * 16)) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: kpis.map((kpi) {
            final gradient = kpi['gradient'] as LinearGradient;
            final color = kpi['color'] as Color;

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22), // One UI Squircle
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      kpi['icon'] as IconData,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kpi['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kpi['value'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kpi['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isDark) {
    final filters = [
      {'label': 'All Orders', 'value': 'all', 'count': '1,284'},
      {'label': 'Processing', 'value': 'processing', 'count': '38'},
      {'label': 'Completed', 'value': 'completed', 'count': '1,192'},
      {'label': 'On Hold', 'value': 'on_hold', 'count': '12'},
      {'label': 'Cancelled', 'value': 'cancelled', 'count': '42'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search by order #, customer name, or email...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exporting orders to CSV...'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export CSV'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFE2E8F0),
                      foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Status Filter Pills Container
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final isSelected = _selectedFilter == f['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilter = f['value']!),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20), // One UI Pill
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : (isDark ? AppColors.darkCard : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                f['count']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersList(BuildContext context, bool isDark) {
    final orders = _filteredOrders;

    if (orders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 36,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No orders match your filter criteria',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Try clearing your search query or switching to another filter status.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, _) => Divider(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        height: 16,
      ),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderItemTile(context, order, isDark);
      },
    );
  }

  Widget _buildOrderItemTile(BuildContext context, OrderItemData order, bool isDark) {
    final timeStr = DateFormat('MMM d, h:mm a').format(order.date);

    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (order.status) {
      case 'processing':
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        statusLabel = 'Processing';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusBg = AppColors.success.withValues(alpha: 0.12);
        statusLabel = 'Completed';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'on_hold':
        statusColor = AppColors.info;
        statusBg = AppColors.info.withValues(alpha: 0.12);
        statusLabel = 'On Hold';
        statusIcon = Icons.pause_circle_rounded;
        break;
      case 'cancelled':
      default:
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        statusLabel = 'Cancelled';
        statusIcon = Icons.cancel_rounded;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Customer Avatar Initials
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryLight,
                      AppColors.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14), // One UI squircle
                ),
                child: Center(
                  child: Text(
                    order.customerName.isNotEmpty ? order.customerName[0] : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Order Number & Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${order.itemsCount} ${order.itemsCount == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName} (${order.customerEmail})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$timeStr • ${order.paymentMethod}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!isCompact) ...[
                // Payment Method & Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.paymentMethod,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
              ],

              // Total Amount & Status Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 11, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
