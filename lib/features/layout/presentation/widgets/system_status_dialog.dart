import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../system_status/bloc/system_status_bloc.dart';
import '../../../system_status/bloc/system_status_event.dart';
import '../../../system_status/bloc/system_status_state.dart';

/// Modal dialog displaying comprehensive WooCommerce system status diagnostics
/// formatted with Samsung One UI aesthetics.
class SystemStatusDialog extends StatelessWidget {
  const SystemStatusDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 640),
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<SystemStatusBloc, SystemStatusState>(
          builder: (context, state) {
            final status = state.status;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
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
                            'System Health & Diagnostics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live WooCommerce REST API v3 Environment',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 16),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildDialogBody(context, state, isDark),
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 14),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'API: v3 • Key: ${EnvConfig.maskedConsumerKey}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                    Row(
                      children: [
                        if (status != null)
                          TextButton.icon(
                            onPressed: () {
                              final text = '''
=== WooCommerce System Status ===
Site URL: ${status.siteUrl.isNotEmpty ? status.siteUrl : EnvConfig.baseUrl}
WooCommerce: ${status.wcVersion}
WordPress: ${status.wpVersion}
PHP Version: ${status.phpVersion}
Server: ${status.serverInfo}
Database: ${status.mysqlVersion}
SSL: ${status.isSecure ? 'Active' : 'Disabled'}
Response Time: ${status.responseTimeMs} ms
Currency: ${status.currency} (${status.currencySymbol})
Active Plugins: ${status.activePluginsCount}
Theme: ${status.themeName} ${status.themeVersion}
                              ''';
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Diagnostics copied to clipboard!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            label: const Text('Copy Report'),
                          ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDialogBody(BuildContext context, SystemStatusState state, bool isDark) {
    if (state is SystemStatusLoading && state.status == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(height: 16),
              Text(
                'Connecting to WooCommerce API...',
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

    if (state is SystemStatusFailure && state.status == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Connection Failed',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                state.errorMessage,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              if (state.statusCode != null) ...[
                const SizedBox(height: 8),
                Text(
                  'HTTP Status Code: ${state.statusCode}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Base URL: ${EnvConfig.baseUrl}',
                style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted),
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: () {
                  context.read<SystemStatusBloc>().add(const SystemStatusRefreshRequested());
                },
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    final status = state.status;
    if (status == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Store overview banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.siteUrl.isNotEmpty ? status.siteUrl : EnvConfig.baseUrl,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Store is responsive • Ping: ${status.responseTimeMs} ms',
                      style: const TextStyle(fontSize: 11, color: AppColors.successDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Grid of details
        _buildInfoTile(context, 'WooCommerce Version', status.wcVersion, Icons.shopping_bag_outlined, isDark),
        _buildInfoTile(context, 'WordPress Version', status.wpVersion, Icons.wordpress_rounded, isDark),
        _buildInfoTile(context, 'PHP Engine Version', status.phpVersion, Icons.code_rounded, isDark),
        _buildInfoTile(context, 'Database Engine', status.mysqlVersion, Icons.storage_rounded, isDark),
        _buildInfoTile(context, 'Web Server Info', status.serverInfo, Icons.computer_rounded, isDark),
        _buildInfoTile(context, 'Active Theme', '${status.themeName} ${status.themeVersion}', Icons.palette_outlined, isDark),
        _buildInfoTile(context, 'Active Plugins', '${status.activePluginsCount} installed', Icons.extension_outlined, isDark),
        _buildInfoTile(
          context,
          'SSL / HTTPS',
          status.isSecure ? 'Active & Secure' : 'Insecure (HTTP)',
          status.isSecure ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
          isDark,
          statusColor: status.isSecure ? AppColors.success : AppColors.warning,
        ),
        _buildInfoTile(context, 'Store Currency', '${status.currency} (${status.currencySymbol})', Icons.monetization_on_outlined, isDark),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 12),
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
              color: statusColor ?? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
