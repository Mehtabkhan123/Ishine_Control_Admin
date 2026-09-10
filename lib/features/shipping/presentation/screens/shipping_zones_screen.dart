import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/shipping_zones_bloc.dart';
import '../../bloc/shipping_zones_event.dart';
import '../../bloc/shipping_zones_state.dart';
import '../../data/models/shipping_zones_model.dart';
import '../../data/repositories/shipping_repository.dart';
import '../widgets/shipping_zone_card.dart';
import 'shipping_zone_details_screen.dart';

/// Modern premium Shipping Zones Screen with Samsung One UI 9 aesthetics.
/// Powered by WooCommerce REST API v3: `GET {{baseUrl}}/wp-json/wc/v3/shipping/zones`
/// Displays each zone's ID, name, order, handles loading, network, auth & error states,
/// supports pull-to-refresh, retry, and dynamic navigation on zone tap.
class ShippingZonesScreen extends StatelessWidget {
  const ShippingZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<ShippingZonesBloc>();
      return const _ShippingZonesView();
    } catch (_) {
      ShippingRepository repository;
      try {
        repository = context.read<ShippingRepository>();
      } catch (_) {
        repository = ShippingRepository();
      }

      return BlocProvider<ShippingZonesBloc>(
        create: (_) => ShippingZonesBloc(repository: repository)
          ..add(const ShippingZonesFetchStarted()),
        child: const _ShippingZonesView(),
      );
    }
  }
}

class _ShippingZonesView extends StatefulWidget {
  const _ShippingZonesView();

  @override
  State<_ShippingZonesView> createState() => _ShippingZonesViewState();
}

class _ShippingZonesViewState extends State<_ShippingZonesView> {
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
      final bloc = context.read<ShippingZonesBloc>();
      if (!bloc.state.hasReachedMax && !bloc.state.isLoadingMore) {
        bloc.add(const ShippingZonesLoadMore());
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<ShippingZonesBloc>().add(ShippingZonesSearchChanged(query));
      }
    });
  }

  void _navigateToZoneDetails(ShippingZonesModel zone) {
    final zoneId = zone.id ?? 0;
    ShippingZoneDetailsScreen.show(
      context,
      zoneId: zoneId,
      initialZone: zone,
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
        child: BlocConsumer<ShippingZonesBloc, ShippingZonesState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.zones.isNotEmpty) {
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
                final bloc = context.read<ShippingZonesBloc>();
                bloc.add(const ShippingZonesRefreshed());
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

  /// One UI 9 Header with Squircle Icon, Title, Subtitle, and Refresh Action
  Widget _buildHeaderSection(
    BuildContext context,
    bool isDark,
    ShippingZonesState state,
  ) {
    final canPop = Navigator.of(context).canPop();

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
                  gradient: AppColors.skyGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
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
                          'Shipping Zones',
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
                            '${state.totalZones > 0 ? state.totalZones : state.zones.length} Zones',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage delivery regions, rates & evaluation priority via WooCommerce REST API v3',
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
        // Live Refresh Button
        IconButton.filledTonal(
          onPressed: state.isLoading
              ? null
              : () {
                  context
                      .read<ShippingZonesBloc>()
                      .add(const ShippingZonesRefreshed());
                },
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh Shipping Zones',
        ),
      ],
    );
  }

  /// KPI Row showing Total Zones, Custom Zones, and Order details
  Widget _buildKpiMetricsRow(
    BuildContext context,
    bool isDark,
    ShippingZonesState state,
  ) {
    final total = state.totalZones > 0 ? state.totalZones : state.zones.length;
    final customCount = state.customZonesCount;
    final hasDefault = state.defaultZone != null;

    final kpis = [
      {
        'title': 'Total Shipping Zones',
        'value': '$total',
        'subtitle': 'Configured store zones',
        'icon': Icons.map_outlined,
        'gradient': AppColors.skyGradient,
      },
      {
        'title': 'Custom Regional Zones',
        'subtitle': 'Targeted geo-locations',
        'value': '$customCount',
        'icon': Icons.location_on_outlined,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Default Fallback Zone',
        'value': hasDefault ? 'Active' : 'Global',
        'subtitle': 'Locations not covered',
        'icon': Icons.public_rounded,
        'gradient': AppColors.purpleGradient,
      },
      {
        'title': 'Evaluation Order',
        'value': 'Active',
        'subtitle': 'Priority sequenced order',
        'icon': Icons.low_priority_rounded,
        'gradient': AppColors.emeraldGradient,
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

  /// Search & Filter Bar with One UI Squircle styling
  Widget _buildSearchToolbar(
    BuildContext context,
    bool isDark,
    ShippingZonesState state,
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
                  hintText: 'Search shipping zones by name, ID, or order...',
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

  /// Dispatches to the appropriate UI based on state
  Widget _buildStateBody(
    BuildContext context,
    bool isDark,
    ShippingZonesState state,
  ) {
    // 1. Initial / Loading State (when no zones cached yet)
    if (state.isLoading && state.zones.isEmpty) {
      return _buildLoadingShimmer(context, isDark);
    }

    // 2. Failure State (when no zones cached)
    if (state.isFailure && state.zones.isEmpty) {
      return _buildErrorCard(context, isDark, state);
    }

    // 3. Empty State (zones is empty and not loading)
    if (state.isEmpty || (state.isSuccess && state.displayZones.isEmpty)) {
      return _buildEmptyState(context, isDark, state);
    }

    // 4. Success State (with loaded zones list)
    final zones = state.displayZones;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section subhead
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ALL SHIPPING ZONES (${zones.length})',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            Text(
              'Tap zone to inspect dynamic ID',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Shipping Zone Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: zones.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final zone = zones[index];
            return ShippingZoneCard(
              zone: zone,
              onTap: (z) => _navigateToZoneDetails(z),
            );
          },
        ),

        // Bottom pagination loader
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

  /// Shimmer loading placeholder cards
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
                width: 52,
                height: 52,
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

  /// Error state card with specific guidance for network, auth, and API issues
  Widget _buildErrorCard(
    BuildContext context,
    bool isDark,
    ShippingZonesState state,
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
          'WooCommerce rejected the API credentials. Check that your Consumer Key and Secret have Read permissions in WordPress.';
    } else if (isNet) {
      errorIcon = Icons.wifi_off_rounded;
      errorTitle = 'Network Connection Error';
      errorDescription =
          'Could not establish a connection to your WooCommerce store. Verify server URL and internet connectivity.';
    } else {
      errorIcon = Icons.error_outline_rounded;
      errorTitle = 'Failed to Load Shipping Zones';
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
                  .read<ShippingZonesBloc>()
                  .add(const ShippingZonesRetryRequested());
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

  /// Empty state display
  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    ShippingZonesState state,
  ) {
    final isFiltering = state.searchQuery.isNotEmpty;

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
              Icons.local_shipping_outlined,
              color: AppColors.primaryLight,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltering
                ? 'No Shipping Zones Found'
                : 'No Shipping Zones Configured',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltering
                ? 'No zones match your query "${state.searchQuery}". Try a different keyword.'
                : 'Your WooCommerce store does not have any custom shipping zones configured yet. The default "Locations not covered by your other zones" is active for all orders.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              if (isFiltering) {
                _searchController.clear();
                _onSearchChanged('');
              } else {
                context
                    .read<ShippingZonesBloc>()
                    .add(const ShippingZonesRefreshed());
              }
            },
            icon: Icon(
              isFiltering ? Icons.clear_rounded : Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(isFiltering ? 'Clear Filter' : 'Refresh Zones'),
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
