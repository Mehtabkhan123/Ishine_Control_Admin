import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/get_general_settings_model.dart';

/// Samsung One UI 9 styled card for displaying a WooCommerce general setting.
/// Dynamically renders appropriate visual controls based on setting `type`
/// (checkbox, select, number, text, multiselect, etc.).
class GeneralSettingCard extends StatelessWidget {
  final GetGeneralSettingsModel setting;

  const GeneralSettingCard({
    super.key,
    required this.setting,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeStr = (setting.type ?? 'text').toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22), // One UI squircle
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Setting Icon, Label, Type Badge, and Copy ID
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Icon Box
                  _buildTypeIcon(typeStr, isDark),
                  const SizedBox(width: 14),
                  // Label & ID
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                setting.displayLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTypeTag(typeStr, isDark),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ID with copy chip
                        if (setting.id != null)
                          InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: setting.id!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Copied ID: ${setting.id}'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.key_rounded,
                                    size: 13,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      setting.id!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
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
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                height: 1,
              ),
              const SizedBox(height: 16),

              // 2. Value Presentation based on type
              _buildValueControl(context, typeStr, isDark),

              // 3. Description text if available
              if (setting.displayDescription.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  setting.displayDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],

              // 4. Tip Callout Banner if tip differs from description
              if (setting.tip != null &&
                  setting.tip!.trim().isNotEmpty &&
                  setting.tip!.trim() != setting.description?.trim()) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          setting.tip!.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1E40AF),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 5. Default Value Indicator
              if (setting.defaultValue != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Default: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          setting.stringDefaultValue.isEmpty
                              ? '(none)'
                              : setting.stringDefaultValue,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (setting.stringValue == setting.stringDefaultValue) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: AppColors.success.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        'Matches default',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds appropriate value control based on setting type
  Widget _buildValueControl(BuildContext context, String typeStr, bool isDark) {
    switch (typeStr) {
      case 'checkbox':
        return _buildCheckboxControl(isDark);
      case 'select':
        return _buildSelectControl(isDark);
      case 'multiselect':
        return _buildMultiselectControl(isDark);
      case 'number':
      case 'integer':
        return _buildNumberControl(context, isDark);
      case 'text':
      case 'textarea':
      case 'email':
      case 'url':
      default:
        return _buildTextControl(context, isDark);
    }
  }

  /// Control for checkbox / boolean settings
  Widget _buildCheckboxControl(bool isDark) {
    final isChecked = setting.boolValue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isChecked
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isChecked
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: isChecked ? AppColors.success : AppColors.darkTextMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            isChecked ? 'Enabled (yes)' : 'Disabled (no)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isChecked
                  ? AppColors.success
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isChecked
                  ? AppColors.success.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              setting.stringValue,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                color: isChecked ? AppColors.success : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Control for single-select dropdown settings
  Widget _buildSelectControl(bool isDark) {
    final optionLabel = setting.displayOptionLabel;
    final rawVal = setting.stringValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_drop_down_circle_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  optionLabel.isNotEmpty ? optionLabel : '(Not selected)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (optionLabel != rawVal && rawVal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Key: $rawVal',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (setting.options != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${setting.options!.length} options',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Control for multi-select list settings
  Widget _buildMultiselectControl(bool isDark) {
    final rawVal = setting.value;
    final List<String> items = [];

    if (rawVal is List) {
      items.addAll(rawVal.map((e) => e.toString()));
    } else if (rawVal is String && rawVal.isNotEmpty) {
      items.add(rawVal);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: items.isEmpty
          ? Text(
              '(No items selected)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                final displayItem = (setting.options != null &&
                        setting.options!.containsKey(item))
                    ? setting.options![item]!
                    : item;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayItem,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  /// Control for numeric settings
  Widget _buildNumberControl(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.pin_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            setting.stringValue.isEmpty ? '0' : setting.stringValue,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: 'Copy numeric value',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: setting.stringValue));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: ${setting.stringValue}'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Control for text, textarea, email, or URL settings
  Widget _buildTextControl(BuildContext context, bool isDark) {
    final displayVal = setting.stringValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            child: Text(
              displayVal.isNotEmpty ? displayVal : '(Empty / Not set)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: displayVal.isNotEmpty
                    ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                fontStyle: displayVal.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          if (displayVal.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'Copy text value',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: displayVal));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: $displayVal'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Builds icon indicator for the setting type
  Widget _buildTypeIcon(String typeStr, bool isDark) {
    IconData icon;
    Color color;

    switch (typeStr) {
      case 'checkbox':
        icon = Icons.toggle_on_rounded;
        color = AppColors.success;
        break;
      case 'select':
        icon = Icons.list_alt_rounded;
        color = AppColors.primary;
        break;
      case 'multiselect':
        icon = Icons.checklist_rounded;
        color = AppColors.secondary;
        break;
      case 'number':
      case 'integer':
        icon = Icons.numbers_rounded;
        color = AppColors.accent;
        break;
      case 'textarea':
        icon = Icons.notes_rounded;
        color = Colors.amber;
        break;
      default:
        icon = Icons.text_fields_rounded;
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// Type tag badge with curated colors
  Widget _buildTypeTag(String typeStr, bool isDark) {
    Color tagColor;

    switch (typeStr) {
      case 'checkbox':
        tagColor = AppColors.success;
        break;
      case 'select':
        tagColor = AppColors.primary;
        break;
      case 'multiselect':
        tagColor = AppColors.secondary;
        break;
      case 'number':
      case 'integer':
        tagColor = AppColors.accent;
        break;
      default:
        tagColor = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        typeStr.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: tagColor,
        ),
      ),
    );
  }
}
