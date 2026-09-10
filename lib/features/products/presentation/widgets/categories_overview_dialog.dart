import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/products_bloc.dart';
import '../../bloc/products_event.dart';
import '../../bloc/products_state.dart';
import '../../data/models/get_categories_model.dart';
import 'create_category_dialog.dart';

/// Samsung One UI 9 styled Categories Overview & Management Modal Dialog.
/// Displays live WooCommerce categories using real API fields:
/// `id`, `name`, `slug`, `parent`, `image`, `count`, and `menu_order`.
/// Supports search filtering, Main vs Subcategory badges, direct product catalog filtering,
/// and edit navigation.
class CategoriesOverviewDialog extends StatefulWidget {
  const CategoriesOverviewDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ProductsBloc>(),
        child: const CategoriesOverviewDialog(),
      ),
    );
  }

  @override
  State<CategoriesOverviewDialog> createState() =>
      _CategoriesOverviewDialogState();
}

class _CategoriesOverviewDialogState extends State<CategoriesOverviewDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // 'all', 'main', 'sub'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCategory() async {
    final created = await CreateCategoryDialog.show(context);
    if (!mounted || created == null) return;
    context.read<ProductsBloc>().add(ProductsCategoryAdded(created));
    context
        .read<ProductsBloc>()
        .add(const ProductsCategoriesRefreshRequested());
  }

  void _openEditCategory(GetCategoriesModel category) async {
    final updated = await CreateCategoryDialog.show(
      context,
      categoryToEdit: category,
    );
    if (!mounted || updated == null) return;
    context.read<ProductsBloc>().add(ProductsCategoryUpdated(updated));
    context
        .read<ProductsBloc>()
        .add(const ProductsCategoriesRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 740),
        padding: const EdgeInsets.all(24),
        child: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            List<GetCategoriesModel> categories = [];
            bool isLoading = false;
            String? errorMessage;

            if (state is ProductsSuccess) {
              categories = state.categories;
            } else if (state is ProductsEmpty) {
              categories = state.categories;
            } else if (state is ProductsLoading) {
              isLoading = state.previousProducts == null;
            } else if (state is ProductsFailure) {
              errorMessage = state.errorMessage;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, isDark, categories.length),
                const SizedBox(height: 16),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(height: 12),

                // Search & Filter Tabs
                _buildSearchAndFilters(isDark),
                const SizedBox(height: 16),

                // Body content by state
                Expanded(
                  child: _buildBody(
                    context,
                    categories: categories,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    selectedCat: state.selectedCategory,
                    selectedCatId: state.selectedCategoryId,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(height: 12),

                // Footer Actions
                _buildFooter(context, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.category_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Product Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'WooCommerce Catalog Categories • GET /wp-json/wc/v3/products/categories',
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
          icon: const Icon(Icons.close_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Row(
      children: [
        // Search Input
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by category name, slug, or ID...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 14),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Filter Pills: All / Main / Sub
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'main', label: Text('Main')),
            ButtonSegment(value: 'sub', label: Text('Sub')),
          ],
          selected: {_filterType},
          onSelectionChanged: (val) {
            setState(() {
              _filterType = val.first;
            });
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<GetCategoriesModel> categories,
    required bool isLoading,
    required String? errorMessage,
    required String selectedCat,
    required int? selectedCatId,
    required bool isDark,
  }) {
    if (isLoading && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Loading WooCommerce Categories...',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null && categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 36, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to Load Categories',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                context
                    .read<ProductsBloc>()
                    .add(const ProductsCategoriesRefreshRequested());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final filtered = categories.where((c) {
      if (_filterType == 'main' && !c.isMainCategory) return false;
      if (_filterType == 'sub' && c.isMainCategory) return false;

      if (query.isNotEmpty) {
        final name = (c.name ?? '').toLowerCase();
        final slug = (c.slug ?? '').toLowerCase();
        final idStr = (c.id ?? '').toString();
        if (!name.contains(query) &&
            !slug.contains(query) &&
            !idStr.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_rounded,
              size: 36,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(height: 12),
            Text(
              query.isNotEmpty
                  ? 'No categories match your search'
                  : 'No Categories Available',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              query.isNotEmpty
                  ? 'Try searching with a different name, slug, or ID.'
                  : 'Click "Add Category" below to create your first category.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final category = filtered[index];
        final isFilteredInCatalog = (selectedCatId != null &&
                category.id != null &&
                selectedCatId == category.id) ||
            (selectedCat == category.slug || selectedCat == category.name);

        return _buildCategoryCard(
          context,
          category: category,
          isSelected: isFilteredInCatalog,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required GetCategoriesModel category,
    required bool isSelected,
    required bool isDark,
  }) {
    final hasImg = category.imageUrl != null && category.imageUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
            : (isDark ? AppColors.darkCard : const Color(0xFFFAFAFC)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image / Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 44,
              height: 44,
              color: isDark ? AppColors.darkBackground : const Color(0xFFEEF2FF),
              child: hasImg
                  ? SafeNetworkImage(
                      imageUrl: category.imageUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      category.isMainCategory
                          ? Icons.folder_rounded
                          : Icons.subdirectory_arrow_right_rounded,
                      color: category.isMainCategory
                          ? AppColors.primary
                          : const Color(0xFF0EA5E9),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Details: Name, ID, Slug, Parent, Order, Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.displayName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Main vs Subcategory badge
                    _buildParentBadge(category, isDark),
                  ],
                ),
                const SizedBox(height: 5),

                // Chips Row: ID, Slug, Menu Order, Products Count
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // ID with Copy
                    InkWell(
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: '${category.id}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied Category ID: ${category.id}'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: ${category.id}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.copy_rounded,
                                size: 10,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                          ],
                        ),
                      ),
                    ),

                    // Slug
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'slug: ${category.displaySlug}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),

                    // Menu Order
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'order: ${category.sortOrder}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ),

                    // Product Count Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${category.productCount} products',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description if present
                if (category.description != null &&
                    category.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    category.description!.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Actions: Filter Catalog & Edit
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Filter Catalog Button
              IconButton(
                tooltip: isSelected
                    ? 'Currently filtering catalog'
                    : 'Filter Catalog by this category',
                icon: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.filter_alt_outlined,
                  size: 19,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
                onPressed: () {
                  final catValue = category.slug ?? category.name ?? '';
                  context.read<ProductsBloc>().add(
                        ProductsCategoryChanged(catValue,
                            categoryId: category.id),
                      );
                  Navigator.of(context).pop();
                },
              ),

              // Edit Category
              IconButton(
                tooltip: 'Edit Category',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openEditCategory(category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentBadge(GetCategoriesModel category, bool isDark) {
    final isMain = category.isMainCategory;
    final color = isMain ? AppColors.success : const Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMain
                ? Icons.stars_rounded
                : Icons.subdirectory_arrow_right_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isMain ? 'Main Category' : 'Sub (Parent #${category.parent})',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: _openAddCategory,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add Category'),
          style: OutlinedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                context
                    .read<ProductsBloc>()
                    .add(const ProductsCategoriesRefreshRequested());
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}
