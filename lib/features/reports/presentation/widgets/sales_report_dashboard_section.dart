import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../system_status/bloc/system_status_bloc.dart';
import '../../bloc/sales_report_bloc.dart';
import '../../bloc/sales_report_event.dart';
import '../../bloc/sales_report_state.dart';
import 'sales_stats_grid.dart';
import 'sales_trend_chart.dart';

/// Premium Samsung One UI-inspired Sales Report Dashboard Section.
/// Connects to [SalesReportBloc] and displays real-time statistics, period filter pills,
/// loading/empty/error states, and the responsive Bézier sales trend chart.
class SalesReportDashboardSection extends StatelessWidget {
  const SalesReportDashboardSection({super.key});

  static const List<Map<String, String>> _periodTabs = [
    {'label': 'This Month', 'value': 'month'},
    {'label': 'This Week', 'value': 'week'},
    {'label': 'Last Month', 'value': 'last_month'},
    {'label': 'This Year', 'value': 'year'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Detect store currency symbol from SystemStatusBloc if available, fallback to '$'
    final systemStatus = context.watch<SystemStatusBloc>().state.status;
    final currencySymbol = systemStatus?.currencySymbol.isNotEmpty == true
        ? systemStatus!.currencySymbol
        : '\$';

    return BlocBuilder<SalesReportBloc, SalesReportState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24), // Samsung One UI signature squircle
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Title and Period Filter Pills
              _buildHeader(context, state, isDark),
              const SizedBox(height: 20),

              // Body based on state
              _buildBody(context, state, isDark, currencySymbol),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, SalesReportState state, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        final titleWidget = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColors.primaryLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sales & Revenue Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live WooCommerce v3 reports/sales feed',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        );

        final periodPills = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Period selector tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30), // One UI pill container
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _periodTabs.map((tab) {
                  final isSelected = state.period == tab['value'];
                  return InkWell(
                    onTap: () {
                      context
                          .read<SalesReportBloc>()
                          .add(SalesReportPeriodChanged(tab['value']!));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tab['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 8),

            // Refresh Button
            IconButton.filledTonal(
              tooltip: 'Sync Latest Sales',
              onPressed: () {
                context.read<SalesReportBloc>().add(const SalesReportRefreshRequested());
              },
              icon: state is SalesReportLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: periodPills,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleWidget,
            periodPills,
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SalesReportState state, bool isDark, String currencySymbol) {
    if (state is SalesReportLoading && state.report == null) {
      return _buildLoadingShimmer(isDark);
    }

    if (state is SalesReportFailure && state.report == null) {
      return _buildErrorCard(context, state, isDark);
    }

    if (state is SalesReportEmpty) {
      return _buildEmptyState(context, isDark);
    }

    final report = state.report;
    if (report == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 10 Key Metric Cards
        SalesStatsGrid(
          report: report,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 24),

        // Sales Trend Performance Chart Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: AppColors.primaryLight, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Sales Performance Trend',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (state is SalesReportSuccess)
                    Text(
                      'Synced at ${DateFormat('HH:mm:ss').format(state.lastUpdated)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 14),

              // Interactive Bézier Chart
              SalesTrendChart(
                totals: report.totals ?? {},
                totalsGroupedBy: report.totalsGroupedBy,
                currencySymbol: currencySymbol,
                height: 240,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
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
              'Fetching live sales analytics from WooCommerce...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, SalesReportFailure state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Text(
                state.isTimeout
                    ? 'Connection Timed Out'
                    : (state.isNetworkError ? 'Network Connection Error' : 'Failed to Load Sales Report'),
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          if (state.statusCode != null) ...[
            const SizedBox(height: 4),
            Text(
              'HTTP Status: ${state.statusCode}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              context.read<SalesReportBloc>().add(const SalesReportRefreshRequested());
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Sales Query'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkBackground : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.query_stats_rounded,
                size: 40,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Sales Activity Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No sales or orders were recorded in your WooCommerce store for this period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: () {
                context.read<SalesReportBloc>().add(const SalesReportRefreshRequested());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Re-check Store Feed'),
            ),
          ],
        ),
      ),
    );
  }
}
