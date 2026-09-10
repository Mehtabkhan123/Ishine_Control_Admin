import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/payment_gateways_bloc.dart';
import '../../bloc/payment_gateways_event.dart';
import '../../bloc/update_payment_gateway_cubit.dart';
import '../../bloc/update_payment_gateway_state.dart';
import '../../data/models/get_payment_gateways_model.dart';
import '../../data/models/put_update_payment_gateways_model.dart' as put_model;
import '../../data/repositories/payment_gateways_repository.dart';

/// Samsung One UI 9-inspired Edit Payment Gateway Screen for WooCommerce Admin.
/// Interacts with WooCommerce API:
/// `PUT /wp-json/wc/v3/payment_gateways/{{paymentGatewayId}}`
///
/// Features:
/// - Pre-fills all editable parameters from existing [GetPaymentGatewaysModel].
/// - Sends ONLY valid writable fields in update payload (`title`, `description`, `order`, `enabled`, `settings`).
/// - Excludes read-only fields (`id`, `method_title`, `needs_setup`, `_links`).
/// - Configurable settings editor handling checkboxes, passwords, multiline text, and standard fields.
/// - In-flight duplicate submission protection.
/// - Synchronizes with PaymentGatewaysBloc upon successful update.
class EditPaymentGatewayScreen extends StatefulWidget {
  final GetPaymentGatewaysModel gateway;

  const EditPaymentGatewayScreen({
    super.key,
    required this.gateway,
  });

  static Route<put_model.PutUpdatePaymentGatewaysModel?> route({
    required GetPaymentGatewaysModel gateway,
  }) {
    return MaterialPageRoute<put_model.PutUpdatePaymentGatewaysModel?>(
      builder: (context) {
        try {
          context.read<UpdatePaymentGatewayCubit>();
          return EditPaymentGatewayScreen(gateway: gateway);
        } catch (_) {
          PaymentGatewaysRepository repo;
          try {
            repo = context.read<PaymentGatewaysRepository>();
          } catch (_) {
            repo = PaymentGatewaysRepository();
          }
          return BlocProvider<UpdatePaymentGatewayCubit>(
            create: (_) => UpdatePaymentGatewayCubit(repository: repo),
            child: EditPaymentGatewayScreen(gateway: gateway),
          );
        }
      },
    );
  }

  static Future<put_model.PutUpdatePaymentGatewaysModel?> show(
    BuildContext context, {
    required GetPaymentGatewaysModel gateway,
  }) {
    return Navigator.of(context).push<put_model.PutUpdatePaymentGatewaysModel?>(
      route(gateway: gateway),
    );
  }

  @override
  State<EditPaymentGatewayScreen> createState() =>
      _EditPaymentGatewayScreenState();
}

class _EditPaymentGatewayScreenState extends State<EditPaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();

  // Primary fields
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _orderController;
  late bool _enabled;

  // Dynamic settings
  final Map<String, TextEditingController> _settingsTextControllers = {};
  final Map<String, bool> _settingsCheckboxValues = {};
  final Map<String, bool> _obscurePasswords = {};

  @override
  void initState() {
    super.initState();
    final gateway = widget.gateway;

    _titleController = TextEditingController(text: gateway.title ?? '');
    _descriptionController =
        TextEditingController(text: gateway.description ?? '');
    _orderController =
        TextEditingController(text: (gateway.order ?? 0).toString());
    _enabled = gateway.isEnabled;

    // Initialize dynamic setting controllers
    if (gateway.settings != null) {
      gateway.settings!.forEach((key, setting) {
        final type = setting.type?.toLowerCase() ?? 'text';
        final val = setting.value ?? setting.defaultValue ?? '';

        if (type == 'checkbox') {
          final isChecked = val == 'yes' || val == 'true' || val == '1';
          _settingsCheckboxValues[key] = isChecked;
        } else {
          _settingsTextControllers[key] = TextEditingController(text: val);
          if (type == 'password') {
            _obscurePasswords[key] = true;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    for (final controller in _settingsTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<UpdatePaymentGatewayCubit>();
    if (cubit.state.isSubmitting) return;

    final gatewayId = widget.gateway.id ?? '';
    if (gatewayId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Payment gateway ID is missing.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Build settings map for writable payload
    final Map<String, dynamic> settingsPayload = {};
    _settingsTextControllers.forEach((key, controller) {
      settingsPayload[key] = controller.text.trim();
    });
    _settingsCheckboxValues.forEach((key, value) {
      settingsPayload[key] = value ? 'yes' : 'no';
    });

    final payload = put_model.PutUpdatePaymentGatewaysModel.toUpdatePayloadMap(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      order: int.tryParse(_orderController.text.trim()),
      enabled: _enabled,
      settings: settingsPayload.isNotEmpty ? settingsPayload : null,
    );

    final result = await cubit.updatePaymentGateway(
      gatewayId: gatewayId,
      updateData: payload,
    );

    if (result != null && mounted) {
      // Synchronize with main PaymentGatewaysBloc
      try {
        context.read<PaymentGatewaysBloc>().add(
              PaymentGatewayUpdated(result.toGetPaymentGatewaysModel()),
            );
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payment gateway "${result.title ?? widget.gateway.displayTitle}" updated successfully',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gateway = widget.gateway;

    return BlocConsumer<UpdatePaymentGatewayCubit, UpdatePaymentGatewayState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit ${gateway.displayTitle}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  gateway.formattedId,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : _submitUpdate,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    isSubmitting ? 'Saving...' : 'Save',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Toggle Card
                  _buildStatusCard(context, isDark),
                  const SizedBox(height: 20),

                  // Basic Information Card (Title, Description, Order)
                  _buildGeneralInfoCard(context, isDark),
                  const SizedBox(height: 20),

                  // Configurable Gateway Settings Card
                  if (gateway.settings != null && gateway.settings!.isNotEmpty) ...[
                    _buildSettingsCard(context, isDark),
                    const SizedBox(height: 20),
                  ],

                  // System Information Card (Read-only reference)
                  _buildSystemInfoCard(context, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Status Card with interactive switch
  Widget _buildStatusCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _enabled
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: _enabled ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _enabled
                  ? AppColors.success.withValues(alpha: 0.12)
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _enabled
                  ? Icons.check_circle_rounded
                  : Icons.pause_circle_outline_rounded,
              color: _enabled
                  ? AppColors.success
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Gateway in Checkout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _enabled
                      ? 'This payment method is currently active and visible to customers.'
                      : 'This payment method is deactivated and hidden at checkout.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch.adaptive(
            value: _enabled,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              setState(() {
                _enabled = val;
              });
            },
          ),
        ],
      ),
    );
  }

  /// General Info Card (Title, Description, Order)
  Widget _buildGeneralInfoCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Display Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            'Gateway Title *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: 'e.g. Direct Bank Transfer',
              prefixIcon: Icons.title_rounded,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Checkout Description',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: 'Customer-facing explanation shown during checkout...',
              prefixIcon: Icons.description_outlined,
            ),
          ),
          const SizedBox(height: 16),

          // Sort Order
          Text(
            'Evaluation Sort Order',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _orderController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              isDark: isDark,
              hintText: '0',
              prefixIcon: Icons.sort_rounded,
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic Settings Card (iterating through gateway.settings)
  Widget _buildSettingsCard(BuildContext context, bool isDark) {
    final settings = widget.gateway.settings!;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: AppColors.secondary, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Configuration Settings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure credentials, instructions, and behavior specific to this gateway.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          ...settings.entries.map((entry) {
            final key = entry.key;
            final setting = entry.value;
            final type = setting.type?.toLowerCase() ?? 'text';
            final label = setting.label ?? key;
            final desc = setting.description;

            // Skip title and description if already covered in primary section
            if (key == 'title' || key == 'description' || key == 'enabled') {
              return const SizedBox.shrink();
            }

            if (type == 'checkbox') {
              final isChecked = _settingsCheckboxValues[key] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            if (desc != null && desc.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: isChecked,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            _settingsCheckboxValues[key] = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            // Text, textarea, password, etc.
            final controller = _settingsTextControllers[key];
            if (controller == null) return const SizedBox.shrink();

            final isPassword = type == 'password';
            final isObscure = _obscurePasswords[key] ?? false;
            final isMultiline = type == 'textarea';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      if (setting.tip != null && setting.tip!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: setting.tip!,
                          child: Icon(Icons.info_outline_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: controller,
                    obscureText: isPassword && isObscure,
                    maxLines: isMultiline ? 3 : 1,
                    decoration: _inputDecoration(
                      isDark: isDark,
                      hintText: setting.placeholder ?? setting.defaultValue ?? '',
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(
                                isObscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePasswords[key] = !isObscure;
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                  if (desc != null && desc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// System Info Card (Read-only metadata)
  Widget _buildSystemInfoCard(BuildContext context, bool isDark) {
    final gateway = widget.gateway;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted),
              const SizedBox(width: 8),
              Text(
                'WooCommerce System Properties (Read-Only)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReadOnlyRow(
              'Gateway ID', gateway.id ?? '--', isDark, isMonospace: true),
          _buildReadOnlyRow(
              'Method Title', gateway.methodTitle ?? '--', isDark),
          _buildReadOnlyRow(
            'Supported Features',
            gateway.methodSupports?.join(', ') ?? 'None specified',
            isDark,
          ),
          if (gateway.settingsUrl != null && gateway.settingsUrl!.isNotEmpty)
            _buildReadOnlyRow(
              'Settings URL',
              gateway.settingsUrl!,
              isDark,
              isMonospace: true,
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value, bool isDark,
      {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: isMonospace ? 'monospace' : null,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              size: 18,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          width: 1.5,
        ),
      ),
    );
  }
}
