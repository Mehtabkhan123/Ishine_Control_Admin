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
import '../../../shipping/presentation/screens/shipping_zones_screen.dart';
import '../../../taxes/presentation/screens/tax_rates_screen.dart';
import '../../../payment_gateways/presentation/screens/payment_gateways_screen.dart';
import '../../../system_status/presentation/screens/system_status_tools_screen.dart';
import 'general_settings_screen.dart';
import 'product_settings_screen.dart';
import 'tax_settings_screen.dart';

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

          // 4. WooCommerce General Store Settings Card
          _buildGeneralSettingsCard(context, isDark),
          const SizedBox(height: 20),

          // 5. WooCommerce Product Settings Card
          _buildProductSettingsCard(context, isDark),
          const SizedBox(height: 20),

          // 6. Shipping & Delivery Configuration Card
          _buildShippingZonesCard(context, isDark),
          const SizedBox(height: 20),

          // 5. Tax Rates & Fiscal Rules Card
          _buildTaxRatesCard(context, isDark),
          const SizedBox(height: 20),

          // 6. WooCommerce Tax Calculation & Display Settings Card
          _buildTaxSettingsCard(context, isDark),
          const SizedBox(height: 20),

          // 7. Payment Gateways & Checkout Methods Card
          _buildPaymentGatewaysCard(context, isDark),
          const SizedBox(height: 20),

          // 8. WooCommerce System Status Tools Card
          _buildSystemStatusToolsCard(context, isDark),
          const SizedBox(height: 20),

          // 9. Cache & Maintenance Card
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
            label: 'Media Upload Pipeline',
            value: EnvConfig.hasWordpressAppPassword
                ? 'WordPress Core API (${EnvConfig.wordpressUsername})'
                : 'Smart Cloud Staging + Auto Sideload (Zero Config)',
            icon: Icons.cloud_upload_outlined,
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
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showWordpressConfigDialog(context),
              icon: const Icon(Icons.vpn_key_rounded, size: 16),
              label: Text(
                EnvConfig.hasWordpressAppPassword
                    ? 'Update WordPress Credentials'
                    : 'Configure WordPress Credentials',
              ),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
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
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SystemStatusToolsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.build_circle_rounded, size: 16),
                    label: const Text('System Status Tools'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
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

  void _showWordpressConfigDialog(BuildContext context) {
    final userController = TextEditingController(text: EnvConfig.wordpressUsername);
    final passController = TextEditingController(text: EnvConfig.wordpressAppPassword);
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'WordPress Credentials',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct media uploads to /wp-json/wp/v2/media require a WordPress admin username and Application Password.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to get an Application Password:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '1. Log into WP Admin > Users > Profile\n'
                          '2. Scroll down to "Application Passwords"\n'
                          '3. Type "Admin App" and click "Add New"\n'
                          '4. Copy the generated 24-character password and paste below.',
                          style: TextStyle(fontSize: 11, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: userController,
                    decoration: InputDecoration(
                      labelText: 'WordPress Username / Email',
                      hintText: 'e.g. admin or username',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Application Password',
                      hintText: 'xxxx xxxx xxxx xxxx xxxx xxxx',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => obscure = !obscure),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final u = userController.text.trim();
                  final p = passController.text.trim();
                  if (u.isNotEmpty && p.isNotEmpty) {
                    EnvConfig.setWordpressCredentials(username: u, appPassword: p);
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    Navigator.of(dialogCtx).pop();
                    messenger?.showSnackBar(
                      const SnackBar(
                        content: Text('WordPress credentials saved!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Credentials'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Shipping & Delivery zones card with direct navigation
  Widget _buildShippingZonesCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Shipping & Delivery Zones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure regional delivery boundaries, evaluation priority, and WooCommerce shipping rates.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShippingZonesScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage Shipping Zones'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tax Rates & Fiscal Rules card with direct navigation
  Widget _buildTaxRatesCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tax Rates & Fiscal Rules',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Manage regional tax calculations, compound taxes, priorities, and WooCommerce tax classes.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaxRatesScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage Tax Rates'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Payment Gateways card with direct navigation
  Widget _buildPaymentGatewaysCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Payment Gateways & Checkout Methods',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure payment processors, direct bank transfers (BACS), Cash on Delivery, Stripe, and checkout options.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaymentGatewaysScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage Payment Gateways'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WooCommerce General Store Settings card with direct navigation
  Widget _buildGeneralSettingsCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'WooCommerce General Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Store address, base currency, currency formatting, tax calculations, and core WooCommerce store configurations.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GeneralSettingsScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage General Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WooCommerce Product Settings card with direct navigation
  Widget _buildProductSettingsCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'WooCommerce Product Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Units of measurement (weights & dimensions), stock management, inventory thresholds, product reviews, and downloadable product settings.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductSettingsScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage Product Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WooCommerce Tax Settings card with direct navigation
  Widget _buildTaxSettingsCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'WooCommerce Tax Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Prices entered with tax, calculation address bases, tax rounding rules, tax classes, and display modes for shop and checkout.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TaxSettingsScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage Tax Settings'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// WooCommerce System Status Tools card with direct navigation
  Widget _buildSystemStatusToolsCard(BuildContext context, bool isDark) {
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'WooCommerce System Status Tools',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Execute store maintenance routines: clear transients, clear expired download permissions, recount terms, reset user roles, and regenerate product lookup tables.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SystemStatusToolsScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage System Tools'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
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
