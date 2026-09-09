import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/orders_bloc.dart';
import '../../bloc/orders_event.dart';
import '../../bloc/single_order_cubit.dart';
import '../../bloc/update_order_cubit.dart';
import '../../bloc/update_order_state.dart';
import '../../data/models/get_single_order_model.dart';
import '../../data/repositories/orders_repository.dart';

/// Samsung One UI 9-inspired Edit Order Screen.
/// Interacts with WooCommerce API:
/// `PUT /wp-json/wc/v3/orders/{{orderId}}`
///
/// Sends ONLY writable WooCommerce fields:
/// - status
/// - customer_note
/// - payment_method & payment_method_title & transaction_id
/// - billing (first_name, last_name, company, address_1, address_2, city, state, postcode, country, email, phone)
/// - shipping (first_name, last_name, company, address_1, address_2, city, state, postcode, country, phone)
/// - line_items (id, quantity)
class EditOrderScreen extends StatefulWidget {
  final GetSingleOrderModel order;

  const EditOrderScreen({
    super.key,
    required this.order,
  });

  static Route<bool> route({required GetSingleOrderModel order}) {
    return MaterialPageRoute<bool>(
      builder: (context) {
        try {
          context.read<UpdateOrderCubit>();
          return EditOrderScreen(order: order);
        } catch (_) {
          final repo = context.read<OrdersRepository>();
          return BlocProvider<UpdateOrderCubit>(
            create: (_) => UpdateOrderCubit(repository: repo),
            child: EditOrderScreen(order: order),
          );
        }
      },
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required GetSingleOrderModel order,
  }) {
    return Navigator.of(context).push<bool>(route(order: order));
  }

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedStatus;
  late TextEditingController _customerNoteController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _paymentMethodTitleController;
  late TextEditingController _transactionIdController;

  // Billing controllers
  late TextEditingController _billingFirstNameController;
  late TextEditingController _billingLastNameController;
  late TextEditingController _billingCompanyController;
  late TextEditingController _billingAddress1Controller;
  late TextEditingController _billingAddress2Controller;
  late TextEditingController _billingCityController;
  late TextEditingController _billingStateController;
  late TextEditingController _billingPostcodeController;
  late TextEditingController _billingCountryController;
  late TextEditingController _billingEmailController;
  late TextEditingController _billingPhoneController;

  // Shipping controllers
  late TextEditingController _shippingFirstNameController;
  late TextEditingController _shippingLastNameController;
  late TextEditingController _shippingCompanyController;
  late TextEditingController _shippingAddress1Controller;
  late TextEditingController _shippingAddress2Controller;
  late TextEditingController _shippingCityController;
  late TextEditingController _shippingStateController;
  late TextEditingController _shippingPostcodeController;
  late TextEditingController _shippingCountryController;
  late TextEditingController _shippingPhoneController;

  // Editable line item quantities: map of itemId -> quantity
  late Map<int, int> _lineItemQuantities;

  static const List<Map<String, dynamic>> _orderStatuses = [
    {
      'slug': 'pending',
      'label': 'Pending Payment',
      'color': AppColors.warning,
      'icon': Icons.hourglass_top_rounded,
    },
    {
      'slug': 'processing',
      'label': 'Processing',
      'color': AppColors.secondary,
      'icon': Icons.autorenew_rounded,
    },
    {
      'slug': 'on-hold',
      'label': 'On Hold',
      'color': AppColors.warningDark,
      'icon': Icons.pause_circle_outline_rounded,
    },
    {
      'slug': 'completed',
      'label': 'Completed',
      'color': AppColors.success,
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'slug': 'cancelled',
      'label': 'Cancelled',
      'color': AppColors.error,
      'icon': Icons.cancel_outlined,
    },
    {
      'slug': 'refunded',
      'label': 'Refunded',
      'color': AppColors.accent,
      'icon': Icons.replay_rounded,
    },
    {
      'slug': 'failed',
      'label': 'Failed',
      'color': AppColors.errorDark,
      'icon': Icons.error_outline_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final o = widget.order;

    _selectedStatus = (o.status ?? 'processing').toLowerCase();
    _customerNoteController = TextEditingController(text: o.customerNote ?? '');
    _paymentMethodController = TextEditingController(text: o.paymentMethod ?? '');
    _paymentMethodTitleController = TextEditingController(text: o.paymentMethodTitle ?? '');
    _transactionIdController = TextEditingController(text: o.transactionId ?? '');

    final b = o.billing;
    _billingFirstNameController = TextEditingController(text: b?.firstName ?? '');
    _billingLastNameController = TextEditingController(text: b?.lastName ?? '');
    _billingCompanyController = TextEditingController(text: b?.company ?? '');
    _billingAddress1Controller = TextEditingController(text: b?.address1 ?? '');
    _billingAddress2Controller = TextEditingController(text: b?.address2 ?? '');
    _billingCityController = TextEditingController(text: b?.city ?? '');
    _billingStateController = TextEditingController(text: b?.state ?? '');
    _billingPostcodeController = TextEditingController(text: b?.postcode ?? '');
    _billingCountryController = TextEditingController(text: b?.country ?? '');
    _billingEmailController = TextEditingController(text: b?.email ?? '');
    _billingPhoneController = TextEditingController(text: b?.phone ?? '');

    final s = o.shipping;
    _shippingFirstNameController = TextEditingController(text: s?.firstName ?? '');
    _shippingLastNameController = TextEditingController(text: s?.lastName ?? '');
    _shippingCompanyController = TextEditingController(text: s?.company ?? '');
    _shippingAddress1Controller = TextEditingController(text: s?.address1 ?? '');
    _shippingAddress2Controller = TextEditingController(text: s?.address2 ?? '');
    _shippingCityController = TextEditingController(text: s?.city ?? '');
    _shippingStateController = TextEditingController(text: s?.state ?? '');
    _shippingPostcodeController = TextEditingController(text: s?.postcode ?? '');
    _shippingCountryController = TextEditingController(text: s?.country ?? '');
    _shippingPhoneController = TextEditingController(text: s?.phone ?? '');

    _lineItemQuantities = {};
    if (o.lineItems != null) {
      for (final item in o.lineItems!) {
        if (item.id != null) {
          _lineItemQuantities[item.id!] = item.quantity ?? 1;
        }
      }
    }
  }

  @override
  void dispose() {
    _customerNoteController.dispose();
    _paymentMethodController.dispose();
    _paymentMethodTitleController.dispose();
    _transactionIdController.dispose();

    _billingFirstNameController.dispose();
    _billingLastNameController.dispose();
    _billingCompanyController.dispose();
    _billingAddress1Controller.dispose();
    _billingAddress2Controller.dispose();
    _billingCityController.dispose();
    _billingStateController.dispose();
    _billingPostcodeController.dispose();
    _billingCountryController.dispose();
    _billingEmailController.dispose();
    _billingPhoneController.dispose();

    _shippingFirstNameController.dispose();
    _shippingLastNameController.dispose();
    _shippingCompanyController.dispose();
    _shippingAddress1Controller.dispose();
    _shippingAddress2Controller.dispose();
    _shippingCityController.dispose();
    _shippingStateController.dispose();
    _shippingPostcodeController.dispose();
    _shippingCountryController.dispose();
    _shippingPhoneController.dispose();
    super.dispose();
  }

  void _copyBillingToShipping() {
    setState(() {
      _shippingFirstNameController.text = _billingFirstNameController.text;
      _shippingLastNameController.text = _billingLastNameController.text;
      _shippingCompanyController.text = _billingCompanyController.text;
      _shippingAddress1Controller.text = _billingAddress1Controller.text;
      _shippingAddress2Controller.text = _billingAddress2Controller.text;
      _shippingCityController.text = _billingCityController.text;
      _shippingStateController.text = _billingStateController.text;
      _shippingPostcodeController.text = _billingPostcodeController.text;
      _shippingCountryController.text = _billingCountryController.text;
      _shippingPhoneController.text = _billingPhoneController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.content_copy_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Billing address copied to Shipping'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final orderId = widget.order.id;
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Order ID. Cannot perform update.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Build strictly valid writable WooCommerce fields payload.
    // Response-only fields (total, total_tax, _links, date_created, etc.) are omitted.
    final Map<String, dynamic> updatePayload = {
      'status': _selectedStatus,
      'customer_note': _customerNoteController.text.trim(),
      'payment_method': _paymentMethodController.text.trim(),
      'payment_method_title': _paymentMethodTitleController.text.trim(),
      'transaction_id': _transactionIdController.text.trim(),
      'billing': {
        'first_name': _billingFirstNameController.text.trim(),
        'last_name': _billingLastNameController.text.trim(),
        'company': _billingCompanyController.text.trim(),
        'address_1': _billingAddress1Controller.text.trim(),
        'address_2': _billingAddress2Controller.text.trim(),
        'city': _billingCityController.text.trim(),
        'state': _billingStateController.text.trim(),
        'postcode': _billingPostcodeController.text.trim(),
        'country': _billingCountryController.text.trim(),
        'email': _billingEmailController.text.trim(),
        'phone': _billingPhoneController.text.trim(),
      },
      'shipping': {
        'first_name': _shippingFirstNameController.text.trim(),
        'last_name': _shippingLastNameController.text.trim(),
        'company': _shippingCompanyController.text.trim(),
        'address_1': _shippingAddress1Controller.text.trim(),
        'address_2': _shippingAddress2Controller.text.trim(),
        'city': _shippingCityController.text.trim(),
        'state': _shippingStateController.text.trim(),
        'postcode': _shippingPostcodeController.text.trim(),
        'country': _shippingCountryController.text.trim(),
        'phone': _shippingPhoneController.text.trim(),
      },
    };

    // Include line items if modified or present
    if (_lineItemQuantities.isNotEmpty) {
      final List<Map<String, dynamic>> itemsPayload = [];
      _lineItemQuantities.forEach((id, qty) {
        itemsPayload.add({
          'id': id,
          'quantity': qty,
        });
      });
      updatePayload['line_items'] = itemsPayload;
    }

    final cubit = context.read<UpdateOrderCubit>();
    await cubit.updateOrder(orderId: orderId, updateData: updatePayload);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final displayOrderNumber = order.displayOrderNumber.isNotEmpty
        ? order.displayOrderNumber
        : '#${order.id}';

    return BlocConsumer<UpdateOrderCubit, UpdateOrderState>(
      listener: (context, state) {
        if (state.isSuccess) {
          // 1. Refresh order details in SingleOrderCubit
          if (widget.order.id != null) {
            try {
              context.read<SingleOrderCubit>().fetchSingleOrder(
                    widget.order.id!,
                    forceRefresh: true,
                  );
            } catch (_) {}
          }

          // 2. Refresh orders list in OrdersBloc if available
          try {
            context.read<OrdersBloc>().add(const OrdersRefreshed());
          } catch (_) {}

          // 3. Display explicit success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Order updated successfully',
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

          // 4. Pop back with true flag indicating update occurred
          Navigator.of(context).pop(true);
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
        final isSubmitting = state.isSubmitting;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: _buildAppBar(context, displayOrderNumber, isDark, isSubmitting),
          body: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Info Notice Card
                          _buildNoticeCard(isDark, displayOrderNumber),
                          const SizedBox(height: 20),

                          if (isWide) ...[
                            // Two-column layout for wide screens
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    children: [
                                      _buildStatusSection(isDark),
                                      const SizedBox(height: 20),
                                      _buildLineItemsSection(isDark),
                                      const SizedBox(height: 20),
                                      _buildPaymentSection(isDark),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildBillingSection(isDark),
                                      const SizedBox(height: 20),
                                      _buildShippingSection(isDark),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Single column layout for mobile/compact
                            _buildStatusSection(isDark),
                            const SizedBox(height: 20),
                            _buildLineItemsSection(isDark),
                            const SizedBox(height: 20),
                            _buildPaymentSection(isDark),
                            const SizedBox(height: 20),
                            _buildBillingSection(isDark),
                            const SizedBox(height: 20),
                            _buildShippingSection(isDark),
                          ],

                          const SizedBox(height: 32),
                          _buildActionBottomBar(context, isDark, isSubmitting),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    String displayOrderNumber,
    bool isDark,
    bool isSubmitting,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: isSubmitting ? null : () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Order $displayOrderNumber',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'WooCommerce REST API • PUT /orders',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ElevatedButton.icon(
            onPressed: isSubmitting ? null : _submitForm,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              isSubmitting ? 'Updating...' : 'Save Changes',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeCard(bool isDark, String displayOrderNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Updating Order $displayOrderNumber',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Changes are submitted directly to WooCommerce using PUT /wp-json/wc/v3/orders/$displayOrderNumber. Read-only fields are safely excluded.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Order Status & Customer Note',
      icon: Icons.flag_rounded,
      iconColor: AppColors.primary,
      children: [
        const Text(
          'Select Order Status',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _orderStatuses.map((st) {
            final slug = st['slug'] as String;
            final label = st['label'] as String;
            final color = st['color'] as Color;
            final icon = st['icon'] as IconData;
            final isSelected = _selectedStatus == slug;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedStatus = slug;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : (isDark ? AppColors.darkCard : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? color
                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _customerNoteController,
          label: 'Customer Note',
          hintText: 'Note added by customer or admin instructions...',
          icon: Icons.sticky_note_2_outlined,
          isDark: isDark,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildLineItemsSection(bool isDark) {
    final items = widget.order.lineItems ?? [];

    return _buildSectionCard(
      isDark: isDark,
      title: 'Order Line Items (${items.length})',
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.secondary,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No line items found in this order.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final itemId = item.id;
              final currentQty = itemId != null ? (_lineItemQuantities[itemId] ?? item.quantity ?? 1) : (item.quantity ?? 1);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 22,
                        color: AppColors.secondaryLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name ?? 'Item #${item.id}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${item.sku != null && item.sku!.isNotEmpty ? item.sku : 'N/A'} • Price: \$${item.price ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Quantity Stepper
                    if (itemId != null)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_rounded, size: 16),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: currentQty > 1
                                  ? () {
                                      setState(() {
                                        _lineItemQuantities[itemId] = currentQty - 1;
                                      });
                                    }
                                  : null,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$currentQty',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              onPressed: () {
                                setState(() {
                                  _lineItemQuantities[itemId] = currentQty + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPaymentSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Payment & Transaction',
      icon: Icons.credit_card_rounded,
      iconColor: AppColors.accent,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _paymentMethodController,
                label: 'Payment Method ID',
                hintText: 'e.g. cod, bacs, stripe',
                icon: Icons.tag_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(
                controller: _paymentMethodTitleController,
                label: 'Payment Method Title',
                hintText: 'e.g. Cash on delivery',
                icon: Icons.payments_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _transactionIdController,
          label: 'Transaction ID',
          hintText: 'e.g. ch_3M5qJ..., txn_10928',
          icon: Icons.receipt_long_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBillingSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Billing Details',
      icon: Icons.receipt_outlined,
      iconColor: AppColors.warning,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _billingFirstNameController,
                label: 'First Name',
                hintText: 'First name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _billingLastNameController,
                label: 'Last Name',
                hintText: 'Last name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _billingCompanyController,
          label: 'Company',
          hintText: 'Company name (optional)',
          icon: Icons.business_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _billingAddress1Controller,
          label: 'Street Address 1',
          hintText: '123 Main Street',
          icon: Icons.home_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _billingAddress2Controller,
          label: 'Street Address 2',
          hintText: 'Apt, Suite, Unit (optional)',
          icon: Icons.apartment_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _billingCityController,
                label: 'City',
                hintText: 'City',
                icon: Icons.location_city_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _billingStateController,
                label: 'State / Province',
                hintText: 'State',
                icon: Icons.map_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _billingPostcodeController,
                label: 'Postcode / ZIP',
                hintText: 'Postal code',
                icon: Icons.markunread_mailbox_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _billingCountryController,
                label: 'Country (2-letter code)',
                hintText: 'US, GB, PK, etc.',
                icon: Icons.public_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _billingEmailController,
          label: 'Email Address',
          hintText: 'customer@example.com',
          icon: Icons.email_outlined,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _billingPhoneController,
          label: 'Phone Number',
          hintText: '+1 555-0199',
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildShippingSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      title: 'Shipping Details',
      icon: Icons.local_shipping_outlined,
      iconColor: AppColors.secondary,
      headerTrailing: TextButton.icon(
        onPressed: _copyBillingToShipping,
        icon: const Icon(Icons.copy_rounded, size: 14),
        label: const Text(
          'Copy Billing',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _shippingFirstNameController,
                label: 'First Name',
                hintText: 'First name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _shippingLastNameController,
                label: 'Last Name',
                hintText: 'Last name',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _shippingCompanyController,
          label: 'Company',
          hintText: 'Company name (optional)',
          icon: Icons.business_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _shippingAddress1Controller,
          label: 'Street Address 1',
          hintText: '123 Delivery Way',
          icon: Icons.home_outlined,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _shippingAddress2Controller,
          label: 'Street Address 2',
          hintText: 'Apt, Suite, Unit (optional)',
          icon: Icons.apartment_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _shippingCityController,
                label: 'City',
                hintText: 'City',
                icon: Icons.location_city_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _shippingStateController,
                label: 'State / Province',
                hintText: 'State',
                icon: Icons.map_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _shippingPostcodeController,
                label: 'Postcode / ZIP',
                hintText: 'Postal code',
                icon: Icons.markunread_mailbox_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _shippingCountryController,
                label: 'Country (2-letter code)',
                hintText: 'US, GB, PK, etc.',
                icon: Icons.public_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _shippingPhoneController,
          label: 'Delivery Contact Phone',
          hintText: '+1 555-0199',
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Widget? headerTrailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              ?headerTrailing,
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBottomBar(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'Discard Changes',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: isSubmitting ? null : _submitForm,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(
            isSubmitting ? 'Updating Order...' : 'Save Order Changes',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}
