// organization_dashboard_page.dart
// Organizations Dashboard — Super Admin / Org Admin view
//
// Shows platform-wide org health at a glance:
//   - Summary KPI cards (total, active, by type)
//   - Type breakdown chips
//   - Territory distribution
//   - Recent organizations with quick-status
//   - Quick actions (add org, export, verify)
//
// No AppBar. No Drawer. Pure page content.
// Drop into ShellNavItems.buildTabs() as-is.
//
// Location: features/organization/presentation/pages/organization_dashboard_page.dart

import 'package:flutter/material.dart';

// ─── Lightweight local models (replace with real domain models) ──────────────

enum OrgStatus { active, inactive, pending, suspended }

enum OrgType { pharmacy, distributor, supplier, manufacturer, logistics }

class _OrgSummary {
  final String id;
  final String name;
  final String slug;
  final List<OrgType> types;
  final OrgStatus status;
  final String territory;
  final int userCount;
  final int activeOrders;
  final bool isVerified;
  final DateTime lastActive;
  final String? logoInitials;

  const _OrgSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.types,
    required this.status,
    required this.territory,
    required this.userCount,
    required this.activeOrders,
    required this.isVerified,
    required this.lastActive,
    this.logoInitials,
  });
}

// ─── Mock data (wire to OrgBloc / repository later) ─────────────────────────

final List<_OrgSummary> _mockOrgs = [
  _OrgSummary(
    id: '01HX001',
    name: 'Bariki Pharmaceuticals',
    slug: 'bariki-pharma',
    types: [OrgType.distributor, OrgType.pharmacy],
    status: OrgStatus.active,
    territory: 'Mbeya Region',
    userCount: 14,
    activeOrders: 23,
    isVerified: true,
    lastActive: DateTime.now().subtract(const Duration(hours: 1)),
    logoInitials: 'BP',
  ),
  _OrgSummary(
    id: '01HX002',
    name: 'Mwanjelwa Pharmacy',
    slug: 'mwanjelwa-pharmacy',
    types: [OrgType.pharmacy],
    status: OrgStatus.active,
    territory: 'Mbeya District',
    userCount: 3,
    activeOrders: 5,
    isVerified: true,
    lastActive: DateTime.now().subtract(const Duration(hours: 3)),
    logoInitials: 'MP',
  ),
  _OrgSummary(
    id: '01HX003',
    name: 'Uyole Health Supplies',
    slug: 'uyole-health',
    types: [OrgType.supplier, OrgType.distributor],
    status: OrgStatus.active,
    territory: 'Mbeya District',
    userCount: 8,
    activeOrders: 11,
    isVerified: true,
    lastActive: DateTime.now().subtract(const Duration(hours: 5)),
    logoInitials: 'UH',
  ),
  _OrgSummary(
    id: '01HX004',
    name: 'Tanzapharm Manufacturers',
    slug: 'tanzapharm',
    types: [OrgType.manufacturer],
    status: OrgStatus.pending,
    territory: 'Dar es Salaam',
    userCount: 2,
    activeOrders: 0,
    isVerified: false,
    lastActive: DateTime.now().subtract(const Duration(days: 2)),
    logoInitials: 'TM',
  ),
  _OrgSummary(
    id: '01HX005',
    name: 'Kariakoo MedStore',
    slug: 'kariakoo-med',
    types: [OrgType.pharmacy],
    status: OrgStatus.inactive,
    territory: 'Dar es Salaam',
    userCount: 1,
    activeOrders: 0,
    isVerified: true,
    lastActive: DateTime.now().subtract(const Duration(days: 14)),
    logoInitials: 'KM',
  ),
  _OrgSummary(
    id: '01HX006',
    name: 'Swift Med Logistics',
    slug: 'swift-med',
    types: [OrgType.logistics],
    status: OrgStatus.active,
    territory: 'Southern Highlands',
    userCount: 6,
    activeOrders: 18,
    isVerified: true,
    lastActive: DateTime.now().subtract(const Duration(minutes: 20)),
    logoInitials: 'SL',
  ),
  _OrgSummary(
    id: '01HX007',
    name: 'Njombe District Pharmacy',
    slug: 'njombe-pharmacy',
    types: [OrgType.pharmacy],
    status: OrgStatus.suspended,
    territory: 'Njombe Region',
    userCount: 2,
    activeOrders: 0,
    isVerified: false,
    lastActive: DateTime.now().subtract(const Duration(days: 30)),
    logoInitials: 'NP',
  ),
];

// ─── Page ────────────────────────────────────────────────────────────────────

class OrganizationDashboardPage extends StatefulWidget {
  const OrganizationDashboardPage({super.key});

  @override
  State<OrganizationDashboardPage> createState() =>
      _OrganizationDashboardPageState();
}

class _OrganizationDashboardPageState extends State<OrganizationDashboardPage> {
  String _searchQuery = '';
  OrgStatus? _statusFilter;
  OrgType? _typeFilter;
  final Set<String> _selected = {};
  bool _isLoading = false;

  List<_OrgSummary> get _filtered {
    return _mockOrgs.where((o) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          o.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.territory.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _statusFilter == null || o.status == _statusFilter;
      final matchesType = _typeFilter == null || o.types.contains(_typeFilter);
      return matchesSearch && matchesStatus && matchesType;
    }).toList();
  }

  // ── Derived stats ──────────────────────────────────────────────────────────

  int get _totalOrgs => _mockOrgs.length;
  int get _activeOrgs =>
      _mockOrgs.where((o) => o.status == OrgStatus.active).length;
  int get _pendingVerification => _mockOrgs.where((o) => !o.isVerified).length;
  int get _suspendedOrgs =>
      _mockOrgs.where((o) => o.status == OrgStatus.suspended).length;
  int get _totalUsers => _mockOrgs.fold(0, (sum, o) => sum + o.userCount);
  int get _totalActiveOrders =>
      _mockOrgs.fold(0, (sum, o) => sum + o.activeOrders);

  Map<OrgType, int> get _typeBreakdown {
    final counts = <OrgType, int>{};
    for (final org in _mockOrgs) {
      for (final type in org.types) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _toggleSelect(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  void _selectAll() => setState(() {
    if (_selected.length == _filtered.length) {
      _selected.clear();
    } else {
      _selected.addAll(_filtered.map((o) => o.id));
    }
  });

  void _clearSelection() => setState(() => _selected.clear());

  void _showBulkActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BulkActionSheet(
        count: _selected.length,
        onAction: (action) {
          Navigator.pop(context);
          _clearSelection();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$action applied to ${_selected.isEmpty ? 0 : _selected.length} organizations',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showAddOrgDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Add Organization form'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActionSheet,
              icon: const Icon(Icons.checklist_rounded),
              label: Text('${_selected.length} selected'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : FloatingActionButton(
              onPressed: _showAddOrgDialog,
              tooltip: 'Add Organization',
              child: const Icon(Icons.add_business_outlined),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await Future.delayed(const Duration(seconds: 1));
          setState(() => _isLoading = false);
        },
        child: CustomScrollView(
          slivers: [
            // ── Page header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _PageHeader(
                totalOrgs: _totalOrgs,
                onExport: () {},
                onFilter: () => _showFilterSheet(context),
              ),
            ),

            // ── KPI cards ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _KpiSection(
                active: _activeOrgs,
                total: _totalOrgs,
                pending: _pendingVerification,
                suspended: _suspendedOrgs,
                totalUsers: _totalUsers,
                totalOrders: _totalActiveOrders,
              ),
            ),

            // ── Type breakdown ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _TypeBreakdownSection(breakdown: _typeBreakdown),
            ),

            // ── Search + filter bar ───────────────────────────────────────
            SliverToBoxAdapter(
              child: _SearchAndFilterBar(
                query: _searchQuery,
                statusFilter: _statusFilter,
                typeFilter: _typeFilter,
                selectedCount: _selected.length,
                totalCount: _filtered.length,
                onSearch: (q) => setState(() => _searchQuery = q),
                onStatusFilter: (s) => setState(() => _statusFilter = s),
                onTypeFilter: (t) => setState(() => _typeFilter = t),
                onSelectAll: _selectAll,
                onClearSelection: _clearSelection,
                allSelected:
                    _selected.length == _filtered.length &&
                    _filtered.isNotEmpty,
              ),
            ),

            // ── Org list ──────────────────────────────────────────────────
            if (_filtered.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  hasFilters:
                      _searchQuery.isNotEmpty ||
                      _statusFilter != null ||
                      _typeFilter != null,
                  onClear: () => setState(() {
                    _searchQuery = '';
                    _statusFilter = null;
                    _typeFilter = null;
                  }),
                ),
              )
            else
              SliverList.separated(
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final org = _filtered[index];
                  return _OrgListTile(
                    org: org,
                    isSelected: _selected.contains(org.id),
                    onTap: () {
                      if (_selected.isNotEmpty) {
                        _toggleSelect(org.id);
                      } else {
                        _navigateToOrgDetail(org);
                      }
                    },
                    onLongPress: () => _toggleSelect(org.id),
                    onQuickAction: (action) => _handleQuickAction(action, org),
                  );
                },
              ),

            // ── Bottom padding for FAB ─────────────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  void _navigateToOrgDetail(_OrgSummary org) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Open detail for ${org.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleQuickAction(String action, _OrgSummary org) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action → ${org.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        currentStatus: _statusFilter,
        currentType: _typeFilter,
        onApply: (status, type) {
          setState(() {
            _statusFilter = status;
            _typeFilter = type;
          });
        },
        onClear: () => setState(() {
          _statusFilter = null;
          _typeFilter = null;
        }),
      ),
    );
  }
}

// ─── Page Header ─────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final int totalOrgs;
  final VoidCallback onExport;
  final VoidCallback onFilter;

  const _PageHeader({
    required this.totalOrgs,
    required this.onExport,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
                    Text(
                      'Organizations',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalOrgs organizations on platform',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: onExport,
                icon: const Icon(Icons.download_outlined, size: 20),
                tooltip: 'Export',
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Filters',
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── KPI Section ─────────────────────────────────────────────────────────────

class _KpiSection extends StatelessWidget {
  final int active;
  final int total;
  final int pending;
  final int suspended;
  final int totalUsers;
  final int totalOrders;

  const _KpiSection({
    required this.active,
    required this.total,
    required this.pending,
    required this.suspended,
    required this.totalUsers,
    required this.totalOrders,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Primary row: Active vs Total
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _KpiCard(
                  label: 'Active',
                  value: active.toString(),
                  subtitle: 'of $total total',
                  icon: Icons.domain_verification_outlined,
                  color: Colors.green,
                  progress: total > 0 ? active / total : 0,
                  showProgress: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _KpiCard(
                  label: 'Pending',
                  value: pending.toString(),
                  subtitle: 'need verification',
                  icon: Icons.pending_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _KpiCard(
                  label: 'Suspended',
                  value: suspended.toString(),
                  subtitle: 'access blocked',
                  icon: Icons.block_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Secondary row: Users + Orders
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Platform Users',
                  value: totalUsers.toString(),
                  subtitle: 'across all orgs',
                  icon: Icons.group_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Active Orders',
                  value: totalOrders.toString(),
                  subtitle: 'in progress',
                  icon: Icons.receipt_long_outlined,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'New This Month',
                  value: '2',
                  subtitle: '+2 vs last month',
                  icon: Icons.trending_up_rounded,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;
  final bool showProgress;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (showProgress && progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Type Breakdown ───────────────────────────────────────────────────────────

class _TypeBreakdownSection extends StatelessWidget {
  final Map<OrgType, int> breakdown;

  const _TypeBreakdownSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organization Types',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OrgType.values
                  .where((t) => (breakdown[t] ?? 0) > 0)
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TypeChip(type: type, count: breakdown[type] ?? 0),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final OrgType type;
  final int count;

  const _TypeChip({required this.type, required this.count});

  Color get _color => switch (type) {
    OrgType.pharmacy => Colors.teal,
    OrgType.distributor => Colors.indigo,
    OrgType.supplier => Colors.orange,
    OrgType.manufacturer => Colors.purple,
    OrgType.logistics => Colors.blue,
  };

  IconData get _icon => switch (type) {
    OrgType.pharmacy => Icons.local_pharmacy_outlined,
    OrgType.distributor => Icons.hub_outlined,
    OrgType.supplier => Icons.inventory_2_outlined,
    OrgType.manufacturer => Icons.factory_outlined,
    OrgType.logistics => Icons.local_shipping_outlined,
  };

  String get _label => switch (type) {
    OrgType.pharmacy => 'Pharmacies',
    OrgType.distributor => 'Distributors',
    OrgType.supplier => 'Suppliers',
    OrgType.manufacturer => 'Manufacturers',
    OrgType.logistics => 'Logistics',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            '$count $_label',
            style: theme.textTheme.labelMedium?.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search & Filter Bar ──────────────────────────────────────────────────────

class _SearchAndFilterBar extends StatelessWidget {
  final String query;
  final OrgStatus? statusFilter;
  final OrgType? typeFilter;
  final int selectedCount;
  final int totalCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<OrgStatus?> onStatusFilter;
  final ValueChanged<OrgType?> onTypeFilter;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final bool allSelected;

  const _SearchAndFilterBar({
    required this.query,
    required this.statusFilter,
    required this.typeFilter,
    required this.selectedCount,
    required this.totalCount,
    required this.onSearch,
    required this.onStatusFilter,
    required this.onTypeFilter,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.allSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasActiveFilters = statusFilter != null || typeFilter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider header
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedCount > 0
                      ? '$selectedCount of $totalCount selected'
                      : 'All Organizations ($totalCount)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (selectedCount > 0)
                TextButton.icon(
                  onPressed: onSelectAll,
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 16,
                  ),
                  label: Text(allSelected ? 'Deselect All' : 'Select All'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Search
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search by name or territory…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => onSearch(''),
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
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
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filters
                ...OrgStatus.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_statusLabel(s)),
                      avatar: Icon(
                        _statusIcon(s),
                        size: 14,
                        color: statusFilter == s
                            ? Colors.white
                            : _statusColor(s),
                      ),
                      selected: statusFilter == s,
                      onSelected: (_) =>
                          onStatusFilter(statusFilter == s ? null : s),
                      selectedColor: _statusColor(s),
                      labelStyle: TextStyle(
                        color: statusFilter == s
                            ? Colors.white
                            : colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Filters active',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24),
                TextButton(
                  onPressed: () {
                    onStatusFilter(null);
                    onTypeFilter(null);
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _statusLabel(OrgStatus s) => switch (s) {
    OrgStatus.active => 'Active',
    OrgStatus.inactive => 'Inactive',
    OrgStatus.pending => 'Pending',
    OrgStatus.suspended => 'Suspended',
  };

  IconData _statusIcon(OrgStatus s) => switch (s) {
    OrgStatus.active => Icons.check_circle_outline,
    OrgStatus.inactive => Icons.pause_circle_outline,
    OrgStatus.pending => Icons.schedule_outlined,
    OrgStatus.suspended => Icons.block_outlined,
  };

  Color _statusColor(OrgStatus s) => switch (s) {
    OrgStatus.active => Colors.green.shade600,
    OrgStatus.inactive => Colors.grey.shade500,
    OrgStatus.pending => Colors.orange.shade600,
    OrgStatus.suspended => Colors.red.shade600,
  };
}

// ─── Org List Tile ────────────────────────────────────────────────────────────

class _OrgListTile extends StatelessWidget {
  final _OrgSummary org;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(String action) onQuickAction;

  const _OrgListTile({
    required this.org,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onQuickAction,
  });

  Color get _statusColor => switch (org.status) {
    OrgStatus.active => Colors.green,
    OrgStatus.inactive => Colors.grey,
    OrgStatus.pending => Colors.orange,
    OrgStatus.suspended => Colors.red,
  };

  String get _statusLabel => switch (org.status) {
    OrgStatus.active => 'Active',
    OrgStatus.inactive => 'Inactive',
    OrgStatus.pending => 'Pending',
    OrgStatus.suspended => 'Suspended',
  };

  Color get _avatarColor => switch (org.types.first) {
    OrgType.pharmacy => Colors.teal,
    OrgType.distributor => Colors.indigo,
    OrgType.supplier => Colors.orange,
    OrgType.manufacturer => Colors.purple,
    OrgType.logistics => Colors.blue,
  };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / selection indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    )
                  : _OrgAvatar(
                      key: const ValueKey('avatar'),
                      initials: org.logoInitials ?? org.name[0],
                      color: _avatarColor,
                      isVerified: org.isVerified,
                    ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          org.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _statusColor.withValues(alpha: 0.3),
                          ),
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
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Territory + types
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        org.territory,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...org.types
                          .take(2)
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _MiniTypeBadge(type: t),
                            ),
                          ),
                      if (org.types.length > 2)
                        Text(
                          '+${org.types.length - 2}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.people_outline,
                        label: '${org.userCount} users',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.receipt_long_outlined,
                        label: '${org.activeOrders} orders',
                      ),
                      const SizedBox(width: 24),
                      Text(
                        _timeAgo(org.lastActive),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // More actions
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              itemBuilder: (_) => _buildMenuItems(context),
              onSelected: onQuickAction,
              tooltip: 'Actions',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'view',
        child: ListTile(
          leading: Icon(Icons.visibility_outlined, size: 18),
          title: Text('View Details'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: 'edit',
        child: ListTile(
          leading: Icon(Icons.edit_outlined, size: 18),
          title: Text('Edit'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
      const PopupMenuItem(
        value: 'users',
        child: ListTile(
          leading: Icon(Icons.people_outline, size: 18),
          title: Text('Manage Users'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    ];

    if (!org.isVerified) {
      items.add(
        const PopupMenuItem(
          value: 'verify',
          child: ListTile(
            leading: Icon(
              Icons.verified_outlined,
              size: 18,
              color: Colors.green,
            ),
            title: Text(
              'Verify Organization',
              style: TextStyle(color: Colors.green),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      );
    }

    if (org.status == OrgStatus.active) {
      items.add(
        const PopupMenuItem(
          value: 'suspend',
          child: ListTile(
            leading: Icon(
              Icons.pause_circle_outline,
              size: 18,
              color: Colors.orange,
            ),
            title: Text('Suspend', style: TextStyle(color: Colors.orange)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      );
    } else if (org.status == OrgStatus.suspended ||
        org.status == OrgStatus.inactive) {
      items.add(
        const PopupMenuItem(
          value: 'activate',
          child: ListTile(
            leading: Icon(
              Icons.play_circle_outline,
              size: 18,
              color: Colors.green,
            ),
            title: Text('Activate', style: TextStyle(color: Colors.green)),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      );
    }

    return items;
  }
}

class _OrgAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final bool isVerified;

  const _OrgAvatar({
    super.key,
    required this.initials,
    required this.color,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        if (isVerified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 14,
                color: Colors.blue.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniTypeBadge extends StatelessWidget {
  final OrgType type;

  const _MiniTypeBadge({required this.type});

  Color get _color => switch (type) {
    OrgType.pharmacy => Colors.teal,
    OrgType.distributor => Colors.indigo,
    OrgType.supplier => Colors.orange,
    OrgType.manufacturer => Colors.purple,
    OrgType.logistics => Colors.blue,
  };

  String get _label => switch (type) {
    OrgType.pharmacy => 'Pharmacy',
    OrgType.distributor => 'Dist.',
    OrgType.supplier => 'Supplier',
    OrgType.manufacturer => 'Mfr.',
    OrgType.logistics => 'Logistics',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
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
                  : Icons.domain_disabled_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No matches found' : 'No organizations yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters.'
                  : 'Add your first organization to get started.',
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

// ─── Bulk Action Sheet ────────────────────────────────────────────────────────

class _BulkActionSheet extends StatelessWidget {
  final int count;
  final void Function(String) onAction;

  const _BulkActionSheet({required this.count, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          Text(
            'Actions for $count organization${count == 1 ? '' : 's'}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _BulkActionTile(
            icon: Icons.play_circle_outline,
            label: 'Activate selected',
            color: Colors.green,
            onTap: () => onAction('Activate'),
          ),
          _BulkActionTile(
            icon: Icons.pause_circle_outline,
            label: 'Suspend selected',
            color: Colors.orange,
            onTap: () => onAction('Suspend'),
          ),
          _BulkActionTile(
            icon: Icons.verified_outlined,
            label: 'Mark as verified',
            color: Colors.blue,
            onTap: () => onAction('Verify'),
          ),
          _BulkActionTile(
            icon: Icons.download_outlined,
            label: 'Export selected',
            color: Colors.purple,
            onTap: () => onAction('Export'),
          ),
          const Divider(height: 24),
          _BulkActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete selected',
            color: Colors.red,
            onTap: () => onAction('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BulkActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final OrgStatus? currentStatus;
  final OrgType? currentType;
  final void Function(OrgStatus?, OrgType?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.currentStatus,
    required this.currentType,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  OrgStatus? _status;
  OrgType? _type;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _type = widget.currentType;
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
                'Filter Organizations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 24),
              TextButton(
                onPressed: () {
                  setState(() {
                    _status = null;
                    _type = null;
                  });
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Status',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: OrgStatus.values
                .map(
                  (s) => FilterChip(
                    label: Text(_statusLabel(s)),
                    selected: _status == s,
                    onSelected: (_) =>
                        setState(() => _status = _status == s ? null : s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Organization Type',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: OrgType.values
                .map(
                  (t) => FilterChip(
                    label: Text(_typeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) =>
                        setState(() => _type = _type == t ? null : t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_status, _type);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(OrgStatus s) => switch (s) {
    OrgStatus.active => 'Active',
    OrgStatus.inactive => 'Inactive',
    OrgStatus.pending => 'Pending',
    OrgStatus.suspended => 'Suspended',
  };

  String _typeLabel(OrgType t) => switch (t) {
    OrgType.pharmacy => 'Pharmacy',
    OrgType.distributor => 'Distributor',
    OrgType.supplier => 'Supplier',
    OrgType.manufacturer => 'Manufacturer',
    OrgType.logistics => 'Logistics',
  };
}
