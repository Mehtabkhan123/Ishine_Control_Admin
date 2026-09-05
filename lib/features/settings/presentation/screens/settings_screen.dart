import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../layout/presentation/widgets/system_status_dialog.dart';
import '../../../reports/bloc/sales_report_bloc.dart';
import '../../../reports/bloc/sales_report_event.dart';
import '../../../reports/bloc/top_sellers_bloc.dart';
import '../../../reports/bloc/top_sellers_event.dart';
import '../../../system_status/bloc/system_status_bloc.dart';
import '../../../system_status/bloc/system_status_event.dart';
import '../../../system_status/bloc/system_status_state.dart';

/// Redesigned Settings Screen with Samsung One UI aesthetics.
/// Grouped squircle section cards for API credentials, theme selector,
/// server diagnostics, and store cache management.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings & Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Store API integration, appearance mode, and server diagnostics',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 1. Appearance & Theme Selection Card
          _buildThemeSection(context, isDark),
          const SizedBox(height: 20),

          // 2. WooCommerce REST API Credentials Card
          _buildApiConfigCard(context, isDark),
          const SizedBox(height: 20),

          // 3. System Diagnostics & Server Environment Card
          _buildSystemDiagnosticsCard(context, isDark),
          const SizedBox(height: 20),

          // 4. Cache & Maintenance Card
          _buildCacheMaintenanceCard(context, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Theme appearance selector card with One UI interactive cards.
  Widget _buildThemeSection(BuildContext context, bool isDark) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24), // One UI Squircle
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette_outlined, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Appearance & Theme Mode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your preferred visual theme for the executive admin panel.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 18),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  final itemWidth = isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildThemeOptionCard(
                        context: context,
                        title: 'Dark Mode',
                        subtitle: 'OLED Midnight Slate',
                        icon: Icons.dark_mode_rounded,
                        isSelected: themeMode == ThemeMode.dark,
                        onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.dark),
                        isDark: isDark,
                        width: itemWidth,
                      ),
                      _buildThemeOptionCard(
                        context: context,
                        title: 'Light Mode',
                        subtitle: 'Crisp Porcelain & Navy',
                        icon: Icons.light_mode_rounded,
                        isSelected: themeMode == ThemeMode.light,
                        onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.light),
                        isDark: isDark,
                        width: itemWidth,
                      ),
                      _buildThemeOptionCard(
                        context: context,
                        title: 'System Default',
                        subtitle: 'Follow OS Settings',
                        icon: Icons.settings_system_daydream_rounded,
                        isSelected: themeMode == ThemeMode.system,
                        onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.system),
                        isDark: isDark,
                        width: itemWidth,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required double width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primaryContainer)
              : (isDark ? AppColors.darkCard : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(18), // One UI Squircle
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// WooCommerce API Credentials & Configuration Card
  Widget _buildApiConfigCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.key_rounded, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'WooCommerce REST API Configuration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Active credentials and endpoint routes loaded securely from environment (.env).',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 12),

          _buildConfigItem(
            context: context,
            label: 'Store Base URL',
            value: EnvConfig.baseUrl.isNotEmpty ? EnvConfig.baseUrl : 'Not Configured',
            icon: Icons.link_rounded,
            isDark: isDark,
            canCopy: true,
          ),
          _buildConfigItem(
            context: context,
            label: 'Consumer Key',
            value: EnvConfig.maskedConsumerKey,
            icon: Icons.vpn_key_rounded,
            isDark: isDark,
            canCopy: false,
          ),
          _buildConfigItem(
            context: context,
            label: 'Consumer Secret',
            value: '••••••••••••••••••••••••••••••••',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            canCopy: false,
          ),
          _buildConfigItem(
            context: context,
            label: 'REST API Version',
            value: 'wp-json/wc/v3 (WooCommerce 3.5+)',
            icon: Icons.route_rounded,
            isDark: isDark,
            canCopy: false,
          ),
          _buildConfigItem(
            context: context,
            label: 'Configuration Driver',
            value: 'flutter_dotenv (.env asset file)',
            icon: Icons.description_outlined,
            isDark: isDark,
            canCopy: false,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigItem({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required bool canCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          if (canCopy) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Icon(
                Icons.copy_rounded,
                size: 14,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// System Diagnostics & Server Environment Card
  Widget _buildSystemDiagnosticsCard(BuildContext context, bool isDark) {
    return BlocBuilder<SystemStatusBloc, SystemStatusState>(
      builder: (context, state) {
        final status = state.status;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dns_rounded, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Store Health & Server Diagnostics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Live telemetric inspection of web server, database, PHP runtime, and SSL status.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              const SizedBox(height: 12),

              if (status != null) ...[
                _buildConfigItem(
                  context: context,
                  label: 'WooCommerce Version',
                  value: status.wcVersion,
                  icon: Icons.shopping_bag_outlined,
                  isDark: isDark,
                  canCopy: false,
                ),
                _buildConfigItem(
                  context: context,
                  label: 'WordPress Core',
                  value: status.wpVersion,
                  icon: Icons.wordpress_rounded,
                  isDark: isDark,
                  canCopy: false,
                ),
                _buildConfigItem(
                  context: context,
                  label: 'PHP Engine',
                  value: status.phpVersion,
                  icon: Icons.code_rounded,
                  isDark: isDark,
                  canCopy: false,
                ),
                _buildConfigItem(
                  context: context,
                  label: 'Response Latency',
                  value: '${status.responseTimeMs} ms',
                  icon: Icons.speed_rounded,
                  isDark: isDark,
                  canCopy: false,
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Diagnostics not currently loaded. Click "Ping Server Now" to query live metrics.',
                    style: TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: context.read<SystemStatusBloc>(),
                          child: const SystemStatusDialog(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.speed_rounded, size: 16),
                    label: const Text('Open Diagnostics Modal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<SystemStatusBloc>().add(const SystemStatusRefreshRequested());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pinging WooCommerce server...'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Ping Server Now'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Cache & Maintenance card
  Widget _buildCacheMaintenanceCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cleaning_services_rounded, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Data Synchronization & Cache Maintenance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Force fresh fetches from WooCommerce REST API and clear cached report state.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () {
                  context.read<SalesReportBloc>().add(const SalesReportRefreshRequested());
                  context.read<TopSellersBloc>().add(const TopSellersRefreshRequested());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('WooCommerce Reports Cache refreshed!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.cached_rounded, size: 16),
                label: const Text('Purge Reports Cache'),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  context.read<SystemStatusBloc>().add(const SystemStatusRefreshRequested());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Store Telemetry refreshed!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Store Telemetry'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
