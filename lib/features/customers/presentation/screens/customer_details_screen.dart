import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../bloc/single_customer_cubit.dart';
import '../../bloc/single_customer_state.dart';
import '../../data/models/get_customers_model.dart';
import '../../data/models/get_single_customers_model.dart';
import '../../data/repositories/customers_repository.dart';

/// Premium Samsung One UI 9-inspired Customer Details Screen.
/// Powered by WooCommerce GET /wp-json/wc/v3/customers/{{customerId}}
/// via [SingleCustomerCubit] and [GETSingleCustomersModel].
class CustomerDetailsScreen extends StatefulWidget {
  final int customerId;
  final dynamic initialCustomer;

  const CustomerDetailsScreen({
    super.key,
    required this.customerId,
    this.initialCustomer,
  });

  static Route<void> route({
    required int customerId,
    dynamic initialCustomer,
  }) {
    return MaterialPageRoute(
      builder: (context) {
        CustomersRepository repo;
        try {
          repo = context.read<CustomersRepository>();
        } catch (_) {
          repo = CustomersRepository();
        }

        try {
          final cubit = context.read<SingleCustomerCubit>();
          if (initialCustomer != null) {
            cubit.setInitialCustomer(initialCustomer);
          }
          cubit.fetchSingleCustomer(customerId);
          return CustomerDetailsScreen(
            customerId: customerId,
            initialCustomer: initialCustomer,
          );
        } catch (_) {
          return BlocProvider<SingleCustomerCubit>(
            create: (_) {
              final cubit = SingleCustomerCubit(repository: repo);
              if (initialCustomer != null) {
                cubit.setInitialCustomer(initialCustomer);
              }
              cubit.fetchSingleCustomer(customerId);
              return cubit;
            },
            child: CustomerDetailsScreen(
              customerId: customerId,
              initialCustomer: initialCustomer,
            ),
          );
        }
      },
    );
  }

  /// Opens Customer Details screen as a route
  static Future<void> show(
    BuildContext context, {
    required int customerId,
    dynamic initialCustomer,
  }) async {
    await Navigator.of(context).push(
      route(customerId: customerId, initialCustomer: initialCustomer),
    );
  }

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  int _selectedSection = 0; // 0: Overview, 1: Billing, 2: Shipping, 3: Metadata

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cubit = context.read<SingleCustomerCubit>();
        if (widget.initialCustomer != null) {
          cubit.setInitialCustomer(widget.initialCustomer);
        }
        cubit.fetchSingleCustomer(widget.customerId);
      }
    });
  }

  GETSingleCustomersModel? _resolveCustomer(SingleCustomerState state) {
    if (state.customer != null && state.customer!.id == widget.customerId) {
      return state.customer;
    }
    if (state.cachedCustomers.containsKey(widget.customerId)) {
      return state.cachedCustomers[widget.customerId];
    }
    if (widget.initialCustomer != null) {
      if (widget.initialCustomer is GETSingleCustomersModel) {
        return widget.initialCustomer as GETSingleCustomersModel;
      } else if (widget.initialCustomer is GETCustomersModel) {
        return GETSingleCustomersModel.fromCustomersModel(
          widget.initialCustomer as GETCustomersModel,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isDark),
      body: BlocConsumer<SingleCustomerCubit, SingleCustomerState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.customer != null) {
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
          final customer = _resolveCustomer(state);
          final isLoading = state.isLoading && customer == null;
          final isFailure = state.isFailure && customer == null;

          if (isLoading) {
            return _buildLoadingState(isDark);
          }

          if (isFailure) {
            return _buildErrorState(context, state, isDark);
          }

          if (customer == null) {
            return _buildEmptyState(context, isDark);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context
                .read<SingleCustomerCubit>()
                .fetchSingleCustomer(widget.customerId, forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtle background refresh indicator if data is re-fetching
                  if (state.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Colors.transparent,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),

                  // Hero Customer Profile Card
                  _buildProfileCard(context, customer, isDark),
                  const SizedBox(height: 18),

                  // One UI 9 Section Navigation Pills
                  _buildSectionPills(context, isDark),
                  const SizedBox(height: 18),

                  // Content Sections based on selection
                  if (_selectedSection == 0) ...[
                    // Quick Metrics & Status Tiles
                    _buildQuickStats(context, customer, isDark),
                    const SizedBox(height: 20),

                    // Two-Column or Single-Column for Billing & Shipping
                    _buildAddressesSection(context, customer, isDark),
                    const SizedBox(height: 20),

                    // Metadata Summary Card
                    _buildMetadataCard(context, customer, isDark),
                  ] else if (_selectedSection == 1) ...[
                    _buildBillingCard(context, customer.billing, isDark),
                  ] else if (_selectedSection == 2) ...[
                    _buildShippingCard(context, customer.shipping, isDark),
                  ] else if (_selectedSection == 3) ...[
                    _buildMetadataCard(context, customer, isDark),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back to Customers',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Customer #${widget.customerId}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(
                  context,
                  '${widget.customerId}',
                  'Customer ID copied',
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'WooCommerce REST API v3 Profile',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Reload Customer Data',
          onPressed: () {
            context
                .read<SingleCustomerCubit>()
                .fetchSingleCustomer(widget.customerId, forceRefresh: true);
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildSectionPills(BuildContext context, bool isDark) {
    final sections = [
      {'label': 'All Details', 'icon': Icons.grid_view_rounded},
      {'label': 'Billing Address', 'icon': Icons.receipt_long_rounded},
      {'label': 'Shipping Address', 'icon': Icons.local_shipping_rounded},
      {'label': 'Metadata & Logs', 'icon': Icons.data_object_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sections.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _selectedSection == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedSection = index),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.darkSurface
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(18), // One UI Pill
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
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
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    GETSingleCustomersModel customer,
    bool isDark,
  ) {
    final isPaying = customer.isPayingCustomer == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24), // One UI Squircle
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;

          final avatarWidget = Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: isPaying
                  ? AppColors.emeraldGradient
                  : AppColors.brandGradient,
              borderRadius: BorderRadius.circular(24), // One UI Squircle
              boxShadow: [
                BoxShadow(
                  color: (isPaying ? AppColors.success : AppColors.primary)
                      .withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: customer.avatarUrl != null &&
                      customer.avatarUrl!.trim().isNotEmpty
                  ? SafeNetworkImage(
                      imageUrl: customer.avatarUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: Center(
                        child: Text(
                          customer.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      errorWidget: Center(
                        child: Text(
                          customer.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        customer.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
            ),
          );

          final detailsWidget = Column(
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment:
                    isCompact ? WrapAlignment.center : WrapAlignment.start,
                children: [
                  Text(
                    customer.displayName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  _buildRoleBadge(customer.roleDisplayName, isDark),
                  _buildPayingBadge(isPaying, isDark),
                ],
              ),
              const SizedBox(height: 6),
              if (customer.username != null &&
                  customer.username!.trim().isNotEmpty) ...[
                Text(
                  '@${customer.username!.trim()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment:
                    isCompact ? WrapAlignment.center : WrapAlignment.start,
                children: [
                  if (customer.email != null &&
                      customer.email!.trim().isNotEmpty)
                    InkWell(
                      onTap: () => _copyToClipboard(
                        context,
                        customer.email!,
                        'Email address copied',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.email!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (customer.primaryPhone != null)
                    InkWell(
                      onTap: () => _copyToClipboard(
                        context,
                        customer.primaryPhone!,
                        'Phone number copied',
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.primaryPhone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.copy_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );

          if (isCompact) {
            return Column(
              children: [
                Center(child: avatarWidget),
                const SizedBox(height: 16),
                detailsWidget,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarWidget,
              const SizedBox(width: 20),
              Expanded(child: detailsWidget),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(String role, bool isDark) {
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
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10), // One UI Pill
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPayingBadge(bool isPaying, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: isPaying
            ? AppColors.success.withValues(alpha: 0.15)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaying ? Icons.verified_rounded : Icons.person_outline_rounded,
            size: 12,
            color: isPaying
                ? AppColors.success
                : (isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted),
          ),
          const SizedBox(width: 4),
          Text(
            isPaying ? 'Paying Customer' : 'Registered',
            style: TextStyle(
              fontSize: 11,
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

  Widget _buildQuickStats(
    BuildContext context,
    GETSingleCustomersModel customer,
    bool isDark,
  ) {
    final registeredDateStr = customer.parsedDateCreated != null
        ? DateFormat('MMM dd, yyyy').format(customer.parsedDateCreated!)
        : (customer.dateCreated ?? 'N/A');

    final modifiedDateStr = customer.parsedDateModified != null
        ? DateFormat('MMM dd, yyyy').format(customer.parsedDateModified!)
        : (customer.dateModified ?? 'N/A');

    final stats = [
      {
        'title': 'Account Role',
        'value': customer.roleDisplayName,
        'subtitle': 'Permission Level',
        'icon': Icons.admin_panel_settings_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'Customer Status',
        'value':
            customer.isPayingCustomer == true ? 'Paying Customer' : 'Standard',
        'subtitle': customer.isPayingCustomer == true
            ? 'Completed purchases'
            : 'No orders yet',
        'icon': Icons.shopping_bag_outlined,
        'color': customer.isPayingCustomer == true
            ? AppColors.success
            : AppColors.warning,
      },
      {
        'title': 'Registered Date',
        'value': registeredDateStr,
        'subtitle': 'Joined store',
        'icon': Icons.calendar_today_rounded,
        'color': AppColors.secondary,
      },
      {
        'title': 'Last Updated',
        'value': modifiedDateStr,
        'subtitle': 'Profile modification',
        'icon': Icons.update_rounded,
        'color': AppColors.accent,
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final itemWidth = isWide
            ? (constraints.maxWidth - (3 * 16)) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: stats.map((s) {
            final color = s['color'] as Color;

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20), // One UI Squircle
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      s['icon'] as IconData,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['title'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['value'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          s['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 10,
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

  Widget _buildAddressesSection(
    BuildContext context,
    GETSingleCustomersModel customer,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildBillingCard(context, customer.billing, isDark),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildShippingCard(context, customer.shipping, isDark),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildBillingCard(context, customer.billing, isDark),
            const SizedBox(height: 20),
            _buildShippingCard(context, customer.shipping, isDark),
          ],
        );
      },
    );
  }

  Widget _buildBillingCard(
    BuildContext context,
    Billing? billing,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Billing Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),
          if (billing == null || billing.isEmpty)
            Text(
              'No billing information recorded for this customer.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            )
          else ...[
            if ('${billing.firstName ?? ''} ${billing.lastName ?? ''}'.trim().isNotEmpty)
              _buildInfoRow('Name', '${billing.firstName ?? ''} ${billing.lastName ?? ''}'.trim(), isDark),
            if (billing.company != null && billing.company!.trim().isNotEmpty)
              _buildInfoRow('Company', billing.company!.trim(), isDark),
            if (billing.address1 != null && billing.address1!.trim().isNotEmpty)
              _buildInfoRow('Address 1', billing.address1!.trim(), isDark),
            if (billing.address2 != null && billing.address2!.trim().isNotEmpty)
              _buildInfoRow('Address 2', billing.address2!.trim(), isDark),
            if (billing.city != null && billing.city!.trim().isNotEmpty)
              _buildInfoRow('City', billing.city!.trim(), isDark),
            if (billing.state != null && billing.state!.trim().isNotEmpty)
              _buildInfoRow('State / Province', billing.state!.trim(), isDark),
            if (billing.postcode != null && billing.postcode!.trim().isNotEmpty)
              _buildInfoRow('Postal / Zip Code', billing.postcode!.trim(), isDark),
            if (billing.country != null && billing.country!.trim().isNotEmpty)
              _buildInfoRow('Country', billing.country!.trim(), isDark),
            if (billing.email != null && billing.email!.trim().isNotEmpty)
              _buildInfoRow(
                'Billing Email',
                billing.email!.trim(),
                isDark,
                copyable: true,
              ),
            if (billing.phone != null && billing.phone!.trim().isNotEmpty)
              _buildInfoRow(
                'Billing Phone',
                billing.phone!.trim(),
                isDark,
                copyable: true,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingCard(
    BuildContext context,
    Shipping? shipping,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
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
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),
          if (shipping == null || shipping.isEmpty)
            Text(
              'No shipping address recorded for this customer.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            )
          else ...[
            if ('${shipping.firstName ?? ''} ${shipping.lastName ?? ''}'.trim().isNotEmpty)
              _buildInfoRow('Name', '${shipping.firstName ?? ''} ${shipping.lastName ?? ''}'.trim(), isDark),
            if (shipping.company != null && shipping.company!.trim().isNotEmpty)
              _buildInfoRow('Company', shipping.company!.trim(), isDark),
            if (shipping.address1 != null && shipping.address1!.trim().isNotEmpty)
              _buildInfoRow('Address 1', shipping.address1!.trim(), isDark),
            if (shipping.address2 != null && shipping.address2!.trim().isNotEmpty)
              _buildInfoRow('Address 2', shipping.address2!.trim(), isDark),
            if (shipping.city != null && shipping.city!.trim().isNotEmpty)
              _buildInfoRow('City', shipping.city!.trim(), isDark),
            if (shipping.state != null && shipping.state!.trim().isNotEmpty)
              _buildInfoRow('State / Province', shipping.state!.trim(), isDark),
            if (shipping.postcode != null && shipping.postcode!.trim().isNotEmpty)
              _buildInfoRow('Postal / Zip Code', shipping.postcode!.trim(), isDark),
            if (shipping.country != null && shipping.country!.trim().isNotEmpty)
              _buildInfoRow('Country', shipping.country!.trim(), isDark),
            if (shipping.phone != null && shipping.phone!.trim().isNotEmpty)
              _buildInfoRow(
                'Shipping Phone',
                shipping.phone!.trim(),
                isDark,
                copyable: true,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataCard(
    BuildContext context,
    GETSingleCustomersModel customer,
    bool isDark,
  ) {
    final metaList = customer.metaData ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22),
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
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.data_object_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'WooCommerce System Metadata',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 14),
          _buildInfoRow('Customer ID', '#${customer.id ?? 0}', isDark),
          _buildInfoRow('Username', customer.username ?? 'None', isDark),
          _buildInfoRow(
            'Date Created (GMT)',
            customer.dateCreatedGmt ?? 'N/A',
            isDark,
          ),
          _buildInfoRow(
            'Date Modified (GMT)',
            customer.dateModifiedGmt ?? 'N/A',
            isDark,
          ),
          if (metaList.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Custom Meta Fields (${metaList.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: metaList.length > 10 ? 10 : metaList.length,
                separatorBuilder: (_, _) => Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = metaList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            item.key ?? 'meta_key',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.value?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (metaList.length > 10) ...[
              const SizedBox(height: 6),
              Text(
                '+ ${metaList.length - 10} more metadata fields',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    bool isDark, {
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Copy to clipboard',
              onPressed: () => _copyToClipboard(context, value, '$label copied'),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching complete customer profile...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    SingleCustomerState state,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load customer profile',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'An unexpected network error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                context.read<SingleCustomerCubit>().fetchSingleCustomer(
                      widget.customerId,
                      forceRefresh: true,
                    );
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

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Customer profile not found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
