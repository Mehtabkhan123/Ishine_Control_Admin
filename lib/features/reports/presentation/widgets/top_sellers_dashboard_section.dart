import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/top_sellers_bloc.dart';
import '../../bloc/top_sellers_event.dart';
import '../../bloc/top_sellers_state.dart';
import '../../data/models/top_seller_model.dart';

/// Premium Samsung One UI-inspired Top Sellers Dashboard Section.
/// Connects to [TopSellersBloc] to display ranked bestsellers from WooCommerce.
class TopSellersDashboardSection extends StatelessWidget {
  const TopSellersDashboardSection({super.key});

  static const List<Map<String, String>> _periods = [
    {'label': 'This Month', 'value': 'month'},
    {'label': 'This Week', 'value': 'week'},
    {'label': 'Last Month', 'value': 'last_month'},
    {'label': 'This Year', 'value': 'year'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TopSellersBloc, TopSellersState>(
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
              // Header with Title & Period Filter Pills
              _buildHeader(context, state, isDark),
              const SizedBox(height: 20),

              // Content according to State
              _buildBody(context, state, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TopSellersState state, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        final titleWidget = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top-Selling Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live WooCommerce v3 reports/top_sellers feed',
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
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _periods.map((tab) {
                  final isSelected = state.period == tab['value'];
                  return InkWell(
                    onTap: () {
                      context
                          .read<TopSellersBloc>()
                          .add(TopSellersPeriodChanged(tab['value']!));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.3),
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
              tooltip: 'Sync Top Sellers',
              onPressed: () {
                context.read<TopSellersBloc>().add(const TopSellersRefreshRequested());
              },
              icon: state is TopSellersLoading
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

  Widget _buildBody(BuildContext context, TopSellersState state, bool isDark) {
    if (state is TopSellersLoading && (state.items == null || state.items!.isEmpty)) {
      return _buildLoadingState(isDark);
    }

    if (state is TopSellersFailure && (state.items == null || state.items!.isEmpty)) {
      return _buildErrorState(context, state, isDark);
    }

    if (state is TopSellersEmpty) {
      return _buildEmptyState(context, isDark, state.period);
    }

    final items = state.items ?? [];
    if (items.isEmpty) {
      return _buildEmptyState(context, isDark, state.period);
    }

    final maxQuantity = items.map((e) => e.quantity).fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top summary metrics banner
        if (state is TopSellersSuccess)
          _buildSummaryBar(state, isDark),
        const SizedBox(height: 16),

        // Product Rankings List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {

            final item = items[index];
            final rank = index + 1;
            return _TopSellerCard(
              item: item,
              rank: rank,
              maxQuantity: maxQuantity,
              isDark: isDark,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryBar(TopSellersSuccess state, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                '${state.items.length} Products Ranked',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.darkTextMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${NumberFormat.decimalPattern().format(state.totalQuantitySold)} total units sold',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          Text(
            'Synced at ${DateFormat('HH:mm:ss').format(state.lastUpdated)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
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
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Querying WooCommerce top sellers...',
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

  Widget _buildEmptyState(BuildContext context, bool isDark, String currentPeriod) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
                color: isDark ? AppColors.darkBackground : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sell_outlined,
                size: 38,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Top Sellers for "${_periodLabel(currentPeriod)}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'There were zero orders logged in this specific timeframe. Check broader periods to view overall historical bestsellers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (currentPeriod != 'year')
                  FilledButton.tonalIcon(
                    onPressed: () {
                      context.read<TopSellersBloc>().add(const TopSellersPeriodChanged('year'));
                    },
                    icon: const Icon(Icons.date_range_rounded, size: 16),
                    label: const Text('View All-Year Top Sellers'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<TopSellersBloc>().add(const TopSellersRefreshRequested());
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, TopSellersFailure state, bool isDark) {
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
                    ? 'Top Sellers Request Timed Out'
                    : (state.isNetworkError ? 'Network Connection Error' : 'Failed to Load Top Sellers'),
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
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              context.read<TopSellersBloc>().add(const TopSellersRefreshRequested());
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry Top Sellers'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static String _periodLabel(String period) {
    switch (period) {
      case 'week':
        return 'This Week';
      case 'last_month':
        return 'Last Month';
      case 'year':
        return 'This Year';
      case 'month':
      default:
        return 'This Month';
    }
  }
}

class _TopSellerCard extends StatelessWidget {
  final TopSellerModel item;
  final int rank;
  final int maxQuantity;
  final bool isDark;

  const _TopSellerCard({
    required this.item,
    required this.rank,
    required this.maxQuantity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Relative sales volume percentage against the #1 top seller
    final relativeRatio = maxQuantity > 0 ? (item.quantity / maxQuantity).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank Medal Badge
              _buildRankBadge(rank),
              const SizedBox(width: 14),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBackground
                                : const Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: #${item.productId}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity Sold Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.decimalPattern().format(item.quantity),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'units sold',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visual Relative Volume Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: relativeRatio,
              minHeight: 5,
              backgroundColor: isDark
                  ? AppColors.darkBackground
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRankColor(rank),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor;
    Color textColor;
    IconData? rankIcon;

    switch (rank) {
      case 1:
        badgeColor = const Color(0xFFFFD700); // Gold
        textColor = const Color(0xFF7A5900);
        rankIcon = Icons.military_tech_rounded;
        break;
      case 2:
        badgeColor = const Color(0xFFE0E0E0); // Silver
        textColor = const Color(0xFF424242);
        rankIcon = Icons.military_tech_rounded;
        break;
      case 3:
        badgeColor = const Color(0xFFCD7F32); // Bronze
        textColor = Colors.white;
        rankIcon = Icons.military_tech_rounded;
        break;
      default:
        badgeColor = isDark ? AppColors.darkBackground : const Color(0xFFE2E8F0);
        textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        rankIcon = null;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12), // Squircle rank badge
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: rankIcon != null
          ? Icon(rankIcon, size: 20, color: textColor)
          : Text(
              '#$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFB800);
      case 2:
        return const Color(0xFF9E9E9E);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.accent;
    }
  }
}
