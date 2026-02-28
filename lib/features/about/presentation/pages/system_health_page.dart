// system_health_page.dart
// System Health — Super Admin real-time platform infrastructure monitor.
//
// Covers:
//   - Overall health score + uptime
//   - API error rate, response time, request volume (last 24h)
//   - Queue: Redis queue depth per queue name, failed jobs
//   - Scheduled jobs: last run, next run, status
//   - Service checks: Database, Redis, S3, WhatsApp API, M-Pesa, FCM
//   - Recent failed jobs with retry / delete
//   - Database stats: size, connections, slow queries
//   - Server vitals: CPU, memory, disk
//
// No AppBar. No Drawer. Pure page content.
// Location: features/platform_admin/presentation/pages/system_health_page.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ServiceStatus { healthy, degraded, down, unknown }

enum JobStatus { completed, running, failed, pending, skipped }

// ─── Models ───────────────────────────────────────────────────────────────────

class _ServiceCheck {
  final String name;
  final String detail;
  final ServiceStatus status;
  final String? latencyMs;
  final IconData icon;
  final Color color;

  const _ServiceCheck({
    required this.name,
    required this.detail,
    required this.status,
    this.latencyMs,
    required this.icon,
    required this.color,
  });
}

class _QueueStat {
  final String name;
  final int pending;
  final int processed24h;
  final int failed24h;
  final Color color;

  const _QueueStat({
    required this.name,
    required this.pending,
    required this.processed24h,
    required this.failed24h,
    required this.color,
  });
}

class _ScheduledJob {
  final String name;
  final String schedule;
  final String? lastRunAt;
  final String? nextRunAt;
  final JobStatus lastStatus;
  final String? duration;
  final IconData icon;

  const _ScheduledJob({
    required this.name,
    required this.schedule,
    this.lastRunAt,
    this.nextRunAt,
    required this.lastStatus,
    this.duration,
    required this.icon,
  });
}

class _FailedJob {
  final int id;
  final String jobClass;
  final String queue;
  final String failedAt;
  final String exception;
  final int attempts;

  const _FailedJob({
    required this.id,
    required this.jobClass,
    required this.queue,
    required this.failedAt,
    required this.exception,
    required this.attempts,
  });
}

class _DataPoint {
  final String label;
  final double value;
  const _DataPoint(this.label, this.value);
}

// ─── Mock data ────────────────────────────────────────────────────────────────

class _Mock {
  // API response times (ms) — last 24 hours, hourly
  static final List<_DataPoint> apiResponseTime = List.generate(24, (i) {
    final hour = i;
    final base = 120.0 + math.sin(i * 0.5) * 40;
    final spike = (i == 14) ? 480.0 : 0.0; // spike at 2pm
    return _DataPoint(
      '${hour}h',
      base + spike + math.Random(i + 10).nextDouble() * 30,
    );
  });

  // Request volume — last 24h
  static final List<_DataPoint> requestVolume = List.generate(24, (i) {
    final base = (i >= 7 && i <= 19) ? 280.0 + i * 12 : 40.0;
    return _DataPoint('${i}h', base + math.Random(i + 20).nextDouble() * 80);
  });

  // Error rate (%) — last 24h
  static final List<_DataPoint> errorRate = List.generate(24, (i) {
    final base = 0.4 + math.Random(i + 30).nextDouble() * 0.8;
    final spike = (i == 14) ? 3.8 : 0.0;
    return _DataPoint('${i}h', base + spike);
  });

  static const List<_ServiceCheck> services = [
    _ServiceCheck(
      name: 'PostgreSQL 16',
      detail: 'Primary database — 127.0.0.1:5432',
      status: ServiceStatus.healthy,
      latencyMs: '2ms',
      icon: Icons.storage_outlined,
      color: Colors.indigo,
    ),
    _ServiceCheck(
      name: 'Redis 7',
      detail: 'Cache + queue driver — 127.0.0.1:6379',
      status: ServiceStatus.healthy,
      latencyMs: '0.3ms',
      icon: Icons.bolt_outlined,
      color: Colors.red,
    ),
    _ServiceCheck(
      name: 'Cloudflare R2',
      detail: 'pharmoos-prod bucket — object storage',
      status: ServiceStatus.healthy,
      latencyMs: '41ms',
      icon: Icons.cloud_outlined,
      color: Colors.deepOrange,
    ),
    _ServiceCheck(
      name: 'WhatsApp Business API',
      detail: 'Meta Graph API — webhook active',
      status: ServiceStatus.healthy,
      latencyMs: '180ms',
      icon: Icons.chat_bubble_outlined,
      color: Colors.green,
    ),
    _ServiceCheck(
      name: 'M-Pesa Daraja API',
      detail: 'Safaricom production — C2B active',
      status: ServiceStatus.healthy,
      latencyMs: '210ms',
      icon: Icons.phone_android_outlined,
      color: Color(0xFF00A550),
    ),
    _ServiceCheck(
      name: 'Airtel Money API',
      detail: 'Authentication token expired',
      status: ServiceStatus.down,
      latencyMs: null,
      icon: Icons.sim_card_outlined,
      color: Colors.red,
    ),
    _ServiceCheck(
      name: 'Firebase FCM',
      detail: 'Push notifications — 1,240 active tokens',
      status: ServiceStatus.healthy,
      latencyMs: '95ms',
      icon: Icons.notifications_outlined,
      color: Colors.orange,
    ),
    _ServiceCheck(
      name: 'Laravel Horizon',
      detail: 'Queue worker — 3 workers active',
      status: ServiceStatus.healthy,
      latencyMs: null,
      icon: Icons.view_in_ar_outlined,
      color: Colors.purple,
    ),
  ];

  static const List<_QueueStat> queues = [
    _QueueStat(
      name: 'default',
      pending: 0,
      processed24h: 1842,
      failed24h: 2,
      color: Colors.blue,
    ),
    _QueueStat(
      name: 'whatsapp',
      pending: 3,
      processed24h: 441,
      failed24h: 1,
      color: Colors.green,
    ),
    _QueueStat(
      name: 'notifications',
      pending: 0,
      processed24h: 892,
      failed24h: 0,
      color: Colors.orange,
    ),
    _QueueStat(
      name: 'reports',
      pending: 1,
      processed24h: 14,
      failed24h: 0,
      color: Colors.teal,
    ),
    _QueueStat(
      name: 'reconciliation',
      pending: 0,
      processed24h: 3,
      failed24h: 0,
      color: Colors.indigo,
    ),
  ];

  static const List<_ScheduledJob> scheduledJobs = [
    _ScheduledJob(
      name: 'ScanExpiryAlerts',
      schedule: 'Daily 06:00',
      lastRunAt: 'Today 06:00',
      nextRunAt: 'Tomorrow 06:00',
      lastStatus: JobStatus.completed,
      duration: '4.2s',
      icon: Icons.alarm_outlined,
    ),
    _ScheduledJob(
      name: 'CheckStockLevels',
      schedule: 'Daily 06:30',
      lastRunAt: 'Today 06:30',
      nextRunAt: 'Tomorrow 06:30',
      lastStatus: JobStatus.completed,
      duration: '1.8s',
      icon: Icons.inventory_2_outlined,
    ),
    _ScheduledJob(
      name: 'ReconcilePayments',
      schedule: 'Daily 08:00',
      lastRunAt: 'Today 08:00',
      nextRunAt: 'Tomorrow 08:00',
      lastStatus: JobStatus.failed,
      duration: null,
      icon: Icons.account_balance_outlined,
    ),
    _ScheduledJob(
      name: 'FlagOverdueInvoices',
      schedule: 'Daily 09:00',
      lastRunAt: 'Today 09:00',
      nextRunAt: 'Tomorrow 09:00',
      lastStatus: JobStatus.completed,
      duration: '0.6s',
      icon: Icons.receipt_long_outlined,
    ),
    _ScheduledJob(
      name: 'GenerateOfficerReports',
      schedule: 'Monday 07:00',
      lastRunAt: 'Mon 24 Feb',
      nextRunAt: 'Mon 03 Mar',
      lastStatus: JobStatus.completed,
      duration: '22.4s',
      icon: Icons.bar_chart_rounded,
    ),
    _ScheduledJob(
      name: 'CleanExpiredTokens',
      schedule: 'Daily 02:00',
      lastRunAt: 'Today 02:00',
      nextRunAt: 'Tomorrow 02:00',
      lastStatus: JobStatus.completed,
      duration: '0.2s',
      icon: Icons.cleaning_services_outlined,
    ),
    _ScheduledJob(
      name: 'BackupDatabase',
      schedule: 'Daily 01:00',
      lastRunAt: 'Today 01:00',
      nextRunAt: 'Tomorrow 01:00',
      lastStatus: JobStatus.completed,
      duration: '142s',
      icon: Icons.backup_outlined,
    ),
  ];

  static const List<_FailedJob> failedJobs = [
    _FailedJob(
      id: 4412,
      jobClass: 'SendWhatsAppPromotion',
      queue: 'whatsapp',
      failedAt: '27 Feb 22:10',
      exception:
          'GuzzleHttp\\Exception\\ConnectException: WhatsApp API timeout after 30s',
      attempts: 3,
    ),
    _FailedJob(
      id: 4398,
      jobClass: 'ReconcilePayments',
      queue: 'reconciliation',
      failedAt: '28 Feb 08:00',
      exception:
          'Illuminate\\Database\\QueryException: SQLSTATE[23000]: Integrity constraint violation',
      attempts: 1,
    ),
    _FailedJob(
      id: 4355,
      jobClass: 'GenerateInvoicePdf',
      queue: 'default',
      failedAt: '26 Feb 14:32',
      exception:
          'RuntimeException: DomPDF out of memory — increase memory_limit',
      attempts: 3,
    ),
  ];

  // Server vitals
  static const double cpuPercent = 18.4;
  static const double memUsedGb = 3.2;
  static const double memTotalGb = 8.0;
  static const double diskUsedGb = 28.4;
  static const double diskTotalGb = 80.0;
  static const int dbConnections = 12;
  static const int dbMaxConnections = 100;
  static const double dbSizeGb = 2.84;
  static const int slowQueries24h = 3;
  static const String uptime = '47 days, 14h 22m';
  static const String phpVersion = 'PHP 8.3.4';
  static const String laravelVersion = 'Laravel 11.5.0';
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class SystemHealthPage extends StatefulWidget {
  const SystemHealthPage({super.key});

  @override
  State<SystemHealthPage> createState() => _SystemHealthPageState();
}

class _SystemHealthPageState extends State<SystemHealthPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _anim;
  bool _isRefreshing = false;
  final Set<int> _expandedJobs = {};

  // Compute overall health
  int get _healthyServices =>
      _Mock.services.where((s) => s.status == ServiceStatus.healthy).length;
  int get _downServices =>
      _Mock.services.where((s) => s.status == ServiceStatus.down).length;
  int get _totalFailedJobs => _Mock.failedJobs.length;
  int get _totalPending => _Mock.queues.fold(0, (a, q) => a + q.pending);
  double get _healthScore {
    final svcScore = (_healthyServices / _Mock.services.length) * 70;
    final jobScore = (_totalFailedJobs == 0) ? 20.0 : 10.0;
    final queueScore = (_totalPending < 5) ? 10.0 : 5.0;
    return svcScore + jobScore + queueScore;
  }

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

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    _animCtrl.reset();
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isRefreshing = false);
    _animCtrl.forward();
    _snack('Health check refreshed');
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildHealthScore(context)),
            SliverToBoxAdapter(child: _buildServerVitals(context)),
            SliverToBoxAdapter(child: _buildApiCharts(context)),
            SliverToBoxAdapter(child: _buildServiceChecks(context)),
            SliverToBoxAdapter(child: _buildQueues(context)),
            SliverToBoxAdapter(child: _buildScheduledJobs(context)),
            SliverToBoxAdapter(child: _buildFailedJobs(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasIssue = _downServices > 0 || _totalFailedJobs > 0;

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
                        color: hasIssue
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasIssue
                              ? Colors.orange.withValues(alpha: 0.4)
                              : Colors.green.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasIssue
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            size: 12,
                            color: hasIssue ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasIssue ? 'DEGRADED' : 'ALL SYSTEMS OPERATIONAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: hasIssue ? Colors.orange : Colors.green,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LivePulse(color: hasIssue ? Colors.orange : Colors.green),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'System Health',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Uptime: ${_Mock.uptime}  ·  ${_Mock.phpVersion}  ·  ${_Mock.laravelVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton.outlined(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh health check',
            ),
        ],
      ),
    );
  }

  // ── Health score ───────────────────────────────────────────────────────────

  Widget _buildHealthScore(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final score = _healthScore;
    final scoreColor = score >= 90
        ? Colors.green
        : score >= 70
        ? Colors.orange
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Score gauge
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _ScoreGaugePainter(
                  score: score,
                  progress: _anim.value,
                  color: scoreColor,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Summary chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Score',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _SummaryChip(
                  icon: Icons.check_circle_outline,
                  label:
                      '$_healthyServices / ${_Mock.services.length} services healthy',
                  color: Colors.green,
                ),
                const SizedBox(height: 4),
                _SummaryChip(
                  icon: Icons.error_outline_rounded,
                  label:
                      '$_downServices service${_downServices == 1 ? '' : 's'} down',
                  color: _downServices > 0 ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 4),
                _SummaryChip(
                  icon: Icons.bug_report_outlined,
                  label:
                      '$_totalFailedJobs failed job${_totalFailedJobs == 1 ? '' : 's'} in queue',
                  color: _totalFailedJobs > 0 ? Colors.orange : Colors.green,
                ),
                const SizedBox(height: 4),
                _SummaryChip(
                  icon: Icons.pending_outlined,
                  label:
                      '$_totalPending job${_totalPending == 1 ? '' : 's'} queued',
                  color: _totalPending > 5 ? Colors.orange : Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Server vitals ──────────────────────────────────────────────────────────

  Widget _buildServerVitals(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.memory_outlined,
            iconColor: Colors.indigo,
            title: 'Server Vitals',
            subtitle: 'Hetzner VPS — 4 vCPU, 8GB RAM, 80GB SSD',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _VitalBar(
                  label: 'CPU',
                  value: _Mock.cpuPercent,
                  max: 100,
                  unit: '%',
                  color: _Mock.cpuPercent > 80
                      ? Colors.red
                      : _Mock.cpuPercent > 60
                      ? Colors.orange
                      : Colors.green,
                  anim: _anim,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VitalBar(
                  label: 'Memory',
                  value: _Mock.memUsedGb,
                  max: _Mock.memTotalGb,
                  unit: 'GB',
                  color: (_Mock.memUsedGb / _Mock.memTotalGb) > 0.85
                      ? Colors.red
                      : Colors.blue,
                  anim: _anim,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _VitalBar(
                  label: 'Disk',
                  value: _Mock.diskUsedGb,
                  max: _Mock.diskTotalGb,
                  unit: 'GB',
                  color: (_Mock.diskUsedGb / _Mock.diskTotalGb) > 0.85
                      ? Colors.red
                      : Colors.teal,
                  anim: _anim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // DB stats row
          Row(
            children: [
              _DbStat(
                icon: Icons.storage_outlined,
                label: 'DB Size',
                value: '${_Mock.dbSizeGb} GB',
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 20),
              _DbStat(
                icon: Icons.cable_outlined,
                label: 'Connections',
                value: '${_Mock.dbConnections} / ${_Mock.dbMaxConnections}',
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 20),
              _DbStat(
                icon: Icons.slow_motion_video_rounded,
                label: 'Slow Queries (24h)',
                value: '${_Mock.slowQueries24h}',
                color: _Mock.slowQueries24h > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── API charts ─────────────────────────────────────────────────────────────

  Widget _buildApiCharts(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.show_chart_rounded,
            iconColor: Colors.blue,
            title: 'API Performance',
            subtitle: 'Last 24 hours — hourly',
            trailing: Row(
              children: [
                _MiniKpi('142ms', 'avg', Colors.blue),
                const SizedBox(width: 12),
                _MiniKpi('1.2%', 'error rate', Colors.orange),
                const SizedBox(width: 12),
                _MiniKpi('8.4K', 'requests', Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Response time chart
          Text(
            'Response Time (ms)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              height: 90,
              child: CustomPaint(
                painter: _MiniLineChart(
                  data: _Mock.apiResponseTime,
                  color: Colors.blue,
                  progress: _anim.value,
                  colorScheme: colorScheme,
                  danger: 400,
                  dangerColor: Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Error rate chart
          Text(
            'Error Rate (%)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              height: 70,
              child: CustomPaint(
                painter: _MiniBarChart(
                  data: _Mock.errorRate,
                  color: Colors.orange,
                  dangerColor: Colors.red,
                  progress: _anim.value,
                  colorScheme: colorScheme,
                  dangerThreshold: 2.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Spike annotation
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 12, color: Colors.orange),
              const SizedBox(width: 5),
              Text(
                'Response spike detected at 14:00 (480ms, 3.8% error rate) — WhatsApp API timeout',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Service checks ─────────────────────────────────────────────────────────

  Widget _buildServiceChecks(BuildContext context) {
    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.electrical_services_outlined,
            iconColor: Colors.teal,
            title: 'Service Status',
            subtitle: '${_healthyServices} healthy · $_downServices down',
          ),
          const SizedBox(height: 8),
          ..._Mock.services.map(
            (s) => _ServiceRow(
              service: s,
              onPing: () => _snack('Pinging ${s.name}…'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Queues ─────────────────────────────────────────────────────────────────

  Widget _buildQueues(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalProcessed = _Mock.queues.fold(0, (a, q) => a + q.processed24h);
    final totalFailed = _Mock.queues.fold(0, (a, q) => a + q.failed24h);

    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.queue_outlined,
            iconColor: Colors.purple,
            title: 'Queue Status',
            subtitle: 'Redis — Laravel Horizon',
            trailing: Row(
              children: [
                _MiniKpi('$totalProcessed', 'processed 24h', Colors.green),
                const SizedBox(width: 12),
                _MiniKpi(
                  '$totalFailed',
                  'failed 24h',
                  totalFailed > 0 ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Queue bars
          ..._Mock.queues.map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => _QueueBar(queue: q, progress: _anim.value),
              ),
            ),
          ),
          const Divider(height: 8),
          const SizedBox(height: 4),
          // Horizon status
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Laravel Horizon running — 3 workers',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _snack('Opening Horizon dashboard…'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('Open Horizon →'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Scheduled jobs ─────────────────────────────────────────────────────────

  Widget _buildScheduledJobs(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.schedule_outlined,
            iconColor: Colors.amber.shade700,
            title: 'Scheduled Jobs',
            subtitle: 'Laravel Scheduler — ${_Mock.scheduledJobs.length} jobs',
          ),
          const SizedBox(height: 8),
          ..._Mock.scheduledJobs.map((job) {
            final failed = job.lastStatus == JobStatus.failed;
            return Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: failed
                    ? Colors.red.withValues(alpha: 0.04)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: failed
                    ? Border.all(color: Colors.red.withValues(alpha: 0.15))
                    : null,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: failed
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    job.icon,
                    size: 16,
                    color: failed ? Colors.red : Colors.amber.shade700,
                  ),
                ),
                title: Text(
                  job.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: failed ? Colors.red : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.schedule}  ·  Last: ${job.lastRunAt ?? 'Never'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (job.nextRunAt != null)
                      Text(
                        'Next: ${job.nextRunAt}',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (job.duration != null)
                      Text(
                        job.duration!,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 6),
                    _JobStatusBadge(job.lastStatus),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Failed jobs ────────────────────────────────────────────────────────────

  Widget _buildFailedJobs(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_Mock.failedJobs.isEmpty) {
      return _Card(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          children: [
            _CardHeader(
              icon: Icons.bug_report_outlined,
              iconColor: Colors.green,
              title: 'Failed Jobs',
              subtitle: 'No failed jobs in queue',
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            const Text(
              'All good! No failed jobs.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return _Card(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            icon: Icons.bug_report_outlined,
            iconColor: Colors.red,
            title: 'Failed Jobs',
            subtitle: '${_Mock.failedJobs.length} jobs in failed_jobs table',
            trailing: OutlinedButton(
              onPressed: () => _snack('Retrying all failed jobs…'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Retry All'),
            ),
          ),
          const SizedBox(height: 8),
          ..._Mock.failedJobs.map((job) {
            final isExpanded = _expandedJobs.contains(job.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(
                      () => isExpanded
                          ? _expandedJobs.remove(job.id)
                          : _expandedJobs.add(job.id),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      job.jobClass,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        job.queue,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
                                          color: Colors.purple,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      job.failedAt,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${job.attempts} attempts',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  job.exception.split(':').first,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: isExpanded ? null : 1,
                                  overflow: isExpanded
                                      ? null
                                      : TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1, indent: 12, endIndent: 12),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full exception
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              job.exception,
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Actions
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    _snack('Retrying job #${job.id}…'),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                ),
                                label: const Text('Retry'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _snack('Job #${job.id} deleted'),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 14,
                                ),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Score Gauge Painter ──────────────────────────────────────────────────────

class _ScoreGaugePainter extends CustomPainter {
  final double score, progress;
  final Color color;
  final ColorScheme colorScheme;

  _ScoreGaugePainter({
    required this.score,
    required this.progress,
    required this.color,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colorScheme.surfaceContainerLow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Score arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (score / 100) * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${(score * progress).toStringAsFixed(0)}\n',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: '/ 100',
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
  bool shouldRepaint(_ScoreGaugePainter old) => old.progress != progress;
}

// ─── Mini charts ──────────────────────────────────────────────────────────────

class _MiniLineChart extends CustomPainter {
  final List<_DataPoint> data;
  final Color color, dangerColor;
  final double progress, danger;
  final ColorScheme colorScheme;

  _MiniLineChart({
    required this.data,
    required this.color,
    required this.progress,
    required this.colorScheme,
    required this.danger,
    required this.dangerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const padL = 32.0, padB = 18.0, padT = 4.0, padR = 4.0;
    final w = size.width - padL - padR;
    final h = size.height - padB - padT;
    final maxY = data.map((d) => d.value).reduce(math.max) * 1.15;

    double xOf(int i) => padL + (i / (data.length - 1)) * w;
    double yOf(double v) => padT + h - (v / maxY) * h;

    final visible = math.max(2, (data.length * progress).round());

    // Danger threshold line
    final ty = yOf(danger);
    final dashPaint = Paint()
      ..color = dangerColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    double dx = padL;
    bool dash = true;
    while (dx < size.width - padR) {
      if (dash)
        canvas.drawLine(
          Offset(dx, ty),
          Offset(math.min(dx + 8, size.width - padR), ty),
          dashPaint,
        );
      dx += dash ? 8 : 4;
      dash = !dash;
    }

    // Grid
    for (int i = 0; i <= 3; i++) {
      final y = padT + (h / 3) * i;
      canvas.drawLine(
        Offset(padL, y),
        Offset(size.width - padR, y),
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.2)
          ..strokeWidth = 1,
      );
      if (i < 3) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${(maxY - (maxY / 3) * i).round()}',
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

    // Area + line
    if (visible > 1) {
      final area = Path()..moveTo(xOf(0), yOf(data[0].value));
      final line = Path()..moveTo(xOf(0), yOf(data[0].value));
      for (int i = 1; i < visible; i++) {
        final cpx = (xOf(i - 1) + xOf(i)) / 2;
        area.cubicTo(
          cpx,
          yOf(data[i - 1].value),
          cpx,
          yOf(data[i].value),
          xOf(i),
          yOf(data[i].value),
        );
        line.cubicTo(
          cpx,
          yOf(data[i - 1].value),
          cpx,
          yOf(data[i].value),
          xOf(i),
          yOf(data[i].value),
        );
      }
      area.lineTo(xOf(visible - 1), padT + h);
      area.lineTo(padL, padT + h);
      area.close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.02),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, padT, size.width, h)),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // X labels every 6h
    for (int i = 0; i < data.length; i += 6) {
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].label,
          style: TextStyle(
            fontSize: 8,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xOf(i) - 6, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(_MiniLineChart old) => old.progress != progress;
}

class _MiniBarChart extends CustomPainter {
  final List<_DataPoint> data;
  final Color color, dangerColor;
  final double progress, dangerThreshold;
  final ColorScheme colorScheme;

  _MiniBarChart({
    required this.data,
    required this.color,
    required this.dangerColor,
    required this.progress,
    required this.dangerThreshold,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const padL = 28.0, padB = 14.0, padT = 4.0, padR = 4.0;
    final w = size.width - padL - padR;
    final h = size.height - padB - padT;
    final maxY = math.max(
      data.map((d) => d.value).reduce(math.max) * 1.2,
      dangerThreshold * 1.5,
    );
    final barW = (w / data.length) - 1.5;

    for (int i = 0; i < data.length; i++) {
      final barH = (data[i].value / maxY) * h * progress;
      final x = padL + (w / data.length) * i + 0.75;
      final y = padT + h - barH;
      final isDanger = data[i].value > dangerThreshold;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barW, barH),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()
          ..color = (isDanger ? dangerColor : color).withValues(alpha: 0.7),
      );
    }

    // Y labels
    for (int i = 0; i <= 2; i++) {
      final v = (maxY / 2) * i;
      final y = padT + h - (v / maxY) * h;
      canvas.drawLine(
        Offset(padL, y),
        Offset(size.width - padR, y),
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.2)
          ..strokeWidth = 1,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${v.toStringAsFixed(1)}%',
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

  @override
  bool shouldRepaint(_MiniBarChart old) => old.progress != progress;
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;

  const _Card({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final Widget? trailing;

  const _CardHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
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
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final _ServiceCheck service;
  final VoidCallback onPing;

  const _ServiceRow({required this.service, required this.onPing});

  Color get _statusColor => switch (service.status) {
    ServiceStatus.healthy => Colors.green,
    ServiceStatus.degraded => Colors.orange,
    ServiceStatus.down => Colors.red,
    ServiceStatus.unknown => Colors.grey,
  };

  String get _statusLabel => switch (service.status) {
    ServiceStatus.healthy => 'Healthy',
    ServiceStatus.degraded => 'Degraded',
    ServiceStatus.down => 'Down',
    ServiceStatus.unknown => 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDown = service.status == ServiceStatus.down;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDown
            ? Colors.red.withValues(alpha: 0.04)
            : colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDown
              ? Colors.red.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: service.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(service.icon, size: 15, color: service.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  service.detail,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (service.latencyMs != null) ...[
            Text(
              service.latencyMs!,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueBar extends StatelessWidget {
  final _QueueStat queue;
  final double progress;

  const _QueueBar({required this.queue, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxProcessed = _Mock.queues
        .map((q) => q.processed24h)
        .reduce(math.max)
        .toDouble();
    final barFrac = maxProcessed > 0
        ? (queue.processed24h / maxProcessed) * progress
        : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            queue.name,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: queue.color,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barFrac,
                  minHeight: 8,
                  color: queue.color,
                  backgroundColor: queue.color.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    '${queue.processed24h} processed',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (queue.failed24h > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${queue.failed24h} failed',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  if (queue.pending > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${queue.pending} pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobStatusBadge extends StatelessWidget {
  final JobStatus status;
  const _JobStatusBadge(this.status);

  Color get _color => switch (status) {
    JobStatus.completed => Colors.green,
    JobStatus.running => Colors.blue,
    JobStatus.failed => Colors.red,
    JobStatus.pending => Colors.orange,
    JobStatus.skipped => Colors.grey,
  };

  String get _label => switch (status) {
    JobStatus.completed => '✓ OK',
    JobStatus.running => '⟳ Running',
    JobStatus.failed => '✕ Failed',
    JobStatus.pending => '· Pending',
    JobStatus.skipped => '— Skipped',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VitalBar extends StatelessWidget {
  final String label, unit;
  final double value, max;
  final Color color;
  final Animation<double> anim;

  const _VitalBar({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
    required this.anim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frac = (value / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              unit == '%'
                  ? '${value.toStringAsFixed(1)}%'
                  : '${value.toStringAsFixed(1)} / $max $unit',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedBuilder(
          animation: anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: frac * anim.value,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }
}

class _DbStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _DbStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String value, label;
  final Color color;

  const _MiniKpi(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _LivePulse extends StatefulWidget {
  final Color color;
  const _LivePulse({required this.color});

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _a = Tween(begin: 0.4, end: 1.0).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _a.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _a.value * 0.4),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
