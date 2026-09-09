import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/coupons_bloc.dart';
import '../../bloc/coupons_event.dart';
import '../../bloc/coupons_state.dart';
import '../../data/models/get_coupon_report_model.dart';
import '../../data/repositories/coupons_repository.dart';
import 'coupon_details_screen.dart';

/// Modern premium Coupons Screen with Samsung One UI 9 aesthetics.
/// Powered by WooCommerce GET /wp-json/wc/v3/coupons?per_page=50&page=1 with
/// infinite scrolling, discount type filtering, search, and live details navigation.
class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    CouponsRepository repository;
    try {
      repository = context.read<CouponsRepository>();
    } catch (_) {
      repository = CouponsRepository();
    }

    return BlocProvider<CouponsBloc>(
      create: (_) => CouponsBloc(repository: repository)
        ..add(const CouponsFetchStarted()),
      child: const _CouponsView(),
    );
  }
}

class _CouponsView extends StatefulWidget {
  const _CouponsView();

  @override
  State<_CouponsView> createState() => _CouponsViewState();
}

class _CouponsViewState extends State<_CouponsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= (maxScroll - 200)) {
      final bloc = context.read<CouponsBloc>();
      if (!bloc.state.hasReachedMax && !bloc.state.isLoadingMore) {
        bloc.add(const CouponsLoadMore());
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<CouponsBloc>().add(CouponsSearchChanged(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CouponsBloc, CouponsState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.coupons.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final bloc = context.read<CouponsBloc>();
            bloc.add(const CouponsRefreshed());
            await bloc.stream
                .firstWhere((s) => !s.isLoading && !s.isLoadingMore);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metric Summary Cards
                _buildKpiGrid(context, state, isDark),
                const SizedBox(height: 24),

                // Main Coupons Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24), // One UI Squircle
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                      // Filter Bar & Search Input
                      _buildFilterBar(context, state, isDark),
                      const SizedBox(height: 20),
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      const SizedBox(height: 16),

                      // Coupons Content by State
                      if (state.isLoading && state.coupons.isEmpty)
                        _buildLoadingShimmer(isDark)
                      else if (state.isFailure && state.coupons.isEmpty)
                        _buildErrorState(context, state, isDark)
                      else if (state.isEmpty)
                        _buildEmptyState(context, state, isDark)
                      else
                        _buildCouponsList(context, state, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    CouponsState state,
    bool isDark,
  ) {
    final totalCountStr = state.totalCoupons > 0
        ? NumberFormat('#,###').format(state.totalCoupons)
        : (state.coupons.isNotEmpty ? state.coupons.length.toString() : '...');

    final kpis = [
      {
        'title': 'Total Coupons',
        'value': totalCountStr,
        'subtitle': 'Configured promotions',
        'icon': Icons.confirmation_number_rounded,
        'color': AppColors.primary,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Active Discounts',
        'value': state.coupons.isNotEmpty
            ? state.activeCouponsCount.toString()
            : '...',
        'subtitle': 'Ready for checkout',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Free Shipping',
        'value': state.coupons.isNotEmpty
            ? state.freeShippingCount.toString()
            : '...',
        'subtitle': 'Zero-shipping incentives',
        'icon': Icons.local_shipping_outlined,
        'color': AppColors.secondary,
        'gradient': AppColors.skyGradient,
      },
      {
        'title': 'Expired / Draft',
        'value': state.coupons.isNotEmpty
            ? state.expiredCouponsCount.toString()
            : '...',
        'subtitle': 'Past validity date',
        'icon': Icons.timer_off_outlined,
        'color': AppColors.warning,
        'gradient': AppColors.amberGradient,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final itemWidth = isWide
            ? (constraints.maxWidth - (3 * 16)) / 4
            : (constraints.maxWidth - 16) / 2;

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
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kpi['value'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildFilterBar(
    BuildContext context,
    CouponsState state,
    bool isDark,
  ) {
    final types = [
      {'label': 'All Coupons', 'value': 'all'},
      {'label': 'Percentage (%)', 'value': 'percent'},
      {'label': 'Fixed Cart (\$)', 'value': 'fixed_cart'},
      {'label': 'Fixed Product (\$/item)', 'value': 'fixed_product'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search coupons by code or description...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<CouponsBloc>()
                                  .add(const CouponsSearchChanged(''));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Reload coupons',
                  child: IconButton.filledTonal(
                    onPressed: () {
                      context
                          .read<CouponsBloc>()
                          .add(const CouponsRefreshed());
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: types.map((t) {
                  final isSelected = state.selectedType == t['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        context
                            .read<CouponsBloc>()
                            .add(CouponsTypeFilterChanged(t['value']!));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20), // One UI Pill
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          t['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
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

  Widget _buildCouponsList(
    BuildContext context,
    CouponsState state,
    bool isDark,
  ) {
    final coupons = state.coupons;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coupons.length,
          separatorBuilder: (_, _) => Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 16,
          ),
          itemBuilder: (context, index) {
            final coupon = coupons[index];
            return InkWell(
              onTap: () {
                CouponDetailsScreen.show(context, coupon: coupon);
              },
              borderRadius: BorderRadius.circular(16),
              child: _buildCouponItemTile(context, coupon, isDark),
            );
          },
        ),

        // Bottom Loading Indicator for Infinite Scrolling
        if (state.isLoadingMore) ...[
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading more coupons (Page ${state.currentPage + 1})...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (state.hasReachedMax && state.coupons.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'All ${state.coupons.length} coupons loaded',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCouponItemTile(
    BuildContext context,
    GETCouponReportModel coupon,
    bool isDark,
  ) {
    final isExpired = coupon.isExpired;
    final code = coupon.code?.toUpperCase() ?? 'CODE';

    final expiresText = coupon.parsedDateExpires != null
        ? 'Expires ${DateFormat('MMM dd, yyyy').format(coupon.parsedDateExpires!)}'
        : 'No expiration date';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ticket Voucher Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isExpired
                      ? AppColors.roseGradient
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16), // One UI Squircle
                  boxShadow: [
                    BoxShadow(
                      color: (isExpired ? AppColors.error : AppColors.primary)
                          .withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Code, Discount amount, type, restrictions
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Coupon Code Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                code,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: code));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Code $code copied'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(coupon.statusDisplayName, isExpired, isDark),
                        if (coupon.freeShipping == true)
                          _buildFreeShippingChip(isDark),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Discount Type & Amount
                    Row(
                      children: [
                        Text(
                          coupon.formattedDiscount,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isExpired
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ${coupon.discountTypeDisplayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Spend requirements & Usage
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              coupon.usageDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (coupon.minimumAmount != null &&
                            coupon.minimumAmount != '0.00' &&
                            coupon.minimumAmount != '0')
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 13,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                coupon.minSpendDisplay,
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
                    ),
                    if (isCompact) ...[
                      const SizedBox(height: 2),
                      Text(
                        expiresText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isExpired
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!isCompact) ...[
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      expiresText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isExpired
                            ? AppColors.error
                            : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coupon.isExpired ? 'Status: Expired' : 'Active promotion',
                      style: TextStyle(
                        fontSize: 11,
                        color: isExpired
                            ? AppColors.error
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status, bool isExpired, bool isDark) {
    Color bg;
    Color fg;

    if (isExpired) {
      bg = AppColors.error.withValues(alpha: 0.15);
      fg = AppColors.error;
    } else if (status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'publish') {
      bg = AppColors.success.withValues(alpha: 0.15);
      fg = AppColors.success;
    } else {
      bg = AppColors.warning.withValues(alpha: 0.15);
      fg = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildFreeShippingChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_rounded,
            size: 11,
            color: AppColors.secondary,
          ),
          SizedBox(width: 3),
          Text(
            'Free Shipping',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading coupons from WooCommerce...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CouponsState state,
    bool isDark,
  ) {
    final hasFilter =
        state.searchQuery.isNotEmpty || state.selectedType != 'all';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 38,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No coupons found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'No promotions match your search keyword or discount type filter.'
                  : 'There are currently no discount coupons created in this WooCommerce store.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<CouponsBloc>()
                      .add(const CouponsSearchChanged(''));
                  context
                      .read<CouponsBloc>()
                      .add(const CouponsTypeFilterChanged('all'));
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Reset Filters'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    CouponsState state,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load coupons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ??
                  'Network connection error while contacting WooCommerce API.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                context.read<CouponsBloc>().add(const CouponsFetchStarted());
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
