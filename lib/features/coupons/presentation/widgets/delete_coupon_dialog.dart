import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/coupons_bloc.dart';
import '../../bloc/coupons_event.dart';
import '../../bloc/delete_coupon_cubit.dart';
import '../../bloc/delete_coupon_state.dart';
import '../../data/repositories/coupons_repository.dart';

/// Premium Samsung One UI 9-inspired confirmation dialog for permanently deleting a coupon.
/// Sends `DELETE /wp-json/wc/v3/coupons/{{couponId}}?force=true`
class DeleteCouponDialog extends StatelessWidget {
  final int couponId;
  final String? couponCode;
  final String? discountDescription;
  final VoidCallback? onDeletedSuccessfully;

  const DeleteCouponDialog({
    super.key,
    required this.couponId,
    this.couponCode,
    this.discountDescription,
    this.onDeletedSuccessfully,
  });

  /// Displays the Delete Coupon confirmation dialog.
  /// Returns `true` if deletion succeeded.
  static Future<bool?> show(
    BuildContext context, {
    required int couponId,
    String? couponCode,
    String? discountDescription,
    VoidCallback? onDeletedSuccessfully,
  }) {
    CouponsRepository repository;
    try {
      repository = context.read<CouponsRepository>();
    } catch (_) {
      repository = CouponsRepository();
    }

    CouponsBloc? couponsBloc;
    try {
      couponsBloc = context.read<CouponsBloc>();
    } catch (_) {}

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Widget content = BlocProvider<DeleteCouponCubit>(
          create: (_) => DeleteCouponCubit(repository: repository),
          child: DeleteCouponDialog(
            couponId: couponId,
            couponCode: couponCode,
            discountDescription: discountDescription,
            onDeletedSuccessfully: onDeletedSuccessfully,
          ),
        );

        if (couponsBloc != null) {
          content = BlocProvider<CouponsBloc>.value(
            value: couponsBloc,
            child: content,
          );
        }

        return content;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCode = couponCode != null && couponCode!.trim().isNotEmpty
        ? couponCode!.toUpperCase()
        : 'COUPON #$couponId';

    return BlocConsumer<DeleteCouponCubit, DeleteCouponState>(
      listener: (context, state) {
        if (state.isSuccess && state.deletedCouponId == couponId) {
          // 1. Sync CouponsBloc: remove coupon locally from loaded list
          // and trigger background refresh to keep pagination and total count in sync with WooCommerce
          try {
            final couponsBloc = context.read<CouponsBloc>();
            couponsBloc.add(CouponsCouponDeleted(couponId));
            couponsBloc.add(const CouponsRefreshed());
          } catch (_) {}

          // 2. Callback if provided
          if (onDeletedSuccessfully != null) {
            onDeletedSuccessfully!();
          }

          // 3. Close dialog with success
          Navigator.of(context).pop(true);

          // 4. Show exact required success message: "Coupon deleted successfully"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Coupon deleted successfully',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        final isDeleting = state.isCouponDeleting(couponId);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // One UI Squircle Dialog
          ),
          backgroundColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 16,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Warning Icon Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Dialog Title
                Text(
                  'Delete Coupon?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Confirmation question
                Text(
                  'Are you sure you want to delete this coupon?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Coupon Preview Box
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground.withValues(alpha: 0.6)
                        : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            displayCode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (discountDescription != null &&
                          discountDescription!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          discountDescription!.trim(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'WooCommerce Coupon #$couponId',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Permanent force=true warning notice
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This coupon will be permanently removed (force=true). This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message banner if failure occurred
                if (state.isFailure && state.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () {
                                context
                                    .read<DeleteCouponCubit>()
                                    .deleteCoupon(couponId, force: true);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor:
                              AppColors.error.withValues(alpha: 0.5),
                        ),
                        child: isDeleting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Deleting...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_rounded, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
