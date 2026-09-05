import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/sales_report_model.dart';

/// Responsive Sales Performance Trend Chart with smooth Bézier curves,
/// gradient fill, interactive touch inspection, and Samsung One UI styling.
class SalesTrendChart extends StatefulWidget {
  final Map<String, DailyTotal> totals;
  final String? totalsGroupedBy;
  final String currencySymbol;
  final double height;

  const SalesTrendChart({
    super.key,
    required this.totals,
    this.totalsGroupedBy,
    this.currencySymbol = '\$',
    this.height = 260,
  });

  @override
  State<SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<SalesTrendChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant SalesTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totals != widget.totals) {
      _selectedIndex = null;
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort dates chronologically
    final sortedEntries = widget.totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (sortedEntries.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No sales trend data available for this range',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final values = sortedEntries.map((e) => e.value.salesValue).toList();
    final maxVal = values.fold<double>(0.0, (prev, curr) => math.max(prev, curr));
    final effectiveMax = maxVal == 0 ? 100.0 : maxVal * 1.15;

    final selectedEntry = (_selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < sortedEntries.length)
        ? sortedEntries[_selectedIndex!]
        : null;

    final groupingLabel = widget.totalsGroupedBy != null && widget.totalsGroupedBy!.isNotEmpty
        ? widget.totalsGroupedBy!.toUpperCase()
        : 'TIMELINE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Grouping & Selected Inspector Tag
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        'GROUPED BY $groupingLabel',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${sortedEntries.length} data points',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            if (selectedEntry != null)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedEntry.key,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.currencySymbol}${selectedEntry.value.salesValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if ((selectedEntry.value.orders ?? 0) > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${selectedEntry.value.orders} orders)',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Text(
                'Tap point to inspect',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Chart Canvas Area
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      _handleTouch(details.localPosition, constraints.maxWidth, sortedEntries.length);
                    },
                    onPanUpdate: (details) {
                      _handleTouch(details.localPosition, constraints.maxWidth, sortedEntries.length);
                    },
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, widget.height),
                      painter: _ChartPainter(
                        entries: sortedEntries,
                        values: values,
                        maxVal: effectiveMax,
                        selectedIndex: _selectedIndex,
                        progress: _progressAnimation.value,
                        isDark: isDark,
                        currencySymbol: widget.currencySymbol,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Bottom Date Label Row (Sampled labels)
        const SizedBox(height: 8),
        _buildBottomLabels(sortedEntries, isDark),
      ],
    );
  }

  void _handleTouch(Offset localPos, double chartWidth, int totalPoints) {
    if (totalPoints <= 1) return;
    const paddingLeft = 45.0;
    const paddingRight = 16.0;
    final usableWidth = chartWidth - paddingLeft - paddingRight;

    final relativeX = localPos.dx - paddingLeft;
    if (relativeX < 0 || relativeX > usableWidth) return;

    final segmentWidth = usableWidth / (totalPoints - 1);
    final index = (relativeX / segmentWidth).round().clamp(0, totalPoints - 1);

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildBottomLabels(List<MapEntry<String, DailyTotal>> entries, bool isDark) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Sample 5-7 labels evenly
    final step = math.max(1, (entries.length / 5).floor());
    final indices = <int>[];
    for (int i = 0; i < entries.length; i += step) {
      indices.add(i);
    }
    if (indices.last != entries.length - 1) {
      indices.add(entries.length - 1);
    }

    final textColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Padding(
      padding: const EdgeInsets.only(left: 45, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: indices.map((idx) {
          final rawKey = entries[idx].key;
          // Format e.g. "2026-09-05" -> "09/05"
          final displayLabel = _formatDateShort(rawKey);
          final isSelected = _selectedIndex == idx;

          return Text(
            displayLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryLight : textColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDateShort(String dateStr) {
    if (dateStr.length >= 10 && dateStr.contains('-')) {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        return '${parts[1]}/${parts[2]}';
      }
    }
    return dateStr;
  }
}

class _ChartPainter extends CustomPainter {
  final List<MapEntry<String, DailyTotal>> entries;
  final List<double> values;
  final double maxVal;
  final int? selectedIndex;
  final double progress;
  final bool isDark;
  final String currencySymbol;

  _ChartPainter({
    required this.entries,
    required this.values,
    required this.maxVal,
    required this.selectedIndex,
    required this.progress,
    required this.isDark,
    required this.currencySymbol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 45.0;
    const paddingRight = 16.0;
    const paddingTop = 16.0;
    const paddingBottom = 20.0;

    final usableWidth = size.width - paddingLeft - paddingRight;
    final usableHeight = size.height - paddingTop - paddingBottom;

    if (entries.isEmpty || usableWidth <= 0 || usableHeight <= 0) return;

    // 1. Draw Grid Lines & Y-Axis Labels
    final gridLinePaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    const horizontalDivisions = 4;
    for (int i = 0; i <= horizontalDivisions; i++) {
      final y = paddingTop + (usableHeight / horizontalDivisions) * i;
      final val = maxVal - (maxVal / horizontalDivisions) * i;

      // Draw dashed horizontal line
      _drawDashedLine(
        canvas,
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridLinePaint,
      );

      // Y-axis label
      final labelText = '$currencySymbol${_formatCompact(val)}';
      final textPainter = TextPainter(
        text: TextSpan(text: labelText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // 2. Compute Points
    final points = <Offset>[];
    final stepX = entries.length > 1 ? usableWidth / (entries.length - 1) : usableWidth;

    for (int i = 0; i < entries.length; i++) {
      final x = paddingLeft + (i * stepX);
      final normalizedValue = (values[i] / maxVal) * progress;
      final y = (paddingTop + usableHeight) - (normalizedValue * usableHeight);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // 3. Build Smooth Bézier Path
    final path = Path();
    final fillPath = Path();

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, paddingTop + usableHeight);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, paddingTop + usableHeight);
    fillPath.close();

    // 4. Draw Gradient Fill Beneath Line
    final gradientFill = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.primary.withValues(alpha: 0.35 * progress),
        AppColors.primary.withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradientFill.createShader(
        Rect.fromLTWH(0, paddingTop, size.width, usableHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Bézier Line Stroke
    final strokePaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // 6. Draw Highlight on Selected or Interactive Point
    if (selectedIndex != null && selectedIndex! < points.length) {
      final selectedPoint = points[selectedIndex!];

      // Vertical guide line
      final guidePaint = Paint()
        ..color = AppColors.primaryLight.withValues(alpha: 0.6)
        ..strokeWidth = 1.5;

      _drawDashedLine(
        canvas,
        Offset(selectedPoint.dx, paddingTop),
        Offset(selectedPoint.dx, paddingTop + usableHeight),
        guidePaint,
      );

      // Outer glow pulse
      final glowPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 12, glowPaint);

      // Inner halo ring
      final haloPaint = Paint()
        ..color = AppColors.primaryLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(selectedPoint, 6, haloPaint);

      // Center solid core
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 4, corePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = p1.dx;
    final isVertical = (p1.dx == p2.dx);

    if (isVertical) {
      double startY = p1.dy;
      while (startY < p2.dy) {
        canvas.drawLine(
          Offset(p1.dx, startY),
          Offset(p1.dx, math.min(startY + dashWidth, p2.dy)),
          paint,
        );
        startY += dashWidth + dashSpace;
      }
    } else {
      while (startX < p2.dx) {
        canvas.drawLine(
          Offset(startX, p1.dy),
          Offset(math.min(startX + dashWidth, p2.dx), p1.dy),
          paint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  String _formatCompact(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.entries != entries ||
        oldDelegate.isDark != isDark;
  }
}
