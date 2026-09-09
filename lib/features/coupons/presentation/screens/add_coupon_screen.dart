import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/coupons_bloc.dart';
import '../../bloc/coupons_event.dart';
import '../../bloc/create_coupon_cubit.dart';
import '../../bloc/create_coupon_state.dart';
import '../../data/models/get_coupon_report_model.dart';
import '../../data/models/post_create_coupon_model.dart';
import '../../data/repositories/coupons_repository.dart';

/// Samsung One UI 9-inspired Add Coupon Screen for WooCommerce Admin.
/// Interacts with WooCommerce API:
/// `POST /wp-json/wc/v3/coupons`
///
/// Features:
/// - Sends ONLY writable fields in creation payload.
/// - Validates code, discount amount, min/max spend, and email formats.
/// - Live Ticket Preview Card that reflects form inputs in real time.
/// - Duplicate submission prevention and loading state indicators.
/// - Comprehensive error handling (validation, auth, network, duplicate codes).
/// - Synchronizes with CouponsBloc on success and shows "Coupon created successfully".
class AddCouponScreen extends StatefulWidget {
  const AddCouponScreen({super.key});

  static Route<bool> route() {
    return MaterialPageRoute<bool>(
      builder: (context) {
        try {
          context.read<CreateCouponCubit>();
          return const AddCouponScreen();
        } catch (_) {
          final repo = context.read<CouponsRepository>();
          return BlocProvider<CreateCouponCubit>(
            create: (_) => CreateCouponCubit(repository: repo),
            child: const AddCouponScreen(),
          );
        }
      },
    );
  }

  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(route());
  }

  @override
  State<AddCouponScreen> createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  final _formKey = GlobalKey<FormState>();

  // General controllers
  late final TextEditingController _codeController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  // Restrictions controllers
  late final TextEditingController _minSpendController;
  late final TextEditingController _maxSpendController;
  late final TextEditingController _productIdsController;
  late final TextEditingController _excludedProductIdsController;
  late final TextEditingController _categoryIdsController;
  late final TextEditingController _excludedCategoryIdsController;
  late final TextEditingController _emailRestrictionsController;

  // Usage limits controllers
  late final TextEditingController _usageLimitController;
  late final TextEditingController _limitUsageToXItemsController;
  late final TextEditingController _usageLimitPerUserController;

  // Configuration options
  String _discountType = 'percent'; // percent, fixed_cart, fixed_product
  DateTime? _dateExpires;
  bool _individualUse = false;
  bool _freeShipping = false;
  bool _excludeSaleItems = false;

  static const List<Map<String, String>> _discountTypes = [
    {
      'value': 'percent',
      'label': 'Percentage discount',
      'subtitle': 'A percentage discount for the entire cart (e.g. 15%)',
      'symbol': '%',
    },
    {
      'value': 'fixed_cart',
      'label': 'Fixed cart discount',
      'subtitle': 'A fixed total discount for the entire cart (e.g. \$10)',
      'symbol': '\$',
    },
    {
      'value': 'fixed_product',
      'label': 'Fixed product discount',
      'subtitle': 'A fixed discount for defined products only (e.g. \$5/item)',
      'symbol': '\$',
    },
  ];

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();

    _minSpendController = TextEditingController();
    _maxSpendController = TextEditingController();
    _productIdsController = TextEditingController();
    _excludedProductIdsController = TextEditingController();
    _categoryIdsController = TextEditingController();
    _excludedCategoryIdsController = TextEditingController();
    _emailRestrictionsController = TextEditingController();

    _usageLimitController = TextEditingController();
    _limitUsageToXItemsController = TextEditingController();
    _usageLimitPerUserController = TextEditingController();

    // Listeners for live ticket preview
    _codeController.addListener(_updatePreview);
    _amountController.addListener(_updatePreview);
    _descriptionController.addListener(_updatePreview);
    _minSpendController.addListener(_updatePreview);
  }

  void _updatePreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _codeController.removeListener(_updatePreview);
    _amountController.removeListener(_updatePreview);
    _descriptionController.removeListener(_updatePreview);
    _minSpendController.removeListener(_updatePreview);

    _codeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();

    _minSpendController.dispose();
    _maxSpendController.dispose();
    _productIdsController.dispose();
    _excludedProductIdsController.dispose();
    _categoryIdsController.dispose();
    _excludedCategoryIdsController.dispose();
    _emailRestrictionsController.dispose();

    _usageLimitController.dispose();
    _limitUsageToXItemsController.dispose();
    _usageLimitPerUserController.dispose();
    super.dispose();
  }

  void _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final randomPart = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    final prefixes = ['SALE', 'PROMO', 'SAVE', 'VIP', 'DEAL'];
    final prefix = prefixes[random.nextInt(prefixes.length)];
    final code = '$prefix-$randomPart';

    _codeController.text = code;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated coupon code: $code'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _codeController.clear();
    _amountController.clear();
    _descriptionController.clear();
    _minSpendController.clear();
    _maxSpendController.clear();
    _productIdsController.clear();
    _excludedProductIdsController.clear();
    _categoryIdsController.clear();
    _excludedCategoryIdsController.clear();
    _emailRestrictionsController.clear();
    _usageLimitController.clear();
    _limitUsageToXItemsController.clear();
    _usageLimitPerUserController.clear();

    setState(() {
      _discountType = 'percent';
      _dateExpires = null;
      _individualUse = false;
      _freeShipping = false;
      _excludeSaleItems = false;
    });
  }

  List<int> _parseIdList(String input) {
    if (input.trim().isEmpty) return [];
    return input
        .split(RegExp(r'[,;\s]+'))
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList();
  }

  List<String> _parseEmailList(String input) {
    if (input.trim().isEmpty) return [];
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return input
        .split(RegExp(r'[,;\s]+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty && emailRegex.hasMatch(s))
        .toSet()
        .toList();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initialDate = _dateExpires ?? now.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    surface: AppColors.darkSurface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    surface: AppColors.lightSurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateExpires = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = _codeController.text.trim();
    final amount = _amountController.text.trim();

    // Validate min and max spend consistency
    final minSpend = double.tryParse(_minSpendController.text.trim());
    final maxSpend = double.tryParse(_maxSpendController.text.trim());
    if (minSpend != null && maxSpend != null && maxSpend < minSpend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum spend must be greater than or equal to minimum spend.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Format expiry date if selected
    String? dateExpiresStr;
    if (_dateExpires != null) {
      dateExpiresStr = DateFormat('yyyy-MM-dd').format(_dateExpires!);
    }

    // Parse relationship IDs and emails
    final productIds = _parseIdList(_productIdsController.text);
    final excludedProductIds = _parseIdList(_excludedProductIdsController.text);
    final categoryIds = _parseIdList(_categoryIdsController.text);
    final excludedCategoryIds = _parseIdList(_excludedCategoryIdsController.text);
    final emailRestrictions = _parseEmailList(_emailRestrictionsController.text);

    final usageLimit = int.tryParse(_usageLimitController.text.trim());
    final usageLimitPerUser =
        int.tryParse(_usageLimitPerUserController.text.trim());
    final limitUsageToXItems =
        int.tryParse(_limitUsageToXItemsController.text.trim());

    // Build ONLY writable fields required by WooCommerce API
    final payload = PostCreateCouponModel.toCreatePayload(
      code: code,
      amount: amount,
      discountType: _discountType,
      description: _descriptionController.text.trim(),
      dateExpires: dateExpiresStr,
      individualUse: _individualUse,
      freeShipping: _freeShipping,
      excludeSaleItems: _excludeSaleItems,
      minimumAmount: _minSpendController.text.trim(),
      maximumAmount: _maxSpendController.text.trim(),
      productIds: productIds.isNotEmpty ? productIds : null,
      excludedProductIds:
          excludedProductIds.isNotEmpty ? excludedProductIds : null,
      productCategories: categoryIds.isNotEmpty ? categoryIds : null,
      excludedProductCategories:
          excludedCategoryIds.isNotEmpty ? excludedCategoryIds : null,
      emailRestrictions:
          emailRestrictions.isNotEmpty ? emailRestrictions : null,
      usageLimit: usageLimit,
      usageLimitPerUser: usageLimitPerUser,
      limitUsageToXItems: limitUsageToXItems,
    );

    final cubit = context.read<CreateCouponCubit>();
    final created = await cubit.createCoupon(payload);

    if (created != null && mounted) {
      // 1. Sync CouponsBloc: add to local list and trigger background refresh
      try {
        final couponReport = GETCouponReportModel.fromJson(created.toJson());
        final couponsBloc = context.read<CouponsBloc>();
        couponsBloc.add(CouponsCouponCreated(couponReport));
        couponsBloc.add(const CouponsRefreshed());
      } catch (_) {}

      // 2. Clear form
      _clearForm();

      // 3. Show exact required success message: "Coupon created successfully"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Coupon created successfully',
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

      // 4. Return true and navigate back to coupons list
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CreateCouponCubit, CreateCouponState>(
      listener: (context, state) {
        if (state.isFailure && state.errorMessage != null) {
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
          appBar: _buildAppBar(context, isDark, isSubmitting),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Ticket Preview Card
                      _buildLiveTicketPreview(isDark),
                      const SizedBox(height: 24),

                      // Section 1: General Details
                      _buildGeneralCard(isDark, isSubmitting),
                      const SizedBox(height: 20),

                      // Section 2: Usage Restrictions
                      _buildRestrictionsCard(isDark, isSubmitting),
                      const SizedBox(height: 20),

                      // Section 3: Usage Limits
                      _buildUsageLimitsCard(isDark, isSubmitting),
                      const SizedBox(height: 28),

                      // Bottom Action Buttons
                      _buildBottomActionButtons(isDark, isSubmitting),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        onPressed: isSubmitting ? null : () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Coupon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            'WooCommerce Promotions & Discounts',
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
          child: Center(
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : _submitForm,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                isSubmitting ? 'Creating...' : 'Create Coupon',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
    );
  }

  /// Live visual ticket preview that updates as the user fills out the coupon form
  Widget _buildLiveTicketPreview(bool isDark) {
    final code = _codeController.text.trim().isNotEmpty
        ? _codeController.text.trim().toUpperCase()
        : 'COUPON_CODE';
    final amount = _amountController.text.trim().isNotEmpty
        ? _amountController.text.trim()
        : '0';

    String discountBadgeText;
    if (_discountType == 'percent') {
      discountBadgeText = '$amount% OFF';
    } else if (_discountType == 'fixed_cart') {
      discountBadgeText = '\$$amount OFF';
    } else {
      discountBadgeText = '\$$amount/item';
    }

    final description = _descriptionController.text.trim().isNotEmpty
        ? _descriptionController.text.trim()
        : 'Configure discount details and promotion rules below.';

    final expiryText = _dateExpires != null
        ? 'Expires: ${DateFormat('MMM dd, yyyy').format(_dateExpires!)}'
        : 'No expiration date';

    final minSpend = _minSpendController.text.trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
              : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'PREVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  discountBadgeText,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Coupon Code Display
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              if (_freeShipping) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_shipping_rounded,
                          size: 13, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text(
                        'Free Shipping',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Badges Row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    expiryText,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (minSpend.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Min. Spend: \$$minSpend',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (_individualUse) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Individual Use',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
              if (_excludeSaleItems) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Excludes Sale Items',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard(bool isDark, bool isSubmitting) {
    final selectedSymbol = _discountType == 'percent' ? '%' : '\$';

    return _buildCard(
      title: 'General Settings',
      icon: Icons.tune_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coupon Code Field with Generator button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _codeController,
                  label: 'Coupon Code *',
                  hint: 'e.g. SUMMER2026',
                  prefixIcon: Icons.confirmation_number_outlined,
                  isDark: isDark,
                  enabled: !isSubmitting,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Coupon code is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Code must be at least 2 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Tooltip(
                  message: 'Generate random coupon code',
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : _generateRandomCode,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text(
                      'Generate',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Discount Type Selector
          Text(
            'Discount Type *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _discountType,
                isExpanded: true,
                dropdownColor:
                    isDark ? AppColors.darkSurface : AppColors.lightSurface,
                icon: const Icon(Icons.arrow_drop_down_rounded),
                onChanged: isSubmitting
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _discountType = val);
                        }
                      },
                items: _discountTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value']!,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          type['label']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          type['subtitle']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Coupon Amount Field
          _buildTextField(
            controller: _amountController,
            label: 'Coupon Amount *',
            hint: _discountType == 'percent' ? 'e.g. 15' : 'e.g. 25.00',
            prefixIcon: _discountType == 'percent'
                ? Icons.percent_rounded
                : Icons.attach_money_rounded,
            suffixText: selectedSymbol,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isDark: isDark,
            enabled: !isSubmitting,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Coupon amount is required';
              }
              final parsed = double.tryParse(value.trim());
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid positive number';
              }
              if (_discountType == 'percent' && parsed > 100) {
                return 'Percentage discount cannot exceed 100%';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Coupon Description
          _buildTextField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            hint: 'e.g. 15% discount on all spring catalog items',
            prefixIcon: Icons.description_outlined,
            maxLines: 2,
            isDark: isDark,
            enabled: !isSubmitting,
          ),
          const SizedBox(height: 18),

          // Expiry Date Picker Container
          Text(
            'Coupon Expiry Date',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: isSubmitting ? null : _pickExpiryDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: _dateExpires != null
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateExpires != null
                          ? DateFormat('MMMM dd, yyyy').format(_dateExpires!)
                          : 'No expiration date (Never expires)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _dateExpires != null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _dateExpires != null
                            ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                      ),
                    ),
                  ),
                  if (_dateExpires != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isSubmitting
                          ? null
                          : () => setState(() => _dateExpires = null),
                      tooltip: 'Clear expiration date',
                    )
                  else
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Free Shipping Switch Tile
          _buildSwitchTile(
            title: 'Allow Free Shipping',
            subtitle:
                'Check this box if the coupon grants free shipping. A free shipping method must be enabled in shipping zones.',
            value: _freeShipping,
            onChanged: isSubmitting
                ? null
                : (val) => setState(() => _freeShipping = val),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionsCard(bool isDark, bool isSubmitting) {
    return _buildCard(
      title: 'Usage Restrictions',
      icon: Icons.lock_outline_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimum and Maximum Spend
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoCol = constraints.maxWidth > 500;
              final minField = _buildTextField(
                controller: _minSpendController,
                label: 'Minimum Spend (\$) (Optional)',
                hint: 'No minimum',
                prefixIcon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                isDark: isDark,
                enabled: !isSubmitting,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final p = double.tryParse(val.trim());
                    if (p == null || p < 0) return 'Invalid minimum spend';
                  }
                  return null;
                },
              );

              final maxField = _buildTextField(
                controller: _maxSpendController,
                label: 'Maximum Spend (\$) (Optional)',
                hint: 'No maximum',
                prefixIcon: Icons.attach_money_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                isDark: isDark,
                enabled: !isSubmitting,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final p = double.tryParse(val.trim());
                    if (p == null || p < 0) return 'Invalid maximum spend';
                  }
                  return null;
                },
              );

              if (isTwoCol) {
                return Row(
                  children: [
                    Expanded(child: minField),
                    const SizedBox(width: 14),
                    Expanded(child: maxField),
                  ],
                );
              }

              return Column(
                children: [
                  minField,
                  const SizedBox(height: 14),
                  maxField,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Individual Use Switch
          _buildSwitchTile(
            title: 'Individual Use Only',
            subtitle:
                'Check this box if the coupon cannot be used in conjunction with other coupons.',
            value: _individualUse,
            onChanged: isSubmitting
                ? null
                : (val) => setState(() => _individualUse = val),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Exclude Sale Items Switch
          _buildSwitchTile(
            title: 'Exclude Sale Items',
            subtitle:
                'Check this box if the coupon should not apply to items on sale. Per-item coupons will only work if the item is not on sale.',
            value: _excludeSaleItems,
            onChanged: isSubmitting
                ? null
                : (val) => setState(() => _excludeSaleItems = val),
            isDark: isDark,
          ),
          const SizedBox(height: 18),

          // Products & Excluded Products
          _buildTextField(
            controller: _productIdsController,
            label: 'Products (IDs)',
            hint: 'e.g. 102, 105, 210',
            prefixIcon: Icons.inventory_2_outlined,
            helperText:
                'Products that the coupon applies to. Leave blank to apply to all products.',
            isDark: isDark,
            enabled: !isSubmitting,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _excludedProductIdsController,
            label: 'Exclude Products (IDs)',
            hint: 'e.g. 305, 412',
            prefixIcon: Icons.block_flipped,
            helperText: 'Products that the coupon will NOT apply to.',
            isDark: isDark,
            enabled: !isSubmitting,
          ),
          const SizedBox(height: 16),

          // Product Categories & Excluded Categories
          _buildTextField(
            controller: _categoryIdsController,
            label: 'Product Categories (IDs)',
            hint: 'e.g. 12, 15',
            prefixIcon: Icons.category_outlined,
            helperText:
                'Product categories that the coupon applies to. Leave blank for all categories.',
            isDark: isDark,
            enabled: !isSubmitting,
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _excludedCategoryIdsController,
            label: 'Exclude Categories (IDs)',
            hint: 'e.g. 18, 22',
            prefixIcon: Icons.remove_circle_outline_rounded,
            helperText: 'Product categories that the coupon will NOT apply to.',
            isDark: isDark,
            enabled: !isSubmitting,
          ),
          const SizedBox(height: 16),

          // Email Restrictions
          _buildTextField(
            controller: _emailRestrictionsController,
            label: 'Email Restrictions (Optional)',
            hint: 'e.g. vip@example.com, john@example.com',
            prefixIcon: Icons.alternate_email_rounded,
            helperText:
                'Comma-separated emails to check against customer billing email at checkout.',
            isDark: isDark,
            enabled: !isSubmitting,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageLimitsCard(bool isDark, bool isSubmitting) {
    return _buildCard(
      title: 'Usage Limits',
      icon: Icons.speed_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _usageLimitController,
            label: 'Usage Limit Per Coupon (Optional)',
            hint: 'Unlimited usage',
            prefixIcon: Icons.repeat_rounded,
            keyboardType: TextInputType.number,
            helperText:
                'How many times this coupon can be used in total before becoming invalid.',
            isDark: isDark,
            enabled: !isSubmitting,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _limitUsageToXItemsController,
            label: 'Limit Usage to X Items (Optional)',
            hint: 'Apply to all qualifying items',
            prefixIcon: Icons.format_list_numbered_rounded,
            keyboardType: TextInputType.number,
            helperText:
                'The maximum number of individual items this discount can apply to when using product discounts.',
            isDark: isDark,
            enabled: !isSubmitting,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _usageLimitPerUserController,
            label: 'Usage Limit Per User (Optional)',
            hint: 'Unlimited usage per customer',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.number,
            helperText:
                'How many times this coupon can be used by an individual customer.',
            isDark: isDark,
            enabled: !isSubmitting,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
          onPressed:
              isSubmitting ? null : () => Navigator.of(context).maybePop(),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.add_task_rounded, size: 18),
          label: Text(
            isSubmitting ? 'Creating Coupon...' : 'Create Coupon',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
    String? hint,
    String? helperText,
    String? suffixText,
    IconData? prefixIcon,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
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
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
