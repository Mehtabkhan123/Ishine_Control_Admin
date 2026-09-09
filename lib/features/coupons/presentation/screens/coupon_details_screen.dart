import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/get_coupon_report_model.dart';
import '../widgets/delete_coupon_dialog.dart';
import 'edit_coupon_screen.dart';

/// Premium Samsung One UI 9-inspired Coupon Details Screen.
/// Displays detailed promotion terms, spend restrictions, usage limits,
/// product rules, and WooCommerce metadata for an individual coupon.
class CouponDetailsScreen extends StatefulWidget {
  final GETCouponReportModel coupon;

  const CouponDetailsScreen({
    super.key,
    required this.coupon,
  });

  static Route<GETCouponReportModel?> route({
    required GETCouponReportModel coupon,
  }) {
    return MaterialPageRoute<GETCouponReportModel?>(
      builder: (_) => CouponDetailsScreen(coupon: coupon),
    );
  }

  static Future<GETCouponReportModel?> show(
    BuildContext context, {
    required GETCouponReportModel coupon,
  }) async {
    return await Navigator.of(context)
        .push<GETCouponReportModel?>(route(coupon: coupon));
  }

  @override
  State<CouponDetailsScreen> createState() => _CouponDetailsScreenState();
}

class _CouponDetailsScreenState extends State<CouponDetailsScreen> {
  late GETCouponReportModel _coupon;

  GETCouponReportModel get coupon => _coupon;

  @override
  void initState() {
    super.initState();
    _coupon = widget.coupon;
  }

  Future<void> _openEditScreen() async {
    final updated = await EditCouponScreen.show(context, coupon: _coupon);
    if (updated != null && mounted) {
      setState(() {
        _coupon = updated;
      });
    }
  }

  Future<void> _confirmDeleteCoupon() async {
    if (_coupon.id == null) return;
    final deleted = await DeleteCouponDialog.show(
      context,
      couponId: _coupon.id!,
      couponCode: _coupon.code,
      discountDescription:
          '${_coupon.formattedDiscount} • ${_coupon.discountTypeDisplayName}',
    );

    if (deleted == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coupon Hero Voucher Card
            _buildVoucherCard(context, isDark),
            const SizedBox(height: 20),

            // Quick Metrics Tiles
            _buildQuickStats(context, isDark),
            const SizedBox(height: 20),

            // Responsive Two-Column or Single-Column for Restrictions & Limits
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildRestrictionsCard(context, isDark),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildUsageLimitsCard(context, isDark),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildRestrictionsCard(context, isDark),
                    const SizedBox(height: 20),
                    _buildUsageLimitsCard(context, isDark),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Metadata & System Card
            _buildMetadataCard(context, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back to Coupons',
        onPressed: () => Navigator.of(context).maybePop(_coupon),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded),
          tooltip: 'Edit Coupon',
          onPressed: _openEditScreen,
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
          ),
          tooltip: 'Delete Coupon',
          onPressed: _confirmDeleteCoupon,
        ),
        const SizedBox(width: 8),
      ],
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                coupon.code?.toUpperCase() ?? 'COUPON',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              if (coupon.code != null && coupon.code!.isNotEmpty)
                InkWell(
                  onTap: () => _copyToClipboard(
                    context,
                    coupon.code!,
                    'Coupon code copied',
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            'WooCommerce Coupon # ${coupon.id ?? 0}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, bool isDark) {
    final code = coupon.code?.toUpperCase() ?? 'PROMO';
    final isExpired = coupon.isExpired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final iconWidget = Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: isExpired
                  ? AppColors.roseGradient
                  : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(22), // One UI Squircle
              boxShadow: [
                BoxShadow(
                  color: (isExpired ? AppColors.error : AppColors.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.confirmation_number_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          );

          final detailsWidget = Column(
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment:
                    isCompact ? WrapAlignment.center : WrapAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          code,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _copyToClipboard(
                            context,
                            code,
                            'Coupon code $code copied',
                          ),
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(coupon.statusDisplayName, isExpired, isDark),
                  if (coupon.freeShipping == true)
                    _buildFreeShippingBadge(isDark),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _openEditScreen,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'EDIT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${coupon.formattedDiscount} • ${coupon.discountTypeDisplayName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isExpired ? AppColors.error : AppColors.primary,
                ),
              ),
              if (coupon.description != null &&
                  coupon.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  coupon.description!.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ],
          );

          if (isCompact) {
            return Column(
              children: [
                Center(child: iconWidget),
                const SizedBox(height: 16),
                detailsWidget,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              iconWidget,
              const SizedBox(width: 20),
              Expanded(child: detailsWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isExpired, bool isDark) {
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10), // One UI Pill
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildFreeShippingBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_shipping_rounded,
            size: 12,
            color: AppColors.secondary,
          ),
          SizedBox(width: 4),
          Text(
            'Free Shipping',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isDark) {
    final expiresDateStr = coupon.parsedDateExpires != null
        ? DateFormat('MMM dd, yyyy').format(coupon.parsedDateExpires!)
        : 'No expiration';

    final stats = [
      {
        'title': 'Discount Amount',
        'value': coupon.formattedDiscount,
        'subtitle': coupon.discountTypeDisplayName,
        'icon': Icons.discount_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'Usage Count',
        'value': coupon.usageDisplay,
        'subtitle': coupon.usageLimit != null ? 'Out of total limit' : 'Unlimited uses',
        'icon': Icons.repeat_rounded,
        'color': AppColors.success,
      },
      {
        'title': 'Expiration Date',
        'value': expiresDateStr,
        'subtitle': coupon.isExpired ? 'Promotion expired' : 'Valid promo period',
        'icon': Icons.event_rounded,
        'color': coupon.isExpired ? AppColors.error : AppColors.secondary,
      },
      {
        'title': 'Minimum Spend',
        'value': coupon.minSpendDisplay,
        'subtitle': coupon.maxSpendDisplay,
        'icon': Icons.shopping_cart_checkout_rounded,
        'color': AppColors.warning,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final itemWidth = isWide
            ? (constraints.maxWidth - (3 * 16)) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats.map((s) {
            final color = s['color'] as Color;

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20), // One UI Squircle
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
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
                          s['value'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          s['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 10,
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

  Widget _buildRestrictionsCard(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rule_folder_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Usage Restrictions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),
          _buildInfoRow('Minimum Spend', coupon.minSpendDisplay, isDark),
          _buildInfoRow('Maximum Spend', coupon.maxSpendDisplay, isDark),
          _buildInfoRow(
            'Individual Use Only',
            coupon.individualUse == true ? 'Yes (Cannot combine with other coupons)' : 'No',
            isDark,
          ),
          _buildInfoRow(
            'Exclude Sale Items',
            coupon.excludeSaleItems == true ? 'Yes' : 'No',
            isDark,
          ),
          _buildInfoRow(
            'Included Products',
            coupon.productIds != null && coupon.productIds!.isNotEmpty
                ? '${coupon.productIds!.length} products specified'
                : 'All products',
            isDark,
          ),
          _buildInfoRow(
            'Excluded Products',
            coupon.excludedProductIds != null && coupon.excludedProductIds!.isNotEmpty
                ? '${coupon.excludedProductIds!.length} products excluded'
                : 'None',
            isDark,
          ),
          _buildInfoRow(
            'Included Categories',
            coupon.productCategories != null && coupon.productCategories!.isNotEmpty
                ? '${coupon.productCategories!.length} categories specified'
                : 'All categories',
            isDark,
          ),
          _buildInfoRow(
            'Excluded Categories',
            coupon.excludedProductCategories != null &&
                    coupon.excludedProductCategories!.isNotEmpty
                ? '${coupon.excludedProductCategories!.length} categories excluded'
                : 'None',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageLimitsCard(BuildContext context, bool isDark) {
    final usedByCount = coupon.usedBy?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Usage Limits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),
          _buildInfoRow(
            'Usage Limit per Coupon',
            coupon.usageLimit != null && coupon.usageLimit.toString() != '0'
                ? '${coupon.usageLimit} uses'
                : 'Unlimited',
            isDark,
          ),
          _buildInfoRow(
            'Limit Usage to X Items',
            coupon.limitUsageToXItems != null &&
                    coupon.limitUsageToXItems.toString() != '0'
                ? '${coupon.limitUsageToXItems} items'
                : 'All qualifying items in cart',
            isDark,
          ),
          _buildInfoRow(
            'Usage Limit per User',
            coupon.usageLimitPerUser != null &&
                    coupon.usageLimitPerUser.toString() != '0'
                ? '${coupon.usageLimitPerUser} uses per customer'
                : 'Unlimited',
            isDark,
          ),
          _buildInfoRow('Total Times Used', '${coupon.usageCount ?? 0} times', isDark),
          _buildInfoRow('Unique Buyers Used', '$usedByCount customers', isDark),
          _buildInfoRow(
            'Free Shipping Flag',
            coupon.freeShipping == true ? 'Enabled' : 'Disabled',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, bool isDark) {
    final metaList = coupon.metaData ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.data_object_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'WooCommerce System Metadata',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),
          _buildInfoRow('Coupon ID', '#${coupon.id ?? 0}', isDark),
          _buildInfoRow('Date Created (GMT)', coupon.dateCreatedGmt ?? 'N/A', isDark),
          _buildInfoRow('Date Modified (GMT)', coupon.dateModifiedGmt ?? 'N/A', isDark),
          _buildInfoRow('Date Expires (GMT)', coupon.dateExpiresGmt ?? 'N/A', isDark),
          if (metaList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Custom Meta Fields (${metaList.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metaList.length > 8 ? 8 : metaList.length,
                separatorBuilder: (_, _) => Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = metaList[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.key ?? 'meta_key',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.value?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
