import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductItemData {
  final String sku;
  final String name;
  final String category;
  final double regularPrice;
  final double? salePrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final String status;
  final IconData categoryIcon;

  const ProductItemData({
    required this.sku,
    required this.name,
    required this.category,
    required this.regularPrice,
    this.salePrice,
    required this.stockQuantity,
    this.lowStockThreshold = 5,
    required this.status,
    required this.categoryIcon,
  });

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= lowStockThreshold;
}

/// Redesigned Products Screen with Samsung One UI aesthetics.
/// Features catalog KPI cards, category filters, stock level progress indicators,
/// and interactive product inventory cards.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<ProductItemData> _allProducts = [
    ProductItemData(
      sku: 'ISH-AUDIO-01',
      name: 'Wireless Noise-Cancelling Headphones Pro',
      category: 'Electronics',
      regularPrice: 249.99,
      salePrice: 199.99,
      stockQuantity: 42,
      status: 'publish',
      categoryIcon: Icons.headphones_rounded,
    ),
    ProductItemData(
      sku: 'ISH-TECH-02',
      name: 'Smart Fitness Tracker Watch Ultra',
      category: 'Electronics',
      regularPrice: 179.00,
      salePrice: 149.00,
      stockQuantity: 18,
      status: 'publish',
      categoryIcon: Icons.watch_rounded,
    ),
    ProductItemData(
      sku: 'ISH-WEAR-03',
      name: 'Premium Breathable Cotton Hoodie',
      category: 'Apparel',
      regularPrice: 69.50,
      stockQuantity: 84,
      status: 'publish',
      categoryIcon: Icons.checkroom_rounded,
    ),
    ProductItemData(
      sku: 'ISH-FOOT-04',
      name: 'Lightweight Running Shoes Edition 5',
      category: 'Footwear',
      regularPrice: 129.95,
      salePrice: 109.95,
      stockQuantity: 4, // Low stock
      status: 'publish',
      categoryIcon: Icons.directions_run_rounded,
    ),
    ProductItemData(
      sku: 'ISH-BAG-05',
      name: 'Water-Resistant Urban Travel Backpack',
      category: 'Accessories',
      regularPrice: 89.00,
      stockQuantity: 31,
      status: 'publish',
      categoryIcon: Icons.backpack_rounded,
    ),
    ProductItemData(
      sku: 'ISH-DESK-06',
      name: 'Ergonomic Wireless Charging Desk Lamp',
      category: 'Home & Office',
      regularPrice: 59.99,
      stockQuantity: 0, // Out of stock
      status: 'draft',
      categoryIcon: Icons.lightbulb_rounded,
    ),
    ProductItemData(
      sku: 'ISH-AUDIO-07',
      name: 'Portable Bluetooth Waterproof Speaker',
      category: 'Electronics',
      regularPrice: 79.99,
      salePrice: 64.99,
      stockQuantity: 3, // Low stock
      status: 'publish',
      categoryIcon: Icons.speaker_rounded,
    ),
    ProductItemData(
      sku: 'ISH-WEAR-08',
      name: 'Classic Slim Fit Denim Jacket',
      category: 'Apparel',
      regularPrice: 110.00,
      stockQuantity: 27,
      status: 'publish',
      categoryIcon: Icons.checkroom_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductItemData> get _filteredProducts {
    return _allProducts.where((p) {
      if (_selectedCategory != 'all' && p.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSku = p.sku.toLowerCase().contains(query);
        final matchesName = p.name.toLowerCase().contains(query);
        final matchesCat = p.category.toLowerCase().contains(query);
        if (!matchesSku && !matchesName && !matchesCat) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Metric Summary Cards
          _buildKpiGrid(context, isDark),
          const SizedBox(height: 24),

          // Main Products Card Container
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24), // One UI Squircle
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                _buildFilterBar(context, isDark),
                const SizedBox(height: 20),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 16),

                // Products List
                _buildProductsList(context, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, bool isDark) {
    final kpis = [
      {
        'title': 'Total Products',
        'value': '248',
        'subtitle': '18 categories cataloged',
        'icon': Icons.inventory_2_rounded,
        'color': AppColors.primary,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'In Stock',
        'value': '214',
        'subtitle': 'Healthy inventory',
        'icon': Icons.check_circle_outline_rounded,
        'color': AppColors.success,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Low Stock Alert',
        'value': '22',
        'subtitle': 'Stock <= 5 units',
        'icon': Icons.warning_amber_rounded,
        'color': AppColors.warning,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'Out of Stock',
        'value': '12',
        'subtitle': 'Action required',
        'icon': Icons.error_outline_rounded,
        'color': AppColors.error,
        'gradient': AppColors.roseGradient,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final itemWidth = isWide ? (constraints.maxWidth - (3 * 16)) / 4 : (constraints.maxWidth - 16) / 2;

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
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kpi['value'] as String,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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

  Widget _buildFilterBar(BuildContext context, bool isDark) {
    final categories = [
      {'label': 'All Products', 'value': 'all'},
      {'label': 'Electronics', 'value': 'Electronics'},
      {'label': 'Apparel', 'value': 'Apparel'},
      {'label': 'Footwear', 'value': 'Footwear'},
      {'label': 'Accessories', 'value': 'Accessories'},
      {'label': 'Home & Office', 'value': 'Home & Office'},
    ];

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
                      color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search products by title, SKU, or category...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WooCommerce Add Product dialog ready.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(isCompact ? 'Add' : 'Add Product'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category Filter Pills Container
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat['value']!),
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
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsList(BuildContext context, bool isDark) {
    final products = _filteredProducts;

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
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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

  Widget _buildProductItemTile(BuildContext context, ProductItemData product, bool isDark) {
    Color stockColor;
    String stockLabel;
    double stockProgress;

    if (product.isOutOfStock) {
      stockColor = AppColors.error;
      stockLabel = 'Out of Stock';
      stockProgress = 0.0;
    } else if (product.isLowStock) {
      stockColor = AppColors.warning;
      stockLabel = '${product.stockQuantity} left (Low Stock)';
      stockProgress = product.stockQuantity / 10.0;
    } else {
      stockColor = AppColors.success;
      stockLabel = '${product.stockQuantity} in stock';
      stockProgress = (product.stockQuantity / 60.0).clamp(0.0, 1.0);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Product Category Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16), // One UI Squircle
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    product.categoryIcon,
                    color: Colors.white,
                    size: 22,
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
                      product.name,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkBackground : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.sku,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stockLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: stockColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockProgress,
                          minHeight: 5,
                          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(stockColor),
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
                  if (product.salePrice != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$${product.regularPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\$${product.salePrice!.toStringAsFixed(2)}',
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
                      '\$${product.regularPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.status == 'publish'
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.darkTextMuted.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.status == 'publish' ? 'Published' : 'Draft',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: product.status == 'publish' ? AppColors.success : AppColors.darkTextMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
