import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/get_tax_rates_model.dart';

/// Premium Samsung One UI 9-inspired Tax Rate Card.
/// Displays tax rate name, rate, country, state, postcode/city, priority,
/// compound status, shipping applicability, tax class, and dynamic ID.
class TaxRateCard extends StatefulWidget {
  final GetTaxRatesModel taxRate;
  final ValueChanged<GetTaxRatesModel>? onTap;

  const TaxRateCard({
    super.key,
    required this.taxRate,
    this.onTap,
  });

  @override
  State<TaxRateCard> createState() => _TaxRateCardState();
}

class _TaxRateCardState extends State<TaxRateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = widget.taxRate;
    final isCompound = rate.compound == true;
    final appliesToShipping = rate.shipping == true;

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
            onTap: widget.onTap != null ? () => widget.onTap!(rate) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading Rate Badge (Squircle container with rate percentage)
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: isCompound
                          ? AppColors.purpleGradient
                          : AppColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompound
                                  ? AppColors.accent
                                  : AppColors.success)
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
                          Text(
                            rate.formattedRate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            rate.formattedId,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Middle Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Tax Class Tag Row
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                rate.displayName,
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                rate.taxClassDisplay,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Location Line (Country, State, City, Postcode)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rate.locationSummary,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Attribute Chips: Priority, Compound, Shipping
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildPill(
                              context: context,
                              isDark: isDark,
                              icon: Icons.low_priority_rounded,
                              label: 'Priority: ${rate.priorityDisplay}',
                              color: AppColors.info,
                            ),
                            _buildPill(
                              context: context,
                              isDark: isDark,
                              icon: isCompound
                                  ? Icons.layers_rounded
                                  : Icons.layers_outlined,
                              label: isCompound ? 'Compound' : 'Standard',
                              color: isCompound
                                  ? AppColors.warning
                                  : AppColors.info,
                            ),
                            _buildPill(
                              context: context,
                              isDark: isDark,
                              icon: appliesToShipping
                                  ? Icons.local_shipping_rounded
                                  : Icons.no_transfer_rounded,
                              label: appliesToShipping
                                  ? 'Shipping: Yes'
                                  : 'Shipping: No',
                              color: appliesToShipping
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            if (rate.order != null)
                              _buildPill(
                                context: context,
                                isDark: isDark,
                                icon: Icons.sort_rounded,
                                label: 'Order: ${rate.order}',
                                color: AppColors.secondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Trailing Chevron Button
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

  Widget _buildPill({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.12)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
