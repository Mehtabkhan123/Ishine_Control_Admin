import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/customers_bloc.dart';
import '../../bloc/customers_event.dart';
import '../../bloc/single_customer_cubit.dart';
import '../../bloc/update_customer_cubit.dart';
import '../../bloc/update_customer_state.dart';
import '../../data/models/get_customers_model.dart';
import '../../data/models/get_single_customers_model.dart';
import '../../data/repositories/customers_repository.dart';
import '../widgets/delete_customer_dialog.dart';

/// Samsung One UI 9-inspired Edit Customer Screen.
/// Interacts with WooCommerce API:
/// `PUT /wp-json/wc/v3/customers/{{customerId}}`
///
/// Sends ONLY writable WooCommerce fields:
/// - first_name, last_name, email, role, username
/// - billing (first_name, last_name, company, address_1, address_2, city, state, postcode, country, email, phone)
/// - shipping (first_name, last_name, company, address_1, address_2, city, state, postcode, country, phone)
class EditCustomerScreen extends StatefulWidget {
  final GETSingleCustomersModel customer;

  const EditCustomerScreen({
    super.key,
    required this.customer,
  });

  static Route<bool> route({required dynamic customer}) {
    GETSingleCustomersModel resolvedCustomer;
    if (customer is GETSingleCustomersModel) {
      resolvedCustomer = customer;
    } else if (customer is GETCustomersModel) {
      resolvedCustomer = GETSingleCustomersModel.fromCustomersModel(customer);
    } else {
      throw ArgumentError('Expected GETSingleCustomersModel or GETCustomersModel');
    }

    return MaterialPageRoute<bool>(
      builder: (context) {
        try {
          context.read<UpdateCustomerCubit>();
          return EditCustomerScreen(customer: resolvedCustomer);
        } catch (_) {
          final repo = context.read<CustomersRepository>();
          return BlocProvider<UpdateCustomerCubit>(
            create: (_) => UpdateCustomerCubit(repository: repo),
            child: EditCustomerScreen(customer: resolvedCustomer),
          );
        }
      },
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required dynamic customer,
  }) {
    return Navigator.of(context).push<bool>(route(customer: customer));
  }

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late String _selectedRole;

  // Billing Controllers
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

  // Shipping Controllers
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

  static const List<Map<String, String>> _availableRoles = [
    {'value': 'customer', 'label': 'Customer'},
    {'value': 'subscriber', 'label': 'Subscriber'},
    {'value': 'shop_manager', 'label': 'Shop Manager'},
    {'value': 'administrator', 'label': 'Administrator'},
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;

    _firstNameController = TextEditingController(text: c.firstName ?? '');
    _lastNameController = TextEditingController(text: c.lastName ?? '');
    _emailController = TextEditingController(text: c.email ?? '');
    _usernameController = TextEditingController(text: c.username ?? '');

    final role = (c.role ?? 'customer').toLowerCase();
    final roleExists = _availableRoles.any((r) => r['value'] == role);
    _selectedRole = roleExists ? role : 'customer';

    // Billing
    final b = c.billing;
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

    // Shipping
    final s = c.shipping;
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
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();

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

    final customerId = widget.customer.id;
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Customer ID. Cannot perform update.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Build strictly valid writable WooCommerce fields payload.
    // Response-only fields (id, date_created, date_modified, avatar_url, _links) are omitted.
    final Map<String, dynamic> updatePayload = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _selectedRole,
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

    final cubit = context.read<UpdateCustomerCubit>();
    await cubit.updateCustomer(
      customerId: customerId,
      updateData: updatePayload,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customer = widget.customer;
    final displayName = customer.displayName.isNotEmpty
        ? customer.displayName
        : 'Customer #${customer.id}';

    return BlocConsumer<UpdateCustomerCubit, UpdateCustomerState>(
      listener: (context, state) {
        if (state.isSuccess) {
          final updated = state.updatedCustomer;

          // 1. Refresh customer details in SingleCustomerCubit
          if (updated != null) {
            try {
              context.read<SingleCustomerCubit>().customerUpdated(updated);
            } catch (_) {}
          }
          if (widget.customer.id != null) {
            try {
              context.read<SingleCustomerCubit>().fetchSingleCustomer(
                    widget.customer.id!,
                    forceRefresh: true,
                  );
            } catch (_) {}
          }

          // 2. Refresh customer in CustomersBloc if loaded in list
          if (updated != null) {
            try {
              context.read<CustomersBloc>().add(CustomersCustomerUpdated(updated));
            } catch (_) {}
          }
          try {
            context.read<CustomersBloc>().add(const CustomersRefreshed());
          } catch (_) {}

          // 3. Display exact required success message: "Customer updated successfully"
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Customer updated successfully',
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

          // 4. Navigate back with true indicating update success
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).maybePop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Customer #${widget.customer.id}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                tooltip: 'Delete Customer',
                onPressed: isSubmitting ? null : _handleDeleteCustomer,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submitForm,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      isSubmitting ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                height: 1,
              ),
            ),
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Avatar & Quick Info
                      _buildHeaderCard(isDark, displayName),
                      const SizedBox(height: 20),

                      // Personal / Account Information Card
                      _buildPersonalInfoCard(isDark),
                      const SizedBox(height: 20),

                      // Billing Address Card
                      _buildBillingAddressCard(isDark),
                      const SizedBox(height: 20),

                      // Shipping Address Card with Copy Action
                      _buildShippingAddressCard(isDark),
                      const SizedBox(height: 32),

                      // Bottom Save Button
                      _buildBottomActionButtons(isDark, isSubmitting),
                      const SizedBox(height: 24),

                      // Danger Zone Card
                      _buildDangerZoneCard(isDark, isSubmitting),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(bool isDark, String displayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: widget.customer.avatarUrl != null &&
                    widget.customer.avatarUrl!.isNotEmpty
                ? NetworkImage(widget.customer.avatarUrl!)
                : null,
            child: widget.customer.avatarUrl == null ||
                    widget.customer.avatarUrl!.isEmpty
                ? Text(
                    displayName.isNotEmpty
                        ? displayName.trim().substring(0, 1).toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
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
                      ),
                      child: Text(
                        'ID #${widget.customer.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.customer.email ?? 'No email configured',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      title: 'Personal & Account Info',
      icon: Icons.person_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  isDark: isDark,
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  isDark: isDark,
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Account Email',
                  isDark: isDark,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRoleDropdown(isDark),
              ),
            ],
          ),
          if (_usernameController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usernameController,
              label: 'Username (Read-only)',
              isDark: isDark,
              enabled: false,
              prefixIcon: Icons.account_circle_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Role',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: _inputDecoration(
            isDark: isDark,
            prefixIcon: Icons.shield_outlined,
          ),
          dropdownColor:
              isDark ? AppColors.darkCardElevated : AppColors.lightSurface,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: _availableRoles.map((role) {
            return DropdownMenuItem<String>(
              value: role['value'],
              child: Text(role['label']!),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedRole = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBillingAddressCard(bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      title: 'Billing Address',
      icon: Icons.receipt_long_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _billingFirstNameController,
                  label: 'First Name',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _billingLastNameController,
                  label: 'Last Name',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _billingCompanyController,
            label: 'Company',
            isDark: isDark,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _billingAddress1Controller,
            label: 'Street Address 1',
            isDark: isDark,
            prefixIcon: Icons.home_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _billingAddress2Controller,
            label: 'Apartment, Suite, Unit, etc. (Optional)',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _billingCityController,
                  label: 'City',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _billingStateController,
                  label: 'State / Province',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _billingPostcodeController,
                  label: 'Postal / ZIP Code',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _billingCountryController,
                  label: 'Country (e.g. US, GB, CA)',
                  isDark: isDark,
                  prefixIcon: Icons.public_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _billingEmailController,
                  label: 'Billing Email',
                  isDark: isDark,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Enter a valid email';
                      }
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _billingPhoneController,
                  label: 'Billing Phone',
                  isDark: isDark,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressCard(bool isDark) {
    return _buildCardWrapper(
      isDark: isDark,
      title: 'Shipping Address',
      icon: Icons.local_shipping_rounded,
      headerTrailing: TextButton.icon(
        onPressed: _copyBillingToShipping,
        icon: const Icon(Icons.content_copy_rounded, size: 16),
        label: const Text(
          'Copy Billing',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _shippingFirstNameController,
                  label: 'First Name',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _shippingLastNameController,
                  label: 'Last Name',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _shippingCompanyController,
            label: 'Company',
            isDark: isDark,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _shippingAddress1Controller,
            label: 'Street Address 1',
            isDark: isDark,
            prefixIcon: Icons.home_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _shippingAddress2Controller,
            label: 'Apartment, Suite, Unit, etc. (Optional)',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _shippingCityController,
                  label: 'City',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _shippingStateController,
                  label: 'State / Province',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _shippingPostcodeController,
                  label: 'Postal / ZIP Code',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _shippingCountryController,
                  label: 'Country (e.g. US, GB, CA)',
                  isDark: isDark,
                  prefixIcon: Icons.public_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _shippingPhoneController,
            label: 'Shipping Phone',
            isDark: isDark,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(bool isDark, bool isSubmitting) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isSubmitting ? null : () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: isSubmitting ? null : _submitForm,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_circle_rounded, size: 18),
          label: Text(
            isSubmitting ? 'Updating Customer...' : 'Save Changes',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({
    required bool isDark,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? headerTrailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              ?headerTrailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    IconData? prefixIcon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: _inputDecoration(
            isDark: isDark,
            prefixIcon: prefixIcon,
            enabled: enabled,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required bool isDark,
    IconData? prefixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: enabled
          ? (isDark ? AppColors.darkCard : AppColors.lightCardElevated)
          : (isDark
              ? AppColors.darkBackground.withValues(alpha: 0.5)
              : AppColors.lightBorderSubtle),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 18,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  Future<void> _handleDeleteCustomer() async {
    final customerId = widget.customer.id;
    if (customerId == null) return;

    final deleted = await DeleteCustomerDialog.show(
      context,
      customerId: customerId,
      customerName: widget.customer.displayName,
      customerEmail: widget.customer.email,
    );

    if (deleted == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildDangerZoneCard(bool isDark, bool isSubmitting) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.error.withValues(alpha: 0.08)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.error.withValues(alpha: isDark ? 0.35 : 0.25),
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
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Permanently delete customer #${widget.customer.id} (${widget.customer.displayName}) from your WooCommerce store using force=true. This action cannot be undone.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isSubmitting ? null : _handleDeleteCustomer,
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text(
              'Delete Customer',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
