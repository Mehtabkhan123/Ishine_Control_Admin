import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/sales_report_model.dart';

/// Samsung One UI-styled responsive statistics grid displaying all 10 key WooCommerce metrics:
/// Total Sales, Net Sales, Average Sales, Orders, Items, Tax, Shipping, Refunds, Discount, and Customers.
class SalesStatsGrid extends StatelessWidget {
  final GetSalesReportModel report;
  final String currencySymbol;

  const SalesStatsGrid({
    super.key,
    required this.report,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 5;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 850) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }

        final cards = [
          _StatData(
            title: 'Total Sales',
            value: '$currencySymbol${_formatCurrency(report.totalSalesValue)}',
            subtitle: 'Gross store revenue',
            icon: Icons.payments_rounded,
            color: AppColors.primary,
          ),
          _StatData(
            title: 'Net Sales',
            value: '$currencySymbol${_formatCurrency(report.netSalesValue)}',
            subtitle: 'Sales minus refunds/tax',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
          _StatData(
            title: 'Average Sales',
            value: '$currencySymbol${_formatCurrency(report.averageSalesValue)}',
            subtitle: 'Per period average',
            icon: Icons.trending_up_rounded,
            color: AppColors.secondary,
          ),
          _StatData(
            title: 'Orders',
            value: '${report.totalOrders ?? 0}',
            subtitle: 'Completed transactions',
            icon: Icons.receipt_long_rounded,
            color: AppColors.accent,
          ),
          _StatData(
            title: 'Items Sold',
            value: '${report.totalItems ?? 0}',
            subtitle: 'Product units',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF06B6D4), // Cyan 500
          ),
          _StatData(
            title: 'Total Tax',
            value: '$currencySymbol${_formatCurrency(report.totalTaxValue)}',
            subtitle: 'Collected sales tax',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFFF97316), // Orange 500
          ),
          _StatData(
            title: 'Shipping',
            value: '$currencySymbol${_formatCurrency(report.totalShippingValue)}',
            subtitle: 'Fulfillment charges',
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF6366F1), // Indigo 500
          ),
          _StatData(
            title: 'Refunds',
            value: '${report.totalRefunds ?? 0}',
            subtitle: 'Returned transactions',
            icon: Icons.assignment_return_rounded,
            color: AppColors.error,
          ),
          _StatData(
            title: 'Coupons / Discount',
            value: '$currencySymbol${_formatCurrency(report.totalDiscountValue)}',
            subtitle: 'Promotional savings',
            icon: Icons.discount_rounded,
            color: const Color(0xFFEC4899), // Pink 500
          ),
          _StatData(
            title: 'Customers',
            value: '${report.totalCustomers ?? 0}',
            subtitle: 'Unique purchasing accounts',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF14B8A6), // Teal 500
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: constraints.maxWidth < 600 ? 2.8 : 1.85,
          ),
          itemBuilder: (context, index) {
            return _OneUiStatCard(data: cards[index]);
          },
        );
      },
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return val.toStringAsFixed(2);
    }
    return val.toStringAsFixed(2);
  }
}

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _OneUiStatCard extends StatelessWidget {
  final _StatData data;

  const _OneUiStatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18), // Samsung One UI generous rounded corners
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pastel icon bubble
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
}
