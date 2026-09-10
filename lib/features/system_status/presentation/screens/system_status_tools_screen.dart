import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/system_status_tools_bloc.dart';
import '../../bloc/system_status_tools_event.dart';
import '../../bloc/system_status_tools_state.dart';
import '../../data/models/get_system_status_tools_model.dart';
import '../../data/repositories/system_status_repository.dart';
import '../widgets/system_status_tool_card.dart';

/// Screen displaying WooCommerce System Status Tools (`GET /wp-json/wc/v3/system_status/tools`).
/// Built with Samsung One UI 9 aesthetics, comprehensive state handling
/// (Loading, Success, Empty, Error), search filtering, and safe action execution.
class SystemStatusToolsScreen extends StatelessWidget {
  const SystemStatusToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final existingBloc = _tryGetBloc(context);

    if (existingBloc != null) {
      return const _SystemStatusToolsView();
    }

    return BlocProvider<SystemStatusToolsBloc>(
      create: (context) {
        final repo =
            _tryGetRepository(context) ?? SystemStatusRepository();
        return SystemStatusToolsBloc(repository: repo)
          ..add(const SystemStatusToolsFetchStarted());
      },
      child: const _SystemStatusToolsView(),
    );
  }

  SystemStatusToolsBloc? _tryGetBloc(BuildContext context) {
    try {
      return context.read<SystemStatusToolsBloc>();
    } catch (_) {
      return null;
    }
  }

  SystemStatusRepository? _tryGetRepository(BuildContext context) {
    try {
      return context.read<SystemStatusRepository>();
    } catch (_) {
      return null;
    }
  }
}

class _SystemStatusToolsView extends StatefulWidget {
  const _SystemStatusToolsView();

  @override
  State<_SystemStatusToolsView> createState() => _SystemStatusToolsViewState();
}

class _SystemStatusToolsViewState extends State<_SystemStatusToolsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';

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
          'System Status Tools',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Tools',
            onPressed: () {
              context
                  .read<SystemStatusToolsBloc>()
                  .add(const SystemStatusToolsRefreshRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<SystemStatusToolsBloc, SystemStatusToolsState>(
          listener: (context, state) {
            // Execution success toast
            if (state.executionSuccessMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.executionSuccessMessage!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
              context
                  .read<SystemStatusToolsBloc>()
                  .add(const SystemStatusToolsExecutionFeedbackCleared());
            }

            // Execution error toast
            if (state.executionErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.executionErrorMessage!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
              context
                  .read<SystemStatusToolsBloc>()
                  .add(const SystemStatusToolsExecutionFeedbackCleared());
            }

            // Fetch error notification if tools were already present
            if (state.isFailure &&
                state.errorMessage != null &&
                state.allTools.isNotEmpty) {
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
            final filteredByCategory =
                _filterByCategory(state.filteredTools, _selectedCategory);

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<SystemStatusToolsBloc>()
                    .add(const SystemStatusToolsRefreshRequested());
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
                          _buildOverviewBanner(context, state, isDark),
                          const SizedBox(height: 16),
                          _buildSearchBar(context, isDark),
                          const SizedBox(height: 12),
                          _buildCategoryChips(context, state, isDark),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // 2. Main Content Body by State
                  if (state.isLoading && state.allTools.isEmpty)
                    _buildLoadingSliver(isDark)
                  else if (state.isFailure && state.allTools.isEmpty)
                    _buildErrorSliver(context, state, isDark)
                  else if (filteredByCategory.isEmpty)
                    _buildEmptySliver(context, state, isDark)
                  else
                    _buildToolsListSliver(
                      filteredByCategory,
                      state.executingToolId,
                    ),

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

  /// Banner showing total tools count, executable tools count, and store health status.
  Widget _buildOverviewBanner(
    BuildContext context,
    SystemStatusToolsState state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Diagnostics & Maintenance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Execute native WooCommerce maintenance routines safely',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Metric Summary Pills
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  label: 'Total Tools',
                  value: state.isLoading && state.allTools.isEmpty
                      ? '...'
                      : '${state.totalCount}',
                  icon: Icons.handyman_outlined,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricPill(
                  label: 'Actions Available',
                  value: state.isLoading && state.allTools.isEmpty
                      ? '...'
                      : '${state.toolsWithActionsCount}',
                  icon: Icons.play_arrow_outlined,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricPill(
                  label: 'Filter Matches',
                  value: '${state.filteredCount}',
                  icon: Icons.filter_alt_outlined,
                  color: const Color(0xFF0EA5E9),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          context
              .read<SystemStatusToolsBloc>()
              .add(SystemStatusToolsSearchChanged(query));
        },
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search tools by name, action, ID, description...',
          hintStyle: TextStyle(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 13.5,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<SystemStatusToolsBloc>()
                        .add(const SystemStatusToolsSearchChanged(''));
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(
    BuildContext context,
    SystemStatusToolsState state,
    bool isDark,
  ) {
    final categories = [
      {'id': 'all', 'label': 'All Tools'},
      {'id': 'transient', 'label': 'Transients & Cache'},
      {'id': 'count', 'label': 'Recount & Counts'},
      {'id': 'session', 'label': 'Sessions & Auth'},
      {'id': 'database', 'label': 'Database & Tables'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat['label']!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurface,
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedCategory = cat['id']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<GetSystemStatusToolsModel> _filterByCategory(
    List<GetSystemStatusToolsModel> tools,
    String category,
  ) {
    if (category == 'all') return tools;

    return tools.where((t) {
      final text = '${t.id?.toLowerCase()} ${t.name?.toLowerCase()} ${t.action?.toLowerCase()}';
      if (category == 'transient') {
        return text.contains('transient') || text.contains('cache');
      } else if (category == 'count') {
        return text.contains('recount') || text.contains('count');
      } else if (category == 'session') {
        return text.contains('session') || text.contains('role') || text.contains('capabilit');
      } else if (category == 'database') {
        return text.contains('table') || text.contains('lookup') || text.contains('database');
      }
      return true;
    }).toList();
  }

  Widget _buildLoadingSliver(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 130,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 180,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: 6,
        ),
      ),
    );
  }

  Widget _buildErrorSliver(
    BuildContext context,
    SystemStatusToolsState state,
    bool isDark,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to Load System Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage ??
                    'Unable to retrieve WooCommerce system status tools. Please check your connection and credentials.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              if (state.errorCode != null) ...[
                const SizedBox(height: 6),
                Text(
                  'HTTP Status Code: ${state.errorCode}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<SystemStatusToolsBloc>()
                      .add(const SystemStatusToolsFetchStarted(forceRefresh: true));
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySliver(
    BuildContext context,
    SystemStatusToolsState state,
    bool isDark,
  ) {
    final hasQuery = state.searchQuery.isNotEmpty || _selectedCategory != 'all';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.build_circle_outlined,
                size: 38,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasQuery ? 'No Tools Match Your Criteria' : 'No System Tools Found',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Try searching for a different keyword or reset active category filters.'
                  : 'Your WooCommerce store did not return any system tools.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategory = 'all';
                  });
                  context
                      .read<SystemStatusToolsBloc>()
                      .add(const SystemStatusToolsSearchChanged(''));
                },
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Reset Filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolsListSliver(
    List<GetSystemStatusToolsModel> tools,
    String? executingToolId,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tool = tools[index];
            final isExecuting = executingToolId == tool.id;

            return SystemStatusToolCard(
              tool: tool,
              isExecuting: isExecuting,
              onExecute: () {
                if (tool.id != null) {
                  context
                      .read<SystemStatusToolsBloc>()
                      .add(SystemStatusToolExecuteRequested(toolId: tool.id!));
                }
              },
            );
          },
          childCount: tools.length,
        ),
      ),
    );
  }
}
