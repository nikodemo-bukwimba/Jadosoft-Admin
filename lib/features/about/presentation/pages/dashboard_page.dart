import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD PAGE
// Super Admin — Pharma SaaS Platform
// Depends on: fl_chart (add to pubspec.yaml)
// ─────────────────────────────────────────────────────────────────────────────

// ── Design tokens ─────────────────────────────────────────────────────────────
const _cPrimary = Color(0xFF1A237E);
const _cPrimaryMid = Color(0xFF3949AB);
const _cPrimaryLight = Color(0xFFE8EAF6);
const _cAccent = Color(0xFF00BCD4);
const _cAccentLight = Color(0xFFE0F7FA);
const _cSuccess = Color(0xFF2E7D32);
const _cSuccessLight = Color(0xFFE8F5E9);
const _cWarning = Color(0xFFF57F17);
const _cWarningLight = Color(0xFFFFF3E0);
const _cError = Color(0xFFC62828);
const _cErrorLight = Color(0xFFFFEBEE);
const _cInfo = Color(0xFF0277BD);
const _cInfoLight = Color(0xFFE1F5FE);
const _cSurface = Color(0xFFF4F6FA);
const _cCard = Colors.white;
const _cTextPrimary = Color(0xFF1A1A2E);
const _cTextSecondary = Color(0xFF6B7280);
const _cBorder = Color(0xFFE5E7EB);

// ── Helpers ──────────────────────────────────────────────────────────────────
BoxDecoration _card({double radius = 12, Color? color}) => BoxDecoration(
  color: color ?? _cCard,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _cBorder, width: 1),
  boxShadow: const [
    BoxShadow(color: Color(0x07000000), blurRadius: 8, offset: Offset(0, 2)),
  ],
);

TextStyle _label(BuildContext ctx) =>
    Theme.of(ctx).textTheme.labelSmall!.copyWith(
      color: _cTextSecondary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

class _StatData {
  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  const _StatData({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class _OrgRow {
  final String name;
  final List<String> types;
  final String territory;
  final String plan;
  final String status;
  final int users;
  final String lastActive;
  const _OrgRow({
    required this.name,
    required this.types,
    required this.territory,
    required this.plan,
    required this.status,
    required this.users,
    required this.lastActive,
  });
}

class _AuditEntry {
  final IconData icon;
  final Color iconColor;
  final String event;
  final String actor;
  final String org;
  final String time;
  const _AuditEntry({
    required this.icon,
    required this.iconColor,
    required this.event,
    required this.actor,
    required this.org,
    required this.time,
  });
}

class _HealthItem {
  final String service;
  final String status; // 'ok' | 'degraded' | 'down'
  final String latency;
  final IconData icon;
  const _HealthItem({
    required this.service,
    required this.status,
    required this.latency,
    required this.icon,
  });
}

class _JobItem {
  final String name;
  final String schedule;
  final String lastRun;
  final String nextRun;
  final String result; // 'success' | 'running' | 'failed' | 'pending'
  const _JobItem({
    required this.name,
    required this.schedule,
    required this.lastRun,
    required this.nextRun,
    required this.result,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

const _stats = [
  _StatData(
    label: 'Total Organizations',
    value: '47',
    delta: '+3 this month',
    deltaPositive: true,
    icon: Icons.business_rounded,
    iconColor: _cPrimary,
    iconBg: _cPrimaryLight,
  ),
  _StatData(
    label: 'Active Users',
    value: '1,284',
    delta: '+127 this month',
    deltaPositive: true,
    icon: Icons.people_alt_rounded,
    iconColor: _cAccent,
    iconBg: _cAccentLight,
  ),
  _StatData(
    label: 'Monthly Revenue',
    value: 'TZS 12.4M',
    delta: '+18% vs last month',
    deltaPositive: true,
    icon: Icons.account_balance_wallet_rounded,
    iconColor: _cSuccess,
    iconBg: _cSuccessLight,
  ),
  _StatData(
    label: 'Orders Today',
    value: '342',
    delta: '+56 vs yesterday',
    deltaPositive: true,
    icon: Icons.receipt_long_rounded,
    iconColor: _cInfo,
    iconBg: _cInfoLight,
  ),
  _StatData(
    label: 'Pending Alerts',
    value: '3',
    delta: '2 critical, 1 warning',
    deltaPositive: false,
    icon: Icons.notifications_active_rounded,
    iconColor: _cError,
    iconBg: _cErrorLight,
  ),
  _StatData(
    label: 'Queue Jobs',
    value: '1,247',
    delta: '8 failed — needs review',
    deltaPositive: false,
    icon: Icons.queue_rounded,
    iconColor: _cWarning,
    iconBg: _cWarningLight,
  ),
];

const _recentOrgs = [
  _OrgRow(
    name: 'Bariki Pharma Ltd',
    types: ['distributor', 'pharmacy'],
    territory: 'Mbeya District',
    plan: 'Enterprise',
    status: 'active',
    users: 34,
    lastActive: '2 mins ago',
  ),
  _OrgRow(
    name: 'MedPlus Pharmacy Dar',
    types: ['pharmacy'],
    territory: 'Dar es Salaam',
    plan: 'Professional',
    status: 'active',
    users: 8,
    lastActive: '14 mins ago',
  ),
  _OrgRow(
    name: 'Coastal Distributors',
    types: ['distributor', 'supplier'],
    territory: 'Coast Region',
    plan: 'Professional',
    status: 'active',
    users: 19,
    lastActive: '1 hour ago',
  ),
  _OrgRow(
    name: 'Kilimanjaro MedHub',
    types: ['pharmacy'],
    territory: 'Kilimanjaro',
    plan: 'Starter',
    status: 'trialing',
    users: 3,
    lastActive: '3 hours ago',
  ),
  _OrgRow(
    name: 'Arusha Health Chain',
    types: ['pharmacy', 'distributor'],
    territory: 'Arusha District',
    plan: 'Enterprise',
    status: 'active',
    users: 27,
    lastActive: '5 hours ago',
  ),
  _OrgRow(
    name: 'Dodoma Central Pharm',
    types: ['pharmacy'],
    territory: 'Dodoma Region',
    plan: 'Starter',
    status: 'suspended',
    users: 4,
    lastActive: '2 days ago',
  ),
];

const _auditEntries = [
  _AuditEntry(
    icon: Icons.person_add_rounded,
    iconColor: _cSuccess,
    event: 'New user created',
    actor: 'admin@bariki.co.tz',
    org: 'Bariki Pharma Ltd',
    time: '3 mins ago',
  ),
  _AuditEntry(
    icon: Icons.receipt_long_rounded,
    iconColor: _cInfo,
    event: 'Order #ORD-2026-00342 approved',
    actor: 'supervisor@bariki.co.tz',
    org: 'Bariki Pharma Ltd',
    time: '7 mins ago',
  ),
  _AuditEntry(
    icon: Icons.block_rounded,
    iconColor: _cError,
    event: 'Organization suspended',
    actor: 'superadmin@pharmaos.tz',
    org: 'Dodoma Central Pharm',
    time: '2 hours ago',
  ),
  _AuditEntry(
    icon: Icons.price_change_rounded,
    iconColor: _cWarning,
    event: 'Pricing tier updated (Gold → Platinum)',
    actor: 'admin@coastal.co.tz',
    org: 'Coastal Distributors',
    time: '3 hours ago',
  ),
  _AuditEntry(
    icon: Icons.inventory_2_rounded,
    iconColor: _cPrimaryMid,
    event: 'New stock batch received (500 units)',
    actor: 'warehouse@bariki.co.tz',
    org: 'Bariki Pharma Ltd',
    time: '4 hours ago',
  ),
  _AuditEntry(
    icon: Icons.business_rounded,
    iconColor: _cAccent,
    event: 'New organization onboarded',
    actor: 'superadmin@pharmaos.tz',
    org: 'MedPlus Pharmacy Dar',
    time: '5 hours ago',
  ),
  _AuditEntry(
    icon: Icons.monetization_on_rounded,
    iconColor: _cSuccess,
    event: 'Payment confirmed TZS 450,000',
    actor: 'finance@arusha.co.tz',
    org: 'Arusha Health Chain',
    time: '6 hours ago',
  ),
];

const _healthItems = [
  _HealthItem(
    service: 'PostgreSQL Database',
    status: 'ok',
    latency: '4 ms',
    icon: Icons.storage_rounded,
  ),
  _HealthItem(
    service: 'Redis Cache & Queue',
    status: 'ok',
    latency: '1 ms',
    icon: Icons.speed_rounded,
  ),
  _HealthItem(
    service: 'WhatsApp Business API',
    status: 'degraded',
    latency: '2,840 ms',
    icon: Icons.chat_rounded,
  ),
  _HealthItem(
    service: 'M-Pesa Daraja API',
    status: 'ok',
    latency: '312 ms',
    icon: Icons.phone_android_rounded,
  ),
  _HealthItem(
    service: 'Airtel Money API',
    status: 'ok',
    latency: '287 ms',
    icon: Icons.phone_android_rounded,
  ),
  _HealthItem(
    service: 'Firebase Cloud Messaging',
    status: 'ok',
    latency: '89 ms',
    icon: Icons.notifications_rounded,
  ),
  _HealthItem(
    service: 'Cloudflare R2 Storage',
    status: 'ok',
    latency: '56 ms',
    icon: Icons.cloud_rounded,
  ),
  _HealthItem(
    service: 'Laravel Horizon (Queue)',
    status: 'ok',
    latency: '3 workers',
    icon: Icons.tune_rounded,
  ),
];

const _scheduledJobs = [
  _JobItem(
    name: 'ScanExpiryAlerts',
    schedule: 'Daily 06:00',
    lastRun: 'Today 06:00',
    nextRun: 'Tomorrow 06:00',
    result: 'success',
  ),
  _JobItem(
    name: 'CheckStockLevels',
    schedule: 'Daily 06:30',
    lastRun: 'Today 06:30',
    nextRun: 'Tomorrow 06:30',
    result: 'success',
  ),
  _JobItem(
    name: 'ReconcilePayments',
    schedule: 'Daily 08:00',
    lastRun: 'Today 08:00',
    nextRun: 'Tomorrow 08:00',
    result: 'failed',
  ),
  _JobItem(
    name: 'FlagOverdueInvoices',
    schedule: 'Daily 09:00',
    lastRun: 'Today 09:00',
    nextRun: 'Tomorrow 09:00',
    result: 'success',
  ),
  _JobItem(
    name: 'GenerateOfficerReports',
    schedule: 'Weekly Mon 07:00',
    lastRun: 'Mon 24 Feb',
    nextRun: 'Mon 03 Mar',
    result: 'success',
  ),
  _JobItem(
    name: 'CleanExpiredTokens',
    schedule: 'Daily 02:00',
    lastRun: 'Today 02:00',
    nextRun: 'Tomorrow 02:00',
    result: 'success',
  ),
  _JobItem(
    name: 'BackupDatabase',
    schedule: 'Daily 01:00',
    lastRun: 'Today 01:00',
    nextRun: 'Tomorrow 01:00',
    result: 'running',
  ),
];

// Chart data — 30 days of active org counts
final _chartData = [
  const FlSpot(1, 28),
  const FlSpot(2, 28),
  const FlSpot(3, 29),
  const FlSpot(4, 29),
  const FlSpot(5, 30),
  const FlSpot(6, 31),
  const FlSpot(7, 30),
  const FlSpot(8, 31),
  const FlSpot(9, 32),
  const FlSpot(10, 33),
  const FlSpot(11, 33),
  const FlSpot(12, 34),
  const FlSpot(13, 35),
  const FlSpot(14, 34),
  const FlSpot(15, 36),
  const FlSpot(16, 37),
  const FlSpot(17, 37),
  const FlSpot(18, 38),
  const FlSpot(19, 39),
  const FlSpot(20, 40),
  const FlSpot(21, 40),
  const FlSpot(22, 41),
  const FlSpot(23, 42),
  const FlSpot(24, 43),
  const FlSpot(25, 43),
  const FlSpot(26, 44),
  const FlSpot(27, 45),
  const FlSpot(28, 46),
  const FlSpot(29, 46),
  const FlSpot(30, 47),
];

final _chartDataOrders = [
  const FlSpot(1, 180),
  const FlSpot(2, 210),
  const FlSpot(3, 195),
  const FlSpot(4, 230),
  const FlSpot(5, 260),
  const FlSpot(6, 245),
  const FlSpot(7, 220),
  const FlSpot(8, 280),
  const FlSpot(9, 310),
  const FlSpot(10, 295),
  const FlSpot(11, 330),
  const FlSpot(12, 350),
  const FlSpot(13, 320),
  const FlSpot(14, 345),
  const FlSpot(15, 370),
  const FlSpot(16, 360),
  const FlSpot(17, 390),
  const FlSpot(18, 410),
  const FlSpot(19, 395),
  const FlSpot(20, 420),
  const FlSpot(21, 380),
  const FlSpot(22, 430),
  const FlSpot(23, 445),
  const FlSpot(24, 460),
  const FlSpot(25, 440),
  const FlSpot(26, 470),
  const FlSpot(27, 490),
  const FlSpot(28, 510),
  const FlSpot(29, 498),
  const FlSpot(30, 342),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _DashboardHeader(),
            SizedBox(height: 16),
            _SystemAlertBanner(),
            SizedBox(height: 28),
            _StatsGrid(),
            SizedBox(height: 28),
            _ChartsRow(),
            SizedBox(height: 28),
            _OrgsAndAuditRow(),
            SizedBox(height: 28),
            _QueueAndJobsRow(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          // ✅ ADD THIS
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _cAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Platform Dashboard',
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _cTextPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  'Saturday, 28 February 2026  ·  East Africa SaaS Platform  ·  All tenants',
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                ),
              ),
            ],
          ),
        ), // ✅ END OF Expanded
        const SizedBox(width: 24),
        // Platform status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _cSuccessLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cSuccess.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _cSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Platform Operational',
                style: text.labelSmall?.copyWith(
                  color: _cSuccess,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 16),
          label: const Text('Export Report'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _cTextPrimary,
            side: const BorderSide(color: _cBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_business_rounded, size: 16),
          label: const Text('New Organization'),
          style: FilledButton.styleFrom(
            backgroundColor: _cPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// SECTION: ALERT BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _SystemAlertBanner extends StatelessWidget {
  const _SystemAlertBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _cWarningLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cWarning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _cWarning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _cWarning,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Color(0xFF7B4F00)),
                children: const [
                  TextSpan(
                    text: 'Service Degradation — ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text:
                        'WhatsApp Business API is experiencing elevated latency (2,840 ms avg). '
                        'Message delivery rates may be affected. Our team is monitoring.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'View Health →',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _cWarning,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.close, size: 16, color: _cWarning),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: STATS GRID
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == _stats.last ? 0 : 12),
                child: _StatCard(data: s),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 20),
              ),
              const SizedBox(width: 24),
              // Mini trend indicator
              Icon(
                data.deltaPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: data.deltaPositive ? _cSuccess : _cError,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.value,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _cTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: text.bodySmall?.copyWith(
              color: _cTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _cBorder),
          const SizedBox(height: 10),
          Text(
            data.delta,
            style: text.labelSmall?.copyWith(
              color: data.deltaPositive ? _cSuccess : _cError,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: CHARTS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ChartsRow extends StatelessWidget {
  const _ChartsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main line chart — platform growth
          Expanded(
            flex: 5,
            child: Container(
              decoration: _card(),
              padding: const EdgeInsets.all(24),
              child: const _PlatformActivityChart(),
            ),
          ),
          const SizedBox(width: 20),
          // System health panel
          Expanded(
            flex: 3,
            child: Container(
              decoration: _card(),
              child: const _SystemHealthPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformActivityChart extends StatelessWidget {
  const _PlatformActivityChart();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Activity',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last 30 days — Active organizations & daily orders',
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Legend
            _ChartLegendDot(color: _cPrimary, label: 'Active Orgs'),
            const SizedBox(width: 16),
            _ChartLegendDot(color: _cAccent, label: 'Orders (÷10)'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cPrimaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '30D',
                style: text.labelSmall?.copyWith(
                  color: _cPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: _cBorder, strokeWidth: 1, dashArray: [4, 4]),
              ),
              borderData: FlBorderData(show: false),
              clipData: const FlClipData.all(),
              minX: 1,
              maxX: 30,
              minY: 20,
              maxY: 55,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 5,
                    getTitlesWidget: (v, m) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: _cTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 5,
                    getTitlesWidget: (v, m) {
                      if (v == 1) return _chartLabel('Feb 1');
                      if (v == 10) return _chartLabel('Feb 10');
                      if (v == 20) return _chartLabel('Feb 20');
                      if (v == 30) return _chartLabel('Feb 28');
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => _cPrimary,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          s.barIndex == 0
                              ? '${s.y.toInt()} orgs'
                              : '${(s.y * 10).toInt()} orders',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                // Active orgs line
                LineChartBarData(
                  spots: _chartData,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: _cPrimary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        _cPrimary.withOpacity(0.15),
                        _cPrimary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Orders line (divided by 10 to fit Y axis)
                LineChartBarData(
                  spots: _chartDataOrders
                      .map((s) => FlSpot(s.x, s.y / 10))
                      .toList(),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: _cAccent,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  dashArray: [6, 3],
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        _cAccent.withOpacity(0.08),
                        _cAccent.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chartLabel(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 11,
      color: _cTextSecondary,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _cTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM HEALTH PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _SystemHealthPanel extends StatelessWidget {
  const _SystemHealthPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ok = _healthItems.where((h) => h.status == 'ok').length;
    final total = _healthItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Health',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _cTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$ok / $total services operational',
                    style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _cWarningLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '1 degraded',
                  style: text.labelSmall?.copyWith(
                    color: _cWarning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Overall health bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: ok / total,
                    backgroundColor: _cWarningLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(_cSuccess),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(height: 1, color: _cBorder),
        ),
        // Service list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _healthItems.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: _cBorder,
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (_, i) => _HealthItemRow(item: _healthItems[i]),
          ),
        ),
      ],
    );
  }
}

class _HealthItemRow extends StatelessWidget {
  final _HealthItem item;
  const _HealthItemRow({required this.item});

  Color get _dotColor {
    return switch (item.status) {
      'ok' => _cSuccess,
      'degraded' => _cWarning,
      'down' => _cError,
      _ => _cTextSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _dotColor.withOpacity(0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(item.icon, size: 15, color: _cTextSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.service,
              style: text.bodySmall?.copyWith(
                color: _cTextPrimary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            item.latency,
            style: text.labelSmall?.copyWith(
              color: item.status == 'degraded' ? _cWarning : _cTextSecondary,
              fontWeight: item.status == 'degraded'
                  ? FontWeight.w700
                  : FontWeight.w400,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: RECENT ORGS TABLE + AUDIT FEED
// ─────────────────────────────────────────────────────────────────────────────

class _OrgsAndAuditRow extends StatelessWidget {
  const _OrgsAndAuditRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Recent orgs table
          Expanded(
            flex: 6,
            child: Container(
              decoration: _card(),
              child: const _RecentOrgsTable(),
            ),
          ),
          const SizedBox(width: 20),
          // Audit feed
          Expanded(
            flex: 4,
            child: Container(
              decoration: _card(),
              child: const _AuditFeedPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrgsTable extends StatelessWidget {
  const _RecentOrgsTable();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Text(
                'Recent Organizations',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _cTextPrimary,
                ),
              ),
              const SizedBox(width: 24),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _cPrimaryMid,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'View All Organizations →',
                  style: text.labelSmall?.copyWith(
                    color: _cPrimaryMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            border: Border(
              top: BorderSide(color: _cBorder),
              bottom: BorderSide(color: _cBorder),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 4, child: _colHeader(context, 'ORGANIZATION')),
              Expanded(flex: 3, child: _colHeader(context, 'TYPES')),
              Expanded(flex: 3, child: _colHeader(context, 'TERRITORY')),
              Expanded(flex: 2, child: _colHeader(context, 'PLAN')),
              Expanded(flex: 2, child: _colHeader(context, 'STATUS')),
              Expanded(flex: 1, child: _colHeader(context, 'USERS')),
              Expanded(flex: 2, child: _colHeader(context, 'LAST ACTIVE')),
              const SizedBox(width: 32),
            ],
          ),
        ),
        // Rows
        ..._recentOrgs.asMap().entries.map(
          (e) => _OrgTableRow(row: e.value, isEven: e.key.isEven),
        ),
      ],
    );
  }

  Widget _colHeader(BuildContext ctx, String label) => Text(
    label,
    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
      color: _cTextSecondary,
      fontWeight: FontWeight.w700,
      fontSize: 10,
      letterSpacing: 0.8,
    ),
  );
}

class _OrgTableRow extends StatelessWidget {
  final _OrgRow row;
  final bool isEven;
  const _OrgTableRow({required this.row, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFBFC),
        border: const Border(bottom: BorderSide(color: _cBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _cPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      row.name.substring(0, 1),
                      style: text.labelMedium?.copyWith(
                        color: _cPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.name,
                    style: text.bodySmall?.copyWith(
                      color: _cTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Types
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: row.types.map((t) => _TypeChip(type: t)).toList(),
            ),
          ),
          // Territory
          Expanded(
            flex: 3,
            child: Text(
              row.territory,
              style: text.bodySmall?.copyWith(color: _cTextSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Plan
          Expanded(
            flex: 2,
            child: Text(
              row.plan,
              style: text.bodySmall?.copyWith(
                color: _cTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Status
          Expanded(flex: 2, child: _StatusChip(status: row.status)),
          // Users
          Expanded(
            flex: 1,
            child: Text(
              row.users.toString(),
              style: text.bodySmall?.copyWith(
                color: _cTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Last active
          Expanded(
            flex: 2,
            child: Text(
              row.lastActive,
              style: text.bodySmall?.copyWith(color: _cTextSecondary),
            ),
          ),
          // Actions
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 16),
              onPressed: () {},
              color: _cTextSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  Color get _bg => switch (type) {
    'distributor' => _cPrimaryLight,
    'pharmacy' => _cAccentLight,
    'supplier' => _cSuccessLight,
    _ => _cSurface,
  };
  Color get _fg => switch (type) {
    'distributor' => _cPrimary,
    'pharmacy' => _cAccent,
    'supplier' => _cSuccess,
    _ => _cTextSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _bg => switch (status) {
    'active' => _cSuccessLight,
    'trialing' => _cInfoLight,
    'suspended' => _cErrorLight,
    'past_due' => _cWarningLight,
    _ => _cSurface,
  };
  Color get _fg => switch (status) {
    'active' => _cSuccess,
    'trialing' => _cInfo,
    'suspended' => _cError,
    'past_due' => _cWarning,
    _ => _cTextSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _fg,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUDIT FEED PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _AuditFeedPanel extends StatelessWidget {
  const _AuditFeedPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Text(
                'Platform Audit Feed',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _cTextPrimary,
                ),
              ),
              const SizedBox(width: 24),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: _cPrimaryMid,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Full Log →',
                  style: text.labelSmall?.copyWith(
                    color: _cPrimaryMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(height: 1, color: _cBorder),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _auditEntries.length,
            itemBuilder: (_, i) => _AuditEntryRow(entry: _auditEntries[i]),
          ),
        ),
      ],
    );
  }
}

class _AuditEntryRow extends StatelessWidget {
  final _AuditEntry entry;
  const _AuditEntryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: entry.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, color: entry.iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.event,
                  style: text.bodySmall?.copyWith(
                    color: _cTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: text.labelSmall?.copyWith(
                      color: _cTextSecondary,
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(text: entry.actor),
                      const TextSpan(text: '  ·  '),
                      TextSpan(
                        text: entry.org,
                        style: const TextStyle(
                          color: _cPrimaryMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            entry.time,
            style: text.labelSmall?.copyWith(
              color: _cTextSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION: QUEUE STATUS + SCHEDULED JOBS
// ─────────────────────────────────────────────────────────────────────────────

class _QueueAndJobsRow extends StatelessWidget {
  const _QueueAndJobsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Queue stats mini cards
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _SectionLabel(label: 'QUEUE STATUS — LAST 24 HOURS'),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: _QueueStatCard(
                      label: 'Processed',
                      value: '12,847',
                      color: _cSuccess,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _QueueStatCard(
                      label: 'Pending',
                      value: '1,247',
                      color: _cInfo,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _QueueStatCard(
                      label: 'Failed',
                      value: '8',
                      color: _cError,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _QueueStatCard(
                      label: 'Workers',
                      value: '3',
                      color: _cWarning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'FAILED JOBS'),
              const SizedBox(height: 12),
              Container(decoration: _card(), child: const _FailedJobsTable()),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Scheduled jobs
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(label: 'SCHEDULED JOBS'),
              const SizedBox(height: 12),
              Container(
                decoration: _card(),
                child: const _ScheduledJobsTable(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _cTextSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _QueueStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _QueueStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: _cTextPrimary,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: text.bodySmall?.copyWith(color: _cTextSecondary)),
        ],
      ),
    );
  }
}

class _FailedJobsTable extends StatelessWidget {
  const _FailedJobsTable();

  static const _failedJobs = [
    (
      job: 'ReconcilePayments',
      time: 'Today 08:00',
      error: 'M-Pesa API timeout',
    ),
    (
      job: 'SendWhatsAppMessage',
      time: '11:42 AM',
      error: 'WhatsApp API degraded',
    ),
    (
      job: 'SendWhatsAppMessage',
      time: '11:38 AM',
      error: 'WhatsApp API degraded',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            border: Border(bottom: BorderSide(color: _cBorder)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: _colH(context, 'JOB CLASS')),
              Expanded(flex: 2, child: _colH(context, 'FAILED AT')),
              Expanded(flex: 3, child: _colH(context, 'ERROR')),
              const SizedBox(width: 60),
            ],
          ),
        ),
        // Rows
        ..._failedJobs.map(
          (j) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    j.job,
                    style: text.bodySmall?.copyWith(
                      color: _cTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    j.time,
                    style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    j.error,
                    style: text.bodySmall?.copyWith(color: _cError),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            'Retry',
                            style: text.labelSmall?.copyWith(
                              color: _cPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _colH(BuildContext ctx, String label) => Text(
    label,
    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
      color: _cTextSecondary,
      fontWeight: FontWeight.w700,
      fontSize: 10,
      letterSpacing: 0.8,
    ),
  );
}

class _ScheduledJobsTable extends StatelessWidget {
  const _ScheduledJobsTable();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            border: Border(bottom: BorderSide(color: _cBorder)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: _colH(context, 'JOB')),
              Expanded(flex: 2, child: _colH(context, 'SCHEDULE')),
              Expanded(flex: 2, child: _colH(context, 'LAST RUN')),
              Expanded(flex: 2, child: _colH(context, 'NEXT RUN')),
              Expanded(flex: 2, child: _colH(context, 'RESULT')),
            ],
          ),
        ),
        // Job rows
        ..._scheduledJobs.asMap().entries.map(
          (e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: e.key.isEven ? Colors.white : const Color(0xFFFAFBFC),
              border: Border(
                bottom: BorderSide(
                  color: e.key == _scheduledJobs.length - 1
                      ? Colors.transparent
                      : _cBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    e.value.name,
                    style: text.bodySmall?.copyWith(
                      color: _cTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    e.value.schedule,
                    style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    e.value.lastRun,
                    style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    e.value.nextRun,
                    style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _JobResultChip(result: e.value.result),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _colH(BuildContext ctx, String label) => Text(
    label,
    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
      color: _cTextSecondary,
      fontWeight: FontWeight.w700,
      fontSize: 10,
      letterSpacing: 0.8,
    ),
  );
}

class _JobResultChip extends StatelessWidget {
  final String result;
  const _JobResultChip({required this.result});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (result) {
      'success' => (_cSuccess, _cSuccessLight, Icons.check_circle_rounded),
      'failed' => (_cError, _cErrorLight, Icons.cancel_rounded),
      'running' => (_cInfo, _cInfoLight, Icons.sync_rounded),
      _ => (_cTextSecondary, _cSurface, Icons.schedule_rounded),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 11),
              const SizedBox(width: 4),
              Text(
                result,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
