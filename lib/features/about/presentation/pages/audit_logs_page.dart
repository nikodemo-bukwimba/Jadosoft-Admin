// audit_logs_page.dart
// Audit Logs — Super Admin immutable activity trail across all tenants.
//
// Maps to: activity_logs table (BIGSERIAL PK, high-volume, no soft delete)
// Every create/update/delete/login is permanently recorded with:
//   tenant_id, user_id, organization_id, event, auditable_type,
//   auditable_id, old_values, new_values, ip_address, user_agent
//
// Capabilities:
//   - Live feed with pull-to-refresh (most recent first)
//   - Event severity classification (info / warning / critical / security)
//   - Filter: by event type, by org, by user, by severity, by date range
//   - Search: event name, user name, org name, IP address
//   - Expandable log entries: old_values / new_values diff viewer
//   - Timeline grouping: Today / Yesterday / This week / Older
//   - Export: filtered log to CSV
//   - Security events highlighted: login failures, suspensions, impersonations
//
// No AppBar. No Drawer. Pure page content.
// Location: features/platform_admin/presentation/pages/audit_logs_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum LogSeverity { info, warning, critical, security }

enum LogDomain {
  auth,
  users,
  organizations,
  orders,
  inventory,
  payments,
  products,
  system,
}

enum DateRange { today, yesterday, last7, last30, all }

// ─── Model ───────────────────────────────────────────────────────────────────

class _AuditLog {
  final int id;
  final String tenantName;
  final String? userName;
  final String? userEmail;
  final String? orgName;
  final String event; // e.g. "order.approved"
  final LogDomain domain;
  final LogSeverity severity;
  final String? auditableType; // e.g. "App\Models\Order"
  final String? auditableId;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const _AuditLog({
    required this.id,
    required this.tenantName,
    this.userName,
    this.userEmail,
    this.orgName,
    required this.event,
    required this.domain,
    required this.severity,
    this.auditableType,
    this.auditableId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final _now = DateTime.now();

final List<_AuditLog> _logs = [
  // ── Today ─────────────────────────────────────────────────────────────────
  _AuditLog(
    id: 10441,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'user.impersonated',
    domain: LogDomain.auth,
    severity: LogSeverity.security,
    auditableType: 'App\\Models\\User',
    auditableId: 'u003',
    oldValues: null,
    newValues: {
      'target_user': 'Fatuma Hassan',
      'target_org': 'Bariki Pharmaceuticals',
    },
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(minutes: 5)),
  ),
  _AuditLog(
    id: 10440,
    tenantName: 'PharmaOS',
    userName: 'Amina Mwangi',
    userEmail: 'amina@barikipharma.co.tz',
    orgName: 'Bariki Pharmaceuticals',
    event: 'order.approved',
    domain: LogDomain.orders,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\Order',
    auditableId: 'ORD-2026-00142',
    oldValues: {'status': 'submitted'},
    newValues: {'status': 'approved', 'approved_by_id': 'u001'},
    ipAddress: '197.156.88.12',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0)',
    createdAt: _now.subtract(const Duration(minutes: 12)),
  ),
  _AuditLog(
    id: 10439,
    tenantName: 'PharmaOS',
    userName: 'David Temba',
    userEmail: 'david@barikipharma.co.tz',
    orgName: 'Bariki Pharmaceuticals',
    event: 'order.delivered',
    domain: LogDomain.orders,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\Order',
    auditableId: 'ORD-2026-00138',
    oldValues: {'status': 'dispatched'},
    newValues: {
      'status': 'delivered',
      'delivered_at': '2026-02-28T09:22:00Z',
      'gps_lat': '-8.9112',
      'gps_lng': '33.4598',
    },
    ipAddress: '197.156.90.44',
    userAgent: 'Flutter/3.19 (Android 13)',
    createdAt: _now.subtract(const Duration(minutes: 28)),
  ),
  _AuditLog(
    id: 10438,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'org.suspended',
    domain: LogDomain.organizations,
    severity: LogSeverity.critical,
    auditableType: 'App\\Models\\Organization',
    auditableId: 'o007',
    oldValues: {'is_active': true},
    newValues: {
      'is_active': false,
      'suspended_reason': 'Overdue subscription — 45 days',
    },
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(hours: 1, minutes: 10)),
  ),
  _AuditLog(
    id: 10437,
    tenantName: 'PharmaOS',
    userName: 'Fatuma Hassan',
    userEmail: 'fatuma@barikipharma.co.tz',
    orgName: 'Bariki Pharmaceuticals',
    event: 'visit.created',
    domain: LogDomain.organizations,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\Visit',
    auditableId: 'v0887',
    oldValues: null,
    newValues: {
      'customer_id': 'c012',
      'gps_lat': '-8.9044',
      'purpose': 'promo',
      'officer_id': 'u003',
    },
    ipAddress: '197.156.77.22',
    userAgent: 'Flutter/3.19 (iOS 17.3)',
    createdAt: _now.subtract(const Duration(hours: 1, minutes: 45)),
  ),
  _AuditLog(
    id: 10436,
    tenantName: 'PharmaOS',
    userName: 'Grace Malale',
    userEmail: 'grace@barikipharma.co.tz',
    orgName: 'Bariki Pharmaceuticals',
    event: 'inventory.batch_received',
    domain: LogDomain.inventory,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\InventoryBatch',
    auditableId: 'b0234',
    oldValues: null,
    newValues: {
      'product': 'Paracetamol 500mg',
      'batch_number': 'GSK-2026-0234',
      'quantity': 5000,
      'expiry_date': '2028-06-30',
    },
    ipAddress: '197.156.80.11',
    userAgent: 'Flutter/3.19 (Android 14)',
    createdAt: _now.subtract(const Duration(hours: 2, minutes: 5)),
  ),
  _AuditLog(
    id: 10435,
    tenantName: 'PharmaOS',
    userName: null,
    userEmail: null,
    orgName: null,
    event: 'auth.login_failed',
    domain: LogDomain.auth,
    severity: LogSeverity.warning,
    auditableType: null,
    auditableId: null,
    oldValues: null,
    newValues: {'email': 'unknown@attempt.io', 'attempts': 5},
    ipAddress: '185.220.101.52',
    userAgent: 'python-requests/2.31.0',
    createdAt: _now.subtract(const Duration(hours: 2, minutes: 30)),
  ),
  _AuditLog(
    id: 10434,
    tenantName: 'PharmaOS',
    userName: 'Ali Msangi',
    userEmail: 'ali@barikipharma.co.tz',
    orgName: 'Bariki Pharmaceuticals',
    event: 'payment.confirmed',
    domain: LogDomain.payments,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\Payment',
    auditableId: 'pay0331',
    oldValues: {'status': 'pending'},
    newValues: {
      'status': 'confirmed',
      'amount': 850000,
      'method': 'mpesa',
      'transaction_reference': 'OEI20260228K4WR',
    },
    ipAddress: '197.156.91.5',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0)',
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),
  _AuditLog(
    id: 10433,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'product.created',
    domain: LogDomain.products,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\MasterProduct',
    auditableId: 'mp031',
    oldValues: null,
    newValues: {
      'name': 'Artemether + Lumefantrine Paediatric',
      'dosage_form': 'tablet',
      'strength': '20mg/120mg',
      'requires_prescription': true,
    },
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(hours: 4, minutes: 15)),
  ),
  _AuditLog(
    id: 10432,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'user.suspended',
    domain: LogDomain.users,
    severity: LogSeverity.critical,
    auditableType: 'App\\Models\\User',
    auditableId: 'u008',
    oldValues: {'status': 'active'},
    newValues: {
      'status': 'suspended',
      'reason': 'Policy violation — falsified GPS data',
    },
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),
  // ── Yesterday ─────────────────────────────────────────────────────────────
  _AuditLog(
    id: 10420,
    tenantName: 'PharmaOS',
    userName: 'Robert Mfinanga',
    userEmail: 'robert@tanzapharm.co.tz',
    orgName: 'Tanzapharm Manufacturers',
    event: 'auth.login',
    domain: LogDomain.auth,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\User',
    auditableId: 'u015',
    oldValues: null,
    newValues: {'method': 'email_password', 'device': 'mobile'},
    ipAddress: '197.156.44.8',
    userAgent: 'Flutter/3.19 (Android 12)',
    createdAt: _now.subtract(const Duration(hours: 26)),
  ),
  _AuditLog(
    id: 10419,
    tenantName: 'PharmaOS',
    userName: 'Christine Kapinga',
    userEmail: 'chris@uyolehealth.co.tz',
    orgName: 'Uyole Health Supplies',
    event: 'org.relationship_created',
    domain: LogDomain.organizations,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\OrgRelationship',
    auditableId: 'rel0044',
    oldValues: null,
    newValues: {
      'parent_org': 'Uyole Health Supplies',
      'child_org': 'Mwanjelwa Pharmacy',
      'pricing_tier': 'Gold',
      'credit_limit': 2000000,
    },
    ipAddress: '197.156.55.3',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0)',
    createdAt: _now.subtract(const Duration(hours: 28)),
  ),
  _AuditLog(
    id: 10418,
    tenantName: 'PharmaOS',
    userName: null,
    userEmail: null,
    orgName: null,
    event: 'system.queue_failed',
    domain: LogDomain.system,
    severity: LogSeverity.critical,
    auditableType: null,
    auditableId: null,
    oldValues: null,
    newValues: {
      'job': 'SendWhatsAppPromotion',
      'queue': 'whatsapp',
      'error': 'WhatsApp API timeout after 30s',
      'failed_at': '2026-02-27T22:10:00Z',
      'attempts': 3,
    },
    ipAddress: null,
    userAgent: null,
    createdAt: _now.subtract(const Duration(hours: 30)),
  ),
  _AuditLog(
    id: 10417,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'org.onboarded',
    domain: LogDomain.organizations,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\Organization',
    auditableId: 'o004',
    oldValues: null,
    newValues: {
      'name': 'Tanzapharm Manufacturers',
      'type': 'manufacturer',
      'territory': 'Dar es Salaam',
      'plan': 'starter',
    },
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(hours: 33)),
  ),
  _AuditLog(
    id: 10416,
    tenantName: 'PharmaOS',
    userName: 'Neema Chambo',
    userEmail: 'neema@swiftmed.co.tz',
    orgName: 'Swift Med Logistics',
    event: 'inventory.stock_adjusted',
    domain: LogDomain.inventory,
    severity: LogSeverity.warning,
    auditableType: 'App\\Models\\InventoryBatch',
    auditableId: 'b0199',
    oldValues: {'quantity_available': 2400},
    newValues: {
      'quantity_available': 2100,
      'reason': 'Damaged goods write-off',
      'movement_type': 'WRITE_OFF',
    },
    ipAddress: '197.156.66.2',
    userAgent: 'Flutter/3.19 (iOS 16.5)',
    createdAt: _now.subtract(const Duration(hours: 35)),
  ),
  _AuditLog(
    id: 10415,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'auth.two_factor_disabled',
    domain: LogDomain.auth,
    severity: LogSeverity.security,
    auditableType: 'App\\Models\\User',
    auditableId: 'u017',
    oldValues: {'two_factor_enabled': true},
    newValues: {'two_factor_enabled': false},
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(hours: 38)),
  ),
  // ── This week ─────────────────────────────────────────────────────────────
  _AuditLog(
    id: 10400,
    tenantName: 'PharmaOS',
    userName: 'Hassan Mwambe',
    userEmail: 'hassan@mwanjelwa.co.tz',
    orgName: 'Mwanjelwa Pharmacy',
    event: 'order.cancelled',
    domain: LogDomain.orders,
    severity: LogSeverity.warning,
    auditableType: 'App\\Models\\Order',
    auditableId: 'ORD-2026-00131',
    oldValues: {'status': 'submitted'},
    newValues: {
      'status': 'cancelled',
      'cancel_reason': 'Stock unavailable at distributor',
    },
    ipAddress: '197.156.100.7',
    userAgent: 'Flutter/3.19 (Android 13)',
    createdAt: _now.subtract(const Duration(days: 3, hours: 4)),
  ),
  _AuditLog(
    id: 10390,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'system.settings_updated',
    domain: LogDomain.system,
    severity: LogSeverity.warning,
    auditableType: null,
    auditableId: null,
    oldValues: {'near_expiry_threshold_days': 60},
    newValues: {'near_expiry_threshold_days': 90},
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(days: 4, hours: 2)),
  ),
  _AuditLog(
    id: 10385,
    tenantName: 'PharmaOS',
    userName: 'Ali Msangi',
    userEmail: 'ali@barikipharma.co.tz',
    orgName: 'Bariki Pharmaceuticals',
    event: 'commission.approved',
    domain: LogDomain.payments,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\CommissionRecord',
    auditableId: 'cr0088',
    oldValues: {'status': 'pending'},
    newValues: {
      'status': 'approved',
      'amount': 127500,
      'officer': 'Fatuma Hassan',
      'period': 'Feb 2026',
    },
    ipAddress: '197.156.91.5',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0)',
    createdAt: _now.subtract(const Duration(days: 5, hours: 1)),
  ),
  _AuditLog(
    id: 10370,
    tenantName: 'PharmaOS',
    userName: null,
    userEmail: null,
    orgName: null,
    event: 'system.backup_completed',
    domain: LogDomain.system,
    severity: LogSeverity.info,
    auditableType: null,
    auditableId: null,
    oldValues: null,
    newValues: {
      'backup_size_mb': 2840,
      'destination': 's3://pharmoos-backups',
      'duration_seconds': 142,
    },
    ipAddress: null,
    userAgent: null,
    createdAt: _now.subtract(const Duration(days: 5, hours: 23)),
  ),
  _AuditLog(
    id: 10360,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'org.plan_upgraded',
    domain: LogDomain.organizations,
    severity: LogSeverity.info,
    auditableType: 'App\\Models\\TenantSubscription',
    auditableId: 'sub0006',
    oldValues: {'plan': 'starter', 'price_monthly': 150000},
    newValues: {
      'plan': 'professional',
      'price_monthly': 450000,
      'billing_cycle': 'annual',
    },
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(days: 6, hours: 3)),
  ),
  // ── Older ─────────────────────────────────────────────────────────────────
  _AuditLog(
    id: 10200,
    tenantName: 'PharmaOS',
    userName: 'Platform Admin',
    userEmail: 'admin@pharmoos.io',
    orgName: null,
    event: 'user.role_changed',
    domain: LogDomain.users,
    severity: LogSeverity.warning,
    auditableType: 'App\\Models\\User',
    auditableId: 'u002',
    oldValues: {'role': 'marketing_officer'},
    newValues: {'role': 'sales_supervisor'},
    ipAddress: '41.220.15.4',
    userAgent: 'Mozilla/5.0 (Macintosh)',
    createdAt: _now.subtract(const Duration(days: 12)),
  ),
  _AuditLog(
    id: 10100,
    tenantName: 'PharmaOS',
    userName: null,
    userEmail: null,
    orgName: null,
    event: 'auth.login_failed',
    domain: LogDomain.auth,
    severity: LogSeverity.security,
    auditableType: null,
    auditableId: null,
    oldValues: null,
    newValues: {
      'email': 'admin@pharmoos.io',
      'attempts': 8,
      'locked_until': '2026-02-16T03:00:00Z',
    },
    ipAddress: '94.102.49.190',
    userAgent: 'curl/7.88.1',
    createdAt: _now.subtract(const Duration(days: 14)),
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  String _search = '';
  LogSeverity? _severityFilter;
  LogDomain? _domainFilter;
  DateRange _dateRange = DateRange.all;
  bool _showSearch = false;
  bool _isRefreshing = false;
  final _searchCtrl = TextEditingController();
  final Set<int> _expanded = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  List<_AuditLog> get _filtered {
    final now = DateTime.now();
    return _logs.where((l) {
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          l.event.toLowerCase().contains(q) ||
          (l.userName?.toLowerCase().contains(q) ?? false) ||
          (l.orgName?.toLowerCase().contains(q) ?? false) ||
          (l.ipAddress?.contains(q) ?? false) ||
          (l.auditableId?.toLowerCase().contains(q) ?? false);

      final matchSeverity =
          _severityFilter == null || l.severity == _severityFilter;
      final matchDomain = _domainFilter == null || l.domain == _domainFilter;

      final matchDate = switch (_dateRange) {
        DateRange.today => l.createdAt.isAfter(
          DateTime(now.year, now.month, now.day),
        ),
        DateRange.yesterday =>
          l.createdAt.isAfter(DateTime(now.year, now.month, now.day - 1)) &&
              l.createdAt.isBefore(DateTime(now.year, now.month, now.day)),
        DateRange.last7 => l.createdAt.isAfter(
          now.subtract(const Duration(days: 7)),
        ),
        DateRange.last30 => l.createdAt.isAfter(
          now.subtract(const Duration(days: 30)),
        ),
        DateRange.all => true,
      };

      return matchSearch && matchSeverity && matchDomain && matchDate;
    }).toList();
  }

  // ── Group by date ─────────────────────────────────────────────────────────

  Map<String, List<_AuditLog>> get _grouped {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<_AuditLog>>{};
    for (final l in _filtered) {
      final d = DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day);
      final String key;
      if (!d.isBefore(today)) {
        key = 'Today';
      } else if (!d.isBefore(yesterday)) {
        key = 'Yesterday';
      } else if (!d.isBefore(weekAgo)) {
        key = 'This Week';
      } else {
        key = 'Older';
      }
      (groups[key] ??= []).add(l);
    }
    return groups;
  }

  // KPIs
  int get _todayCount {
    final cutoff = DateTime(_now.year, _now.month, _now.day);
    return _logs.where((l) => l.createdAt.isAfter(cutoff)).length;
  }

  int get _criticalCount =>
      _logs.where((l) => l.severity == LogSeverity.critical).length;

  int get _securityCount =>
      _logs.where((l) => l.severity == LogSeverity.security).length;

  int get _warningCount =>
      _logs.where((l) => l.severity == LogSeverity.warning).length;

  bool get _hasFilters =>
      _severityFilter != null ||
      _domainFilter != null ||
      _dateRange != DateRange.all ||
      _search.isNotEmpty;

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() => _isRefreshing = false);
    _snack('Audit log refreshed');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grouped = _grouped;
    final groupOrder = ['Today', 'Yesterday', 'This Week', 'Older'];

    // Flatten to sliver-friendly list: header + items
    final items = <_ListItem>[];
    for (final key in groupOrder) {
      final entries = grouped[key];
      if (entries == null || entries.isEmpty) continue;
      items.add(_HeaderItem(key, entries.length));
      for (final l in entries) {
        items.add(_LogItem(l));
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // ── Page header ────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── KPI strip ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _KpiRow(
                total: _logs.length,
                todayCount: _todayCount,
                critical: _criticalCount,
                security: _securityCount,
                warnings: _warningCount,
              ),
            ),

            // ── Domain pill filter ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: _DomainRail(
                selected: _domainFilter,
                onSelect: (d) => setState(
                  () => _domainFilter = _domainFilter == d ? null : d,
                ),
              ),
            ),

            // ── Filter controls bar ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _ControlBar(
                severityFilter: _severityFilter,
                dateRange: _dateRange,
                hasFilters: _hasFilters,
                resultCount: _filtered.length,
                isRefreshing: _isRefreshing,
                onSeverity: (s) => setState(
                  () => _severityFilter = _severityFilter == s ? null : s,
                ),
                onDateRange: () => _showDateSheet(),
                onClearFilters: _clearFilters,
                onExport: () =>
                    _snack('Exporting ${_filtered.length} records to CSV…'),
                onFilter: () => _showFilterSheet(),
              ),
            ),

            // ── Log entries ────────────────────────────────────────────────
            if (items.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  hasFilters: _hasFilters,
                  onClear: _clearFilters,
                ),
              )
            else
              SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final item = items[i];
                  return switch (item) {
                    _HeaderItem(:final label, :final count) => _GroupHeader(
                      label: label,
                      count: count,
                    ),
                    _LogItem(:final log) => _LogTile(
                      log: log,
                      isExpanded: _expanded.contains(log.id),
                      onToggle: () => setState(
                        () => _expanded.contains(log.id)
                            ? _expanded.remove(log.id)
                            : _expanded.add(log.id),
                      ),
                      onCopyId: () {
                        if (log.auditableId != null) {
                          Clipboard.setData(
                            ClipboardData(text: log.auditableId!),
                          );
                          _snack('Copied ${log.auditableId}');
                        }
                      },
                      onCopyIp: () {
                        if (log.ipAddress != null) {
                          Clipboard.setData(
                            ClipboardData(text: log.ipAddress!),
                          );
                          _snack('Copied ${log.ipAddress}');
                        }
                      },
                    ),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                size: 12,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SUPER ADMIN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red.shade700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live indicator
                        _LiveDot(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Audit Logs',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Immutable activity trail — every action across all tenants',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: () => setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _search = '';
                    _searchCtrl.clear();
                  }
                }),
                icon: Icon(
                  _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                onPressed: () =>
                    _snack('Exporting ${_filtered.length} records…'),
                icon: const Icon(Icons.download_outlined, size: 20),
                tooltip: 'Export CSV',
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _showSearch
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (q) => setState(() => _search = q),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            'Search event, user, org, IP address, record ID…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _clearFilters() => setState(() {
    _severityFilter = null;
    _domainFilter = null;
    _dateRange = DateRange.all;
    _search = '';
    _searchCtrl.clear();
    _showSearch = false;
  });

  void _showDateSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DateRangeSheet(
        current: _dateRange,
        onSelect: (r) {
          setState(() => _dateRange = r);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        severity: _severityFilter,
        domain: _domainFilter,
        dateRange: _dateRange,
        onApply: (s, d, r) {
          setState(() {
            _severityFilter = s;
            _domainFilter = d;
            _dateRange = r;
          });
          Navigator.pop(context);
        },
        onClear: () {
          _clearFilters();
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Live dot ─────────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: _pulse.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: _pulse.value * 0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int total, todayCount, critical, security, warnings;

  const _KpiRow({
    required this.total,
    required this.todayCount,
    required this.critical,
    required this.security,
    required this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _KpiCard(
            value: '$total',
            label: 'Total Events',
            sublabel: 'all time',
            icon: Icons.receipt_long_outlined,
            color: colorScheme.primary,
            flex: 3,
          ),
          const SizedBox(width: 8),
          _KpiCard(
            value: '$todayCount',
            label: 'Today',
            sublabel: 'last 24h',
            icon: Icons.today_outlined,
            color: Colors.teal,
            flex: 2,
          ),
          const SizedBox(width: 8),
          _KpiCard(
            value: '$critical',
            label: 'Critical',
            sublabel: 'need review',
            icon: Icons.error_outline_rounded,
            color: Colors.red,
            flex: 2,
          ),
          const SizedBox(width: 8),
          _KpiCard(
            value: '$security',
            label: 'Security',
            sublabel: 'auth events',
            icon: Icons.security_outlined,
            color: Colors.orange,
            flex: 2,
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value, label, sublabel;
  final IconData icon;
  final Color color;
  final int flex;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sublabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Domain Rail ─────────────────────────────────────────────────────────────

class _DomainRail extends StatelessWidget {
  final LogDomain? selected;
  final ValueChanged<LogDomain> onSelect;

  const _DomainRail({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LogDomain.values.map((d) {
            final isSel = selected == d;
            final color = _domainColor(d);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? color.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel
                          ? color.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _domainIcon(d),
                        size: 13,
                        color: isSel ? color : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _domainLabel(d),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? color : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Control Bar ─────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  final LogSeverity? severityFilter;
  final DateRange dateRange;
  final bool hasFilters;
  final int resultCount;
  final bool isRefreshing;
  final ValueChanged<LogSeverity> onSeverity;
  final VoidCallback onDateRange;
  final VoidCallback onClearFilters;
  final VoidCallback onExport;
  final VoidCallback onFilter;

  const _ControlBar({
    required this.severityFilter,
    required this.dateRange,
    required this.hasFilters,
    required this.resultCount,
    required this.isRefreshing,
    required this.onSeverity,
    required this.onDateRange,
    required this.onClearFilters,
    required this.onExport,
    required this.onFilter,
  });

  String get _dateLabel => switch (dateRange) {
    DateRange.today => 'Today',
    DateRange.yesterday => 'Yesterday',
    DateRange.last7 => 'Last 7 days',
    DateRange.last30 => 'Last 30 days',
    DateRange.all => 'All time',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Count + controls
          Row(
            children: [
              if (isRefreshing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              else
                Icon(
                  Icons.list_alt_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              const SizedBox(width: 6),
              Text(
                '$resultCount event${resultCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasFilters) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'filtered',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Date range
              GestureDetector(
                onTap: onDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: dateRange != DateRange.all
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: dateRange != DateRange.all
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 13,
                        color: dateRange != DateRange.all
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dateRange != DateRange.all
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded, size: 18),
                visualDensity: VisualDensity.compact,
                tooltip: 'More filters',
              ),
              if (hasFilters)
                IconButton(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Clear filters',
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Severity quick filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SevChip(
                  label: 'All',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  selected: severityFilter == null,
                  onTap: () {},
                ),
                const SizedBox(width: 8),
                ...LogSeverity.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SevChip(
                      label: _severityLabel(s),
                      color: _severityColor(s),
                      selected: severityFilter == s,
                      onTap: () => onSeverity(s),
                      icon: _severityIcon(s),
                    ),
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

class _SevChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SevChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: selected ? color : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Group Header ─────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;

  const _GroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      color: colorScheme.surface,
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Tile ─────────────────────────────────────────────────────────────────

class _LogTile extends StatelessWidget {
  final _AuditLog log;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onCopyId;
  final VoidCallback onCopyIp;

  const _LogTile({
    required this.log,
    required this.isExpanded,
    required this.onToggle,
    required this.onCopyId,
    required this.onCopyIp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sevColor = _severityColor(log.severity);
    final isSystem = log.userName == null;

    return InkWell(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isExpanded
              ? sevColor.withValues(alpha: 0.03)
              : Colors.transparent,
          border: isExpanded
              ? Border(left: BorderSide(color: sevColor, width: 3))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity dot + domain icon
                  Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _domainColor(
                                log.domain,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _domainIcon(log.domain),
                              size: 18,
                              color: _domainColor(log.domain),
                            ),
                          ),
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: sevColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event name + time
                        Row(
                          children: [
                            Expanded(child: _EventLabel(event: log.event)),
                            const SizedBox(width: 8),
                            Text(
                              _timeLabel(log.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Actor row
                        Row(
                          children: [
                            if (isSystem)
                              _ActorChip(
                                label: 'System',
                                icon: Icons.smart_toy_outlined,
                                color: colorScheme.onSurfaceVariant,
                              )
                            else ...[
                              Icon(
                                Icons.person_outline,
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                log.userName!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (log.orgName != null) ...[
                              Text(
                                ' · ',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Icon(
                                Icons.domain_outlined,
                                size: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  log.orgName!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (log.auditableId != null) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: onCopyId,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tag_rounded,
                                  size: 11,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  log.auditableId!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.copy_outlined,
                                  size: 9,
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Expand chevron
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ],
              ),

              // ── Expanded payload ──────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12, left: 48),
                        child: _LogPayload(log: log, onCopyIp: onCopyIp),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Event Label (domain.action chips) ───────────────────────────────────────

class _EventLabel extends StatelessWidget {
  final String event;

  const _EventLabel({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = event.split('.');
    final domain = parts.length > 1 ? parts[0] : '';
    final action = parts.length > 1 ? parts.sublist(1).join('.') : event;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            domain,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '.',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        Flexible(
          child: Text(
            action,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActorChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ActorChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Payload (expanded diff view) ────────────────────────────────────────

class _LogPayload extends StatelessWidget {
  final _AuditLog log;
  final VoidCallback onCopyIp;

  const _LogPayload({required this.log, required this.onCopyIp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta row: IP + user agent + timestamp
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.ipAddress != null)
                GestureDetector(
                  onTap: onCopyIp,
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        log.ipAddress!,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy_outlined,
                        size: 9,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              if (log.userAgent != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.devices_outlined,
                      size: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        log.userAgent!,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _fullTimestamp(log.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.tag_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Log ID: #${log.id}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Diff viewer
        if (log.oldValues != null || log.newValues != null) ...[
          const SizedBox(height: 8),
          if (log.oldValues != null) ...[
            _DiffBlock(
              label: 'BEFORE',
              data: log.oldValues!,
              color: Colors.red,
              icon: Icons.remove_circle_outline,
            ),
            const SizedBox(height: 6),
          ],
          if (log.newValues != null)
            _DiffBlock(
              label: 'AFTER',
              data: log.newValues!,
              color: Colors.green,
              icon: Icons.add_circle_outline,
            ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  String _fullTimestamp(DateTime dt) {
    final pad = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} '
        '${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)} UTC';
  }
}

class _DiffBlock extends StatelessWidget {
  final String label;
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;

  const _DiffBlock({
    required this.label,
    required this.data,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(9),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Key-value pairs
          ...data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      e.key,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${e.value}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: color.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Sheets ───────────────────────────────────────────────────────────────────

class _DateRangeSheet extends StatelessWidget {
  final DateRange current;
  final ValueChanged<DateRange> onSelect;

  const _DateRangeSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final opts = [
      (DateRange.today, 'Today', Icons.wb_sunny_outlined),
      (DateRange.yesterday, 'Yesterday', Icons.history_outlined),
      (DateRange.last7, 'Last 7 days', Icons.date_range_outlined),
      (DateRange.last30, 'Last 30 days', Icons.calendar_month_outlined),
      (DateRange.all, 'All time', Icons.all_inclusive_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Date Range',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...opts.map((o) {
            final (range, label, icon) = o;
            final sel = current == range;
            return ListTile(
              leading: Icon(icon, color: sel ? colorScheme.primary : null),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  color: sel ? colorScheme.primary : null,
                ),
              ),
              trailing: sel
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () => onSelect(range),
              selected: sel,
              selectedTileColor: colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final LogSeverity? severity;
  final LogDomain? domain;
  final DateRange dateRange;
  final void Function(LogSeverity?, LogDomain?, DateRange) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.severity,
    required this.domain,
    required this.dateRange,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  LogSeverity? _severity;
  LogDomain? _domain;
  DateRange _dateRange = DateRange.all;

  @override
  void initState() {
    super.initState();
    _severity = widget.severity;
    _domain = widget.domain;
    _dateRange = widget.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Filter Logs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _severity = null;
                      _domain = null;
                      _dateRange = DateRange.all;
                    });
                    widget.onClear();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Severity
            Text(
              'Severity',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: LogSeverity.values
                  .map(
                    (s) => FilterChip(
                      avatar: Icon(
                        _severityIcon(s),
                        size: 14,
                        color: _severityColor(s),
                      ),
                      label: Text(_severityLabel(s)),
                      selected: _severity == s,
                      onSelected: (_) =>
                          setState(() => _severity = _severity == s ? null : s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Domain
            Text(
              'Domain',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: LogDomain.values
                  .map(
                    (d) => FilterChip(
                      avatar: Icon(_domainIcon(d), size: 14),
                      label: Text(_domainLabel(d)),
                      selected: _domain == d,
                      onSelected: (_) =>
                          setState(() => _domain = _domain == d ? null : d),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onApply(_severity, _domain, _dateRange),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.manage_search_rounded
                  : Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matching events' : 'No events yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your filters or date range.'
                  : 'Activity will appear here as users interact with the platform.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sealed list items (for SliverList) ──────────────────────────────────────

sealed class _ListItem {}

final class _HeaderItem extends _ListItem {
  final String label;
  final int count;
  _HeaderItem(this.label, this.count);
}

final class _LogItem extends _ListItem {
  final _AuditLog log;
  _LogItem(this.log);
}

// ─── Domain helpers ───────────────────────────────────────────────────────────

Color _domainColor(LogDomain d) => switch (d) {
  LogDomain.auth => Colors.orange,
  LogDomain.users => Colors.indigo,
  LogDomain.organizations => Colors.teal,
  LogDomain.orders => Colors.blue,
  LogDomain.inventory => Colors.amber.shade700,
  LogDomain.payments => Colors.green,
  LogDomain.products => Colors.purple,
  LogDomain.system => Colors.grey,
};

IconData _domainIcon(LogDomain d) => switch (d) {
  LogDomain.auth => Icons.lock_outline_rounded,
  LogDomain.users => Icons.person_outline,
  LogDomain.organizations => Icons.domain_outlined,
  LogDomain.orders => Icons.receipt_long_outlined,
  LogDomain.inventory => Icons.inventory_2_outlined,
  LogDomain.payments => Icons.payments_outlined,
  LogDomain.products => Icons.medication_outlined,
  LogDomain.system => Icons.settings_outlined,
};

String _domainLabel(LogDomain d) => switch (d) {
  LogDomain.auth => 'Auth',
  LogDomain.users => 'Users',
  LogDomain.organizations => 'Orgs',
  LogDomain.orders => 'Orders',
  LogDomain.inventory => 'Inventory',
  LogDomain.payments => 'Payments',
  LogDomain.products => 'Products',
  LogDomain.system => 'System',
};

// ─── Severity helpers ─────────────────────────────────────────────────────────

Color _severityColor(LogSeverity s) => switch (s) {
  LogSeverity.info => Colors.blue,
  LogSeverity.warning => Colors.orange,
  LogSeverity.critical => Colors.red,
  LogSeverity.security => Colors.deepPurple,
};

IconData _severityIcon(LogSeverity s) => switch (s) {
  LogSeverity.info => Icons.info_outline_rounded,
  LogSeverity.warning => Icons.warning_amber_rounded,
  LogSeverity.critical => Icons.error_outline_rounded,
  LogSeverity.security => Icons.security_outlined,
};

String _severityLabel(LogSeverity s) => switch (s) {
  LogSeverity.info => 'Info',
  LogSeverity.warning => 'Warning',
  LogSeverity.critical => 'Critical',
  LogSeverity.security => 'Security',
};
