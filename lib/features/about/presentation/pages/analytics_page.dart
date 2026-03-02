// analytics_page.dart
// Analytics — Super Admin platform-wide intelligence dashboard.
//
// Data sources this page aggregates:
//   tenant_subscriptions  → MRR / ARR / plan breakdown
//   orders                → order volume, GMV trends
//   organizations         → org growth, churn
//   users                 → active users, DAU
//   visits                → field activity
//   payments              → collection rate
//
// Capabilities:
//   - MRR / ARR / GMV headline KPIs with delta vs last period
//   - Revenue trend line chart (12-month)
//   - Org growth area chart (cumulative)
//   - Plan distribution donut
//   - Order volume bar chart (daily, 30 days)
//   - Top orgs by revenue table
//   - Field activity heatmap (visits per day-of-week × hour)
//   - Collection rate gauge
//   - Period selector: 7d / 30d / 90d / 12m
//
// All charts drawn with CustomPainter — zero external dependencies.
// No AppBar. No Drawer. Pure page content.
// Location: features/platform_admin/presentation/pages/analytics_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Period ───────────────────────────────────────────────────────────────────

enum Period { d7, d30, d90, m12 }

// ─── Data models ─────────────────────────────────────────────────────────────

class _DataPoint {
  final String label;
  final double value;
  const _DataPoint(this.label, this.value);
}

class _OrgRow {
  final String name;
  final String plan;
  final double mrr;
  final int orders;
  final double growth;
  final Color color;
  const _OrgRow({
    required this.name,
    required this.plan,
    required this.mrr,
    required this.orders,
    required this.growth,
    required this.color,
  });
}

// ─── Mock data factory ────────────────────────────────────────────────────────

class _MockData {
  // MRR monthly series — Jan 2025 to Feb 2026
  static const List<_DataPoint> mrrMonthly = [
    _DataPoint('J', 450000),
    _DataPoint('F', 450000),
    _DataPoint('M', 600000),
    _DataPoint('A', 600000),
    _DataPoint('M', 750000),
    _DataPoint('J', 750000),
    _DataPoint('J', 900000),
    _DataPoint('A', 900000),
    _DataPoint('S', 1050000),
    _DataPoint('O', 1200000),
    _DataPoint('N', 1200000),
    _DataPoint('D', 1350000),
    _DataPoint('J\'26', 1500000),
    _DataPoint('Feb', 1650000),
  ];

  // Cumulative org count per month
  static const List<_DataPoint> orgGrowth = [
    _DataPoint('J', 1),
    _DataPoint('F', 1),
    _DataPoint('M', 2),
    _DataPoint('A', 3),
    _DataPoint('M', 3),
    _DataPoint('J', 4),
    _DataPoint('J', 5),
    _DataPoint('A', 5),
    _DataPoint('S', 5),
    _DataPoint('O', 6),
    _DataPoint('N', 6),
    _DataPoint('D', 6),
    _DataPoint('J\'26', 7),
    _DataPoint('Feb', 7),
  ];

  // Daily order volume — last 30 days
  static List<_DataPoint> orderVolume30d = List.generate(30, (i) {
    final day = 30 - i;
    // Add weekly pattern + growth trend
    final base = 18.0 + (day * 0.6);
    final weekdayFactor = (day % 7 < 5) ? 1.0 : 0.4;
    final noise = (math.sin(day * 1.7) * 5 + math.cos(day * 0.9) * 3);
    return _DataPoint('${day}d', math.max(0, (base * weekdayFactor + noise)));
  }).reversed.toList();

  // Top orgs
  static const List<_OrgRow> topOrgs = [
    _OrgRow(
      name: 'Bariki Pharmaceuticals',
      plan: 'Professional',
      mrr: 450000,
      orders: 142,
      growth: 18.4,
      color: Colors.indigo,
    ),
    _OrgRow(
      name: 'Uyole Health Supplies',
      plan: 'Professional',
      mrr: 450000,
      orders: 98,
      growth: 12.1,
      color: Colors.teal,
    ),
    _OrgRow(
      name: 'Swift Med Logistics',
      plan: 'Starter',
      mrr: 150000,
      orders: 211,
      growth: 34.7,
      color: Colors.orange,
    ),
    _OrgRow(
      name: 'Mwanjelwa Pharmacy',
      plan: 'Starter',
      mrr: 150000,
      orders: 67,
      growth: 5.2,
      color: Colors.green,
    ),
    _OrgRow(
      name: 'Kariakoo MedStore',
      plan: 'Starter',
      mrr: 150000,
      orders: 44,
      growth: -2.1,
      color: Colors.blue,
    ),
    _OrgRow(
      name: 'Tanzapharm Manufacturers',
      plan: 'Starter',
      mrr: 150000,
      orders: 8,
      growth: 0.0,
      color: Colors.purple,
    ),
    _OrgRow(
      name: 'Njombe District Pharmacy',
      plan: 'Starter',
      mrr: 0,
      orders: 0,
      growth: -100.0,
      color: Colors.red,
    ),
  ];

  // Visit heatmap: [hour][dayOfWeek] = count
  static List<List<int>> visitHeatmap = List.generate(12, (hour) {
    // Hours 7am–6pm
    return List.generate(7, (day) {
      if (day >= 5)
        return (math.Random(hour * 7 + day).nextInt(3)); // weekend low
      final peak = (hour >= 2 && hour <= 5) ? 1.8 : 1.0; // 9am-12pm peak
      final base = (hour >= 8 && hour <= 9) ? 3 : 1;
      return math.min(
        20,
        (math.Random(hour * 7 + day + 42).nextInt(15) * peak).round() + base,
      );
    });
  });

  // Plan breakdown (count of orgs)
  static const Map<String, int> planBreakdown = {
    'Starter': 5,
    'Professional': 2,
    'Enterprise': 0,
  };

  // Collection rate breakdown
  static const double collectionRate = 78.4;
  static const double overdueRate = 14.2;
  static const double writtenOffRate = 7.4;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  Period _period = Period.m12;
  late final AnimationController _animCtrl;
  late final Animation<double> _anim;
  int? _hoveredOrgIndex;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _setPeriod(Period p) {
    setState(() => _period = p);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildPeriodSelector(context)),
          SliverToBoxAdapter(child: _buildHeadlineKpis(context)),
          SliverToBoxAdapter(child: _buildRevenueChart(context)),
          SliverToBoxAdapter(child: _buildOrgGrowthAndPlanRow(context)),
          SliverToBoxAdapter(child: _buildOrderVolumeChart(context)),
          SliverToBoxAdapter(child: _buildTopOrgsTable(context)),
          SliverToBoxAdapter(child: _buildBottomRow(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 12,
                            color: Colors.purple.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'PLATFORM INTELLIGENCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.purple.shade700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Analytics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Revenue, growth & activity across all organizations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            onPressed: () => _showSnack(context, 'Exporting analytics report…'),
            icon: const Icon(Icons.download_outlined, size: 20),
            tooltip: 'Export Report',
          ),
        ],
      ),
    );
  }

  // ── Period selector ────────────────────────────────────────────────────────

  Widget _buildPeriodSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final opts = [
      (Period.d7, '7D'),
      (Period.d30, '30D'),
      (Period.d90, '90D'),
      (Period.m12, '12M'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: opts.map((o) {
            final (period, label) = o;
            final sel = _period == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => _setPeriod(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: sel
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Headline KPIs ──────────────────────────────────────────────────────────

  Widget _buildHeadlineKpis(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _KpiTile(
                label: 'MRR',
                value: 'TZS 1.65M',
                delta: '+10.0%',
                positive: true,
                sublabel: 'vs last month',
                icon: Icons.trending_up_rounded,
                color: Colors.green,
                anim: _anim,
              ),
              const SizedBox(width: 10),
              _KpiTile(
                label: 'ARR',
                value: 'TZS 19.8M',
                delta: '+35.3%',
                positive: true,
                sublabel: 'annualised',
                icon: Icons.calendar_month_outlined,
                color: Colors.blue,
                anim: _anim,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _KpiTile(
                label: 'GMV (30d)',
                value: 'TZS 68.4M',
                delta: '+22.7%',
                positive: true,
                sublabel: 'gross merch. value',
                icon: Icons.shopping_cart_outlined,
                color: Colors.teal,
                anim: _anim,
              ),
              const SizedBox(width: 10),
              _KpiTile(
                label: 'Active Orgs',
                value: '6 / 7',
                delta: '1 suspended',
                positive: false,
                sublabel: 'paying customers',
                icon: Icons.domain_outlined,
                color: Colors.indigo,
                anim: _anim,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _KpiTile(
                label: 'Platform Users',
                value: '23',
                delta: '+3 (30d)',
                positive: true,
                sublabel: 'across all orgs',
                icon: Icons.group_outlined,
                color: Colors.purple,
                anim: _anim,
              ),
              const SizedBox(width: 10),
              _KpiTile(
                label: 'Orders (30d)',
                value: '570',
                delta: '+18.1%',
                positive: true,
                sublabel: 'processed orders',
                icon: Icons.receipt_long_outlined,
                color: Colors.orange,
                anim: _anim,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Revenue trend chart ────────────────────────────────────────────────────

  Widget _buildRevenueChart(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SectionCard(
      title: 'Monthly Recurring Revenue',
      subtitle: 'MRR trend — Jan 2025 to Feb 2026',
      icon: Icons.show_chart_rounded,
      iconColor: Colors.green,
      action: _ChartLegend(
        items: const [('MRR', Colors.green), ('Target', Colors.blue)],
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _LineChartPainter(
              data: _MockData.mrrMonthly,
              color: Colors.green,
              targetColor: Colors.blue,
              targetValue: 1200000,
              progress: _anim.value,
              colorScheme: colorScheme,
              showArea: true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  // ── Org growth + plan donut row ────────────────────────────────────────────

  Widget _buildOrgGrowthAndPlanRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Org growth
          Expanded(
            flex: 3,
            child: _SectionCard(
              title: 'Org Growth',
              subtitle: 'Cumulative orgs',
              icon: Icons.domain_add_outlined,
              iconColor: Colors.indigo,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => SizedBox(
                  height: 130,
                  child: CustomPaint(
                    painter: _AreaChartPainter(
                      data: _MockData.orgGrowth,
                      color: Colors.indigo,
                      progress: _anim.value,
                      colorScheme: colorScheme,
                      maxY: 10,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Plan donut
          Expanded(
            flex: 2,
            child: _SectionCard(
              title: 'Plan Mix',
              subtitle:
                  '${_MockData.planBreakdown.values.fold(0, (a, b) => a + b)} orgs',
              icon: Icons.pie_chart_outline_rounded,
              iconColor: Colors.purple,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => SizedBox(
                      height: 90,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          data: {
                            'Starter': (5, Colors.teal),
                            'Pro': (2, Colors.indigo),
                            'Ent': (0, Colors.purple),
                          },
                          progress: _anim.value,
                          colorScheme: colorScheme,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _DonutLegend(
                    items: const [
                      ('Starter', Colors.teal, 5),
                      ('Pro', Colors.indigo, 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Order volume bar chart ─────────────────────────────────────────────────

  Widget _buildOrderVolumeChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      title: 'Order Volume',
      subtitle: 'Daily orders — last 30 days',
      icon: Icons.bar_chart_rounded,
      iconColor: Colors.orange,
      action: _ChartLegend(
        items: const [('Orders', Colors.orange), ('Weekends', Colors.grey)],
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _BarChartPainter(
              data: _MockData.orderVolume30d,
              color: Colors.orange,
              weekendColor: Colors.grey.shade300,
              progress: _anim.value,
              colorScheme: colorScheme,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  // ── Top orgs table ─────────────────────────────────────────────────────────

  Widget _buildTopOrgsTable(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SectionCard(
      title: 'Organizations by Revenue',
      subtitle: 'MRR · Order volume · Growth',
      icon: Icons.leaderboard_outlined,
      iconColor: Colors.indigo,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Organization',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'MRR',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Orders',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    'Growth',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._MockData.topOrgs.asMap().entries.map((entry) {
            final i = entry.key;
            final org = entry.value;
            final isSuspended = org.mrr == 0;
            return _OrgTableRow(
              rank: i + 1,
              org: org,
              isSuspended: isSuspended,
              isHovered: _hoveredOrgIndex == i,
              onHover: (h) => setState(() => _hoveredOrgIndex = h ? i : null),
              animate: _anim,
            );
          }),
        ],
      ),
    );
  }

  // ── Bottom row: heatmap + collection gauge ────────────────────────────────

  Widget _buildBottomRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visit heatmap
          Expanded(
            flex: 3,
            child: _SectionCard(
              title: 'Visit Activity',
              subtitle: 'Field visits by hour × weekday',
              icon: Icons.grid_on_rounded,
              iconColor: Colors.teal,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: _VisitHeatmap(data: _MockData.visitHeatmap, anim: _anim),
            ),
          ),
          const SizedBox(width: 10),
          // Collection rate
          Expanded(
            flex: 2,
            child: _SectionCard(
              title: 'Collections',
              subtitle: 'Payment status breakdown',
              icon: Icons.payments_outlined,
              iconColor: Colors.green,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => SizedBox(
                      height: 100,
                      child: CustomPaint(
                        painter: _GaugePainter(
                          value: _MockData.collectionRate,
                          progress: _anim.value,
                          colorScheme: colorScheme,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _GaugeLegend(
                    collected: _MockData.collectionRate,
                    overdue: _MockData.overdueRate,
                    writtenOff: _MockData.writtenOffRate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── KPI Tile ─────────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final String label, value, delta, sublabel;
  final bool positive;
  final IconData icon;
  final Color color;
  final Animation<double> anim;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dColor = positive ? Colors.green : Colors.red;

    return Expanded(
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) => Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - anim.value)),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: dColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              positive
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 10,
                              color: dColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              delta,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: dColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? action;
  final EdgeInsets padding;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Chart Legend ──────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  final List<(String, Color)> items;
  const _ChartLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        final (label, color) = item;
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Line Chart Painter ───────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<_DataPoint> data;
  final Color color;
  final Color targetColor;
  final double targetValue;
  final double progress;
  final ColorScheme colorScheme;
  final bool showArea;

  _LineChartPainter({
    required this.data,
    required this.color,
    required this.targetColor,
    required this.targetValue,
    required this.progress,
    required this.colorScheme,
    required this.showArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxY = data.map((d) => d.value).reduce(math.max) * 1.2;
    final minY = 0.0;
    final padLeft = 44.0;
    final padBottom = 24.0;
    final padTop = 10.0;
    final padRight = 10.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padBottom - padTop;

    double xOf(int i) => padLeft + (i / (data.length - 1)) * chartW;
    double yOf(double v) =>
        padTop + chartH - ((v - minY) / (maxY - minY)) * chartH;

    // Grid lines
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    const gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final y = padTop + (chartH / gridLines) * i;
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        gridPaint,
      );
      final val = maxY - (maxY / gridLines) * i;
      _drawText(
        canvas,
        _fmtVal(val),
        Offset(0, y - 6),
        9,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        size: padLeft - 4,
      );
    }

    // Target line
    final ty = yOf(targetValue);
    final targetPaint = Paint()
      ..color = targetColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dashPath = Path();
    double x = padLeft;
    bool dash = true;
    while (x < size.width - padRight) {
      if (dash) {
        dashPath.moveTo(x, ty);
        dashPath.lineTo(math.min(x + 12, size.width - padRight), ty);
      }
      x += dash ? 12 : 6;
      dash = !dash;
    }
    canvas.drawPath(dashPath, targetPaint);

    // Points up to progress
    final visibleCount = math.max(2, (data.length * progress).round());
    final visData = data.sublist(0, visibleCount);

    // Area fill
    if (showArea && visData.length > 1) {
      final areaPath = Path();
      areaPath.moveTo(xOf(0), yOf(visData[0].value));
      for (int i = 1; i < visData.length; i++) {
        final cpx = (xOf(i - 1) + xOf(i)) / 2;
        areaPath.cubicTo(
          cpx,
          yOf(visData[i - 1].value),
          cpx,
          yOf(visData[i].value),
          xOf(i),
          yOf(visData[i].value),
        );
      }
      areaPath.lineTo(xOf(visData.length - 1), padTop + chartH);
      areaPath.lineTo(padLeft, padTop + chartH);
      areaPath.close();

      final areaGrad = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, padTop, size.width, chartH));
      canvas.drawPath(areaPath, areaGrad);
    }

    // Line
    if (visData.length > 1) {
      final linePath = Path();
      linePath.moveTo(xOf(0), yOf(visData[0].value));
      for (int i = 1; i < visData.length; i++) {
        final cpx = (xOf(i - 1) + xOf(i)) / 2;
        linePath.cubicTo(
          cpx,
          yOf(visData[i - 1].value),
          cpx,
          yOf(visData[i].value),
          xOf(i),
          yOf(visData[i].value),
        );
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Data points + labels
    for (int i = 0; i < data.length; i++) {
      final px = xOf(i);
      final py = yOf(data[i].value);
      final isVisible = i < visData.length;
      // X labels
      _drawText(
        canvas,
        data[i].label,
        Offset(px - 8, size.height - 16),
        9,
        colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      );
      if (!isVisible) continue;
      // Dot
      canvas.drawCircle(
        Offset(px, py),
        3.5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(px, py),
        3.5,
        Paint()
          ..color = colorScheme.surfaceContainerLowest
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  String _fmtVal(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    double fontSize,
    Color color, {
    double size = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.progress != progress || old.data != data;
}

// ─── Area Chart Painter ───────────────────────────────────────────────────────

class _AreaChartPainter extends CustomPainter {
  final List<_DataPoint> data;
  final Color color;
  final double progress;
  final ColorScheme colorScheme;
  final double maxY;

  _AreaChartPainter({
    required this.data,
    required this.color,
    required this.progress,
    required this.colorScheme,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    const padLeft = 24.0;
    const padBottom = 20.0;
    const padTop = 6.0;
    const padRight = 6.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padBottom - padTop;

    double xOf(int i) => padLeft + (i / (data.length - 1)) * chartW;
    double yOf(double v) => padTop + chartH - (v / maxY) * chartH;

    final visibleCount = math.max(2, (data.length * progress).round());
    final visData = data.sublist(0, visibleCount);

    // Grid
    for (int i = 0; i <= 2; i++) {
      final y = padTop + (chartH / 2) * i;
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
    }

    // Area
    if (visData.length > 1) {
      final areaPath = Path();
      areaPath.moveTo(xOf(0), yOf(visData[0].value));
      for (int i = 1; i < visData.length; i++) {
        final cpx = (xOf(i - 1) + xOf(i)) / 2;
        areaPath.cubicTo(
          cpx,
          yOf(visData[i - 1].value),
          cpx,
          yOf(visData[i].value),
          xOf(i),
          yOf(visData[i].value),
        );
      }
      areaPath.lineTo(xOf(visData.length - 1), padTop + chartH);
      areaPath.lineTo(padLeft, padTop + chartH);
      areaPath.close();

      canvas.drawPath(
        areaPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.03),
            ],
          ).createShader(Rect.fromLTWH(0, padTop, size.width, chartH)),
      );

      // Line
      final linePath = Path();
      linePath.moveTo(xOf(0), yOf(visData[0].value));
      for (int i = 1; i < visData.length; i++) {
        final cpx = (xOf(i - 1) + xOf(i)) / 2;
        linePath.cubicTo(
          cpx,
          yOf(visData[i - 1].value),
          cpx,
          yOf(visData[i].value),
          xOf(i),
          yOf(visData[i].value),
        );
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      // Current value label
      final last = visData.last;
      final lx = xOf(visData.length - 1);
      final ly = yOf(last.value);
      canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = color);
    }

    // X labels — show every 3
    for (int i = 0; i < data.length; i += 3) {
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: TextStyle(
            fontSize: 8,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xOf(i) - 6, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) => old.progress != progress;
}

// ─── Bar Chart Painter ────────────────────────────────────────────────────────

class _BarChartPainter extends CustomPainter {
  final List<_DataPoint> data;
  final Color color;
  final Color weekendColor;
  final double progress;
  final ColorScheme colorScheme;

  _BarChartPainter({
    required this.data,
    required this.color,
    required this.weekendColor,
    required this.progress,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxY = data.map((d) => d.value).reduce(math.max) * 1.15;
    const padLeft = 28.0;
    const padBottom = 16.0;
    const padTop = 8.0;
    const padRight = 4.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padBottom - padTop;
    final barW = (chartW / data.length) - 2;

    // Grid
    for (int i = 0; i <= 3; i++) {
      final y = padTop + (chartH / 3) * i;
      canvas.drawLine(
        Offset(padLeft, y),
        Offset(size.width - padRight, y),
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.25)
          ..strokeWidth = 1,
      );
      if (i < 3) {
        final val = maxY - (maxY / 3) * i;
        final tp = TextPainter(
          text: TextSpan(
            text: val.round().toString(),
            style: TextStyle(
              fontSize: 8,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, y - 5));
      }
    }

    // Bars
    for (int i = 0; i < data.length; i++) {
      final isWeekend = (i % 7 >= 5);
      final barH = (data[i].value / maxY) * chartH * progress;
      final x = padLeft + (chartW / data.length) * i + 1;
      final y = padTop + chartH - barH;

      final rRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barW, barH),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(
        rRect,
        Paint()
          ..color = isWeekend
              ? weekendColor.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.75),
      );
    }

    // Week markers every 7
    for (int i = 0; i < data.length; i += 7) {
      final x = padLeft + (chartW / data.length) * i;
      canvas.drawLine(
        Offset(x, padTop),
        Offset(x, padTop + chartH),
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.4)
          ..strokeWidth = 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => old.progress != progress;
}

// ─── Donut Painter ───────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final Map<String, (int, Color)> data;
  final double progress;
  final ColorScheme colorScheme;

  _DonutPainter({
    required this.data,
    required this.progress,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (a, b) => a + b.$1);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeW = 22.0;

    double startAngle = -math.pi / 2;
    final totalSweep = 2 * math.pi * progress;

    for (final entry in data.entries) {
      final (count, color) = entry.value;
      if (count == 0) continue;
      final sweep = (count / total) * totalSweep;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeW
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$total\n',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'orgs',
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.progress != progress;
}

class _DonutLegend extends StatelessWidget {
  final List<(String, Color, int)> items;
  const _DonutLegend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final (label, color, count) = item;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Gauge Painter ────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  final double value;
  final double progress;
  final ColorScheme colorScheme;

  _GaugePainter({
    required this.value,
    required this.progress,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = math.min(size.width, size.height * 1.4) / 2 - 8;
    const strokeW = 16.0;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = colorScheme.surfaceContainerLow
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Overdue arc
    final overdueSweep = (14.2 / 100) * sweepAngle;
    final overdueStart = startAngle + (value / 100) * sweepAngle * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      overdueStart,
      overdueSweep * progress,
      false,
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.7)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Collected arc
    final collectedSweep = (value / 100) * sweepAngle * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      collectedSweep,
      false,
      Paint()
        ..color = Colors.green
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Center value
    final valTp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${(value * progress).toStringAsFixed(0)}%\n',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.green.shade700,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: 'collected',
            style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    valTp.paint(canvas, center - Offset(valTp.width / 2, valTp.height / 2));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

class _GaugeLegend extends StatelessWidget {
  final double collected, overdue, writtenOff;
  const _GaugeLegend({
    required this.collected,
    required this.overdue,
    required this.writtenOff,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GLItem('${collected.toStringAsFixed(1)}%', 'Collected', Colors.green),
        const SizedBox(width: 12),
        _GLItem('${overdue.toStringAsFixed(1)}%', 'Overdue', Colors.orange),
        const SizedBox(width: 12),
        _GLItem(
          '${writtenOff.toStringAsFixed(1)}%',
          'Written off',
          Colors.red.shade300,
        ),
      ],
    );
  }
}

class _GLItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _GLItem(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Visit Heatmap ────────────────────────────────────────────────────────────

class _VisitHeatmap extends StatelessWidget {
  final List<List<int>> data;
  final Animation<double> anim;

  const _VisitHeatmap({required this.data, required this.anim});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final hours = List.generate(12, (i) => '${i + 7}h');
    final maxVal = data.expand((r) => r).reduce(math.max).toDouble();

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: days
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Grid rows
          ...data.asMap().entries.map((rowEntry) {
            final rowI = rowEntry.key;
            final row = rowEntry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      hours[rowI],
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                  ...row.asMap().entries.map((cellEntry) {
                    final v = cellEntry.value;
                    final intensity = maxVal > 0
                        ? (v / maxVal) * anim.value
                        : 0.0;
                    final isWeekend = cellEntry.key >= 5;
                    return Expanded(
                      child: Container(
                        height: 14,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: isWeekend
                              ? Colors.grey.withValues(alpha: intensity * 0.5)
                              : Colors.teal.withValues(
                                  alpha: 0.08 + intensity * 0.82,
                                ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          // Intensity legend
          Row(
            children: [
              const SizedBox(width: 22),
              Text(
                'Low',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(
                5,
                (i) => Container(
                  width: 14,
                  height: 8,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1 + i * 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'High',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Org Table Row ────────────────────────────────────────────────────────────

class _OrgTableRow extends StatelessWidget {
  final int rank;
  final _OrgRow org;
  final bool isSuspended;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final Animation<double> animate;

  const _OrgTableRow({
    required this.rank,
    required this.org,
    required this.isSuspended,
    required this.isHovered,
    required this.onHover,
    required this.animate,
  });

  String _fmtTzs(double v) {
    if (v >= 1000000) return 'TZS ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return 'TZS ${(v / 1000).toStringAsFixed(0)}K';
    return 'TZS ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final growthColor = org.growth > 0
        ? Colors.green
        : org.growth < 0
        ? Colors.red
        : colorScheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: animate,
      builder: (_, child) => Opacity(
        opacity: animate.value,
        child: Transform.translate(
          offset: Offset(8 * (1 - animate.value), 0),
          child: child,
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: isHovered
              ? colorScheme.surfaceContainerLow
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 24,
                  child: rank == 1
                      ? const Text('🥇', style: TextStyle(fontSize: 14))
                      : rank == 2
                      ? const Text('🥈', style: TextStyle(fontSize: 14))
                      : rank == 3
                      ? const Text('🥉', style: TextStyle(fontSize: 14))
                      : Text(
                          '$rank',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                const SizedBox(width: 8),

                // Org name + plan
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 28,
                        decoration: BoxDecoration(
                          color: org.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSuspended
                                    ? colorScheme.onSurface.withValues(
                                        alpha: 0.4,
                                      )
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _planColor(
                                      org.plan,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    org.plan,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _planColor(org.plan),
                                    ),
                                  ),
                                ),
                                if (isSuspended) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Suspended',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // MRR
                SizedBox(
                  width: 80,
                  child: Text(
                    isSuspended ? '—' : _fmtTzs(org.mrr),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSuspended ? colorScheme.onSurfaceVariant : null,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                // Orders
                SizedBox(
                  width: 50,
                  child: Text(
                    '${org.orders}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),

                // Growth
                SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (org.growth != 0)
                        Icon(
                          org.growth > 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 10,
                          color: growthColor,
                        ),
                      const SizedBox(width: 2),
                      Text(
                        org.growth == 0
                            ? '—'
                            : org.growth == -100
                            ? 'Churned'
                            : '${org.growth.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: growthColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _planColor(String plan) => switch (plan) {
    'Professional' => Colors.indigo,
    'Enterprise' => Colors.amber.shade700,
    _ => Colors.teal,
  };
}
