import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/get_system_status_tools_model.dart';

/// Samsung One UI 9 styled card displaying a WooCommerce System Status Tool.
/// Presents tool name, ID, description, action availability, and provides
/// a safe confirmation dialog before executing actions.
class SystemStatusToolCard extends StatelessWidget {
  final GetSystemStatusToolsModel tool;
  final bool isExecuting;
  final VoidCallback? onExecute;

  const SystemStatusToolCard({
    super.key,
    required this.tool,
    this.isExecuting = false,
    this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = _getToolIcon(tool.id ?? '', tool.name ?? '');
    final isDestructive = _isPotentiallyDestructive(tool.id ?? '', tool.action ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tool Icon, Name, ID & Action Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIconBox(iconData, isDestructive, isDark),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tool.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildActionBadge(isDestructive, isDark),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ID with copy chip
                        if (tool.id != null)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: tool.id!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied Tool ID: ${tool.id}'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tool.id!,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description
              if (tool.description != null && tool.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground.withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorderSubtle
                          : AppColors.lightBorderSubtle,
                    ),
                  ),
                  child: Text(
                    tool.displayDescription,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],

              // Footer: Action Button & Links
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Href info badge if present
                  if (tool.firstHref.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'v3/system_status/tools/${tool.id}',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  const SizedBox(width: 8),

                  // Execute Action Button
                  if (tool.hasAction)
                    _buildExecuteButton(context, isDestructive, isDark)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorderSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Read Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, bool isDestructive, bool isDark) {
    final gradientColors = isDestructive
        ? [const Color(0xFFF97316), const Color(0xFFEA580C)] // Amber/Orange
        : [AppColors.primaryLight, AppColors.primary]; // Indigo

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildActionBadge(bool isDestructive, bool isDark) {
    if (!tool.hasAction) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Info',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      );
    }

    final color = isDestructive ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDestructive ? Icons.warning_amber_rounded : Icons.flash_on_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            'Executable',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteButton(
    BuildContext context,
    bool isDestructive,
    bool isDark,
  ) {
    if (isExecuting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Running...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    final buttonColor = isDestructive ? const Color(0xFFD97706) : AppColors.primary;

    return ElevatedButton.icon(
      onPressed: () => _confirmAndExecute(context),
      icon: const Icon(Icons.play_arrow_rounded, size: 17),
      label: Text(
        tool.displayAction,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Displays a safe Samsung One UI styled confirmation dialog.
  Future<void> _confirmAndExecute(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDestructive =
        _isPotentiallyDestructive(tool.id ?? '', tool.action ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDestructive ? AppColors.warning : AppColors.primary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDestructive
                      ? Icons.warning_amber_rounded
                      : Icons.help_outline_rounded,
                  color: isDestructive ? AppColors.warning : AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirm Execution',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to run this system tool?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Action: ${tool.displayAction}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDestructive
                            ? (isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFB45309))
                            : AppColors.primary,
                      ),
                    ),
                    if (tool.description != null &&
                        tool.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        tool.displayDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isDestructive) ...[
                const SizedBox(height: 10),
                Text(
                  'Note: This action modifies or clears store cached data.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive
                    ? const Color(0xFFD97706)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Run ${tool.displayAction}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onExecute?.call();
    }
  }

  IconData _getToolIcon(String id, String name) {
    final lower = '${id.toLowerCase()} ${name.toLowerCase()}';
    if (lower.contains('transient') || lower.contains('cache')) {
      return Icons.cleaning_services_rounded;
    } else if (lower.contains('session')) {
      return Icons.people_outline_rounded;
    } else if (lower.contains('recount') || lower.contains('count')) {
      return Icons.calculate_outlined;
    } else if (lower.contains('download') || lower.contains('permission')) {
      return Icons.download_done_rounded;
    } else if (lower.contains('table') || lower.contains('lookup') || lower.contains('database')) {
      return Icons.storage_rounded;
    } else if (lower.contains('role') || lower.contains('capabilit')) {
      return Icons.admin_panel_settings_outlined;
    } else if (lower.contains('regenerate') || lower.contains('renew')) {
      return Icons.autorenew_rounded;
    } else if (lower.contains('log')) {
      return Icons.description_outlined;
    } else if (lower.contains('tax')) {
      return Icons.receipt_long_outlined;
    } else if (lower.contains('shipping')) {
      return Icons.local_shipping_outlined;
    } else if (lower.contains('verify') || lower.contains('check')) {
      return Icons.verified_outlined;
    }
    return Icons.build_circle_outlined;
  }

  bool _isPotentiallyDestructive(String id, String action) {
    final lower = '${id.toLowerCase()} ${action.toLowerCase()}';
    return lower.contains('clear') ||
        lower.contains('delete') ||
        lower.contains('reset') ||
        lower.contains('drop');
  }
}
