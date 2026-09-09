import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/create_category_cubit.dart';
import '../../bloc/create_category_state.dart';
import '../../bloc/products_bloc.dart';
import '../../bloc/products_event.dart';
import '../../data/models/post_create_model.dart';
import '../../data/repositories/products_repository.dart';

/// Samsung One UI-inspired Create & Edit Category Modal Dialog for iShine Admin.
/// Allows admins to input/update category name, slug, parent category, display type,
/// description, and upload or set an image from device gallery or camera.
/// Supports both:
/// - POST /wp-json/wc/v3/products/categories (Create)
/// - PUT /wp-json/wc/v3/products/categories/{{id}} (Update)
/// - DELETE /wp-json/wc/v3/products/categories/{{id}} (Delete)

class CreateCategoryDialog extends StatefulWidget {
  final int? defaultParentId;
  final ProductCategoryRef? categoryToEdit;
  final void Function(int categoryId)? onCategoryDeleted;
  final void Function(ProductCategoryRef category)? onCategoryUpdated;

  const CreateCategoryDialog({
    super.key,
    this.defaultParentId,
    this.categoryToEdit,
    this.onCategoryDeleted,
    this.onCategoryUpdated,
  });

  /// Displays the dialog inside its own [CreateCategoryCubit] instance.
  /// If [categoryToEdit] is provided, opens in Edit mode (PUT / DELETE).
  /// If null, opens in Create mode (POST).
  static Future<ProductCategoryRef?> show(
    BuildContext context, {
    int? defaultParentId,
    ProductCategoryRef? categoryToEdit,
    void Function(int categoryId)? onCategoryDeleted,
    void Function(ProductCategoryRef category)? onCategoryUpdated,
  }) {
    ProductsBloc? productsBloc;
    try {
      productsBloc = context.read<ProductsBloc>();
    } catch (_) {}

    return showDialog<ProductCategoryRef>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (_) {
          final cubit = CreateCategoryCubit(
            repository: context.read<ProductsRepository>(),
          )..loadParentCategories();
          if (categoryToEdit?.image != null) {
            cubit.setImage(categoryToEdit?.image);
          }
          return cubit;
        },
        child: CreateCategoryDialog(
          defaultParentId: defaultParentId,
          categoryToEdit: categoryToEdit,
          onCategoryDeleted: (id) {
            onCategoryDeleted?.call(id);
            productsBloc?.add(ProductsCategoryDeleted(id));
          },
          onCategoryUpdated: (cat) {
            onCategoryUpdated?.call(cat);
            productsBloc?.add(ProductsCategoryUpdated(cat));
          },
        ),
      ),
    );
  }

  @override
  State<CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<CreateCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  int? _selectedParentId;
  String _selectedDisplay = 'default';
  bool _isManualSlug = false;

  static const List<Map<String, dynamic>> _displayOptions = [
    {
      'value': 'default',
      'label': 'Default',
      'description': 'Store default display setting',
      'icon': Icons.layers_outlined,
    },
    {
      'value': 'products',
      'label': 'Products',
      'description': 'Directly shows product catalog',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'value': 'subcategories',
      'label': 'Subcategories',
      'description': 'Shows child categories only',
      'icon': Icons.folder_copy_outlined,
    },
    {
      'value': 'both',
      'label': 'Both',
      'description': 'Shows subcategories & products',
      'icon': Icons.dashboard_customize_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      final cat = widget.categoryToEdit!;
      _nameController.text = cat.name ?? '';
      _slugController.text = cat.slug ?? '';
      _descriptionController.text = cat.description ?? '';
      _selectedParentId = cat.parent;
      _selectedDisplay = (cat.display != null && cat.display!.isNotEmpty)
          ? cat.display!
          : 'default';
      _isManualSlug = true;
    } else {
      _selectedParentId = widget.defaultParentId;
    }

    _nameController.addListener(() {
      if (!_isManualSlug) {
        final slug = _slugify(_nameController.text);
        _slugController.text = slug;
      }
    });

    _slugController.addListener(() {
      if (_slugController.text.isNotEmpty &&
          _slugController.text != _slugify(_nameController.text)) {
        _isManualSlug = true;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _pickImage(ImageSource source) async {
    final cubit = context.read<CreateCategoryCubit>();
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      final filename = file.name.isNotEmpty
          ? file.name
          : 'category_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (!mounted) return;
      await cubit.uploadImage(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty) {
      context.read<CreateCategoryCubit>().setImage(ProductImageRef(src: url));
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cubit = context.read<CreateCategoryCubit>();

    // If using direct URL input and an image hasn't been set yet
    if (_imageUrlController.text.trim().isNotEmpty &&
        cubit.state.selectedImage == null) {
      cubit.setImage(ProductImageRef(src: _imageUrlController.text.trim()));
    }

    if (widget.categoryToEdit != null && widget.categoryToEdit!.id != null) {
      cubit.updateCategory(
        categoryId: widget.categoryToEdit!.id!,
        name: _nameController.text,
        slug: _slugController.text,
        description: _descriptionController.text,
        parentId: _selectedParentId,
        display: _selectedDisplay,
      );
    } else {
      cubit.submitCategory(
        name: _nameController.text,
        slug: _slugController.text,
        description: _descriptionController.text,
        parentId: _selectedParentId,
        display: _selectedDisplay,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext dialogContext) async {
    final cat = widget.categoryToEdit;
    if (cat == null || cat.id == null) return;

    if (!dialogContext.mounted) return;

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (confirmCtx) {
        final isDark = Theme.of(confirmCtx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${cat.name ?? 'this category'}" (ID: #${cat.id}) from WooCommerce? This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmCtx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(confirmCtx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text(
                'Delete Permanently',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<CreateCategoryCubit>().deleteCategory(cat.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return BlocConsumer<CreateCategoryCubit, CreateCategoryState>(
      listener: (context, state) {
        if (state.isSuccess) {
          final result = state.updatedCategory ?? state.createdCategory;
          if (widget.categoryToEdit != null) {
            widget.onCategoryUpdated?.call(result ?? widget.categoryToEdit!);
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text(
                  'Category "${result?.name ?? widget.categoryToEdit?.name}" updated successfully.',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text(
                  'Category "${result?.name ?? 'New category'}" created successfully.',
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(result);
          }
        } else if (state.isDeleteSuccess) {
          final id = state.deletedCategoryId ?? widget.categoryToEdit?.id;
          if (id != null) {
            widget.onCategoryDeleted?.call(id);
          }
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                'Category "${widget.categoryToEdit?.name ?? 'Category'}" deleted permanently.',
              ),
              backgroundColor: AppColors.darkSurface,
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(null);
          }
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // One UI Header
                _buildHeader(context, isDark, state),

                // Scrollable Form Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.isFailure &&
                              state.errorMessage != null) ...[
                            _buildErrorBanner(state.errorMessage!, isDark),
                            const SizedBox(height: 16),
                          ],

                          // Basic Information Card
                          _buildSectionTitle('Basic Information', isDark),
                          const SizedBox(height: 12),
                          _buildNameField(isDark, state.isBusy),
                          const SizedBox(height: 14),
                          _buildSlugField(isDark, state.isBusy),
                          const SizedBox(height: 20),

                          // Hierarchy & Layout Card
                          _buildSectionTitle('Hierarchy & Display', isDark),
                          const SizedBox(height: 12),
                          _buildParentCategoryDropdown(state, isDark),
                          const SizedBox(height: 14),
                          _buildDisplayTypeDropdown(isDark, state.isBusy),
                          const SizedBox(height: 20),

                          // Description
                          _buildSectionTitle('Description (Optional)', isDark),
                          const SizedBox(height: 12),
                          _buildDescriptionField(isDark, state.isBusy),
                          const SizedBox(height: 20),

                          // Image
                          _buildSectionTitle('Category Thumbnail', isDark),
                          const SizedBox(height: 12),
                          _buildImageSection(state, isDark),
                        ],
                      ),
                    ),
                  ),
                ),

                // One UI Footer Action Bar
                _buildFooter(context, state, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    CreateCategoryState state,
  ) {
    final isEdit = widget.categoryToEdit != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: isEdit
                  ? const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(14),

              boxShadow: [
                BoxShadow(
                  color: (isEdit ? const Color(0xFF2563EB) : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              isEdit
                  ? Icons.edit_note_rounded
                  : Icons.create_new_folder_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Category' : 'Add New Category',
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
                  isEdit
                      ? 'PUT /wp-json/wc/v3/products/categories/${widget.categoryToEdit!.id}'
                      : 'POST /wp-json/wc/v3/products/categories',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: state.isBusy ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isDark, bool isBusy) {
    return TextFormField(
      controller: _nameController,
      enabled: !isBusy,
      autofocus: true,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Category Name *',
        hintText: 'e.g. Smart Electronics, Accessories...',
        prefixIcon: const Icon(Icons.label_outline_rounded, size: 18),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Category name cannot be empty';
        }
        return null;
      },
    );
  }

  Widget _buildSlugField(bool isDark, bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _slugController,
          enabled: !isBusy,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Slug (URL Friendly)',
            hintText: 'e.g. smart-electronics',
            prefixIcon: const Icon(Icons.link_rounded, size: 18),
            suffixIcon: _isManualSlug
                ? IconButton(
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                    tooltip: 'Regenerate from name',
                    onPressed: () {
                      setState(() {
                        _isManualSlug = false;
                        _slugController.text = _slugify(_nameController.text);
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.darkBackground
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'The URL-friendly slug used for permalinks. Auto-generated from name if left empty.',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentCategoryDropdown(CreateCategoryState state, bool isDark) {
    final filteredCategories = state.parentCategories
        .where(
          (cat) =>
              widget.categoryToEdit?.id == null ||
              cat.id != widget.categoryToEdit!.id,
        )
        .toList();
    final availableIds = filteredCategories.map((c) => c.id).toSet();
    final effectiveValue =
        (_selectedParentId != null && availableIds.contains(_selectedParentId))
        ? _selectedParentId
        : null;

    return DropdownButtonFormField<int?>(
      initialValue: effectiveValue,
      decoration: InputDecoration(
        labelText: 'Parent Category',
        prefixIcon: const Icon(Icons.account_tree_outlined, size: 18),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('None (Top Level Category)'),
        ),
        ...filteredCategories.map((cat) {
          final prefix = (cat.parent != null && cat.parent! > 0) ? '— ' : '';
          return DropdownMenuItem<int?>(
            value: cat.id,
            child: Text('$prefix${cat.name ?? 'Untitled'} (ID: ${cat.id})'),
          );
        }),
      ],
      onChanged: state.isBusy
          ? null
          : (val) {
              setState(() {
                _selectedParentId = val;
              });
            },
    );
  }

  Widget _buildDisplayTypeDropdown(bool isDark, bool isBusy) {
    final validDisplays = _displayOptions
        .map((e) => e['value'] as String)
        .toSet();
    final effectiveDisplay = validDisplays.contains(_selectedDisplay)
        ? _selectedDisplay
        : 'default';

    return DropdownButtonFormField<String>(
      initialValue: effectiveDisplay,
      decoration: InputDecoration(
        labelText: 'Display Type',
        prefixIcon: const Icon(Icons.view_agenda_outlined, size: 18),
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
      items: _displayOptions.map((opt) {
        return DropdownMenuItem<String>(
          value: opt['value'] as String,
          child: Row(
            children: [
              Icon(
                opt['icon'] as IconData,
                size: 16,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              const SizedBox(width: 8),
              Text(opt['label'] as String),
            ],
          ),
        );
      }).toList(),
      onChanged: isBusy
          ? null
          : (val) {
              if (val != null) {
                setState(() {
                  _selectedDisplay = val;
                });
              }
            },
    );
  }

  Widget _buildDescriptionField(bool isDark, bool isBusy) {
    return TextFormField(
      controller: _descriptionController,
      enabled: !isBusy,
      maxLines: 3,
      minLines: 2,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Brief summary of products organized in this category...',
        alignLabelWithHint: true,
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildImageSection(CreateCategoryState state, bool isDark) {
    final image = state.selectedImage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.src != null && image.src!.isNotEmpty) ...[
            // Image Preview Card
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    child: SafeNetworkImage(
                      imageUrl: image.src!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            image.id != null
                                ? 'Uploaded (ID: ${image.id})'
                                : 'Image URL linked',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        image.src ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  tooltip: 'Remove Image',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    foregroundColor: AppColors.error,
                  ),
                  onPressed: state.isBusy
                      ? null
                      : () {
                          context.read<CreateCategoryCubit>().removeImage();
                          _imageUrlController.clear();
                        },
                ),
              ],
            ),
          ] else if (state.isUploadingImage) ...[
            // Uploading progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Uploading image to media library...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: state.uploadProgress > 0 ? state.uploadProgress : null,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ] else ...[
            // Pick / URL Input Controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: const Text('Device Gallery'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageUrlController,
                    enabled: !state.isBusy,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Or enter public image URL (https://...)',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      prefixIcon: const Icon(Icons.link_rounded, size: 16),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _applyImageUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: state.isBusy ? null : _applyImageUrl,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    CreateCategoryState state,
    bool isDark,
  ) {
    final isEdit = widget.categoryToEdit != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (isEdit) ...[
            FilledButton.icon(
              onPressed: state.isBusy ? null : () => _confirmDelete(context),
              icon: state.isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(state.isDeleting ? 'Deleting...' : 'Delete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
          const Spacer(),
          OutlinedButton(
            onPressed: state.isBusy ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: state.isBusy ? null : _submit,
            icon: state.isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isEdit ? Icons.check_rounded : Icons.add_rounded,
                    size: 18,
                  ),
            label: Text(
              state.isSubmitting
                  ? (isEdit ? 'Saving...' : 'Creating...')
                  : (isEdit ? 'Save Changes' : 'Create Category'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Type alias for semantic flexibility
typedef CategoryFormDialog = CreateCategoryDialog;
