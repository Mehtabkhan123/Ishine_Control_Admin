import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/customers_bloc.dart';
import '../../bloc/customers_event.dart';
import '../../bloc/delete_customer_cubit.dart';
import '../../bloc/delete_customer_state.dart';
import '../../bloc/single_customer_cubit.dart';
import '../../data/repositories/customers_repository.dart';

/// Premium Samsung One UI 9-inspired confirmation dialog for deleting a customer.
/// Sends `DELETE /wp-json/wc/v3/customers/{{customerId}}?force=true`
class DeleteCustomerDialog extends StatelessWidget {
  final int customerId;
  final String? customerName;
  final String? customerEmail;
  final VoidCallback? onDeletedSuccessfully;

  const DeleteCustomerDialog({
    super.key,
    required this.customerId,
    this.customerName,
    this.customerEmail,
    this.onDeletedSuccessfully,
  });

  /// Displays the Delete Customer confirmation dialog.
  /// Returns `true` if deletion succeeded.
  static Future<bool?> show(
    BuildContext context, {
    required int customerId,
    String? customerName,
    String? customerEmail,
    VoidCallback? onDeletedSuccessfully,
  }) {
    CustomersRepository repository;
    try {
      repository = context.read<CustomersRepository>();
    } catch (_) {
      repository = CustomersRepository();
    }

    CustomersBloc? customersBloc;
    try {
      customersBloc = context.read<CustomersBloc>();
    } catch (_) {}

    SingleCustomerCubit? singleCustomerCubit;
    try {
      singleCustomerCubit = context.read<SingleCustomerCubit>();
    } catch (_) {}

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Widget content = BlocProvider<DeleteCustomerCubit>(
          create: (_) => DeleteCustomerCubit(repository: repository),
          child: DeleteCustomerDialog(
            customerId: customerId,
            customerName: customerName,
            customerEmail: customerEmail,
            onDeletedSuccessfully: onDeletedSuccessfully,
          ),
        );

        if (customersBloc != null) {
          content = BlocProvider<CustomersBloc>.value(
            value: customersBloc,
            child: content,
          );
        }

        if (singleCustomerCubit != null) {
          content = BlocProvider<SingleCustomerCubit>.value(
            value: singleCustomerCubit,
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
    final displayName = customerName != null && customerName!.trim().isNotEmpty
        ? customerName!
        : 'Customer #$customerId';

    return BlocConsumer<DeleteCustomerCubit, DeleteCustomerState>(
      listener: (context, state) {
        if (state.isSuccess && state.deletedCustomerId == customerId) {
          // 1. Sync CustomersBloc: remove customer locally from loaded list
          // and trigger background refresh to keep pagination and total count in sync with WooCommerce
          try {
            final customersBloc = context.read<CustomersBloc>();
            customersBloc.add(CustomersCustomerDeleted(customerId));
            customersBloc.add(const CustomersFetchStarted(isRefresh: true));
          } catch (_) {}

          // 2. Sync SingleCustomerCubit: remove from cache & active state
          try {
            context.read<SingleCustomerCubit>().customerDeleted(customerId);
          } catch (_) {}

          // 3. Callback if provided
          if (onDeletedSuccessfully != null) {
            onDeletedSuccessfully!();
          }

          // 4. Close dialog with success
          Navigator.of(context).pop(true);

          // 5. Show exact required success message: "Customer deleted successfully"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Customer deleted successfully',
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
        final isDeleting = state.isCustomerDeleting(customerId);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(28), // Samsung One UI 9 Squircle
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Header with destructive red glow
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
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
                              'Delete Customer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Permanent Deletion',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Confirmation Question Prompt
                  Text(
                    'Are you sure you want to delete this customer?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Explanation Text
                  Text(
                    'This action will permanently delete this customer profile, addresses, and account details from WooCommerce using force=true. This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            displayName.isNotEmpty
                                ? displayName.trim().substring(0, 1).toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customerEmail ?? 'ID: #$customerId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
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
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.of(context).maybePop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () {
                                context
                                    .read<DeleteCustomerCubit>()
                                    .deleteCustomer(customerId, force: true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18),
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
