import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/get_payment_gateways_model.dart';
import '../screens/edit_payment_gateway_screen.dart';

/// Samsung One UI 9-styled Payment Gateway Card.
/// Displays gateway title, method title, enabled status, needs setup indicator,
/// description, supported capabilities, and expandable settings breakdown.
class PaymentGatewayCard extends StatefulWidget {
  final GetPaymentGatewaysModel gateway;
  final ValueChanged<GetPaymentGatewaysModel>? onTap;
  final ValueChanged<GetPaymentGatewaysModel>? onViewDetails;

  const PaymentGatewayCard({
    super.key,
    required this.gateway,
    this.onTap,
    this.onViewDetails,
  });

  @override
  State<PaymentGatewayCard> createState() => _PaymentGatewayCardState();
}

class _PaymentGatewayCardState extends State<PaymentGatewayCard> {
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gateway = widget.gateway;
    final isEnabled = gateway.isEnabled;
    final requiresSetup = gateway.requiresSetup;
    final settingsList = gateway.settingsList;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: requiresSetup
              ? AppColors.warning.withValues(alpha: 0.5)
              : (isEnabled
                  ? AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.25)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: requiresSetup || isEnabled ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            if (widget.onTap != null) {
              widget.onTap!(gateway);
            } else if (widget.onViewDetails != null) {
              widget.onViewDetails!(gateway);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Title + Status Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gateway Icon Avatar
                    _buildGatewayIcon(gateway.id, isEnabled, isDark),
                    const SizedBox(width: 14),

                    // Title, Method Title & ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  gateway.displayTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(isEnabled, requiresSetup),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  gateway.formattedId,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                              if (gateway.order != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Order: ${gateway.order}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                              if (gateway.methodTitle != null &&
                                  gateway.methodTitle != gateway.title) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '(${gateway.methodTitle})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Gateway Description
                Text(
                  gateway.displayDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                  maxLines: _isSettingsExpanded ? 10 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Method Supports Capabilities Chips
                if (gateway.methodSupports != null &&
                    gateway.methodSupports!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: gateway.methodSupports!.map((support) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              support,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Expandable Settings Section
                if (settingsList.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _isSettingsExpanded = !_isSettingsExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration Settings (${settingsList.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _isSettingsExpanded ? 'Hide' : 'Inspect',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            _isSettingsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isSettingsExpanded) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: settingsList.take(6).map((setting) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    setting.displayLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    setting.displayValue,
                                    style: TextStyle(
                                      fontSize: 12,
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
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],

                // Action Bar: Edit Settings & View Details Buttons
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        EditPaymentGatewayScreen.show(context, gateway: gateway);
                      },
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: const Text(
                        'Edit Settings',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (widget.onViewDetails != null) {
                          widget.onViewDetails!(gateway);
                        } else if (widget.onTap != null) {
                          widget.onTap!(gateway);
                        }
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: const Text(
                        'Gateway Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayIcon(String? id, bool isEnabled, bool isDark) {
    IconData icon;
    LinearGradient gradient;

    final lower = (id ?? '').toLowerCase();
    if (lower.contains('bacs') || lower.contains('bank')) {
      icon = Icons.account_balance_rounded;
      gradient = AppColors.brandGradient;
    } else if (lower.contains('cod') || lower.contains('cash')) {
      icon = Icons.local_atm_rounded;
      gradient = AppColors.emeraldGradient;
    } else if (lower.contains('cheque') || lower.contains('check')) {
      icon = Icons.receipt_long_rounded;
      gradient = AppColors.amberGradient;
    } else if (lower.contains('stripe') || lower.contains('card')) {
      icon = Icons.credit_card_rounded;
      gradient = AppColors.purpleGradient;
    } else if (lower.contains('paypal')) {
      icon = Icons.payment_rounded;
      gradient = AppColors.brandGradient;
    } else {
      icon = Icons.payments_outlined;
      gradient = AppColors.brandGradient;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? gradient
            : LinearGradient(
                colors: [
                  isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                  isDark ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                ],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge(bool isEnabled, bool requiresSetup) {
    if (requiresSetup) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 13,
              color: AppColors.warning,
            ),
            SizedBox(width: 4),
            Text(
              'Needs Setup',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      );
    }

    if (isEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: AppColors.success,
            ),
            SizedBox(width: 4),
            Text(
              'Active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        'Disabled',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
        ),
      ),
    );
  }
}
