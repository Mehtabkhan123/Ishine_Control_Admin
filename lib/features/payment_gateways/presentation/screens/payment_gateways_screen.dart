import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/payment_gateways_bloc.dart';
import '../../bloc/payment_gateways_event.dart';
import '../../bloc/payment_gateways_state.dart';
import '../../data/models/get_payment_gateways_model.dart';
import '../../data/repositories/payment_gateways_repository.dart';
import '../widgets/payment_gateway_card.dart';
import 'payment_gateway_details_screen.dart';

/// Modern premium Payment Gateways Screen with Samsung One UI 9 aesthetics.
/// Powered by WooCommerce REST API v3: `GET {{baseUrl}}/wp-json/wc/v3/payment_gateways`
/// Supports pull-to-refresh, retry, status filtering, live search, and gateway inspection.
class PaymentGatewaysScreen extends StatelessWidget {
  const PaymentGatewaysScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: SafeArea(
            child: PaymentGatewaysScreen(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      context.read<PaymentGatewaysBloc>();
      return const _PaymentGatewaysView();
    } catch (_) {
      PaymentGatewaysRepository repository;
      try {
        repository = context.read<PaymentGatewaysRepository>();
      } catch (_) {
        repository = PaymentGatewaysRepository();
      }

      return BlocProvider<PaymentGatewaysBloc>(
        create: (_) => PaymentGatewaysBloc(repository: repository)
          ..add(const PaymentGatewaysFetchStarted()),
        child: const _PaymentGatewaysView(),
      );
    }
  }
}

class _PaymentGatewaysView extends StatefulWidget {
  const _PaymentGatewaysView();

  @override
  State<_PaymentGatewaysView> createState() => _PaymentGatewaysViewState();
}

class _PaymentGatewaysViewState extends State<_PaymentGatewaysView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const List<Map<String, String>> _statusFilters = [
    {'id': 'all', 'label': 'All Gateways'},
    {'id': 'enabled', 'label': 'Enabled'},
    {'id': 'needs_setup', 'label': 'Needs Setup'},
    {'id': 'disabled', 'label': 'Disabled'},
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<PaymentGatewaysBloc>().add(PaymentGatewaysSearchChanged(query));
      }
    });
  }

  void _navigateToGatewayDetails(GetPaymentGatewaysModel gateway) {
    PaymentGatewayDetailsScreen.show(context, gateway: gateway);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        top: false,
        child: BlocConsumer<PaymentGatewaysBloc, PaymentGatewaysState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.gateways.isNotEmpty) {
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
                final bloc = context.read<PaymentGatewaysBloc>();
                bloc.add(const PaymentGatewaysRefreshed());
                await bloc.stream.firstWhere((s) => !s.isLoading);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header Section (One UI 9)
                    _buildHeaderSection(context, isDark, state),
                    const SizedBox(height: 20),

                    // KPI Metric Summary Cards
                    _buildKpiMetricsRow(context, isDark, state),
                    const SizedBox(height: 20),

                    // Status Filter Tabs
                    _buildFilterTabs(context, isDark, state),
                    const SizedBox(height: 16),

                    // Search Toolbar
                    _buildSearchToolbar(context, isDark, state),
                    const SizedBox(height: 24),

                    // Body based on state: Loading, Error, Empty, or List
                    _buildStateBody(context, isDark, state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    final canPop = Navigator.of(context).canPop();
    final count = state.totalCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (canPop) ...[
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Payment Gateways',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count Gateways',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage checkout payment methods, processors & configurations',
                      style: TextStyle(
                        fontSize: 12,
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
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: state.isLoading
              ? null
              : () {
                  context
                      .read<PaymentGatewaysBloc>()
                      .add(const PaymentGatewaysRefreshed());
                },
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh Payment Gateways',
        ),
      ],
    );
  }

  Widget _buildKpiMetricsRow(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    final kpis = [
      {
        'title': 'Total Gateways',
        'value': '${state.totalCount}',
        'subtitle': 'Installed checkout processors',
        'icon': Icons.payment_rounded,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Enabled',
        'value': '${state.enabledCount}',
        'subtitle': 'Actively accepting payments',
        'icon': Icons.check_circle_rounded,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Needs Setup',
        'value': '${state.needsSetupCount}',
        'subtitle': 'Configuration incomplete',
        'icon': Icons.warning_amber_rounded,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'Disabled',
        'value': '${state.disabledCount}',
        'subtitle': 'Inactive checkout methods',
        'icon': Icons.block_rounded,
        'gradient': LinearGradient(
          colors: [
            isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ],
        ),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;
        final cardWidth = isNarrow
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis.map((kpi) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: kpi['gradient'] as LinearGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        kpi['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kpi['value'] as String,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            kpi['title'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((tab) {
          final isSelected = state.selectedFilter == tab['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(tab['label']!),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              onSelected: (_) {
                context
                    .read<PaymentGatewaysBloc>()
                    .add(PaymentGatewaysFilterChanged(tab['id']!));
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchToolbar(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    return Material(
      color: Colors.transparent,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search gateways by title, method or ID...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<PaymentGatewaysBloc>()
                        .add(const PaymentGatewaysSearchChanged(''));
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateBody(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    if (state.isLoading && state.gateways.isEmpty) {
      return _buildLoadingShimmer(context, isDark);
    }

    if (state.isFailure && state.gateways.isEmpty) {
      return _buildErrorCard(context, isDark, state);
    }

    if (state.isEmpty || (state.isSuccess && state.displayGateways.isEmpty)) {
      return _buildEmptyState(context, isDark, state);
    }

    final gateways = state.displayGateways;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAYMENT METHODS (${gateways.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            if (state.searchQuery.isNotEmpty || state.selectedFilter != 'all')
              Text(
                'Filtered from ${state.totalCount} total',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gateways.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final gateway = gateways[index];
            return PaymentGatewayCard(
              gateway: gateway,
              onTap: _navigateToGatewayDetails,
              onViewDetails: _navigateToGatewayDetails,
            );
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDark) {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 160,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.6)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 220,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.4)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    final isAuth = state.isAuthError;
    final isNet = state.isNetworkError;

    IconData errorIcon;
    String errorTitle;
    String errorDescription;

    if (isAuth) {
      errorIcon = Icons.lock_outline_rounded;
      errorTitle = 'Authentication Failed';
      errorDescription =
          'WooCommerce rejected the credentials. Verify that your Consumer Key and Secret have Read permissions in WordPress.';
    } else if (isNet) {
      errorIcon = Icons.wifi_off_rounded;
      errorTitle = 'Network Connection Error';
      errorDescription =
          'Could not establish a connection to your WooCommerce store. Verify store URL and internet connectivity.';
    } else {
      errorIcon = Icons.error_outline_rounded;
      errorTitle = 'Failed to Load Payment Gateways';
      errorDescription = state.errorMessage ??
          'An unexpected error occurred while communicating with the WooCommerce REST API.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(errorIcon, color: AppColors.error, size: 36),
          ),
          const SizedBox(height: 18),
          Text(
            errorTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            errorDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          if (state.errorStatusCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'HTTP Status: ${state.errorStatusCode}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              context
                  .read<PaymentGatewaysBloc>()
                  .add(const PaymentGatewaysRetryRequested());
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry Connection'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    PaymentGatewaysState state,
  ) {
    final isFiltering =
        state.searchQuery.isNotEmpty || state.selectedFilter != 'all';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.primaryLight,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltering
                ? 'No Gateways Matching Filters'
                : 'No Payment Gateways Configured',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltering
                ? 'No payment gateways match your current search and status filters. Try clearing your filters.'
                : 'Your WooCommerce store does not have any payment gateways configured yet. Set up payment methods in WooCommerce > Settings > Payments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              if (isFiltering) {
                _searchController.clear();
                context
                    .read<PaymentGatewaysBloc>()
                    .add(const PaymentGatewaysFilterChanged('all'));
                context
                    .read<PaymentGatewaysBloc>()
                    .add(const PaymentGatewaysSearchChanged(''));
              } else {
                context
                    .read<PaymentGatewaysBloc>()
                    .add(const PaymentGatewaysRefreshed());
              }
            },
            icon: Icon(
              isFiltering ? Icons.clear_rounded : Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(isFiltering ? 'Clear Filter' : 'Refresh Gateways'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
