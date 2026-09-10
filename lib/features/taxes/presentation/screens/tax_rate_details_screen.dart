import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/get_tax_rates_model.dart';
import '../../data/repositories/taxes_repository.dart';

/// Samsung One UI 9-inspired Tax Rate Details & Operations Screen.
/// Utilizes the dynamic `taxRateId` for inspection and future Edit/Delete operations.
class TaxRateDetailsScreen extends StatefulWidget {
  final int taxRateId;
  final GetTaxRatesModel? initialTaxRate;

  const TaxRateDetailsScreen({
    super.key,
    required this.taxRateId,
    this.initialTaxRate,
  });

  static Route<void> route({
    required int taxRateId,
    GetTaxRatesModel? initialTaxRate,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => TaxRateDetailsScreen(
        taxRateId: taxRateId,
        initialTaxRate: initialTaxRate,
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required int taxRateId,
    GetTaxRatesModel? initialTaxRate,
  }) async {
    return Navigator.of(context).push<void>(
      route(taxRateId: taxRateId, initialTaxRate: initialTaxRate),
    );
  }

  @override
  State<TaxRateDetailsScreen> createState() => _TaxRateDetailsScreenState();
}

class _TaxRateDetailsScreenState extends State<TaxRateDetailsScreen> {
  late int _taxRateId;
  GetTaxRatesModel? _rate;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _taxRateId = widget.taxRateId;
    _rate = widget.initialTaxRate;
    if (_rate == null) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<TaxesRepository>();
      final rate = await repository.getTaxRate(
        _taxRateId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _rate = rate;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rate = _rate;
    final isCompound = rate?.compound == true;
    final appliesToShipping = rate?.shipping == true;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          rate?.displayName ?? 'Tax Rate #$_taxRateId',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Rate Data',
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : () => _loadDetails(forceRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Tax Rate Banner (One UI 9)
            _buildHeroRateBanner(context, isDark, rate, isCompound),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              _buildErrorBanner(context, isDark),
              const SizedBox(height: 20),
            ],

            // Core Tax Rate Parameters Card
            _buildParametersCard(context, isDark, rate, isCompound, appliesToShipping),
            const SizedBox(height: 20),

            // Geographic Jurisdiction Card
            _buildJurisdictionCard(context, isDark, rate),
            const SizedBox(height: 20),

            // Dynamic Operations & Future Actions Card (Edit / Delete / API)
            _buildOperationsCard(context, isDark, rate),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroRateBanner(
    BuildContext context,
    bool isDark,
    GetTaxRatesModel? rate,
    bool isCompound,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isCompound ? AppColors.purpleGradient : AppColors.emeraldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isCompound ? AppColors.accent : AppColors.success)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'RATE ID: $_taxRateId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${rate?.taxClassDisplay ?? "Standard"} Class',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate?.formattedRate ?? '0%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  rate?.displayName ?? 'Tax Rate',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Applies to: ${rate?.locationSummary ?? "Global / All jurisdictions"}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersCard(
    BuildContext context,
    bool isDark,
    GetTaxRatesModel? rate,
    bool isCompound,
    bool appliesToShipping,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tax Calculation Attributes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.percent_rounded,
            label: 'Tax Percentage Rate',
            value: rate?.formattedRate ?? '0%',
            actionIcon: Icons.copy_rounded,
            onAction: () => _copyToClipboard(rate?.rate ?? '0', 'Tax Rate'),
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.category_outlined,
            label: 'Tax Class',
            value: rate?.taxClassDisplay ?? 'Standard',
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.low_priority_rounded,
            label: 'Priority',
            value: rate?.priorityDisplay ?? '1',
            description:
                'Only 1 matching rate per priority will be used. Higher priority rates apply in order.',
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.layers_outlined,
            label: 'Compound Tax',
            value: isCompound ? 'Yes (Calculated on top of other taxes)' : 'No (Standard tax)',
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.local_shipping_outlined,
            label: 'Apply to Shipping',
            value: appliesToShipping
                ? 'Yes (Shipping charges are taxed)'
                : 'No (Shipping is tax-exempt)',
          ),
        ],
      ),
    );
  }

  Widget _buildJurisdictionCard(
    BuildContext context,
    bool isDark,
    GetTaxRatesModel? rate,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.public_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Geographic Jurisdiction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.flag_outlined,
            label: 'Country Code',
            value: (rate?.country != null && rate!.country!.isNotEmpty)
                ? rate.country!.toUpperCase()
                : 'All Countries (*)',
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.map_outlined,
            label: 'State / Province',
            value: (rate?.state != null && rate!.state!.isNotEmpty)
                ? rate.state!
                : 'All States (*)',
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.location_city_rounded,
            label: 'City / Cities',
            value: (rate?.cities != null && rate!.cities!.isNotEmpty)
                ? rate.cities!.join(', ')
                : (rate?.city?.isNotEmpty == true ? rate!.city! : 'All Cities (*)'),
          ),
          const Divider(height: 22),

          _buildAttributeItem(
            context,
            isDark,
            icon: Icons.markunread_mailbox_outlined,
            label: 'Postcode / ZIP Codes',
            value: (rate?.postcodes != null && rate!.postcodes!.isNotEmpty)
                ? rate.postcodes!.join(', ')
                : (rate?.postcode?.isNotEmpty == true ? rate!.postcode! : 'All Postcodes (*)'),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsCard(
    BuildContext context,
    bool isDark,
    GetTaxRatesModel? rate,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tax Rate Operations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action 1: Dynamic Edit Tax Rate
          _buildActionRow(
            context: context,
            isDark: isDark,
            icon: Icons.edit_note_rounded,
            title: 'Edit Tax Rate',
            subtitle: 'Dynamic target: PUT /wp-json/wc/v3/taxes/$_taxRateId',
            color: AppColors.primary,
            buttonText: 'Edit Rate',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tax Rate #$_taxRateId ready for editing'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Action 2: Dynamic Delete Tax Rate
          _buildActionRow(
            context: context,
            isDark: isDark,
            icon: Icons.delete_outline_rounded,
            title: 'Delete Tax Rate',
            subtitle: 'Dynamic target: DELETE /wp-json/wc/v3/taxes/$_taxRateId?force=true',
            color: AppColors.error,
            buttonText: 'Delete Rate',
            onTap: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
          const SizedBox(height: 12),

          // Action 3: Copy ID Reference
          _buildActionRow(
            context: context,
            isDark: isDark,
            icon: Icons.copy_rounded,
            title: 'Copy Tax Rate ID',
            subtitle: 'Tax rate ID: $_taxRateId for controllers and batch operations',
            color: AppColors.info,
            buttonText: 'Copy ID',
            onTap: () => _copyToClipboard('$_taxRateId', 'Tax Rate ID'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Tax Rate?'),
        content: Text(
          'Are you sure you want to delete Tax Rate #$_taxRateId (${_rate?.displayName ?? ""})? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tax Rate #$_taxRateId ready for permanent deletion'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeItem(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    String? description,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionIcon != null && onAction != null)
          IconButton(
            icon: Icon(actionIcon, size: 18),
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            onPressed: onAction,
            tooltip: 'Copy',
          ),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to load details',
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _loadDetails(forceRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
