import 'package:flutter/material.dart';
import '../../domain/projections/marketing_dashboard_projection.dart';
import 'shared_dash_components.dart';

// ─── KPI Row ───

class MktKpiRow extends StatelessWidget {
  final MarketingDashboardProjection projection;
  const MktKpiRow({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 840;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: isDesktop ? 1.6 : 1.4,
      children: [
        KpiCard(title: 'Total Visits', value: projection.totalVisits.toString(),
          delta: '+12%', deltaPositive: true, icon: Icons.location_on_outlined, color: Colors.blue.shade600),
        KpiCard(title: 'Active Officers', value: projection.activeOfficers.toString(),
          delta: '${projection.visitsByOfficer.length} tracked', deltaPositive: true, icon: Icons.badge_outlined, color: Colors.teal.shade600),
        KpiCard(title: 'Plan Compliance', value: '${(projection.planComplianceRate * 100).round()}%',
          delta: projection.planComplianceRate >= 0.7 ? 'On Track' : 'Below',
          deltaPositive: projection.planComplianceRate >= 0.7, icon: Icons.fact_check_outlined, color: Colors.orange.shade600),
        KpiCard(title: 'Reports Filed', value: projection.dailyReportSubmissionRate.toString(),
          delta: 'this period', deltaPositive: true, icon: Icons.summarize_outlined, color: Colors.purple.shade600),
      ],
    );
  }
}

// ─── Visits Chart ───

class MktVisitsChart extends StatelessWidget {
  final MarketingDashboardProjection projection;
  final String period;
  const MktVisitsChart({super.key, required this.projection, this.period = 'This Week'});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final Map<String, int> visitsByDay = {};
    final labels = <String>[];

    for (var i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d.weekday - 1];
      labels.add(key);
      visitsByDay[key] = 0;
    }
    for (final v in projection.recentVisits) {
      final key = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][v.visitDate.weekday - 1];
      if (visitsByDay.containsKey(key)) visitsByDay[key] = (visitsByDay[key] ?? 0) + 1;
    }
    if (visitsByDay.values.every((v) => v == 0)) {
      final mock = [4, 7, 3, 9, 5, 8, 6];
      for (var i = 0; i < labels.length && i < mock.length; i++) visitsByDay[labels[i]] = mock[i];
    }

    final maxVal = visitsByDay.values.reduce((a, b) => a > b ? a : b);
    final displayMax = maxVal < 1 ? 1 : maxVal;

    return DashCard(
      title: 'Field Visits',
      subtitle: period,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Text('${projection.totalVisits} total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
      ),
      child: SizedBox(height: 180, child: Row(crossAxisAlignment: CrossAxisAlignment.end,
        children: labels.asMap().entries.map((entry) {
          final label = entry.value;
          final count = visitsByDay[label] ?? 0;
          final ratio = count / displayMax;
          final isHighest = count == maxVal && maxVal > 0;
          final isToday = entry.key == labels.length - 1;

          return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (count > 0) Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: isHighest ? cs.primary : cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: Duration(milliseconds: 500 + entry.key * 60), curve: Curves.easeOutCubic,
                height: (ratio * 130).clamp(4.0, 130.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: isToday ? [cs.primary, cs.primary.withValues(alpha: 0.6)]
                      : isHighest ? [Colors.blue.shade500, Colors.blue.shade300]
                      : [cs.primary.withValues(alpha: 0.4), cs.primary.withValues(alpha: 0.15)]),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isHighest ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))] : null)),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                color: isToday ? cs.primary : cs.onSurfaceVariant)),
              if (isToday) Container(margin: const EdgeInsets.only(top: 3), width: 4, height: 4,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary)),
            ])));
        }).toList())),
    );
  }
}

// ─── Compliance Ring ───

class MktComplianceRing extends StatelessWidget {
  final MarketingDashboardProjection projection;
  const MktComplianceRing({super.key, required this.projection});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rate = projection.planComplianceRate;
    final pct = (rate * 100).round();
    final rateColor = rate >= 0.7 ? Colors.green : rate >= 0.4 ? Colors.orange : Colors.red;

    return DashCard(
      title: 'Plan Compliance',
      subtitle: 'Weekly plan approval rate',
      child: Column(children: [
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 130, height: 130, child: CustomPaint(painter: RingPainter(
              value: rate, color: rateColor, backgroundColor: cs.surfaceContainerHighest, strokeWidth: 16))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$pct%', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: rateColor)),
              Text('compliance', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LegendRow(color: Colors.green, label: 'Approved', value: '${pct}%'),
            const SizedBox(height: 8),
            _LegendRow(color: Colors.orange, label: 'Pending', value: '${((1 - rate) * 60).round()}%'),
            const SizedBox(height: 8),
            _LegendRow(color: Colors.red, label: 'Rejected', value: '${((1 - rate) * 40).round()}%'),
            const SizedBox(height: 12),
            // Customers visited
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(Icons.storefront, size: 16, color: cs.primary), const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${projection.customersVisitedThisMonth}/${projection.totalCustomers}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary)),
                  Text('Customers visited', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ])),
              ])),
          ])),
        ]),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color; final String label; final String value;
  const _LegendRow({required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 8), Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
  ]);
}