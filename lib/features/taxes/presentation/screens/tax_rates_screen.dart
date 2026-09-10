import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/tax_rates_bloc.dart';
import '../../bloc/tax_rates_event.dart';
import '../../bloc/tax_rates_state.dart';
import '../../data/models/get_tax_rates_model.dart';
import '../../data/repositories/taxes_repository.dart';
import '../widgets/tax_rate_card.dart';
import 'add_tax_rate_screen.dart';
import 'tax_rate_details_screen.dart';
import '../../../settings/presentation/screens/tax_settings_screen.dart';

/// Modern premium Tax Rates Screen with Samsung One UI 9 aesthetics.
/// Powered by WooCommerce REST API v3: `GET {{baseUrl}}/wp-json/wc/v3/taxes?per_page=50&page=1`
/// Supports infinite scrolling, pull-to-refresh, retry, class filtering, and dynamic tap navigation.
class TaxRatesScreen extends StatelessWidget {
  const TaxRatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<TaxRatesBloc>();
      return const _TaxRatesView();
    } catch (_) {
      TaxesRepository repository;
      try {
        repository = context.read<TaxesRepository>();
      } catch (_) {
        repository = TaxesRepository();
      }

      return BlocProvider<TaxRatesBloc>(
        create: (_) => TaxRatesBloc(repository: repository)
          ..add(const TaxRatesFetchStarted()),
        child: const _TaxRatesView(),
      );
    }
  }
}

class _TaxRatesView extends StatefulWidget {
  const _TaxRatesView();

  @override
  State<_TaxRatesView> createState() => _TaxRatesViewState();
}

class _TaxRatesViewState extends State<_TaxRatesView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  static const List<Map<String, String>> _taxClasses = [
    {'id': 'all', 'label': 'All Classes'},
    {'id': 'standard', 'label': 'Standard'},
    {'id': 'reduced-rate', 'label': 'Reduced Rate'},
    {'id': 'zero-rate', 'label': 'Zero Rate'},
  ];

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
      final bloc = context.read<TaxRatesBloc>();
      if (!bloc.state.hasReachedMax && !bloc.state.isLoadingMore) {
        bloc.add(const TaxRatesLoadMore());
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<TaxRatesBloc>().add(TaxRatesSearchChanged(query));
      }
    });
  }

  void _navigateToRateDetails(GetTaxRatesModel rate) {
    final rateId = rate.id ?? 0;
    TaxRateDetailsScreen.show(
      context,
      taxRateId: rateId,
      initialTaxRate: rate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        top: false,
        child: BlocConsumer<TaxRatesBloc, TaxRatesState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.taxRates.isNotEmpty) {
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
                final bloc = context.read<TaxRatesBloc>();
                bloc.add(const TaxRatesRefreshed());
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
                    // Top Header Section (One UI 9)
                    _buildHeaderSection(context, isDark, state),
                    const SizedBox(height: 20),

                    // KPI Metric Summary Cards
                    _buildKpiMetricsRow(context, isDark, state),
                    const SizedBox(height: 20),

                    // Tax Class Filter Tabs
                    _buildClassFilterTabs(context, isDark, state),
                    const SizedBox(height: 16),

                    // Search & Filter Toolbar
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
    TaxRatesState state,
  ) {
    final canPop = Navigator.of(context).canPop();
    final count = state.totalTaxRates > 0
        ? state.totalTaxRates
        : state.taxRates.length;

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
                  gradient: AppColors.emeraldGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
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
                          'Tax Rates',
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
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count Rates',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage regional sales tax rates, classes, priority & compounding',
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
                  context.read<TaxRatesBloc>().add(const TaxRatesRefreshed());
                },
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh Tax Rates',
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TaxSettingsScreen()),
            );
          },
          icon: const Icon(Icons.settings_suggest_rounded, size: 20),
          tooltip: 'Tax Calculation & Display Settings',
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => AddTaxRateScreen.show(context),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Add Tax Rate',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emeraldGradient.colors.first,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiMetricsRow(
    BuildContext context,
    bool isDark,
    TaxRatesState state,
  ) {
    final total = state.totalTaxRates > 0
        ? state.totalTaxRates
        : state.taxRates.length;

    final kpis = [
      {
        'title': 'Total Tax Rates',
        'value': '$total',
        'subtitle': 'Configured store rates',
        'icon': Icons.percent_rounded,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Standard Class',
        'value': '${state.standardRatesCount}',
        'subtitle': 'Default rate category',
        'icon': Icons.category_outlined,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Compound Taxes',
        'value': '${state.compoundRatesCount}',
        'subtitle': 'Tiered on top of taxes',
        'icon': Icons.layers_rounded,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'Applies to Shipping',
        'value': '${state.shippingRatesCount}',
        'subtitle': 'Taxed delivery rates',
        'icon': Icons.local_shipping_outlined,
        'gradient': AppColors.skyGradient,
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

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
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
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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
                            letterSpacing: -0.3,
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
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildClassFilterTabs(
    BuildContext context,
    bool isDark,
    TaxRatesState state,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _taxClasses.map((item) {
          final id = item['id']!;
          final label = item['label']!;
          final isSelected = state.selectedClass.toLowerCase() == id.toLowerCase();

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(label),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) {
                context
                    .read<TaxRatesBloc>()
                    .add(TaxRatesClassFilterChanged(id));
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
    TaxRatesState state,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search tax rates by name, rate, country, state, city...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateBody(
    BuildContext context,
    bool isDark,
    TaxRatesState state,
  ) {
    if (state.isLoading && state.taxRates.isEmpty) {
      return _buildLoadingShimmer(context, isDark);
    }

    if (state.isFailure && state.taxRates.isEmpty) {
      return _buildErrorCard(context, isDark, state);
    }

    if (state.isEmpty || (state.isSuccess && state.displayRates.isEmpty)) {
      return _buildEmptyState(context, isDark, state);
    }

    final rates = state.displayRates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ALL TAX RATES (${rates.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            Text(
              'Page ${state.currentPage} of ${state.totalPages}',
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
          itemCount: rates.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final rate = rates[index];
            return TaxRateCard(
              taxRate: rate,
              onTap: (r) => _navigateToRateDetails(r),
            );
          },
        ),

        if (state.isLoadingMore) ...[
          const SizedBox(height: 20),
          const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDark) {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder.withValues(alpha: 0.4)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder.withValues(alpha: 0.4)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
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
    TaxRatesState state,
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
      errorTitle = 'Failed to Load Tax Rates';
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
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
                  .read<TaxRatesBloc>()
                  .add(const TaxRatesRetryRequested());
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
    TaxRatesState state,
  ) {
    final isFiltering =
        state.searchQuery.isNotEmpty || state.selectedClass != 'all';

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
              Icons.receipt_long_outlined,
              color: AppColors.primaryLight,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltering
                ? 'No Tax Rates Found'
                : 'No Tax Rates Configured',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltering
                ? 'No tax rates match your current search and class filter. Try clearing filters.'
                : 'Your WooCommerce store does not have any tax rates configured yet. Configure tax rates in WooCommerce > Settings > Tax.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  if (isFiltering) {
                    _searchController.clear();
                    context
                        .read<TaxRatesBloc>()
                        .add(const TaxRatesClassFilterChanged('all'));
                    context
                        .read<TaxRatesBloc>()
                        .add(const TaxRatesSearchChanged(''));
                  } else {
                    context
                        .read<TaxRatesBloc>()
                        .add(const TaxRatesRefreshed());
                  }
                },
                icon: Icon(
                  isFiltering ? Icons.clear_rounded : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(isFiltering ? 'Clear Filter' : 'Refresh Rates'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (!isFiltering) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => AddTaxRateScreen.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create First Tax Rate'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emeraldGradient.colors.first,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
