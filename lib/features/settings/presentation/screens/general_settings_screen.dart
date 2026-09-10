import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/general_settings_bloc.dart';
import '../../bloc/general_settings_event.dart';
import '../../bloc/general_settings_state.dart';
import '../../data/models/get_general_settings_model.dart';
import '../../data/repositories/general_settings_repository.dart';
import '../widgets/general_setting_card.dart';

/// Screen displaying WooCommerce General Settings (`GET /wp-json/wc/v3/settings/general`).
/// Built with Samsung One UI 9 aesthetics, comprehensive state handling
/// (Loading, Success, Empty, Error), search filtering, and type chips.
class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If the BLoC is already provided in ancestor context, use it;
    // otherwise, instantiate it from repository or default.
    final existingBloc = _tryGetBloc(context);

    if (existingBloc != null) {
      return const _GeneralSettingsView();
    }

    return BlocProvider<GeneralSettingsBloc>(
      create: (context) {
        final repo = _tryGetRepository(context) ?? GeneralSettingsRepository();
        return GeneralSettingsBloc(repository: repo)
          ..add(const GeneralSettingsFetchStarted());
      },
      child: const _GeneralSettingsView(),
    );
  }

  GeneralSettingsBloc? _tryGetBloc(BuildContext context) {
    try {
      return context.read<GeneralSettingsBloc>();
    } catch (_) {
      return null;
    }
  }

  GeneralSettingsRepository? _tryGetRepository(BuildContext context) {
    try {
      return context.read<GeneralSettingsRepository>();
    } catch (_) {
      return null;
    }
  }
}

class _GeneralSettingsView extends StatefulWidget {
  const _GeneralSettingsView();

  @override
  State<_GeneralSettingsView> createState() => _GeneralSettingsViewState();
}

class _GeneralSettingsViewState extends State<_GeneralSettingsView> {
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
          'General Store Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh General Settings',
            onPressed: () {
              context
                  .read<GeneralSettingsBloc>()
                  .add(const GeneralSettingsRefreshRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<GeneralSettingsBloc, GeneralSettingsState>(
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
                    .read<GeneralSettingsBloc>()
                    .add(const GeneralSettingsRefreshRequested());
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

  /// Store Overview Card showing live summaries (Currency, Tax, Location)
  Widget _buildStoreOverviewCard(
    BuildContext context,
    GeneralSettingsState state,
    bool isDark,
  ) {
    final currencySetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_currency',
      orElse: () => GetGeneralSettingsModel(),
    );
    final countrySetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_default_country',
      orElse: () => GetGeneralSettingsModel(),
    );
    final taxSetting = state.allSettings.firstWhere(
      (s) => s.id == 'woocommerce_calc_taxes',
      orElse: () => GetGeneralSettingsModel(),
    );

    final currency = currencySetting.stringValue.isNotEmpty
        ? currencySetting.stringValue
        : 'USD';
    final location = countrySetting.displayOptionLabel.isNotEmpty
        ? countrySetting.displayOptionLabel
        : (countrySetting.stringValue.isNotEmpty
            ? countrySetting.stringValue
            : 'Default Location');
    final taxesEnabled = taxSetting.boolValue;

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
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
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
                      'Store Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'API endpoint: /wp-json/wc/v3/settings/general',
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.totalCount} Settings',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
                label: 'Base Currency',
                value: currency,
                icon: Icons.attach_money_rounded,
                color: AppColors.primary,
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildOverviewMetric(
                label: 'Tax Calculations',
                value: taxesEnabled ? 'Active' : 'Disabled',
                icon: Icons.percent_rounded,
                color: taxesEnabled ? AppColors.success : AppColors.warning,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 14,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Store Base: $location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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
                .read<GeneralSettingsBloc>()
                .add(GeneralSettingsSearchChanged(val));
          },
          decoration: InputDecoration(
            hintText: 'Search settings by name, ID, or value...',
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
                          .read<GeneralSettingsBloc>()
                          .add(const GeneralSettingsSearchChanged(''));
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
    GeneralSettingsState state,
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
              selectedColor: AppColors.primary,
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
                    .read<GeneralSettingsBloc>()
                    .add(const GeneralSettingsTypeFilterChanged(null));
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
                selectedColor: AppColors.primary,
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
                  context.read<GeneralSettingsBloc>().add(
                        GeneralSettingsTypeFilterChanged(
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
                  color: AppColors.primary.withValues(alpha: 0.6),
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
    GeneralSettingsState state,
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
                'Failed to Load General Settings',
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
                      .read<GeneralSettingsBloc>()
                      .add(const GeneralSettingsRefreshRequested());
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Query'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
    GeneralSettingsState state,
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
                    : Icons.tune_rounded,
                size: 36,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering
                  ? 'No matching settings found'
                  : 'No general settings available',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltering
                  ? 'Try searching with a different term or resetting the type filter.'
                  : 'WooCommerce returned an empty settings list for /settings/general.',
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
                      .read<GeneralSettingsBloc>()
                      .add(const GeneralSettingsSearchChanged(''));
                  context
                      .read<GeneralSettingsBloc>()
                      .add(const GeneralSettingsTypeFilterChanged(null));
                  setState(() {});
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Clear Filters'),
              )
            else
              FilledButton.icon(
                onPressed: () {
                  context
                      .read<GeneralSettingsBloc>()
                      .add(const GeneralSettingsRefreshRequested());
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Store Settings'),
              ),
          ],
        ),
      ),
    );
  }

  /// List of Settings Sliver
  Widget _buildSettingsListSliver(List<GetGeneralSettingsModel> settings) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final setting = settings[index];
            return GeneralSettingCard(
              key: ValueKey(setting.id ?? 'setting_$index'),
              setting: setting,
            );
          },
          childCount: settings.length,
        ),
      ),
    );
  }
}
