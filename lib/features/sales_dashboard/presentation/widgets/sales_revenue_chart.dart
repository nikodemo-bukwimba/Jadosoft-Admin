import 'package:flutter/material.dart';
import '../../domain/projections/sales_dashboard_projection.dart';
import '../../../marketing_dashboard/presentation/widgets/shared_dash_components.dart';

class SalesRevenueChart extends StatelessWidget {
  final SalesDashboardProjection projection;
  const SalesRevenueChart({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final Map<String, double> dailyRevenue = {};
    final labels = <String>[];

    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][d.weekday - 1];
      labels.add(key);
      dailyRevenue[key] = 0;
    }
    for (final order in projection.recentOrders) {
      final key = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][order.createdAt.weekday - 1];
      if (dailyRevenue.containsKey(key)) {
        dailyRevenue[key] = (dailyRevenue[key] ?? 0) + order.total;
      }
    }

    final hasData = dailyRevenue.values.any((v) => v > 0);
    final maxVal = hasData
        ? dailyRevenue.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final displayMax = maxVal < 1 ? 1.0 : maxVal;

    return DashCard(
      title: 'Revenue This Week',
      subtitle: 'Daily sales breakdown',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'TZS ${_fmtCurrency(projection.totalRevenue)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.green.shade700,
          ),
        ),
      ),
      child: hasData
          ? SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: labels.asMap().entries.map((entry) {
                  final label = entry.value;
                  final value = dailyRevenue[label] ?? 0;
                  final ratio = value / displayMax;
                  final isHighest = value == maxVal && maxVal > 0;
                  final isToday = entry.key == labels.length - 1;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (value > 0)
                            Text(
                              _fmtShort(value),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isHighest
                                    ? cs.primary
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: Duration(
                              milliseconds: 500 + entry.key * 60,
                            ),
                            curve: Curves.easeOutCubic,
                            height: (ratio * 130).clamp(4.0, 130.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isToday
                                    ? [
                                        cs.primary,
                                        cs.primary.withValues(alpha: 0.6),
                                      ]
                                    : isHighest
                                    ? [
                                        Colors.green.shade500,
                                        Colors.green.shade300,
                                      ]
                                    : [
                                        cs.primary.withValues(alpha: 0.5),
                                        cs.primary.withValues(alpha: 0.2),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isHighest
                                  ? [
                                      BoxShadow(
                                        color: Colors.green.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isToday ? cs.primary : cs.onSurfaceVariant,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          : SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 40,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No revenue data this week',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _fmtCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
