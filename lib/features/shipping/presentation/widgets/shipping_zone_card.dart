import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/shipping_zones_model.dart';

/// Premium Samsung One UI 9-inspired Shipping Zone Card.
/// Displays zone ID, name, priority order, and dynamic navigation touch target.
class ShippingZoneCard extends StatefulWidget {
  final ShippingZonesModel zone;
  final ValueChanged<ShippingZonesModel>? onTap;

  const ShippingZoneCard({
    super.key,
    required this.zone,
    this.onTap,
  });

  @override
  State<ShippingZoneCard> createState() => _ShippingZoneCardState();
}

class _ShippingZoneCardState extends State<ShippingZoneCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zone = widget.zone;
    final isDefault = zone.isDefaultZone;

    final cardBg = isDark
        ? (_isHovered ? AppColors.darkCardElevated : AppColors.darkCard)
        : (_isHovered ? const Color(0xFFF1F5F9) : AppColors.lightSurface);

    final borderColor = isDark
        ? (_isHovered ? AppColors.primaryLight.withValues(alpha: 0.4) : AppColors.darkBorder)
        : (_isHovered ? AppColors.primary.withValues(alpha: 0.35) : AppColors.lightBorder);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20), // One UI 9 squircle
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isDark
              ? [
                  if (_isHovered)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.07 : 0.03),
                    blurRadius: _isHovered ? 14 : 8,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap != null ? () => widget.onTap!(zone) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  // Zone Badge Container with One UI squircle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isDefault
                          ? AppColors.purpleGradient
                          : AppColors.skyGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isDefault
                                  ? AppColors.accent
                                  : AppColors.secondary)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isDefault
                                ? Icons.public_rounded
                                : Icons.local_shipping_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            zone.formattedId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Zone Details (Name, Order, Type)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                zone.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'Rest of the World',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accentLight,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Metadata Row: Zone ID & Priority Order Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Zone ID chip
                            _buildInfoChip(
                              context: context,
                              isDark: isDark,
                              icon: Icons.tag_rounded,
                              label: 'Zone ID: ${zone.id ?? "N/A"}',
                              color: AppColors.primary,
                            ),

                            // Sort Order chip
                            _buildInfoChip(
                              context: context,
                              isDark: isDark,
                              icon: Icons.sort_rounded,
                              label: 'Order: ${zone.formattedOrder}',
                              color: AppColors.info,
                            ),

                            // Endpoints link indicator if available
                            if (zone.lLinks?.self != null &&
                                zone.lLinks!.self!.isNotEmpty)
                              _buildInfoChip(
                                context: context,
                                isDark: isDark,
                                icon: Icons.link_rounded,
                                label: 'REST v3',
                                color: AppColors.success,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Trailing Action Icon with One UI circular container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder.withValues(alpha: 0.5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
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

  Widget _buildInfoChip({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
