import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/coupons_bloc.dart';
import '../../bloc/coupons_event.dart';
import '../../bloc/update_coupon_cubit.dart';
import '../../bloc/update_coupon_state.dart';
import '../../data/models/get_coupon_report_model.dart';
import '../../data/models/put_update_coupon_model.dart';
import '../../data/repositories/coupons_repository.dart';

/// Samsung One UI 9-inspired Edit Coupon Screen for WooCommerce Admin.
/// Interacts with WooCommerce API:
/// `PUT /wp-json/wc/v3/coupons/{{couponId}}`
///
/// Features:
/// - Pre-fills all editable parameters from existing [GETCouponReportModel].
/// - Sends ONLY writable fields in update payload.
/// - Validates code, discount amount, min/max spend, and email formats.
/// - Live Ticket Preview Card that reflects edits in real time.
/// - Duplicate submission prevention and loading state indicators.
/// - Comprehensive error handling (validation, auth, network, duplicate codes).
/// - Synchronizes with CouponsBloc on success and shows "Coupon updated successfully".
/// - Returns the updated [GETCouponReportModel] to the caller for instant in-place refresh.
class EditCouponScreen extends StatefulWidget {
  final GETCouponReportModel coupon;

  const EditCouponScreen({
    super.key,
    required this.coupon,
  });

  static Route<GETCouponReportModel?> route({
    required GETCouponReportModel coupon,
  }) {
    return MaterialPageRoute<GETCouponReportModel?>(
      builder: (context) {
        try {
          context.read<UpdateCouponCubit>();
          return EditCouponScreen(coupon: coupon);
        } catch (_) {
          final repo = context.read<CouponsRepository>();
          return BlocProvider<UpdateCouponCubit>(
            create: (_) => UpdateCouponCubit(repository: repo),
            child: EditCouponScreen(coupon: coupon),
          );
        }
      },
    );
  }

  static Future<GETCouponReportModel?> show(
    BuildContext context, {
    required GETCouponReportModel coupon,
  }) {
    return Navigator.of(context).push<GETCouponReportModel?>(
      route(coupon: coupon),
    );
  }

  @override
  State<EditCouponScreen> createState() => _EditCouponScreenState();
}

class _EditCouponScreenState extends State<EditCouponScreen> {
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
  late String _discountType;
  DateTime? _dateExpires;
  late bool _individualUse;
  late bool _freeShipping;
  late bool _excludeSaleItems;

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
    final c = widget.coupon;

    _codeController = TextEditingController(text: c.code ?? '');
    _amountController = TextEditingController(text: c.amount ?? '');
    _descriptionController = TextEditingController(text: c.description ?? '');

    final minAmount = (c.minimumAmount != null &&
            c.minimumAmount != '0.00' &&
            c.minimumAmount != '0')
        ? c.minimumAmount!
        : '';
    final maxAmount = (c.maximumAmount != null &&
            c.maximumAmount != '0.00' &&
            c.maximumAmount != '0')
        ? c.maximumAmount!
        : '';

    _minSpendController = TextEditingController(text: minAmount);
    _maxSpendController = TextEditingController(text: maxAmount);

    _productIdsController = TextEditingController(
      text: c.productIds != null && c.productIds!.isNotEmpty
          ? c.productIds!.join(', ')
          : '',
    );
    _excludedProductIdsController = TextEditingController(
      text: c.excludedProductIds != null && c.excludedProductIds!.isNotEmpty
          ? c.excludedProductIds!.join(', ')
          : '',
    );
    _categoryIdsController = TextEditingController(
      text: c.productCategories != null && c.productCategories!.isNotEmpty
          ? c.productCategories!.join(', ')
          : '',
    );
    _excludedCategoryIdsController = TextEditingController(
      text: c.excludedProductCategories != null &&
              c.excludedProductCategories!.isNotEmpty
          ? c.excludedProductCategories!.join(', ')
          : '',
    );
    _emailRestrictionsController = TextEditingController(
      text: c.emailRestrictions != null && c.emailRestrictions!.isNotEmpty
          ? c.emailRestrictions!.join(', ')
          : '',
    );

    _usageLimitController = TextEditingController(
      text: c.usageLimit != null && c.usageLimit > 0
          ? c.usageLimit.toString()
          : '',
    );
    _limitUsageToXItemsController = TextEditingController(
      text: c.limitUsageToXItems != null && c.limitUsageToXItems > 0
          ? c.limitUsageToXItems.toString()
          : '',
    );
    _usageLimitPerUserController = TextEditingController(
      text: c.usageLimitPerUser != null && c.usageLimitPerUser > 0
          ? c.usageLimitPerUser.toString()
          : '',
    );

    _discountType = c.discountType ?? 'percent';
    _dateExpires = c.parsedDateExpires;
    _individualUse = c.individualUse ?? false;
    _freeShipping = c.freeShipping ?? false;
    _excludeSaleItems = c.excludeSaleItems ?? false;

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
    final randomPart =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
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

  void _resetToInitial() {
    final c = widget.coupon;
    _formKey.currentState?.reset();

    _codeController.text = c.code ?? '';
    _amountController.text = c.amount ?? '';
    _descriptionController.text = c.description ?? '';

    final minAmount = (c.minimumAmount != null &&
            c.minimumAmount != '0.00' &&
            c.minimumAmount != '0')
        ? c.minimumAmount!
        : '';
    final maxAmount = (c.maximumAmount != null &&
            c.maximumAmount != '0.00' &&
            c.maximumAmount != '0')
        ? c.maximumAmount!
        : '';

    _minSpendController.text = minAmount;
    _maxSpendController.text = maxAmount;

    _productIdsController.text =
        c.productIds != null && c.productIds!.isNotEmpty
            ? c.productIds!.join(', ')
            : '';
    _excludedProductIdsController.text =
        c.excludedProductIds != null && c.excludedProductIds!.isNotEmpty
            ? c.excludedProductIds!.join(', ')
            : '';
    _categoryIdsController.text =
        c.productCategories != null && c.productCategories!.isNotEmpty
            ? c.productCategories!.join(', ')
            : '';
    _excludedCategoryIdsController.text =
        c.excludedProductCategories != null &&
                c.excludedProductCategories!.isNotEmpty
            ? c.excludedProductCategories!.join(', ')
            : '';
    _emailRestrictionsController.text =
        c.emailRestrictions != null && c.emailRestrictions!.isNotEmpty
            ? c.emailRestrictions!.join(', ')
            : '';

    _usageLimitController.text = c.usageLimit != null && c.usageLimit > 0
        ? c.usageLimit.toString()
        : '';
    _limitUsageToXItemsController.text =
        c.limitUsageToXItems != null && c.limitUsageToXItems > 0
            ? c.limitUsageToXItems.toString()
            : '';
    _usageLimitPerUserController.text =
        c.usageLimitPerUser != null && c.usageLimitPerUser > 0
            ? c.usageLimitPerUser.toString()
            : '';

    setState(() {
      _discountType = c.discountType ?? 'percent';
      _dateExpires = c.parsedDateExpires;
      _individualUse = c.individualUse ?? false;
      _freeShipping = c.freeShipping ?? false;
      _excludeSaleItems = c.excludeSaleItems ?? false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form reset to original values'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      initialDate: initialDate,
      firstDate: DateTime(2020),
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

    final couponId = widget.coupon.id;
    if (couponId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon ID. Cannot update coupon.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          content: Text(
              'Maximum spend must be greater than or equal to minimum spend.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Format expiry date
    String? dateExpiresStr;
    if (_dateExpires != null) {
      dateExpiresStr = DateFormat('yyyy-MM-dd').format(_dateExpires!);
    } else {
      dateExpiresStr = '';
    }

    // Parse relationship IDs and emails
    final productIds = _parseIdList(_productIdsController.text);
    final excludedProductIds = _parseIdList(_excludedProductIdsController.text);
    final categoryIds = _parseIdList(_categoryIdsController.text);
    final excludedCategoryIds =
        _parseIdList(_excludedCategoryIdsController.text);
    final emailRestrictions = _parseEmailList(_emailRestrictionsController.text);

    final usageLimit = int.tryParse(_usageLimitController.text.trim());
    final usageLimitPerUser =
        int.tryParse(_usageLimitPerUserController.text.trim());
    final limitUsageToXItems =
        int.tryParse(_limitUsageToXItemsController.text.trim());

    // Build ONLY writable fields required by WooCommerce API
    final payload = PutUpdateCouponModel.toUpdatePayload(
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
      productIds: productIds,
      excludedProductIds: excludedProductIds,
      productCategories: categoryIds,
      excludedProductCategories: excludedCategoryIds,
      emailRestrictions: emailRestrictions,
      usageLimit: usageLimit,
      usageLimitPerUser: usageLimitPerUser,
      limitUsageToXItems: limitUsageToXItems,
    );

    final cubit = context.read<UpdateCouponCubit>();
    final updated = await cubit.updateCoupon(
      couponId: couponId,
      updateData: payload,
    );

    if (updated != null && mounted) {
      final updatedReportModel = updated.toCouponReportModel();

      // 1. Sync CouponsBloc: update coupon in local list without breaking pagination
      try {
        final couponsBloc = context.read<CouponsBloc>();
        couponsBloc.add(CouponsCouponUpdated(updatedReportModel));
      } catch (_) {}

      // 2. Show exact required success message: "Coupon updated successfully"
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Coupon updated successfully',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

      // 3. Return updated model to CouponDetailsScreen for immediate view refresh
      Navigator.of(context).pop(updatedReportModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isDark),
      body: BlocConsumer<UpdateCouponCubit, UpdateCouponState>(
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
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Ticket Preview Card
                  _buildLiveTicketPreview(isDark),
                  const SizedBox(height: 24),

                  // Error notification banner if state has error
                  if (state.errorMessage != null) ...[
                    _buildErrorBanner(state.errorMessage!, isDark),
                    const SizedBox(height: 20),
                  ],

                  // Section 1: General Details
                  _buildGeneralCard(isDark, state.isSubmitting),
                  const SizedBox(height: 20),

                  // Section 2: Usage Restrictions
                  _buildRestrictionsCard(isDark, state.isSubmitting),
                  const SizedBox(height: 20),

                  // Section 3: Usage Limits
                  _buildLimitsCard(isDark, state.isSubmitting),
                  const SizedBox(height: 28),

                  // Action Buttons
                  _buildActionButtons(isDark, state.isSubmitting),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Cancel and back',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Coupon #${widget.coupon.id ?? 0}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            widget.coupon.code?.toUpperCase() ?? 'COUPON',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reset to original values',
          onPressed: _resetToInitial,
        ),
        const SizedBox(width: 8),
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

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Failed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
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
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.error,
            tooltip: 'Dismiss',
            onPressed: () {
              context.read<UpdateCouponCubit>().clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTicketPreview(bool isDark) {
    final code = _codeController.text.trim().isNotEmpty
        ? _codeController.text.trim().toUpperCase()
        : (widget.coupon.code?.toUpperCase() ?? 'PROMO');
    final rawAmount = _amountController.text.trim();
    final amountVal = double.tryParse(rawAmount) ?? 0.0;

    String discountBadge;
    if (_discountType == 'percent') {
      discountBadge =
          '${amountVal > 0 ? (amountVal % 1 == 0 ? amountVal.toInt() : amountVal) : '0'}% OFF';
    } else if (_discountType == 'fixed_cart') {
      discountBadge =
          '\$${amountVal > 0 ? amountVal.toStringAsFixed(2) : '0.00'} OFF';
    } else {
      discountBadge =
          '\$${amountVal > 0 ? amountVal.toStringAsFixed(2) : '0.00'} / ITEM';
    }

    final typeLabel = _discountTypes
        .firstWhere((e) => e['value'] == _discountType,
            orElse: () => {'label': 'Discount'})['label']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_rounded,
                        size: 13, color: AppColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'LIVE TICKET PREVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_dateExpires != null)
                Text(
                  'Expires ${DateFormat('MMM dd, yyyy').format(_dateExpires!)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                )
              else
                Text(
                  'No expiry set',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          discountBadge,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $typeLabel',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_descriptionController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _descriptionController.text.trim(),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_freeShipping)
                _buildTag('Free Shipping', Icons.local_shipping_rounded,
                    AppColors.success, isDark),
              if (_individualUse)
                _buildTag('Individual Use Only', Icons.person_rounded,
                    AppColors.primary, isDark),
              if (_excludeSaleItems)
                _buildTag('Excludes Sale Items', Icons.money_off_rounded,
                    AppColors.warning, isDark),
              if (_minSpendController.text.trim().isNotEmpty)
                _buildTag(
                    'Min Spend \$${_minSpendController.text.trim()}',
                    Icons.shopping_bag_outlined,
                    AppColors.info,
                    isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(
      String label, IconData icon, Color baseColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: baseColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: baseColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 1: GENERAL DETAILS
  // ==========================================
  Widget _buildGeneralCard(bool isDark, bool isSubmitting) {
    return _buildCardContainer(
      isDark: isDark,
      title: 'General Settings',
      subtitle: 'Coupon code, discount formula, and terms',
      icon: Icons.tune_rounded,
      children: [
        // Coupon Code input + Generate button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                enabled: !isSubmitting,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-\.]')),
                  UpperCaseTextFormatter(),
                ],
                decoration: _inputDecoration(
                  label: 'Coupon Code *',
                  hint: 'e.g. SUMMER50',
                  icon: Icons.confirmation_number_outlined,
                  isDark: isDark,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Coupon code is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Coupon code must be at least 2 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : _generateRandomCode,
                icon: const Icon(Icons.casino_outlined, size: 16),
                label: const Text('Random'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Discount Type Selector
        DropdownButtonFormField<String>(
          initialValue: _discountType,
          isExpanded: true,
          decoration: _inputDecoration(
            label: 'Discount Type *',
            icon: Icons.local_offer_outlined,
            isDark: isDark,
          ),
          dropdownColor:
              isDark ? AppColors.darkSurface : AppColors.lightSurface,
          items: _discountTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type['value'],
              child: Text(
                type['label']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            );
          }).toList(),
          onChanged: isSubmitting
              ? null
              : (val) {
                  if (val != null) {
                    setState(() {
                      _discountType = val;
                    });
                  }
                },
        ),
        const SizedBox(height: 18),

        // Coupon Amount
        TextFormField(
          controller: _amountController,
          enabled: !isSubmitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: _inputDecoration(
            label: 'Coupon Amount *',
            hint: _discountType == 'percent' ? 'e.g. 20 (for 20%)' : 'e.g. 15.00',
            icon: _discountType == 'percent'
                ? Icons.percent_rounded
                : Icons.attach_money_rounded,
            isDark: isDark,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Discount amount is required';
            }
            final amount = double.tryParse(val.trim());
            if (amount == null || amount <= 0) {
              return 'Enter a valid amount greater than 0';
            }
            if (_discountType == 'percent' && amount > 100) {
              return 'Percentage discount cannot exceed 100%';
            }
            return null;
          },
        ),
        const SizedBox(height: 18),

        // Description
        TextFormField(
          controller: _descriptionController,
          enabled: !isSubmitting,
          maxLines: 2,
          decoration: _inputDecoration(
            label: 'Description (Optional)',
            hint: 'Internal notes or customer visible explanation...',
            icon: Icons.notes_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 18),

        // Expiry Date Picker
        InkWell(
          onTap: isSubmitting ? null : _pickExpiryDate,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: _inputDecoration(
              label: 'Coupon Expiry Date',
              hint: 'YYYY-MM-DD (No expiration if left blank)',
              icon: Icons.calendar_today_rounded,
              isDark: isDark,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateExpires != null
                      ? DateFormat('yyyy-MM-dd (EEEE, MMM d, yyyy)')
                          .format(_dateExpires!)
                      : 'No expiration date',
                  style: TextStyle(
                    fontSize: 14,
                    color: _dateExpires != null
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                    fontWeight: _dateExpires != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (_dateExpires != null)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    tooltip: 'Remove expiry date',
                    onPressed: isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _dateExpires = null;
                            });
                          },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Free Shipping switch
        _buildSwitchTile(
          title: 'Allow Free Shipping',
          subtitle:
              'Check this box if the coupon grants free shipping. A free shipping method must be enabled in your shipping zone.',
          value: _freeShipping,
          isDark: isDark,
          onChanged: isSubmitting
              ? null
              : (val) => setState(() => _freeShipping = val),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2: USAGE RESTRICTIONS
  // ==========================================
  Widget _buildRestrictionsCard(bool isDark, bool isSubmitting) {
    return _buildCardContainer(
      isDark: isDark,
      title: 'Usage Restrictions',
      subtitle: 'Cart totals, individual use, and product requirements',
      icon: Icons.rule_rounded,
      children: [
        // Min / Max spend
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _minSpendController,
                enabled: !isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: _inputDecoration(
                  label: 'Minimum Spend',
                  hint: 'No minimum',
                  icon: Icons.arrow_downward_rounded,
                  isDark: isDark,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _maxSpendController,
                enabled: !isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: _inputDecoration(
                  label: 'Maximum Spend',
                  hint: 'No maximum',
                  icon: Icons.arrow_upward_rounded,
                  isDark: isDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Individual Use switch
        _buildSwitchTile(
          title: 'Individual Use Only',
          subtitle:
              'Check this box if the coupon cannot be used in conjunction with other coupons.',
          value: _individualUse,
          isDark: isDark,
          onChanged: isSubmitting
              ? null
              : (val) => setState(() => _individualUse = val),
        ),
        const Divider(height: 24),

        // Exclude Sale Items switch
        _buildSwitchTile(
          title: 'Exclude Sale Items',
          subtitle:
              'Check this box if the coupon should not apply to items on sale. Per-item coupons will only work if the item is not on sale.',
          value: _excludeSaleItems,
          isDark: isDark,
          onChanged: isSubmitting
              ? null
              : (val) => setState(() => _excludeSaleItems = val),
        ),
        const Divider(height: 24),

        // Products IDs
        TextFormField(
          controller: _productIdsController,
          enabled: !isSubmitting,
          decoration: _inputDecoration(
            label: 'Products (IDs)',
            hint: 'e.g. 101, 102, 103 (comma separated)',
            icon: Icons.inventory_2_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Excluded Products IDs
        TextFormField(
          controller: _excludedProductIdsController,
          enabled: !isSubmitting,
          decoration: _inputDecoration(
            label: 'Exclude Products (IDs)',
            hint: 'e.g. 201, 202',
            icon: Icons.remove_circle_outline_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Product Categories IDs
        TextFormField(
          controller: _categoryIdsController,
          enabled: !isSubmitting,
          decoration: _inputDecoration(
            label: 'Product Categories (IDs)',
            hint: 'e.g. 15, 24',
            icon: Icons.category_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Excluded Category IDs
        TextFormField(
          controller: _excludedCategoryIdsController,
          enabled: !isSubmitting,
          decoration: _inputDecoration(
            label: 'Exclude Categories (IDs)',
            hint: 'e.g. 99, 104',
            icon: Icons.folder_delete_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Allowed Emails
        TextFormField(
          controller: _emailRestrictionsController,
          enabled: !isSubmitting,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration(
            label: 'Allowed Customer Emails',
            hint: 'customer@example.com, vip@ishine.com',
            icon: Icons.alternate_email_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 3: USAGE LIMITS
  // ==========================================
  Widget _buildLimitsCard(bool isDark, bool isSubmitting) {
    return _buildCardContainer(
      isDark: isDark,
      title: 'Usage Limits',
      subtitle: 'Limits per coupon, per user, or per cart items',
      icon: Icons.speed_rounded,
      children: [
        // Limit per coupon
        TextFormField(
          controller: _usageLimitController,
          enabled: !isSubmitting,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            label: 'Usage Limit Per Coupon',
            hint: 'Unlimited if left blank',
            icon: Icons.all_inclusive_rounded,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Limit to X items
        TextFormField(
          controller: _limitUsageToXItemsController,
          enabled: !isSubmitting,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            label: 'Limit Usage to X Items',
            hint: 'Apply to all qualifying items if blank',
            icon: Icons.shopping_basket_outlined,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: 16),

        // Limit per user
        TextFormField(
          controller: _usageLimitPerUserController,
          enabled: !isSubmitting,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _inputDecoration(
            label: 'Usage Limit Per User',
            hint: 'Unlimited if left blank',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, bool isSubmitting) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: isSubmitting
                ? null
                : () {
                    Navigator.of(context).maybePop();
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            ),
            child: isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Updating Coupon...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
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
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: isDark
          ? AppColors.darkCard.withValues(alpha: 0.5)
          : AppColors.lightBackground.withValues(alpha: 0.7),
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
            .withValues(alpha: 0.6),
      ),
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
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

/// Formatter ensuring coupon code input is always capitalized
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
