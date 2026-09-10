import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/shipping_zones_model.dart';
import '../../data/repositories/shipping_repository.dart';

/// Samsung One UI 9-inspired Shipping Zone Details & Operations Screen.
/// Utilizes the dynamic `zoneId` to display and inspect WooCommerce shipping zone configurations.
class ShippingZoneDetailsScreen extends StatefulWidget {
  final int zoneId;
  final ShippingZonesModel? initialZone;

  const ShippingZoneDetailsScreen({
    super.key,
    required this.zoneId,
    this.initialZone,
  });

  static Route<void> route({
    required int zoneId,
    ShippingZonesModel? initialZone,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => ShippingZoneDetailsScreen(
        zoneId: zoneId,
        initialZone: initialZone,
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required int zoneId,
    ShippingZonesModel? initialZone,
  }) async {
    return Navigator.of(context).push<void>(
      route(zoneId: zoneId, initialZone: initialZone),
    );
  }

  @override
  State<ShippingZoneDetailsScreen> createState() =>
      _ShippingZoneDetailsScreenState();
}

class _ShippingZoneDetailsScreenState extends State<ShippingZoneDetailsScreen> {
  late int _zoneId;
  ShippingZonesModel? _zone;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _zoneId = widget.zoneId;
    _zone = widget.initialZone;
    if (_zone == null) {
      _loadZoneDetails();
    }
  }

  Future<void> _loadZoneDetails({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = context.read<ShippingRepository>();
      final zone = await repository.getShippingZone(
        _zoneId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _zone = zone;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDefault = _zoneId == 0;
    final zone = _zone;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          zone?.displayName ?? 'Shipping Zone #$_zoneId',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Zone Data',
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : () => _loadZoneDetails(forceRefresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Zone Banner Card (One UI 9)
            _buildHeroZoneBanner(context, isDark, zone, isDefault),
            const SizedBox(height: 20),

            // Error banner if single fetch failed
            if (_errorMessage != null) ...[
              _buildErrorBanner(context, isDark),
              const SizedBox(height: 20),
            ],

            // Zone Core Attributes Card
            _buildCoreAttributesCard(context, isDark, zone),
            const SizedBox(height: 20),

            // Next Shipping Operations & API Capabilities
            _buildNextOperationsCard(context, isDark, zone),
            const SizedBox(height: 20),

            // REST API v3 Links & Endpoints Card
            _buildApiLinksCard(context, isDark, zone),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroZoneBanner(
    BuildContext context,
    bool isDark,
    ShippingZonesModel? zone,
    bool isDefault,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDefault ? AppColors.purpleGradient : AppColors.skyGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDefault ? AppColors.accent : AppColors.secondary)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'ZONE ID: $_zoneId',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Default Fallback',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            zone?.displayName ?? 'Zone #$_zoneId',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDefault
                ? 'This zone applies to customers who do not match any of your custom zones.'
                : 'Priority Order: ${zone?.formattedOrder ?? "0"} • WooCommerce v3 Shipping Zone',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreAttributesCard(
    BuildContext context,
    bool isDark,
    ShippingZonesModel? zone,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
                  Icons.tune_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Zone Configuration & Order',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),

          _buildAttributeRow(
            context,
            isDark,
            icon: Icons.tag_rounded,
            label: 'Zone Identifier',
            value: '$_zoneId',
            actionIcon: Icons.copy_rounded,
            onAction: () => _copyToClipboard('$_zoneId', 'Zone ID'),
          ),
          const Divider(height: 24),

          _buildAttributeRow(
            context,
            isDark,
            icon: Icons.badge_outlined,
            label: 'Zone Name',
            value: zone?.displayName ?? 'Loading...',
            actionIcon: Icons.copy_rounded,
            onAction: zone?.name != null
                ? () => _copyToClipboard(zone!.name!, 'Zone Name')
                : null,
          ),
          const Divider(height: 24),

          _buildAttributeRow(
            context,
            isDark,
            icon: Icons.sort_rounded,
            label: 'Evaluation Order',
            value: zone?.formattedOrder ?? '0',
            description:
                'Determines the priority order in which WooCommerce evaluates this zone during customer checkout.',
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    String? description,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionIcon != null && onAction != null)
          IconButton(
            icon: Icon(actionIcon, size: 18),
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            onPressed: onAction,
            tooltip: 'Copy',
          ),
      ],
    );
  }

  Widget _buildNextOperationsCard(
    BuildContext context,
    bool isDark,
    ShippingZonesModel? zone,
  ) {
    final operations = [
      {
        'title': 'Zone Shipping Methods',
        'subtitle':
            'Endpoints: GET /wp-json/wc/v3/shipping/zones/$_zoneId/methods',
        'icon': Icons.local_shipping_outlined,
        'color': AppColors.primary,
        'actionText': 'Zone Methods',
      },
      {
        'title': 'Zone Geographic Locations',
        'subtitle':
            'Endpoints: GET /wp-json/wc/v3/shipping/zones/$_zoneId/locations',
        'icon': Icons.pin_drop_outlined,
        'color': AppColors.secondary,
        'actionText': 'Zone Locations',
      },
      {
        'title': 'Dynamic Zone ID Reference',
        'subtitle': 'Pass zoneId: $_zoneId to associated WooCommerce controllers',
        'icon': Icons.integration_instructions_outlined,
        'color': AppColors.accent,
        'actionText': 'Copy ID',
        'onTap': () => _copyToClipboard('$_zoneId', 'Zone ID'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
                  Icons.hub_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Dynamic Zone Operations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...operations.map((op) {
            final color = op['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(op['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          op['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          op['subtitle'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: (op['onTap'] as VoidCallback?) ??
                        () {
                          _copyToClipboard(
                            '$_zoneId',
                            'Zone ID #$_zoneId for ${op['title']}',
                          );
                        },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      op['actionText'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildApiLinksCard(
    BuildContext context,
    bool isDark,
    ShippingZonesModel? zone,
  ) {
    final selfHref = (zone?.lLinks?.self != null && zone!.lLinks!.self!.isNotEmpty)
        ? zone.lLinks!.self!.first.href
        : null;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
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
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.api_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'WooCommerce REST API v3 Links',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (selfHref != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 18, color: AppColors.info),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selfHref,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () => _copyToClipboard(selfHref, 'Endpoint URL'),
                    tooltip: 'Copy URL',
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'No REST links provided in API response for zone #$_zoneId.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Failed to load details',
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _loadZoneDetails(forceRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
