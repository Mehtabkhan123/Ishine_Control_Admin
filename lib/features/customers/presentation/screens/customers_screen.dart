import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerItemData {
  final String name;
  final String email;
  final String country;
  final int totalOrders;
  final double totalSpent;
  final String tier;
  final DateTime joinedDate;

  const CustomerItemData({
    required this.name,
    required this.email,
    required this.country,
    required this.totalOrders,
    required this.totalSpent,
    required this.tier,
    required this.joinedDate,
  });
}

/// Redesigned Customers Screen with Samsung One UI aesthetics.
/// Features customer CRM KPIs, VIP segments, customer search,
/// and interactive customer directory cards.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _selectedSegment = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static final List<CustomerItemData> _allCustomers = [
    CustomerItemData(
      name: 'Alexander Wright',
      email: 'a.wright@enterprise.com',
      country: 'United States',
      totalOrders: 28,
      totalSpent: 4890.50,
      tier: 'VIP',
      joinedDate: DateTime(2025, 1, 15),
    ),
    CustomerItemData(
      name: 'Sarah Jenkins',
      email: 'sarah.j@example.com',
      country: 'United Kingdom',
      totalOrders: 16,
      totalSpent: 2740.00,
      tier: 'VIP',
      joinedDate: DateTime(2025, 3, 22),
    ),
    CustomerItemData(
      name: 'Michael Chen',
      email: 'mchen.tech@gmail.com',
      country: 'Canada',
      totalOrders: 12,
      totalSpent: 1850.25,
      tier: 'Gold',
      joinedDate: DateTime(2025, 5, 8),
    ),
    CustomerItemData(
      name: 'Emma Watson',
      email: 'emma.w@icloud.com',
      country: 'Australia',
      totalOrders: 9,
      totalSpent: 1240.00,
      tier: 'Gold',
      joinedDate: DateTime(2025, 8, 14),
    ),
    CustomerItemData(
      name: 'David Miller',
      email: 'david.m@outlook.com',
      country: 'Germany',
      totalOrders: 5,
      totalSpent: 840.90,
      tier: 'Regular',
      joinedDate: DateTime(2025, 11, 2),
    ),
    CustomerItemData(
      name: 'Jessica Taylor',
      email: 'jess.taylor@gmail.com',
      country: 'United States',
      totalOrders: 3,
      totalSpent: 430.00,
      tier: 'Regular',
      joinedDate: DateTime(2026, 1, 10),
    ),
    CustomerItemData(
      name: 'Lucas Rodriguez',
      email: 'lucas.rod@domain.co',
      country: 'Spain',
      totalOrders: 2,
      totalSpent: 290.00,
      tier: 'New',
      joinedDate: DateTime(2026, 2, 1),
    ),
    CustomerItemData(
      name: 'Olivia Davis',
      email: 'olivia.d@webmail.org',
      country: 'France',
      totalOrders: 1,
      totalSpent: 125.00,
      tier: 'New',
      joinedDate: DateTime(2026, 2, 28),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerItemData> get _filteredCustomers {
    return _allCustomers.where((c) {
      if (_selectedSegment != 'all' && c.tier.toLowerCase() != _selectedSegment.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(query);
        final matchesEmail = c.email.toLowerCase().contains(query);
        final matchesCountry = c.country.toLowerCase().contains(query);
        if (!matchesName && !matchesEmail && !matchesCountry) return false;
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

          // Main Customers Container
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
                // Filter & Search Bar
                _buildFilterBar(context, isDark),
                const SizedBox(height: 20),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 16),

                // Customers List
                _buildCustomersList(context, isDark),
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
        'title': 'Total Customers',
        'value': '892',
        'subtitle': 'Across 42 countries',
        'icon': Icons.people_alt_rounded,
        'color': AppColors.primary,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Active Buyers',
        'value': '640',
        'subtitle': 'Purchased in last 90 days',
        'icon': Icons.shopping_bag_rounded,
        'color': AppColors.success,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'VIP Accounts',
        'value': '186',
        'subtitle': 'Lifetime value > \$1,000',
        'icon': Icons.workspace_premium_rounded,
        'color': AppColors.warning,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'New This Month',
        'value': '74',
        'subtitle': '+18% signup growth',
        'icon': Icons.person_add_alt_1_rounded,
        'color': AppColors.secondary,
        'gradient': AppColors.skyGradient,
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
    final segments = [
      {'label': 'All Customers', 'value': 'all'},
      {'label': 'VIP Tier', 'value': 'vip'},
      {'label': 'Gold Tier', 'value': 'gold'},
      {'label': 'Regular', 'value': 'regular'},
      {'label': 'New Signups', 'value': 'new'},
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
                              hintText: 'Search customers by name, email, or country...',
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
                        content: Text('Add Customer form ready.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text(isCompact ? 'Add' : 'Add Customer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Segment Filter Pills Container
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: segments.map((seg) {
                  final isSelected = _selectedSegment == seg['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSegment = seg['value']!),
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
                          seg['label']!,
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

  Widget _buildCustomersList(BuildContext context, bool isDark) {
    final customers = _filteredCustomers;

    if (customers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 36,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No customers found',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search keywords or switching to another tier segment.',
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
      itemCount: customers.length,
      separatorBuilder: (_, _) => Divider(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        height: 16,
      ),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerItemTile(context, customer, isDark);
      },
    );
  }

  Widget _buildCustomerItemTile(BuildContext context, CustomerItemData customer, bool isDark) {
    Color tierColor;
    Color tierBg;

    switch (customer.tier) {
      case 'VIP':
        tierColor = AppColors.warning;
        tierBg = AppColors.warning.withValues(alpha: 0.15);
        break;
      case 'Gold':
        tierColor = AppColors.secondary;
        tierBg = AppColors.secondary.withValues(alpha: 0.15);
        break;
      case 'New':
        tierColor = AppColors.success;
        tierBg = AppColors.success.withValues(alpha: 0.15);
        break;
      case 'Regular':
      default:
        tierColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        tierBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Customer Avatar Initials with Gradient
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.purpleGradient,
                  borderRadius: BorderRadius.circular(16), // One UI squircle
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    customer.name.isNotEmpty ? customer.name[0] : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Customer Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            customer.tier,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: tierColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.email} • ${customer.country}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCompact) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${customer.totalOrders} orders • \$${customer.totalSpent.toStringAsFixed(2)} spent',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!isCompact) ...[
                // Order count & Lifetime Value (LTV)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${customer.totalSpent.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.totalOrders} ${customer.totalOrders == 1 ? 'order' : 'orders'} placed',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
              ],

              // Quick Action Tooltip
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viewing profile for ${customer.name}...'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.chevron_right_rounded),
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                tooltip: 'View Customer Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
