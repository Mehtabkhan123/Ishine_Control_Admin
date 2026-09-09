import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/delete_order_cubit.dart';
import '../../bloc/delete_order_state.dart';
import '../../bloc/orders_bloc.dart';
import '../../bloc/orders_event.dart';
import '../../bloc/single_order_cubit.dart';
import '../../data/repositories/orders_repository.dart';

/// Premium Samsung One UI 9-inspired confirmation dialog for deleting an order.
/// Sends `DELETE /wp-json/wc/v3/orders/{{orderId}}?force=true`
class DeleteOrderDialog extends StatelessWidget {
  final int orderId;
  final String? displayOrderNumber;
  final VoidCallback? onDeletedSuccessfully;

  const DeleteOrderDialog({
    super.key,
    required this.orderId,
    this.displayOrderNumber,
    this.onDeletedSuccessfully,
  });

  /// Displays the Delete Order confirmation dialog.
  /// Returns `true` if deletion succeeded.
  static Future<bool?> show(
    BuildContext context, {
    required int orderId,
    String? displayOrderNumber,
    VoidCallback? onDeletedSuccessfully,
  }) {
    OrdersRepository repository;
    try {
      repository = context.read<OrdersRepository>();
    } catch (_) {
      repository = OrdersRepository();
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider<DeleteOrderCubit>(
          create: (_) => DeleteOrderCubit(repository: repository),
          child: DeleteOrderDialog(
            orderId: orderId,
            displayOrderNumber: displayOrderNumber,
            onDeletedSuccessfully: onDeletedSuccessfully,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderLabel = displayOrderNumber != null && displayOrderNumber!.isNotEmpty
        ? displayOrderNumber!
        : '#$orderId';

    return BlocConsumer<DeleteOrderCubit, DeleteOrderState>(
      listener: (context, state) {
        if (state.isSuccess && state.deletedOrderId == orderId) {
          // 1. Sync OrdersBloc: remove item locally
          try {
            context.read<OrdersBloc>().add(OrdersOrderDeleted(orderId));
          } catch (_) {}

          // 2. Sync SingleOrderCubit: remove from cache
          try {
            context.read<SingleOrderCubit>().orderDeleted(orderId);
          } catch (_) {}

          // 3. Callback if provided
          if (onDeletedSuccessfully != null) {
            onDeletedSuccessfully!();
          }

          // 4. Close dialog with success
          Navigator.of(context).pop(true);

          // 5. Show exact success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Order deleted successfully',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state.isFailure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isProcessing = state.isOrderDeleting(orderId);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          elevation: 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning Header Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppColors.error,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Order $orderLabel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Permanent deletion (force=true)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Confirmation Question text as required
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Are you sure you want to delete this order?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'This order will be permanently purged from WooCommerce and cannot be recovered or restored from trash.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: isProcessing
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Confirm Delete Button (Disabled when processing)
                      ElevatedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () {
                                context.read<DeleteOrderCubit>().deleteOrder(
                                      orderId,
                                      force: true,
                                    );
                              },
                        icon: isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_rounded, size: 17),
                        label: Text(
                          isProcessing ? 'Deleting...' : 'Delete Permanently',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
