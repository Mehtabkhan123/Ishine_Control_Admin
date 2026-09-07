import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../bloc/create_product_bloc.dart';
import '../../bloc/create_product_event.dart';
import '../../bloc/create_product_state.dart';
import '../../bloc/gallery_upload_cubit.dart';
import '../../data/models/post_create_model.dart';
import '../../data/repositories/products_repository.dart';
import '../widgets/product_gallery_picker.dart';

/// Samsung One UI-inspired Add Product screen for WooCommerce Admin.
/// Supports product name, type, status, regular & sale prices, stock management,
/// categories, tags, images, attributes, dimensions, tax, and shipping fields.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  static Route<bool> route() {
    return MaterialPageRoute<bool>(
      builder: (context) => const AddProductScreen(),
    );
  }

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _regularPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '10');
  final _lowStockAmountController = TextEditingController(text: '3');
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _shippingClassController = TextEditingController();
  final _taxClassController = TextEditingController();
  final _purchaseNoteController = TextEditingController();
  final _newCategoryController = TextEditingController();
  final _newTagController = TextEditingController();

  // Attribute draft controllers
  final _attrNameController = TextEditingController();
  final _attrOptionsController = TextEditingController();

  // Configuration values
  String _productType = 'simple';
  String _productStatus = 'publish';
  String _catalogVisibility = 'visible';
  bool _isFeatured = false;
  bool _isVirtual = false;
  bool _isDownloadable = false;
  bool _manageStock = true;
  String _stockStatus = 'instock';
  String _backorders = 'no';
  bool _soldIndividually = false;
  String _taxStatus = 'taxable';
  bool _reviewsAllowed = true;

  // Selected relationships
  final List<ProductCategoryRef> _selectedCategories = [];
  final List<ProductTagRef> _selectedTags = [];
  final List<ProductAttributeRef> _attributes = [];
  late final GalleryUploadCubit _galleryCubit;

  @override
  void initState() {
    super.initState();
    _galleryCubit = GalleryUploadCubit(
      repository: context.read<ProductsRepository>(),
    );
    // Fetch live categories and tags from WooCommerce API
    context.read<CreateProductBloc>().add(const CreateProductTaxonomiesRequested());
  }

  @override
  void dispose() {
    _galleryCubit.close();
    _nameController.dispose();
    _skuController.dispose();
    _regularPriceController.dispose();
    _salePriceController.dispose();
    _descriptionController.dispose();
    _shortDescriptionController.dispose();
    _stockQuantityController.dispose();
    _lowStockAmountController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _shippingClassController.dispose();
    _taxClassController.dispose();
    _purchaseNoteController.dispose();
    _newCategoryController.dispose();
    _newTagController.dispose();
    _attrNameController.dispose();
    _attrOptionsController.dispose();
    super.dispose();
  }

  void _submitProduct({String? statusOverride}) {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the validation errors before submitting.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_galleryCubit.state.isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for gallery images to finish uploading.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final regularPrice = _regularPriceController.text.trim();
    final salePrice = _salePriceController.text.trim();

    if (regularPrice.isNotEmpty && salePrice.isNotEmpty) {
      final regNum = double.tryParse(regularPrice);
      final saleNum = double.tryParse(salePrice);
      if (regNum != null && saleNum != null && saleNum >= regNum) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale price must be lower than the regular price.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final dimensions = Dimensions(
      length: _lengthController.text.trim(),
      width: _widthController.text.trim(),
      height: _heightController.text.trim(),
    );

    final shippingClass = _shippingClassController.text.trim();
    final taxClass = _taxClassController.text.trim();
    final galleryImages = _galleryCubit.state.toProductImageRefs();

    final productToCreate = PostCreateModel(
      name: _nameController.text.trim(),
      type: _productType,
      status: statusOverride ?? _productStatus,
      featured: _isFeatured,
      catalogVisibility: _catalogVisibility,
      description: _descriptionController.text.trim(),
      shortDescription: _shortDescriptionController.text.trim(),
      sku: _skuController.text.trim(),
      regularPrice: regularPrice,
      salePrice: salePrice.isNotEmpty ? salePrice : null,
      virtual: _isVirtual,
      downloadable: _isDownloadable,
      taxStatus: _taxStatus,
      taxClass: taxClass.isNotEmpty ? taxClass : null,
      manageStock: _manageStock,
      stockQuantity: _manageStock ? int.tryParse(_stockQuantityController.text.trim()) : null,
      stockStatus: _stockStatus,
      backorders: _backorders,
      lowStockAmount: _manageStock ? int.tryParse(_lowStockAmountController.text.trim()) : null,
      soldIndividually: _soldIndividually,
      weight: _weightController.text.trim(),
      dimensions: dimensions,
      shippingClass: shippingClass.isNotEmpty ? shippingClass : null,
      reviewsAllowed: _reviewsAllowed,
      purchaseNote: _purchaseNoteController.text.trim(),
      categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      tags: _selectedTags.isNotEmpty ? _selectedTags : null,
      images: galleryImages.isNotEmpty ? galleryImages : null,
      attributes: _attributes.isNotEmpty ? _attributes : null,
    );

    context.read<CreateProductBloc>().add(CreateProductSubmitted(productToCreate));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 950;

    return BlocProvider<GalleryUploadCubit>.value(
      value: _galleryCubit,
      child: BlocListener<CreateProductBloc, CreateProductState>(
      listener: (context, state) {
        if (state.isSuccess) {
          final createdName = state.createdProduct?.name ?? 'Product';
          final createdId = state.createdProduct?.id;

          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Successfully published "$createdName" ${createdId != null ? "(ID: #$createdId)" : ""}!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );

          // Navigate back to product list with success flag
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        } else if (state.isFailure && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    state.isTimeout ? Icons.timer_off_rounded : Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
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
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  context.read<CreateProductBloc>().add(const CreateProductReset());
                },
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: _buildAppBar(context, isDark),
        body: BlocBuilder<CreateProductBloc, CreateProductState>(
          builder: (context, state) {
            return Stack(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.isFailure && state.errorMessage != null) ...[
                          _buildErrorBanner(state, isDark),
                          const SizedBox(height: 18),
                        ],
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left main column (65%)
                              Expanded(
                                flex: 65,
                                child: Column(
                                  children: [
                                    _buildGeneralCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildImagesCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildPricingCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildInventoryCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildShippingDimensionsCard(isDark),
                                    const SizedBox(height: 20),
                                    _buildAttributesCard(isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right sidebar column (35%)
                              Expanded(
                                flex: 35,
                                child: Column(
                                  children: [
                                    _buildPublishActionCard(state, isDark),
                                    const SizedBox(height: 20),
                                    _buildCategoriesCard(state, isDark),
                                    const SizedBox(height: 20),
                                    _buildTagsCard(state, isDark),
                                    const SizedBox(height: 20),
                                    _buildTaxAndExtraCard(isDark),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildPublishActionCard(state, isDark),
                          const SizedBox(height: 20),
                          _buildGeneralCard(isDark),
                          const SizedBox(height: 20),
                          _buildImagesCard(isDark),
                          const SizedBox(height: 20),
                          _buildPricingCard(isDark),
                          const SizedBox(height: 20),
                          _buildInventoryCard(isDark),
                          const SizedBox(height: 20),
                          _buildCategoriesCard(state, isDark),
                          const SizedBox(height: 20),
                          _buildTagsCard(state, isDark),
                          const SizedBox(height: 20),
                          _buildShippingDimensionsCard(isDark),
                          const SizedBox(height: 20),
                          _buildAttributesCard(isDark),
                          const SizedBox(height: 20),
                          _buildTaxAndExtraCard(isDark),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (state.isSubmitting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Publishing to WooCommerce...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'POST /wp-json/wc/v3/products',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                'WooCommerce v3 REST API Catalog Builder',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        BlocBuilder<CreateProductBloc, CreateProductState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.icon(
                onPressed: state.isSubmitting ? null : () => _submitProduct(),
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 16),
                label: Text(state.isSubmitting ? 'Publishing...' : 'Publish Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildErrorBanner(CreateProductState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.isTimeout
                      ? 'Connection Timeout (408)'
                      : (state.isDuplicateBlocked ? 'Duplicate Blocked' : 'API Submission Error'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.errorMessage ?? 'Failed to create product. Please retry.',
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

  Widget _buildCardContainer({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildGeneralCard(bool isDark) {
    return _buildCardContainer(
      title: 'General Information',
      icon: Icons.info_outline_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Product Title *',
            hint: 'e.g. Wireless Noise-Cancelling Headphones Pro',
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Product title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _skuController,
                  label: 'SKU (Stock Keeping Unit)',
                  hint: 'e.g. ISH-AUDIO-101',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Product Type',
                  value: _productType,
                  items: const [
                    DropdownMenuItem(value: 'simple', child: Text('Simple Product')),
                    DropdownMenuItem(value: 'variable', child: Text('Variable Product')),
                    DropdownMenuItem(value: 'grouped', child: Text('Grouped Product')),
                    DropdownMenuItem(value: 'external', child: Text('External / Affiliate')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _productType = val);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _shortDescriptionController,
            label: 'Short Summary',
            hint: 'A quick 1-2 sentence overview visible on product lists...',
            maxLines: 2,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Full Description',
            hint: 'Detailed product specifications, feature highlights, dimensions...',
            maxLines: 4,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSwitchTile(
                  title: 'Virtual Product',
                  subtitle: 'Item is intangible (no shipping required)',
                  value: _isVirtual,
                  onChanged: (v) => setState(() => _isVirtual = v),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSwitchTile(
                  title: 'Downloadable',
                  subtitle: 'Provides file access upon purchase',
                  value: _isDownloadable,
                  onChanged: (v) => setState(() => _isDownloadable = v),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(bool isDark) {
    return _buildCardContainer(
      title: 'Pricing & Currency',
      icon: Icons.attach_money_rounded,
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _regularPriceController,
                  label: 'Regular Price (\$) *',
                  hint: 'e.g. 199.99',
                  prefixText: '\$ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isDark: isDark,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Regular price is required';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _salePriceController,
                  label: 'Sale Price (\$) (Optional)',
                  hint: 'e.g. 149.99',
                  prefixText: '\$ ',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  isDark: isDark,
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(bool isDark) {
    return _buildCardContainer(
      title: 'Inventory & Stock Management',
      icon: Icons.inventory_2_outlined,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSwitchTile(
            title: 'Manage Stock Quantity',
            subtitle: 'Enable WooCommerce automatic stock decrement on purchase',
            value: _manageStock,
            onChanged: (v) => setState(() => _manageStock = v),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          if (_manageStock) ...[
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stockQuantityController,
                    label: 'Stock Quantity *',
                    hint: 'e.g. 25',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    validator: (v) {
                      if (_manageStock) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (int.tryParse(v.trim()) == null) return 'Must be integer';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _lowStockAmountController,
                    label: 'Low Stock Notification Threshold',
                    hint: 'e.g. 3',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Stock Status',
                  value: _stockStatus,
                  items: const [
                    DropdownMenuItem(value: 'instock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'outofstock', child: Text('Out of Stock')),
                    DropdownMenuItem(value: 'onbackorder', child: Text('On Backorder')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _stockStatus = val);
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'Backorders Policy',
                  value: _backorders,
                  items: const [
                    DropdownMenuItem(value: 'no', child: Text('Do not allow')),
                    DropdownMenuItem(value: 'notify', child: Text('Allow, but notify buyer')),
                    DropdownMenuItem(value: 'yes', child: Text('Allow freely')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _backorders = val);
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSwitchTile(
            title: 'Sold Individually',
            subtitle: 'Limit purchases to 1 item per order',
            value: _soldIndividually,
            onChanged: (v) => setState(() => _soldIndividually = v),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildShippingDimensionsCard(bool isDark) {
    return _buildCardContainer(
      title: 'Shipping & Dimensions',
      icon: Icons.local_shipping_outlined,
      isDark: isDark,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  hint: 'e.g. 0.85',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lengthController,
                  label: 'Length (cm)',
                  hint: 'e.g. 20',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _widthController,
                  label: 'Width (cm)',
                  hint: 'e.g. 15',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _heightController,
                  label: 'Height (cm)',
                  hint: 'e.g. 8',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _shippingClassController,
            label: 'Shipping Class Slug (Optional)',
            hint: 'e.g. heavy-items or standard',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAttributesCard(bool isDark) {
    return _buildCardContainer(
      title: 'Attributes & Specifications',
      icon: Icons.tune_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attributes.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attributes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final attr = _attributes[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          attr.name ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          attr.options?.join(', ') ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          setState(() => _attributes.removeAt(index));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                flex: 40,
                child: _buildTextField(
                  controller: _attrNameController,
                  label: 'Attribute Name',
                  hint: 'e.g. Color or Size',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 60,
                child: _buildTextField(
                  controller: _attrOptionsController,
                  label: 'Options (Comma separated)',
                  hint: 'e.g. Black, White, Red',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: FilledButton(
                  onPressed: () {
                    final name = _attrNameController.text.trim();
                    final optionsStr = _attrOptionsController.text.trim();
                    if (name.isNotEmpty && optionsStr.isNotEmpty) {
                      final opts = optionsStr
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      setState(() {
                        _attributes.add(
                          ProductAttributeRef(
                            name: name,
                            options: opts,
                            visible: true,
                            position: _attributes.length,
                          ),
                        );
                        _attrNameController.clear();
                        _attrOptionsController.clear();
                      });
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublishActionCard(CreateProductState state, bool isDark) {
    return _buildCardContainer(
      title: 'Publish & Status',
      icon: Icons.published_with_changes_rounded,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdown(
            label: 'Status',
            value: _productStatus,
            items: const [
              DropdownMenuItem(value: 'publish', child: Text('Published (Visible to Store)')),
              DropdownMenuItem(value: 'draft', child: Text('Draft (Saved privately)')),
              DropdownMenuItem(value: 'pending', child: Text('Pending Review')),
              DropdownMenuItem(value: 'private', child: Text('Private (Admins only)')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _productStatus = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildDropdown(
            label: 'Catalog Visibility',
            value: _catalogVisibility,
            items: const [
              DropdownMenuItem(value: 'visible', child: Text('Shop and search results')),
              DropdownMenuItem(value: 'catalog', child: Text('Shop only')),
              DropdownMenuItem(value: 'search', child: Text('Search results only')),
              DropdownMenuItem(value: 'hidden', child: Text('Hidden')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _catalogVisibility = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildSwitchTile(
            title: 'Featured Product',
            subtitle: 'Highlight in storefront featured carousels',
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => _submitProduct(statusOverride: 'draft'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.isSubmitting ? null : () => _submitProduct(),
                  icon: state.isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: Text(state.isSubmitting ? 'Publishing...' : 'Publish'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard(bool isDark) {
    return ProductGalleryPicker(
      isDark: isDark,
    );
  }

  Widget _buildCategoriesCard(CreateProductState state, bool isDark) {
    return _buildCardContainer(
      title: 'Categories',
      icon: Icons.category_outlined,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isLoadingTaxonomies)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else if (state.categories.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.categories.map((cat) {
                    final isSelected = _selectedCategories.any((c) => c.id == cat.id);

                    return FilterChip(
                      selected: isSelected,
                      label: Text(cat.name ?? ''),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCategories.add(cat);
                          } else {
                            _selectedCategories.removeWhere((c) => c.id == cat.id);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Add custom category
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _newCategoryController,
                  label: 'Add Category by Name',
                  hint: 'e.g. Smart Wearables',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: IconButton.filled(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () {
                    final name = _newCategoryController.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _selectedCategories.add(ProductCategoryRef(name: name));
                        _newCategoryController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsCard(CreateProductState state, bool isDark) {
    return _buildCardContainer(
      title: 'Tags',
      icon: Icons.sell_outlined,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.tags.isNotEmpty) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.tags.map((tag) {
                    final isSelected = _selectedTags.any((t) => t.id == tag.id);

                    return FilterChip(
                      selected: isSelected,
                      label: Text('#${tag.name ?? ""}'),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.removeWhere((t) => t.id == tag.id);
                          }
                        });
                      },
                      selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _newTagController,
                  label: 'Add Tag by Name',
                  hint: 'e.g. Wireless, Premium',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: IconButton.filled(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
                  onPressed: () {
                    final name = _newTagController.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _selectedTags.add(ProductTagRef(name: name));
                        _newTagController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxAndExtraCard(bool isDark) {
    return _buildCardContainer(
      title: 'Tax & Settings',
      icon: Icons.receipt_long_rounded,
      isDark: isDark,
      child: Column(
        children: [
          _buildDropdown(
            label: 'Tax Status',
            value: _taxStatus,
            items: const [
              DropdownMenuItem(value: 'taxable', child: Text('Taxable')),
              DropdownMenuItem(value: 'shipping', child: Text('Shipping only')),
              DropdownMenuItem(value: 'none', child: Text('None')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _taxStatus = val);
            },
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _taxClassController,
            label: 'Tax Class (Optional)',
            hint: 'e.g. reduced-rate or zero-rate',
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildSwitchTile(
            title: 'Enable Product Reviews',
            subtitle: 'Allow verified customer reviews on product page',
            value: _reviewsAllowed,
            onChanged: (v) => setState(() => _reviewsAllowed = v),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _purchaseNoteController,
            label: 'Purchase Note',
            hint: 'Private note sent to the customer after purchase...',
            maxLines: 2,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    String? prefixText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
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
          validator: validator,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required bool isDark,
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
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
    required void Function(bool) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
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
                    fontSize: 13,
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
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primaryLight,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
