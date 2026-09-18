import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RevenueTrendChart extends StatefulWidget {
  final List<dynamic> trends;
  final String period;

  const RevenueTrendChart({
    super.key,
    required this.trends,
    required this.period,
  });

  @override
  State<RevenueTrendChart> createState() => _RevenueTrendChartState();
}

class _RevenueTrendChartState extends State<RevenueTrendChart> {
  final numFormat = NumberFormat('#,##,###');
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.trends.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'No chart data available for this period',
          style: TextStyle(color: colorScheme.outline),
        ),
      );
    }

    double maxVal = 0.0;
    for (var item in widget.trends) {
      final double sales = _getDouble(item['salesAmount']);
      final double payments = _getDouble(item['paymentAmount']);
      maxVal = max(maxVal, max(sales, payments));
    }
    if (maxVal == 0) maxVal = 1000;

    return Column(
      children: [
        // Legend Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Sales Revenue', Colors.orangeAccent),
            const SizedBox(width: 20),
            _buildLegendItem('Payments Collected', Colors.green),
          ],
        ),
        const SizedBox(height: 16),

        // Hover Info Box
        if (_hoveredIndex != null && _hoveredIndex! < widget.trends.length)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.trends[_hoveredIndex!]['label'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sales: ₹${numFormat.format(_getDouble(widget.trends[_hoveredIndex!]['salesAmount']))}',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Text(
                  'Paid: ₹${numFormat.format(_getDouble(widget.trends[_hoveredIndex!]['paymentAmount']))}',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 28),

        // Bars Container
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.trends.length, (index) {
              final item = widget.trends[index];
              final double sales = _getDouble(item['salesAmount']);
              final double payments = _getDouble(item['paymentAmount']);
              final String label = item['label'] ?? '';

              final double salesHeightPct = (sales / maxVal).clamp(0.05, 1.0);
              final double paymentsHeightPct = (payments / maxVal).clamp(0.05, 1.0);

              final isHovered = _hoveredIndex == index;

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: GestureDetector(
                  onTap: () => setState(() => _hoveredIndex = isHovered ? null : index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Sales Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isHovered ? 14 : 10,
                              height: 130 * salesHeightPct,
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                boxShadow: isHovered
                                    ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 8)]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Payments Bar
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isHovered ? 14 : 10,
                              height: 130 * paymentsHeightPct,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                boxShadow: isHovered
                                    ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 8)]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Axis Label
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isHovered ? FontWeight.bold : FontWeight.normal,
                          color: isHovered ? colorScheme.primary : colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  double _getDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
