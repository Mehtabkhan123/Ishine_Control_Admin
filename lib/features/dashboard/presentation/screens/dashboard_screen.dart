import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../layout/presentation/widgets/system_status_dialog.dart';
import '../../../reports/presentation/widgets/sales_report_dashboard_section.dart';
import '../../../reports/presentation/widgets/top_sellers_dashboard_section.dart';
import '../../../system_status/bloc/system_status_bloc.dart';
import '../../../system_status/bloc/system_status_event.dart';
import '../../../system_status/bloc/system_status_state.dart';

/// Redesigned Dashboard Screen with Samsung One UI-inspired e-commerce aesthetics.
/// Displays live WooCommerce store metrics, sales analytics, top sellers,
/// store diagnostics, and quick executive action cards.
class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Executive Hero Welcome Banner
          _buildHeroBanner(context, isDark),
          const SizedBox(height: 24),

          // Live System Environment & Status Grid
          _buildSystemEnvironmentCard(context, isDark),
          const SizedBox(height: 24),

          // Real WooCommerce Sales Report & Analytics Section
          const SalesReportDashboardSection(),
          const SizedBox(height: 24),

          // Real WooCommerce Top Sellers Report & Ranking Section
          const TopSellersDashboardSection(),
          const SizedBox(height: 24),

          // Quick Management Hub & Action Cards
          _buildQuickActionHub(context, isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Executive hero banner with personalized greeting, store domain, and live status.
  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E1B4B), // Deep indigo
                  const Color(0xFF182238),
                ]
              : [
                  const Color(0xFFEEF2FF),
                  const Color(0xFFE0E7FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCompact) ...[
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.primary.withValues(alpha: 0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: const AppBrandLogo(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'LIVE STORE DASHBOARD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: AppColors.primaryLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE STORE DASHBOARD',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '$greeting, Administrator 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor real-time sales revenue, inventory performance, and WooCommerce system health.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Store URL Chip with Copy Action
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      if (EnvConfig.baseUrl.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: EnvConfig.baseUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Store URL copied!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link_rounded, size: 14, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Text(
                            EnvConfig.baseUrl.isNotEmpty ? EnvConfig.baseUrl : 'Not Configured',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 13, color: AppColors.success),
                        SizedBox(width: 6),
                        Text(
                          'REST API v3 Ready',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

          if (isCompact) {
            return content;
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 24),
              // Glowing Visual Emblem with Noback-preview Logo
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(24), // One UI squircle
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : AppColors.primary.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const AppBrandLogo(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Live System Environment & Status strip with One UI squircle metric cards.
  Widget _buildSystemEnvironmentCard(BuildContext context, bool isDark) {
    return BlocBuilder<SystemStatusBloc, SystemStatusState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Store Environment & Health',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live WooCommerce & WordPress diagnostic telemetry',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: context.read<SystemStatusBloc>(),
                          child: const SystemStatusDialog(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Full Diagnostics'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              const SizedBox(height: 18),

              // Body Content
              if (state is SystemStatusLoading && state.status == null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Connecting to WooCommerce store...',
                          style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (state is SystemStatusFailure && state.status == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connection Diagnostic Error',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.errorMessage,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          context.read<SystemStatusBloc>().add(const SystemStatusRefreshRequested());
                        },
                        child: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                ),
              ] else if (state.status case final status?) ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final itemWidth = isWide ? (constraints.maxWidth - (5 * 14)) / 6 : (constraints.maxWidth - 14) / 2;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _buildMetricPill(
                          'WooCommerce',
                          status.wcVersion,
                          Icons.shopping_bag_outlined,
                          AppColors.primary,
                          isDark,
                          itemWidth,
                        ),
                        _buildMetricPill(
                          'WordPress Core',
                          status.wpVersion,
                          Icons.wordpress_rounded,
                          AppColors.info,
                          isDark,
                          itemWidth,
                        ),
                        _buildMetricPill(
                          'PHP Engine',
                          status.phpVersion,
                          Icons.code_rounded,
                          AppColors.secondary,
                          isDark,
                          itemWidth,
                        ),
                        _buildMetricPill(
                          'Ping Latency',
                          '${status.responseTimeMs} ms',
                          Icons.speed_rounded,
                          status.responseTimeMs < 500 ? AppColors.success : AppColors.warning,
                          isDark,
                          itemWidth,
                        ),
                        _buildMetricPill(
                          'HTTPS Security',
                          status.isSecure ? 'Active SSL' : 'Disabled',
                          status.isSecure ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                          status.isSecure ? AppColors.success : AppColors.warning,
                          isDark,
                          itemWidth,
                        ),
                        _buildMetricPill(
                          'Active Plugins',
                          '${status.activePluginsCount}',
                          Icons.extension_outlined,
                          AppColors.accent,
                          isDark,
                          itemWidth,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricPill(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16), // One UI squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick action hub with interactive management shortcuts.
  Widget _buildQuickActionHub(BuildContext context, bool isDark) {
    final actions = [
      {
        'title': 'Orders Center',
        'subtitle': 'Manage and track fulfillment',
        'icon': Icons.receipt_long_rounded,
        'gradient': AppColors.brandGradient,
        'tabIndex': 1,
      },
      {
        'title': 'Product Catalog',
        'subtitle': 'Inventory and stock levels',
        'icon': Icons.inventory_2_rounded,
        'gradient': AppColors.skyGradient,
        'tabIndex': 2,
      },
      {
        'title': 'Customers CRM',
        'subtitle': 'Profiles and buyer history',
        'icon': Icons.people_alt_rounded,
        'gradient': AppColors.purpleGradient,
        'tabIndex': 3,
      },
      {
        'title': 'Coupons & Promos',
        'subtitle': 'Vouchers & discount rules',
        'icon': Icons.confirmation_number_rounded,
        'gradient': AppColors.amberGradient,
        'tabIndex': 4,
      },
      {
        'title': 'Store Settings',
        'subtitle': 'API configuration & diagnostics',
        'icon': Icons.settings_rounded,
        'gradient': AppColors.emeraldGradient,
        'tabIndex': 5,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.hub_rounded,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Management Hub',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Direct shortcuts to core e-commerce administration sections',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final itemWidth = isWide ? (constraints.maxWidth - (3 * 16)) / 4 : (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: actions.map((act) {
                  final gradient = act['gradient'] as LinearGradient;
                  final tabIdx = act['tabIndex'] as int;

                  return InkWell(
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(tabIdx);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: itemWidth,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(16), // One UI squircle
                              boxShadow: [
                                BoxShadow(
                                  color: gradient.colors.first.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              act['icon'] as IconData,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  act['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
