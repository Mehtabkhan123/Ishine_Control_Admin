import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../system_status/bloc/system_status_bloc.dart';
import '../../../system_status/bloc/system_status_event.dart';
import '../../../system_status/bloc/system_status_state.dart';
import 'system_status_dialog.dart';

/// Interactive live connection health indicator widget with Samsung One UI styling.
class ConnectionHealthIndicator extends StatefulWidget {
  const ConnectionHealthIndicator({super.key});

  @override
  State<ConnectionHealthIndicator> createState() => _ConnectionHealthIndicatorState();
}

class _ConnectionHealthIndicatorState extends State<ConnectionHealthIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SystemStatusBloc, SystemStatusState>(
      builder: (context, state) {
        Color dotColor;
        Color badgeBgColor;
        Color badgeBorderColor;
        String label;
        String? subLabel;
        IconData? trailingIcon;

        if (state is SystemStatusSuccess) {
          dotColor = AppColors.success;
          badgeBgColor = AppColors.success.withValues(alpha: 0.12);
          badgeBorderColor = AppColors.success.withValues(alpha: 0.3);
          label = 'Store Connected';
          subLabel = '${state.status?.responseTimeMs ?? 0}ms';
          trailingIcon = Icons.info_outline_rounded;
        } else if (state is SystemStatusFailure) {
          dotColor = AppColors.error;
          badgeBgColor = AppColors.error.withValues(alpha: 0.12);
          badgeBorderColor = AppColors.error.withValues(alpha: 0.3);
          label = 'Store Disconnected';
          subLabel = 'Error';
          trailingIcon = Icons.refresh_rounded;
        } else {
          // Loading / Checking
          dotColor = AppColors.warning;
          badgeBgColor = AppColors.warning.withValues(alpha: 0.12);
          badgeBorderColor = AppColors.warning.withValues(alpha: 0.3);
          label = 'Checking Health';
          subLabel = '...';
        }

        return Tooltip(
          message: state is SystemStatusFailure
              ? 'Click to retry connection (${state.errorMessage})'
              : 'Click to view WooCommerce system status & diagnostics',
          child: InkWell(
            onTap: () {
              if (state is SystemStatusFailure) {
                context.read<SystemStatusBloc>().add(const SystemStatusRefreshRequested());
              } else {
                showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<SystemStatusBloc>(),
                    child: const SystemStatusDialog(),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(24), // One UI squircle pill
                border: Border.all(color: badgeBorderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotColor.withValues(
                            alpha: state is SystemStatusLoading ? _pulseAnimation.value : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.6 * _pulseAnimation.value),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: dotColor,
                    ),
                  ),
                  if (subLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: dotColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: dotColor,
                        ),
                      ),
                    ),
                  ],
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      trailingIcon,
                      size: 14,
                      color: dotColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
