import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/create_tax_rate_cubit.dart';
import '../../bloc/create_tax_rate_state.dart';
import '../../bloc/tax_rates_bloc.dart';
import '../../bloc/tax_rates_event.dart';
import '../../data/models/post_tax_rates_model.dart';
import '../../data/repositories/taxes_repository.dart';

/// Samsung One UI 9-inspired Add Tax Rate Screen for WooCommerce Admin.
/// Submits real tax rate creation to:
/// `POST /wp-json/wc/v3/taxes`
///
/// Features:
/// - Supports all required and optional WooCommerce tax rate fields:
///   country, state, postcode, city, rate, name, priority, compound, shipping, order, class, postcodes, cities.
/// - Live Ticket Preview Card that reflects form inputs in real time.
/// - Validates required fields (Tax Name, Rate percentage) and format errors.
/// - Prevents duplicate in-flight submissions.
/// - On success: parses 201 response, notifies TaxRatesBloc, shows toast, and closes form.
class AddTaxRateScreen extends StatefulWidget {
  const AddTaxRateScreen({super.key});

  static Route<bool> route() {
    return MaterialPageRoute<bool>(
      builder: (context) {
        try {
          context.read<CreateTaxRateCubit>();
          return const AddTaxRateScreen();
        } catch (_) {
          final repo = context.read<TaxesRepository>();
          return BlocProvider<CreateTaxRateCubit>(
            create: (_) => CreateTaxRateCubit(repository: repo),
            child: const AddTaxRateScreen(),
          );
        }
      },
    );
  }

  static Future<bool?> show(BuildContext context) {
    return Navigator.of(context).push<bool>(route());
  }

  @override
  State<AddTaxRateScreen> createState() => _AddTaxRateScreenState();
}

class _AddTaxRateScreenState extends State<AddTaxRateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  late final TextEditingController _countryController;
  late final TextEditingController _stateController;
  late final TextEditingController _postcodeController;
  late final TextEditingController _cityController;
  late final TextEditingController _priorityController;
  late final TextEditingController _orderController;
  late final TextEditingController _postcodesListController;
  late final TextEditingController _citiesListController;

  // Options
  String _taxClass = 'standard';
  bool _compound = false;
  bool _shipping = true;

  static const List<Map<String, String>> _taxClassOptions = [
    {
      'value': 'standard',
      'label': 'Standard rate',
      'subtitle': 'Default standard tax class',
    },
    {
      'value': 'reduced-rate',
      'label': 'Reduced rate',
      'subtitle': 'Concessionary or lower rate bracket',
    },
    {
      'value': 'zero-rate',
      'label': 'Zero rate',
      'subtitle': '0% VAT / exempt items',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _rateController = TextEditingController();
    _countryController = TextEditingController(text: '*');
    _stateController = TextEditingController(text: '*');
    _postcodeController = TextEditingController(text: '*');
    _cityController = TextEditingController(text: '*');
    _priorityController = TextEditingController(text: '1');
    _orderController = TextEditingController(text: '0');
    _postcodesListController = TextEditingController();
    _citiesListController = TextEditingController();

    // Listen to changes to update live preview
    _nameController.addListener(_onFieldChanged);
    _rateController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _rateController.removeListener(_onFieldChanged);
    _countryController.removeListener(_onFieldChanged);
    _stateController.removeListener(_onFieldChanged);

    _nameController.dispose();
    _rateController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _cityController.dispose();
    _priorityController.dispose();
    _orderController.dispose();
    _postcodesListController.dispose();
    _citiesListController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  List<String> _parseCsv(String input) {
    if (input.trim().isEmpty) return [];
    return input
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _submitForm() async {
    final cubit = context.read<CreateTaxRateCubit>();
    if (cubit.state.isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final postcodesList = _parseCsv(_postcodesListController.text);
    final citiesList = _parseCsv(_citiesListController.text);

    final taxRate = PostTaxRatesModel(
      name: _nameController.text.trim(),
      rate: _rateController.text.trim(),
      country: _countryController.text.trim(),
      state: _stateController.text.trim(),
      postcode: _postcodeController.text.trim(),
      city: _cityController.text.trim(),
      priority: int.tryParse(_priorityController.text.trim()) ?? 1,
      order: int.tryParse(_orderController.text.trim()) ?? 0,
      compound: _compound,
      shipping: _shipping,
      taxClass: _taxClass,
      postcodes: postcodesList.isNotEmpty ? postcodesList : null,
      cities: citiesList.isNotEmpty ? citiesList : null,
    );

    final created = await cubit.createTaxRate(taxRate);

    if (created != null && mounted) {
      // Notify TaxRatesBloc to prepend newly created tax rate immediately
      try {
        context.read<TaxRatesBloc>().add(TaxRatesRateCreated(created));
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tax Rate "${created.name ?? "New Rate"}" (#${created.id ?? ""}) created successfully!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CreateTaxRateCubit, CreateTaxRateState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Add Tax Rate',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Tax Rate Preview Card (One UI 9)
                  _buildLivePreviewCard(context, isDark),
                  const SizedBox(height: 24),

                  // Section 1: General Tax Rate Parameters
                  _buildGeneralCard(context, isDark, isSubmitting),
                  const SizedBox(height: 20),

                  // Section 2: Geographic Jurisdiction
                  _buildJurisdictionCard(context, isDark, isSubmitting),
                  const SizedBox(height: 20),

                  // Section 3: Calculation Rules & Compound/Shipping Toggles
                  _buildCalculationRulesCard(context, isDark, isSubmitting),
                  const SizedBox(height: 20),

                  // Section 4: Multi-Postcode & Multi-City Lists (Optional)
                  _buildMultiLocationsCard(context, isDark, isSubmitting),
                  const SizedBox(height: 28),

                  // Submit Action Button
                  _buildSubmitButton(context, isSubmitting),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Live preview ticket card reflecting user inputs in real time
  Widget _buildLivePreviewCard(BuildContext context, bool isDark) {
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Tax Rate Name';
    final rate = _rateController.text.trim().isNotEmpty
        ? '${_rateController.text.trim()}%'
        : '0.00%';
    final country = _countryController.text.trim().isNotEmpty
        ? _countryController.text.trim().toUpperCase()
        : '*';
    final state = _stateController.text.trim().isNotEmpty
        ? _stateController.text.trim().toUpperCase()
        : '*';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: _compound ? AppColors.purpleGradient : AppColors.emeraldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_compound ? AppColors.accent : AppColors.success)
                .withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'LIVE TICKET PREVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _taxClass.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Jurisdiction: $country • $state • Priority: ${_priorityController.text} • ${_compound ? "Compound" : "Standard"}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 1: General Parameters
  Widget _buildGeneralCard(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'General Tax Rate Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tax Name Field
          TextFormField(
            controller: _nameController,
            enabled: !isSubmitting,
            decoration: InputDecoration(
              labelText: 'Tax Name *',
              hintText: 'e.g. State Sales Tax or VAT',
              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter a tax rate name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Tax Rate Percentage
          TextFormField(
            controller: _rateController,
            enabled: !isSubmitting,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}')),
            ],
            decoration: InputDecoration(
              labelText: 'Tax Rate (%) *',
              hintText: 'e.g. 20.0000 or 8.25',
              prefixIcon: const Icon(Icons.percent_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please specify the percentage rate';
              }
              final numVal = double.tryParse(val.trim());
              if (numVal == null) {
                return 'Please enter a valid numeric percentage';
              }
              if (numVal < 0) {
                return 'Tax rate cannot be negative';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Tax Class Selection
          const Text(
            'Tax Class',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taxClassOptions.map((opt) {
              final val = opt['value']!;
              final isSelected = _taxClass == val;

              return ChoiceChip(
                label: Text(opt['label']!),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor:
                    isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: isSubmitting
                    ? null
                    : (selected) {
                        if (selected) {
                          setState(() {
                            _taxClass = val;
                          });
                        }
                      },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Section 2: Geographic Jurisdiction
  Widget _buildJurisdictionCard(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(height: 6),
          Text(
            'Specify ISO country code, state/province, or leave as "*" for global application.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // Country Code
              Expanded(
                child: TextFormField(
                  controller: _countryController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Country Code',
                    hintText: 'e.g. US, GB, or *',
                    prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // State Code
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  enabled: !isSubmitting,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'State Code',
                    hintText: 'e.g. CA, NY, or *',
                    prefixIcon: const Icon(Icons.map_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // City
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'City',
                    hintText: 'e.g. Miami or *',
                    prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Postcode / ZIP
              Expanded(
                child: TextFormField(
                  controller: _postcodeController,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Postcode / ZIP',
                    hintText: 'e.g. 90210 or *',
                    prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section 3: Calculation Rules & Compound/Shipping Toggles
  Widget _buildCalculationRulesCard(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
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
                'Calculation Rules & Priorities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // Priority
              Expanded(
                child: TextFormField(
                  controller: _priorityController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    hintText: 'e.g. 1',
                    prefixIcon: const Icon(Icons.low_priority_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Order
              Expanded(
                child: TextFormField(
                  controller: _orderController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Sort Order',
                    hintText: 'e.g. 0',
                    prefixIcon: const Icon(Icons.sort_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Compound Tax Toggle
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Compound Tax',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Apply this tax rate on top of all other taxes already calculated.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            value: _compound,
            activeTrackColor: AppColors.warning,
            onChanged: isSubmitting
                ? null
                : (val) {
                    setState(() {
                      _compound = val;
                    });
                  },
          ),
          const Divider(height: 16),

          // Shipping Tax Toggle
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Apply to Shipping Charges',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'When enabled, shipping costs are also taxed at this rate.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            value: _shipping,
            activeTrackColor: AppColors.success,
            onChanged: isSubmitting
                ? null
                : (val) {
                    setState(() {
                      _shipping = val;
                    });
                  },
          ),
        ],
      ),
    );
  }

  /// Section 4: Multi-Postcode & Multi-City Lists (Optional)
  Widget _buildMultiLocationsCard(
    BuildContext context,
    bool isDark,
    bool isSubmitting,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Multiple Postcodes & Cities (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target specific batches of postcodes or city jurisdictions. Separate entries with commas or newlines.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 18),

          TextFormField(
            controller: _postcodesListController,
            enabled: !isSubmitting,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Multiple Postcodes (Comma-separated)',
              hintText: 'e.g. 90210, 90211, 90212',
              prefixIcon: const Icon(Icons.markunread_mailbox_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _citiesListController,
            enabled: !isSubmitting,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Multiple Cities (Comma-separated)',
              hintText: 'e.g. Beverly Hills, Santa Monica, Culver City',
              prefixIcon: const Icon(Icons.location_city_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, bool isSubmitting) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: isSubmitting ? null : _submitForm,
        icon: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_task_rounded, size: 20),
        label: Text(
          isSubmitting ? 'Creating Tax Rate...' : 'Create Tax Rate',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldGradient.colors.first,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
