import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../system_status/bloc/system_status_bloc.dart';

class AdminNavRailItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String? badgeText;
  final Color? badgeColor;

  const AdminNavRailItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badgeText,
    this.badgeColor,
  });
}

/// Samsung One UI-inspired modern navigation rail for iShine Control Admin.
/// Handles width expansion/collapse smoothly using LayoutBuilder to prevent
/// rendering overflows during intermediate animation frames.
class AdminNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const AdminNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isExpanded = true,
    this.onToggleExpanded,
  });

  static const List<AdminNavRailItem> navItems = [
    AdminNavRailItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AdminNavRailItem(
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      badgeText: '38',
      badgeColor: AppColors.warning,
    ),
    AdminNavRailItem(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      badgeText: '248',
      badgeColor: AppColors.secondary,
    ),
    AdminNavRailItem(
      label: 'Customers',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_alt_rounded,
    ),
    AdminNavRailItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = isExpanded ? 268.0 : 80.0;
    final bgColor = isDark ? AppColors.darkSidebar : const Color(0xFF0F172A);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFF1E293B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Guard against intermediate animation frames where width is insufficient for text
            final isFullyExpanded = isExpanded && constraints.maxWidth >= 200;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Logo & Branding with Collapse button
                _buildBrandHeader(context, isFullyExpanded),

                Divider(color: borderColor, height: 1),
                const SizedBox(height: 16),

                // Section label if expanded
                if (isFullyExpanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'MAIN MENU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Nav Items
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: navItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = navItems[index];
                      final isSelected = selectedIndex == index;

                      return _buildNavItem(
                        context: context,
                        item: item,
                        isSelected: isSelected,
                        isFullyExpanded: isFullyExpanded,
                        onTap: () => onDestinationSelected(index),
                      );
                    },
                  ),
                ),

                // Footer / Connected Store Card & Collapse Action
                Divider(color: borderColor, height: 1),
                _buildFooter(context, isFullyExpanded),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, bool isFullyExpanded) {
    if (!isFullyExpanded) {
      return Container(
        height: 72,
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'iShine',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Control',
                            style: TextStyle(
                              color: AppColors.secondaryLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'WooCommerce Admin',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onToggleExpanded != null)
            IconButton(
              onPressed: onToggleExpanded,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(
                Icons.menu_open_rounded,
                size: 19,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              tooltip: 'Collapse sidebar',
              hoverColor: Colors.white.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required AdminNavRailItem item,
    required bool isSelected,
    required bool isFullyExpanded,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: !isFullyExpanded ? item.label : '',
        waitDuration: const Duration(milliseconds: 400),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isFullyExpanded ? 16 : 0),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.brandGradient : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: isFullyExpanded
                ? Row(
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 21,
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (item.badgeColor ?? AppColors.primary).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : (item.badgeColor ?? AppColors.primary).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.badgeText!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : (item.badgeColor ?? Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        ),
                        if (item.badgeText != null)
                          Positioned(
                            top: -2,
                            right: -4,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.badgeColor ?? AppColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isFullyExpanded) {
    final status = context.watch<SystemStatusBloc>().state.status;
    final isOnline = status != null;

    if (!isFullyExpanded) {
      return Container(
        height: 68,
        alignment: Alignment.center,
        child: IconButton(
          onPressed: onToggleExpanded,
          icon: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 22,
          ),
          tooltip: 'Expand sidebar',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF182238),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF24324B)),
        ),
        child: Row(
          children: [
            // Status avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    size: 17,
                    color: AppColors.secondaryLight,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.success : AppColors.warning,
                      border: Border.all(color: const Color(0xFF182238), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'WooCommerce Store',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOnline) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    EnvConfig.baseUrl.isNotEmpty ? EnvConfig.baseUrl : 'Not Configured',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Copy store URL
            IconButton(
              onPressed: () {
                if (EnvConfig.baseUrl.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: EnvConfig.baseUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Store URL copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              tooltip: 'Copy Store URL',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}
