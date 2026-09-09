import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/products_bloc.dart';
import '../../bloc/products_event.dart';
import '../../bloc/products_state.dart';
import '../../data/models/post_create_model.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../widgets/create_category_dialog.dart';

/// Redesigned Products Catalog Screen with Samsung One UI aesthetics.
/// Connected to live WooCommerce REST API v3 via [ProductsBloc].
/// Displays catalog KPI summary cards, live category filters, stock progress indicators,
/// and navigates to [AddProductScreen] for product creation and [EditProductScreen] for product updates.

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure catalog is fetched on screen init if not already loaded
    final bloc = context.read<ProductsBloc>();
    if (bloc.state is ProductsInitial) {
      bloc.add(const ProductsFetchRequested());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(AddProductScreen.route());
    if (created == true && mounted) {
      context.read<ProductsBloc>().add(const ProductsRefreshRequested());
    }
  }

  void _openAddCategory() async {
    final created = await CreateCategoryDialog.show(context);
    if (created != null && mounted) {
      context.read<ProductsBloc>().add(ProductsCategoryAdded(created));
      context.read<ProductsBloc>().add(const ProductsCategoriesRefreshRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Category '${created.name}' created successfully!",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _openEditCategory(ProductCategoryRef category) async {
    final updated = await CreateCategoryDialog.show(
      context,
      categoryToEdit: category,
    );
    if (updated != null && mounted) {
      context.read<ProductsBloc>().add(ProductsCategoryUpdated(updated));
      context.read<ProductsBloc>().add(const ProductsCategoriesRefreshRequested());
    }
  }

  void _openEditProduct(PostCreateModel product) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(EditProductScreen.route(product: product));
    if (updated == true && mounted) {
      context.read<ProductsBloc>().add(const ProductsRefreshRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProductsBloc>().add(const ProductsRefreshRequested());
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metric Summary Cards
                _buildKpiGrid(context, state, isDark),
                const SizedBox(height: 24),

                // Main Products Card Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24), // One UI Squircle
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
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
                      // Filter & Action Bar
                      _buildFilterBar(context, state, isDark),
                      const SizedBox(height: 20),
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      const SizedBox(height: 16),

                      // Products Content
                      _buildProductsContent(context, state, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(BuildContext context, ProductsState state, bool isDark) {
    int total = 0;
    int inStock = 0;
    int lowStock = 0;
    int outOfStock = 0;

    if (state is ProductsSuccess) {
      total = state.totalCount;
      inStock = state.inStockCount;
      lowStock = state.lowStockCount;
      outOfStock = state.outOfStockCount;
    }

    final kpis = [
      {
        'title': 'Total Products',
        'value': total.toString(),
        'subtitle': 'Live WooCommerce catalog',
        'icon': Icons.inventory_2_rounded,
        'color': AppColors.primary,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'In Stock',
        'value': inStock.toString(),
        'subtitle': 'Ready for fulfillment',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Low Stock Alert',
        'value': lowStock.toString(),
        'subtitle': 'Stock <= threshold',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.warning,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'Out of Stock',
        'value': outOfStock.toString(),
        'subtitle': 'Replenishment needed',
        'icon': Icons.error_outline_rounded,
        'color': AppColors.error,
        'gradient': AppColors.roseGradient,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final itemWidth = isWide
            ? (constraints.maxWidth - (3 * 16)) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: kpis.map((kpi) {
            final gradient = kpi['gradient'] as LinearGradient;
            final color = kpi['color'] as Color;

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(22), // One UI Squircle
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      kpi['icon'] as IconData,
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
                          kpi['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kpi['value'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kpi['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ProductsState state,
    bool isDark,
  ) {
    List<ProductCategoryRef> categories = [];
    String selectedCategory = state.selectedCategory;

    if (state is ProductsSuccess) {
      categories = state.categories;
      selectedCategory = state.selectedCategory;
    } else if (state is ProductsEmpty) {
      categories = state.categories;
      selectedCategory = state.selectedCategory;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              context.read<ProductsBloc>().add(
                                ProductsSearchChanged(val),
                              );
                            },
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search products by title, SKU, or category...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              context.read<ProductsBloc>().add(
                                const ProductsSearchChanged(''),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Refresh Products',
                  onPressed: () {
                    context.read<ProductsBloc>().add(
                      const ProductsRefreshRequested(),
                    );
                  },
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _openAddCategory,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: Text(isCompact ? 'Category' : 'Add Category'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _openAddProduct,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(isCompact ? 'Add' : 'Add Product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category Filter Pills Container
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryPill(
                    label: 'All Products',
                    value: 'all',
                    isSelected: selectedCategory == 'all',
                    isDark: isDark,
                  ),
                  ...categories.map((cat) {
                    final catValue = cat.slug ?? cat.name ?? '';
                    return _buildCategoryPill(
                      label: cat.name ?? '',
                      value: catValue,
                      isSelected: selectedCategory == catValue,
                      isDark: isDark,
                      category: cat,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'New Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      backgroundColor: AppColors.primary
                          .withValues(alpha: isDark ? 0.15 : 0.08),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: _openAddCategory,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryPill({
    required String label,
    required String value,
    required bool isSelected,
    required bool isDark,
    ProductCategoryRef? category,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: category != null
            ? (isSelected
                ? '$label (Tap to filter, long-press to edit/delete)'
                : '$label (Long-press to edit/delete)')
            : label,
        child: InkWell(
          onTap: () {
            context.read<ProductsBloc>().add(ProductsCategoryChanged(value));
          },
          onLongPress: category != null ? () => _openEditCategory(category) : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                  ),
                ),
                if (category != null && isSelected) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _openEditCategory(category),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductsContent(
    BuildContext context,
    ProductsState state,
    bool isDark,
  ) {
    if (state is ProductsLoading && state.previousProducts == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Loading WooCommerce Products...',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ProductsFailure) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                state.isTimeout
                    ? Icons.timer_off_rounded
                    : Icons.cloud_off_rounded,
                size: 42,
                color: AppColors.error,
              ),
              const SizedBox(height: 14),
              Text(
                state.isTimeout
                    ? 'Request Timed Out'
                    : 'Failed to Load Products',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  context.read<ProductsBloc>().add(
                    const ProductsFetchRequested(forceRefresh: true),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<PostCreateModel> products = [];
    if (state is ProductsSuccess) {
      products = state.filteredProducts;
    }

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  size: 36,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No products match your search or filter',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Try selecting a different category or clearing the search query.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openAddProduct,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Create First Product'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => Divider(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        height: 16,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItemTile(context, product, isDark);
      },
    );
  }

  Widget _buildProductItemTile(
    BuildContext context,
    PostCreateModel product,
    bool isDark,
  ) {
    final name = product.name ?? 'Untitled Product';
    final sku = (product.sku != null && product.sku!.isNotEmpty)
        ? product.sku!
        : 'No SKU';
    final categoryName = product.categories?.isNotEmpty == true
        ? (product.categories!.first.name ?? 'Uncategorized')
        : 'Uncategorized';

    final isManageStock = product.manageStock == true;
    final stockQty = product.stockQuantity ?? 0;
    final stockStatus = product.stockStatus ?? 'instock';

    Color stockColor;
    String stockLabel;
    double stockProgress;

    if (isManageStock) {
      if (stockQty <= 0) {
        stockColor = AppColors.error;
        stockLabel = 'Out of Stock (0)';
        stockProgress = 0.0;
      } else if (stockQty <= (product.lowStockAmount ?? 5)) {
        stockColor = AppColors.warning;
        stockLabel = '$stockQty left (Low Stock)';
        stockProgress = (stockQty / 10.0).clamp(0.0, 1.0);
      } else {
        stockColor = AppColors.success;
        stockLabel = '$stockQty in stock';
        stockProgress = (stockQty / 50.0).clamp(0.0, 1.0);
      }
    } else {
      if (stockStatus == 'outofstock') {
        stockColor = AppColors.error;
        stockLabel = 'Out of Stock';
        stockProgress = 0.0;
      } else if (stockStatus == 'onbackorder') {
        stockColor = AppColors.warning;
        stockLabel = 'On Backorder';
        stockProgress = 0.5;
      } else {
        stockColor = AppColors.success;
        stockLabel = 'In Stock';
        stockProgress = 1.0;
      }
    }

    final imageUrl = product.images?.isNotEmpty == true
        ? product.images!.first.src
        : null;

    final regularPrice = product.regularPrice ?? product.price ?? '';
    final salePrice = product.salePrice;
    final isPublished = product.status == 'publish';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _openEditProduct(product),
            borderRadius: BorderRadius.circular(14),
            hoverColor: (isDark ? AppColors.darkCard : AppColors.lightCard)
                .withValues(alpha: 0.6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // Product Image or Gradient Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14), // One UI Squircle
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? SafeNetworkImage(
                              imageUrl: imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorWidget: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.brandGradient,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title, SKU & Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBackground
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sku,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              categoryName,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (isCompact) ...[
                          const SizedBox(height: 6),
                          Text(
                            stockLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!isCompact) ...[
                    // Stock Level with Visual Progress Bar
                    SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stockLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: stockColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stockProgress,
                              minHeight: 5,
                              backgroundColor: isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                stockColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],

                  // Price & Sale Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (salePrice != null && salePrice.isNotEmpty) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$$regularPrice',
                              style: TextStyle(
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '\$$salePrice',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryLight,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          regularPrice.isNotEmpty ? '\$$regularPrice' : 'Free',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.darkTextMuted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPublished
                              ? 'Published'
                              : (product.status?.toUpperCase() ?? 'DRAFT'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isPublished
                                ? AppColors.success
                                : AppColors.darkTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  // Edit Action Button
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    tooltip: 'Edit Product',
                    onPressed: () => _openEditProduct(product),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkBackground.withValues(alpha: 0.6)
                          : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
