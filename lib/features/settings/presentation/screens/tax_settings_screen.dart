import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/tax_settings_bloc.dart';
import '../../bloc/tax_settings_event.dart';
import '../../bloc/tax_settings_state.dart';
import '../../data/models/get_tax_settings_model.dart';
import '../../data/repositories/tax_settings_repository.dart';
import '../widgets/tax_setting_card.dart';

/// Screen displaying WooCommerce Tax Settings (`GET /wp-json/wc/v3/settings/tax`).
/// Built with Samsung One UI 9 aesthetics, comprehensive state handling
/// (Loading, Success, Empty, Error), search filtering, and type chips.
class TaxSettingsScreen extends StatelessWidget {
  const TaxSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final existingBloc = _tryGetBloc(context);

    if (existingBloc != null) {
      return const _TaxSettingsView();
    }

    return BlocProvider<TaxSettingsBloc>(
      create: (context) {
        final repo = _tryGetRepository(context) ?? TaxSettingsRepository();
        return TaxSettingsBloc(repository: repo)
          ..add(const TaxSettingsFetchStarted());
      },
      child: const _TaxSettingsView(),
    );
  }

  TaxSettingsBloc? _tryGetBloc(BuildContext context) {
    try {
      return context.read<TaxSettingsBloc>();
    } catch (_) {
      return null;
    }
  }

  TaxSettingsRepository? _tryGetRepository(BuildContext context) {
    try {
      return context.read<TaxSettingsRepository>();
    } catch (_) {
      return null;
    }
  }
}

class _TaxSettingsView extends StatefulWidget {
  const _TaxSettingsView();

  @override
  State<_TaxSettingsView> createState() => _TaxSettingsViewState();
}

class _TaxSettingsViewState extends State<_TaxSettingsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Tax Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Tax Settings',
            onPressed: () {
              context
                  .read<TaxSettingsBloc>()
                  .add(const TaxSettingsRefreshRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<TaxSettingsBloc, TaxSettingsState>(
          listener: (context, state) {
            if (state.isFailure && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TaxSettingsBloc>()
                    .add(const TaxSettingsRefreshRequested());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Header Banner & Search Controls
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStoreOverviewCard(context, state, isDark),
                          const SizedBox(height: 16),
                          _buildSearchBar(context, isDark),
                          const SizedBox(height: 12),
                          _buildTypeFilterChips(context, state, isDark),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // 2. Main Content Body by State
                  if (state.isLoading && state.allSettings.isEmpty)
                    _buildLoadingSliver(isDark)
                  else if (state.isFailure && state.allSettings.isEmpty)
                    _buildErrorSliver(context, state, isDark)
                  else if (state.filteredSettings.isEmpty)
                    _buildEmptySliver(context, state, isDark)
                  else
                    _buildSettingsListSliver(state.filteredSettings),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Overview Card showing live summaries (Prices Include Tax, Calculation Base, Display in Shop, Display in Cart)
  Widget _buildStoreOverviewCard(
    BuildContext context,
    TaxSettingsState state,
    bool isDark,
  ) {
    final pricesIncludeTaxSetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_prices_include_tax',
      orElse: () => GetTextSettingsModel(),
    );
    final taxBasedOnSetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_tax_based_on',
      orElse: () => GetTextSettingsModel(),
    );
    final displayShopSetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_tax_display_shop',
      orElse: () => GetTextSettingsModel(),
    );
    final displayCartSetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_tax_display_cart',
      orElse: () => GetTextSettingsModel(),
    );

    final pricesIncludeTax = pricesIncludeTaxSetting.boolValue;
    final taxBasedOn = taxBasedOnSetting.displayOptionLabel.isNotEmpty
        ? taxBasedOnSetting.displayOptionLabel
        : (taxBasedOnSetting.stringValue.isNotEmpty
            ? taxBasedOnSetting.stringValue
            : 'Customer shipping');
    final displayShop = displayShopSetting.displayOptionLabel.isNotEmpty
        ? displayShopSetting.displayOptionLabel
        : (displayShopSetting.stringValue.isNotEmpty
            ? displayShopSetting.stringValue
            : 'Excl. tax');
    final displayCart = displayCartSetting.displayOptionLabel.isNotEmpty
        ? displayCartSetting.displayOptionLabel
        : (displayCartSetting.stringValue.isNotEmpty
            ? displayCartSetting.stringValue
            : 'Excl. tax');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tax Calculation & Display Rules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'API endpoint: /wp-json/wc/v3/settings/tax',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.darkTextMuted,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.totalCount} Settings',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildOverviewMetric(
                label: 'Prices Include Tax',
                value: pricesIncludeTax ? 'Yes (Inclusive)' : 'No (Exclusive)',
                icon: Icons.price_check_rounded,
                color: pricesIncludeTax ? AppColors.success : AppColors.warning,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildOverviewMetric(
                label: 'Calculate Tax Based On',
                value: taxBasedOn,
                icon: Icons.location_on_outlined,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildOverviewMetric(
                label: 'Shop Price Display',
                value: displayShop,
                icon: Icons.storefront_rounded,
                color: AppColors.secondary,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildOverviewMetric(
                label: 'Cart Price Display',
                value: displayCart,
                icon: Icons.shopping_cart_outlined,
                color: Colors.teal,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search Bar with instant debounce-friendly query dispatch
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            context
                .read<TaxSettingsBloc>()
                .add(TaxSettingsSearchChanged(val));
          },
          decoration: InputDecoration(
            hintText: 'Search tax settings by label, ID, or value...',
            hintStyle: TextStyle(
              fontSize: 13,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      context
                          .read<TaxSettingsBloc>()
                          .add(const TaxSettingsSearchChanged(''));
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  /// Setting Type Filter Chips
  Widget _buildTypeFilterChips(
    BuildContext context,
    TaxSettingsState state,
    bool isDark,
  ) {
    final types = state.availableTypes;
    if (types.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: state.selectedTypeFilter == null,
              label: Text('All (${state.totalCount})'),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.selectedTypeFilter == null
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: state.selectedTypeFilter == null
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ),
              selectedColor: AppColors.success,
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              onSelected: (_) {
                context
                    .read<TaxSettingsBloc>()
                    .add(const TaxSettingsTypeFilterChanged(null));
              },
            ),
          ),
          // Individual Type Chips
          ...types.map((type) {
            final isSelected = state.selectedTypeFilter == type;
            final count =
                state.allSettings.where((s) => s.type?.toLowerCase() == type).length;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text('${type.toUpperCase()} ($count)'),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                selectedColor: AppColors.success,
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                onSelected: (_) {
                  context.read<TaxSettingsBloc>().add(
                        TaxSettingsTypeFilterChanged(
                          isSelected ? null : type,
                        ),
                      );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Loading Shimmer / Skeletons
  Widget _buildLoadingSliver(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 140,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.success.withValues(alpha: 0.6),
                ),
              ),
            );
          },
          childCount: 4,
        ),
      ),
    );
  }

  /// Error State View with Retry
  Widget _buildErrorSliver(
    BuildContext context,
    TaxSettingsState state,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load Tax Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ??
                    'An error occurred communicating with the WooCommerce REST API.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.errorCode != null) ...[
                const SizedBox(height: 4),
                Text(
                  'HTTP Status Code: ${state.errorCode}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  context
                      .read<TaxSettingsBloc>()
                      .add(const TaxSettingsRefreshRequested());
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Query'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty State View
  Widget _buildEmptySliver(
    BuildContext context,
    TaxSettingsState state,
    bool isDark,
  ) {
    final isFiltering =
        state.searchQuery.isNotEmpty || state.selectedTypeFilter != null;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Icon(
                isFiltering
                    ? Icons.filter_alt_off_rounded
                    : Icons.receipt_long_outlined,
                size: 36,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? 'No matching tax settings found'
                  : 'No tax settings available',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltering
                  ? 'Try searching with a different term or resetting the type filter.'
                  : 'WooCommerce returned an empty settings list for /settings/tax.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isFiltering)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<TaxSettingsBloc>()
                      .add(const TaxSettingsSearchChanged(''));
                  context
                      .read<TaxSettingsBloc>()
                      .add(const TaxSettingsTypeFilterChanged(null));
                  setState(() {});
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Clear Filters'),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  context
                      .read<TaxSettingsBloc>()
                      .add(const TaxSettingsRefreshRequested());
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Tax Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// List of Settings Sliver
  Widget _buildSettingsListSliver(List<GetTextSettingsModel> settings) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final setting = settings[index];
            return TaxSettingCard(
              key: ValueKey(setting.id ?? 'tax_setting_$index'),
              setting: setting,
            );
          },
          childCount: settings.length,
        ),
      ),
    );
  }
}
