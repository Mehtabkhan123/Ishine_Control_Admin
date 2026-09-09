import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/customers_bloc.dart';
import '../../bloc/customers_event.dart';
import '../../bloc/customers_state.dart';
import '../../data/models/get_customers_model.dart';
import '../../data/repositories/customers_repository.dart';
import 'customer_details_screen.dart';
import 'edit_customer_screen.dart';
import '../widgets/delete_customer_dialog.dart';

/// Redesigned Customers Screen with Samsung One UI 9 aesthetics.
/// Powered by WooCommerce GET /wp-json/wc/v3/customers with pagination (per_page=20),
/// registered_date descending sort, infinite scrolling, role filtering, search,
/// and live customer details navigation.
class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<CustomersBloc>();
      return const _CustomersView();
    } catch (_) {
      CustomersRepository repository;
      try {
        repository = context.read<CustomersRepository>();
      } catch (_) {
        repository = CustomersRepository();
      }

      return BlocProvider<CustomersBloc>(
        create: (_) => CustomersBloc(repository: repository)
          ..add(const CustomersFetchStarted()),
        child: const _CustomersView(),
      );
    }
  }
}

class _CustomersView extends StatefulWidget {
  const _CustomersView();

  @override
  State<_CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<_CustomersView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger next page when within 200px of bottom
    if (currentScroll >= (maxScroll - 200)) {
      final bloc = context.read<CustomersBloc>();
      if (!bloc.state.hasReachedMax && !bloc.state.isLoadingMore) {
        bloc.add(const CustomersLoadMore());
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<CustomersBloc>().add(CustomersSearchChanged(query));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<CustomersBloc, CustomersState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.customers.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            final bloc = context.read<CustomersBloc>();
            bloc.add(const CustomersRefreshed());
            await bloc.stream
                .firstWhere((s) => !s.isLoading && !s.isLoadingMore);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Metric Summary Cards
                _buildKpiGrid(context, state, isDark),
                const SizedBox(height: 24),

                // Main Customers Container
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24), // One UI Squircle
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                      // Filter Bar & Search Input
                      _buildFilterBar(context, state, isDark),
                      const SizedBox(height: 20),
                      Divider(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      const SizedBox(height: 16),

                      // Customers Content by State
                      if (state.isLoading && state.customers.isEmpty)
                        _buildLoadingShimmer(isDark)
                      else if (state.isFailure && state.customers.isEmpty)
                        _buildErrorState(context, state, isDark)
                      else if (state.isEmpty)
                        _buildEmptyState(context, state, isDark)
                      else
                        _buildCustomersList(context, state, isDark),
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

  Widget _buildKpiGrid(
    BuildContext context,
    CustomersState state,
    bool isDark,
  ) {
    final totalCountStr = state.totalCustomers > 0
        ? NumberFormat('#,###').format(state.totalCustomers)
        : (state.customers.isNotEmpty
            ? state.customers.length.toString()
            : '...');

    final payingCount = state.payingCustomersCount;
    final nonPayingCount = state.nonPayingCustomersCount;

    final kpis = [
      {
        'title': 'Total Customers',
        'value': totalCountStr,
        'subtitle': 'WooCommerce v3 Directory',
        'icon': Icons.people_alt_rounded,
        'color': AppColors.primary,
        'gradient': AppColors.brandGradient,
      },
      {
        'title': 'Paying Customers',
        'value': state.customers.isNotEmpty ? payingCount.toString() : '...',
        'subtitle': 'Verified buyers with orders',
        'icon': Icons.verified_user_rounded,
        'color': AppColors.success,
        'gradient': AppColors.emeraldGradient,
      },
      {
        'title': 'Registered Accounts',
        'value': state.customers.isNotEmpty ? nonPayingCount.toString() : '...',
        'subtitle': 'Awaiting first purchase',
        'icon': Icons.person_outline_rounded,
        'color': AppColors.warning,
        'gradient': AppColors.amberGradient,
      },
      {
        'title': 'Newest Signups',
        'value': state.customers.isNotEmpty
            ? '${state.customers.length} Loaded'
            : '0',
        'subtitle': 'Sorted by registered date',
        'icon': Icons.fiber_new_rounded,
        'color': AppColors.secondary,
        'gradient': AppColors.skyGradient,
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
                          overflow: TextOverflow.ellipsis,
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
    CustomersState state,
    bool isDark,
  ) {
    final roles = [
      {'label': 'All Roles', 'value': 'all'},
      {'label': 'Customer', 'value': 'customer'},
      {'label': 'Subscriber', 'value': 'subscriber'},
      {'label': 'Administrator', 'value': 'administrator'},
      {'label': 'Shop Manager', 'value': 'shop_manager'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
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
                            onChanged: _onSearchChanged,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search by customer name, email, username...',
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
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _searchController.clear();
                              context
                                  .read<CustomersBloc>()
                                  .add(const CustomersSearchChanged(''));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'Refresh directory',
                  child: IconButton.filledTonal(
                    onPressed: () {
                      context
                          .read<CustomersBloc>()
                          .add(const CustomersRefreshed());
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Role Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: roles.map((r) {
                  final isSelected = state.selectedRole == r['value'];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        context
                            .read<CustomersBloc>()
                            .add(CustomersRoleFilterChanged(r['value']!));
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBackground
                                  : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20), // One UI Pill
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Text(
                          r['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
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

  Widget _buildCustomersList(
    BuildContext context,
    CustomersState state,
    bool isDark,
  ) {
    final customers = state.customers;

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: customers.length,
          separatorBuilder: (_, _) => Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 16,
          ),
          itemBuilder: (context, index) {
            final customer = customers[index];
            return InkWell(
              onTap: () {
                if (customer.id != null) {
                  CustomerDetailsScreen.show(
                    context,
                    customerId: customer.id!,
                    initialCustomer: customer,
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: _buildCustomerItemTile(context, customer, isDark),
            );
          },
        ),

        // Bottom Loading Indicator for Infinite Scrolling
        if (state.isLoadingMore) ...[
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading more customers (Page ${state.currentPage + 1})...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (state.hasReachedMax && state.customers.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: Text(
              'All ${state.customers.length} customers loaded',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildCustomerItemTile(
    BuildContext context,
    GETCustomersModel customer,
    bool isDark,
  ) {
    final isPaying = customer.isPayingCustomer == true;

    // Format registration date
    final registeredDateStr = customer.parsedDateCreated != null
        ? DateFormat('MMM dd, yyyy').format(customer.parsedDateCreated!)
        : (customer.dateCreated ?? '');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with SafeNetworkImage and Initials Gradient Squircle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: isPaying
                      ? AppColors.emeraldGradient
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16), // One UI Squircle
                  boxShadow: [
                    BoxShadow(
                      color: (isPaying ? AppColors.success : AppColors.primary)
                          .withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: customer.avatarUrl != null &&
                          customer.avatarUrl!.trim().isNotEmpty
                      ? SafeNetworkImage(
                          imageUrl: customer.avatarUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: Center(
                            child: Text(
                              customer.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          errorWidget: Center(
                            child: Text(
                              customer.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            customer.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Customer Name, Email, Username, Badges, Phone, Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          customer.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        _buildRoleChip(customer.roleDisplayName, isDark),
                        _buildPayingChip(isPaying, isDark),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Email & Username
                    Row(
                      children: [
                        if (customer.email != null &&
                            customer.email!.trim().isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              customer.email!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (customer.username != null &&
                            customer.username!.trim().isNotEmpty) ...[
                          Text(
                            ' • @${customer.username!}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Location & Phone
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              customer.locationSummary,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (customer.primaryPhone != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 13,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                customer.primaryPhone!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (isCompact && registeredDateStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Joined: $registeredDateStr',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (!isCompact && registeredDateStr.isNotEmpty) ...[
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      registeredDateStr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Registered date',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(width: 6),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  size: 20,
                ),
                tooltip: 'Customer Options',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                onSelected: (value) {
                  if (value == 'view') {
                    if (customer.id != null) {
                      CustomerDetailsScreen.show(
                        context,
                        customerId: customer.id!,
                        initialCustomer: customer,
                      );
                    }
                  } else if (value == 'edit') {
                    EditCustomerScreen.show(context, customer: customer);
                  } else if (value == 'delete') {
                    if (customer.id != null) {
                      DeleteCustomerDialog.show(
                        context,
                        customerId: customer.id!,
                        customerName: customer.displayName,
                        customerEmail: customer.email,
                      );
                    }
                  }
                },
                itemBuilder: (menuContext) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit Customer'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Delete Customer',
                            style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleChip(String role, bool isDark) {
    Color bg;
    Color fg;

    switch (role.toLowerCase()) {
      case 'administrator':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
      case 'shop_manager':
      case 'shop manager':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
      case 'subscriber':
        bg = AppColors.secondary.withValues(alpha: 0.15);
        fg = AppColors.secondary;
        break;
      case 'customer':
      default:
        bg = isDark
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.indigoPastel;
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPayingChip(bool isPaying, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isPaying
            ? AppColors.success.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaying ? Icons.verified_rounded : Icons.person_outline_rounded,
            size: 11,
            color: isPaying
                ? AppColors.success
                : (isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted),
          ),
          const SizedBox(width: 3),
          Text(
            isPaying ? 'Paying' : 'Standard',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isPaying
                  ? AppColors.success
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading customers from WooCommerce...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CustomersState state,
    bool isDark,
  ) {
    final hasFilter =
        state.searchQuery.isNotEmpty || state.selectedRole != 'all';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 38,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No customers found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilter
                  ? 'No customers match your search criteria or role filter.'
                  : 'There are currently no customer accounts in this WooCommerce store.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context
                      .read<CustomersBloc>()
                      .add(const CustomersSearchChanged(''));
                  context
                      .read<CustomersBloc>()
                      .add(const CustomersRoleFilterChanged('all'));
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Reset Filters'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    CustomersState state,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load customers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              state.errorMessage ??
                  'Network connection error while contacting WooCommerce API.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                context
                    .read<CustomersBloc>()
                    .add(const CustomersFetchStarted());
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
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
}
