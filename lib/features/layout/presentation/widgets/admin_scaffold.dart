import 'package:flutter/material.dart';
import '../../../coupons/presentation/screens/coupons_screen.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../products/presentation/screens/products_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../shipping/presentation/screens/shipping_zones_screen.dart';
import '../../../taxes/presentation/screens/tax_rates_screen.dart';
import '../../../payment_gateways/presentation/screens/payment_gateways_screen.dart';
import 'admin_header.dart';
import 'admin_nav_rail.dart';

/// The root layout scaffold for iShine Control Admin Application with Samsung One UI layout styling.
/// Features a left navigation rail sidebar, top header with live health indicator, and routed content body.
class AdminScaffold extends StatefulWidget {
  final int initialIndex;

  const AdminScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  late int _selectedIndex;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  static const List<Map<String, String>> _sectionMeta = [
    {
      'title': 'Dashboard',
      'subtitle': 'Store performance, live health & overview',
    },
    {
      'title': 'Orders',
      'subtitle': 'Manage, track and fulfill customer orders',
    },
    {
      'title': 'Products',
      'subtitle': 'Inventory catalog, pricing & stock status',
    },
    {
      'title': 'Customers',
      'subtitle': 'Customer directory, accounts & buyer insights',
    },
    {
      'title': 'Coupons',
      'subtitle': 'Store discount codes, promotional rules & vouchers',
    },
    {
      'title': 'Shipping Zones',
      'subtitle': 'Manage delivery regions, rates & evaluation priority',
    },
    {
      'title': 'Tax Rates',
      'subtitle': 'Manage regional tax rates, priorities & classes',
    },
    {
      'title': 'Payment Gateways',
      'subtitle': 'Manage checkout payment methods, gateways & rules',
    },
    {
      'title': 'Settings',
      'subtitle': 'WooCommerce REST API, store preferences & diagnostics',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final meta = _sectionMeta[_selectedIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 800;
    final isExpanded = isCompact ? false : _isSidebarExpanded;

    final screens = [
      DashboardScreen(
        onNavigateTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const OrdersScreen(),
      const ProductsScreen(),
      const CustomersScreen(),
      const CouponsScreen(),
      const ShippingZonesScreen(),
      const TaxRatesScreen(),
      const PaymentGatewaysScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Navigation Rail
          AdminNavRail(
            selectedIndex: _selectedIndex,
            isExpanded: isExpanded,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            onToggleExpanded: () {
              setState(() {
                _isSidebarExpanded = !_isSidebarExpanded;
              });
            },
          ),

          // Main App Area
          Expanded(
            child: Column(
              children: [
                // Top Header with Live Health Indicator
                AdminHeader(
                  title: meta['title'] ?? 'iShine Control',
                  subtitle: meta['subtitle'],
                ),

                // Content View
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
