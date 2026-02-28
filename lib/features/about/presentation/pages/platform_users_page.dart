// platform_users_page.dart
// Platform Users — Super Admin god-mode view.
//
// Shows ALL users across ALL tenants and organizations on the platform.
// This is NOT an org-scoped view — Super Admin sees everything.
//
// Capabilities:
//   - Summary KPIs: total users, by status, by role tier, new this month
//   - Role distribution visual (all 8 platform roles)
//   - Search: name, email, phone, org name
//   - Filter: by role, by status, by organization, by tenant
//   - Per-user: impersonate, suspend/reactivate, reset password, view org
//   - Bulk actions: suspend batch, activate batch, export
//   - Sort: by name, last login, created date, org
//
// No AppBar. No Drawer. Pure page content.
// Location: features/platform_admin/presentation/pages/platform_users_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum PlatformRole {
  superAdmin,
  orgAdmin,
  salesSupervisor,
  marketingOfficer,
  warehouseStaff,
  financeAccountant,
  deliveryDriver,
  customerRep,
}

enum RoleTier { platform, organization }

enum UserStatus { active, suspended, pending }

enum SortOption { nameAsc, lastLoginDesc, createdDesc, orgName }

// ─── Models ──────────────────────────────────────────────────────────────────

class _PlatformUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final PlatformRole role;
  final UserStatus status;
  final String orgName;
  final String orgId;
  final String orgSlug;
  final String tenantName;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final bool emailVerified;
  final String? avatarInitials;
  final String preferredLanguage;

  const _PlatformUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.orgName,
    required this.orgId,
    required this.orgSlug,
    required this.tenantName,
    this.lastLogin,
    required this.createdAt,
    required this.emailVerified,
    this.avatarInitials,
    this.preferredLanguage = 'sw',
  });
}

// ─── Mock data (46 users across 7 orgs, 2 tenants) ───────────────────────────

final List<_PlatformUser> _allUsers = [
  // ── Bariki Pharmaceuticals ────────────────────────────────────────────────
  _PlatformUser(
    id: 'u001',
    name: 'Amina Mwangi',
    email: 'amina@barikipharma.co.tz',
    phone: '+255 744 001 001',
    role: PlatformRole.orgAdmin,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
    createdAt: DateTime(2024, 3, 15),
    emailVerified: true,
    avatarInitials: 'AM',
  ),
  _PlatformUser(
    id: 'u002',
    name: 'James Kilonzo',
    email: 'james@barikipharma.co.tz',
    phone: '+255 756 002 002',
    role: PlatformRole.salesSupervisor,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
    createdAt: DateTime(2024, 3, 16),
    emailVerified: true,
    avatarInitials: 'JK',
  ),
  _PlatformUser(
    id: 'u003',
    name: 'Fatuma Hassan',
    email: 'fatuma@barikipharma.co.tz',
    phone: '+255 712 003 003',
    role: PlatformRole.marketingOfficer,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 5)),
    createdAt: DateTime(2024, 3, 17),
    emailVerified: true,
    avatarInitials: 'FH',
  ),
  _PlatformUser(
    id: 'u004',
    name: 'Peter Ngowi',
    email: 'peter@barikipharma.co.tz',
    phone: '+255 768 004 004',
    role: PlatformRole.marketingOfficer,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 1)),
    createdAt: DateTime(2024, 3, 17),
    emailVerified: true,
    avatarInitials: 'PN',
  ),
  _PlatformUser(
    id: 'u005',
    name: 'Grace Malale',
    email: 'grace@barikipharma.co.tz',
    phone: '+255 723 005 005',
    role: PlatformRole.warehouseStaff,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
    createdAt: DateTime(2024, 3, 18),
    emailVerified: true,
    avatarInitials: 'GM',
  ),
  _PlatformUser(
    id: 'u006',
    name: 'Ali Msangi',
    email: 'ali@barikipharma.co.tz',
    phone: '+255 745 006 006',
    role: PlatformRole.financeAccountant,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 4)),
    createdAt: DateTime(2024, 3, 18),
    emailVerified: true,
    avatarInitials: 'AS',
  ),
  _PlatformUser(
    id: 'u007',
    name: 'David Temba',
    email: 'david@barikipharma.co.tz',
    phone: '+255 754 007 007',
    role: PlatformRole.deliveryDriver,
    status: UserStatus.active,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
    createdAt: DateTime(2024, 4, 1),
    emailVerified: true,
    avatarInitials: 'DT',
  ),
  _PlatformUser(
    id: 'u008',
    name: 'Sarah Juma',
    email: 'sarah@barikipharma.co.tz',
    phone: '+255 789 008 008',
    role: PlatformRole.marketingOfficer,
    status: UserStatus.suspended,
    orgName: 'Bariki Pharmaceuticals',
    orgId: 'o001',
    orgSlug: 'bariki-pharma',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 14)),
    createdAt: DateTime(2024, 4, 2),
    emailVerified: true,
    avatarInitials: 'SJ',
  ),
  // ── Mwanjelwa Pharmacy ────────────────────────────────────────────────────
  _PlatformUser(
    id: 'u009',
    name: 'Hassan Mwambe',
    email: 'hassan@mwanjelwa.co.tz',
    phone: '+255 711 009 009',
    role: PlatformRole.orgAdmin,
    status: UserStatus.active,
    orgName: 'Mwanjelwa Pharmacy',
    orgId: 'o002',
    orgSlug: 'mwanjelwa-pharmacy',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 6)),
    createdAt: DateTime(2024, 5, 1),
    emailVerified: true,
    avatarInitials: 'HM',
  ),
  _PlatformUser(
    id: 'u010',
    name: 'Zainab Ally',
    email: 'zainab@mwanjelwa.co.tz',
    phone: '+255 722 010 010',
    role: PlatformRole.customerRep,
    status: UserStatus.active,
    orgName: 'Mwanjelwa Pharmacy',
    orgId: 'o002',
    orgSlug: 'mwanjelwa-pharmacy',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 8)),
    createdAt: DateTime(2024, 5, 2),
    emailVerified: true,
    avatarInitials: 'ZA',
  ),
  _PlatformUser(
    id: 'u011',
    name: 'Musa Kileo',
    email: 'musa@mwanjelwa.co.tz',
    phone: '+255 733 011 011',
    role: PlatformRole.customerRep,
    status: UserStatus.active,
    orgName: 'Mwanjelwa Pharmacy',
    orgId: 'o002',
    orgSlug: 'mwanjelwa-pharmacy',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 3)),
    createdAt: DateTime(2024, 5, 3),
    emailVerified: false,
    avatarInitials: 'MK',
  ),
  // ── Uyole Health Supplies ─────────────────────────────────────────────────
  _PlatformUser(
    id: 'u012',
    name: 'Christine Kapinga',
    email: 'chris@uyolehealth.co.tz',
    phone: '+255 744 012 012',
    role: PlatformRole.orgAdmin,
    status: UserStatus.active,
    orgName: 'Uyole Health Supplies',
    orgId: 'o003',
    orgSlug: 'uyole-health',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
    createdAt: DateTime(2024, 6, 1),
    emailVerified: true,
    avatarInitials: 'CK',
  ),
  _PlatformUser(
    id: 'u013',
    name: 'John Mwakalebela',
    email: 'john@uyolehealth.co.tz',
    phone: '+255 755 013 013',
    role: PlatformRole.warehouseStaff,
    status: UserStatus.active,
    orgName: 'Uyole Health Supplies',
    orgId: 'o003',
    orgSlug: 'uyole-health',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
    createdAt: DateTime(2024, 6, 5),
    emailVerified: true,
    avatarInitials: 'JM',
  ),
  _PlatformUser(
    id: 'u014',
    name: 'Perpetua Shoo',
    email: 'perp@uyolehealth.co.tz',
    phone: '+255 766 014 014',
    role: PlatformRole.financeAccountant,
    status: UserStatus.active,
    orgName: 'Uyole Health Supplies',
    orgId: 'o003',
    orgSlug: 'uyole-health',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 7)),
    createdAt: DateTime(2024, 6, 6),
    emailVerified: true,
    avatarInitials: 'PS',
  ),
  // ── Tanzapharm Manufacturers ──────────────────────────────────────────────
  _PlatformUser(
    id: 'u015',
    name: 'Robert Mfinanga',
    email: 'robert@tanzapharm.co.tz',
    phone: '+255 777 015 015',
    role: PlatformRole.orgAdmin,
    status: UserStatus.pending,
    orgName: 'Tanzapharm Manufacturers',
    orgId: 'o004',
    orgSlug: 'tanzapharm',
    tenantName: 'PharmaOS',
    lastLogin: null,
    createdAt: DateTime(2026, 2, 20),
    emailVerified: false,
    avatarInitials: 'RM',
  ),
  _PlatformUser(
    id: 'u016',
    name: 'Lucia Mhagama',
    email: 'lucia@tanzapharm.co.tz',
    phone: '+255 788 016 016',
    role: PlatformRole.warehouseStaff,
    status: UserStatus.pending,
    orgName: 'Tanzapharm Manufacturers',
    orgId: 'o004',
    orgSlug: 'tanzapharm',
    tenantName: 'PharmaOS',
    lastLogin: null,
    createdAt: DateTime(2026, 2, 21),
    emailVerified: false,
    avatarInitials: 'LM',
  ),
  // ── Kariakoo MedStore ─────────────────────────────────────────────────────
  _PlatformUser(
    id: 'u017',
    name: 'Ibrahim Nyambe',
    email: 'ibrahim@kariakoo.co.tz',
    phone: '+255 799 017 017',
    role: PlatformRole.orgAdmin,
    status: UserStatus.active,
    orgName: 'Kariakoo MedStore',
    orgId: 'o005',
    orgSlug: 'kariakoo-med',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 14)),
    createdAt: DateTime(2024, 8, 1),
    emailVerified: true,
    avatarInitials: 'IN',
  ),
  // ── Swift Med Logistics ────────────────────────────────────────────────────
  _PlatformUser(
    id: 'u018',
    name: 'Neema Chambo',
    email: 'neema@swiftmed.co.tz',
    phone: '+255 700 018 018',
    role: PlatformRole.orgAdmin,
    status: UserStatus.active,
    orgName: 'Swift Med Logistics',
    orgId: 'o006',
    orgSlug: 'swift-med',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(minutes: 45)),
    createdAt: DateTime(2024, 9, 1),
    emailVerified: true,
    avatarInitials: 'NC',
  ),
  _PlatformUser(
    id: 'u019',
    name: 'Francis Makundi',
    email: 'francis@swiftmed.co.tz',
    phone: '+255 711 019 019',
    role: PlatformRole.deliveryDriver,
    status: UserStatus.active,
    orgName: 'Swift Med Logistics',
    orgId: 'o006',
    orgSlug: 'swift-med',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(minutes: 10)),
    createdAt: DateTime(2024, 9, 5),
    emailVerified: true,
    avatarInitials: 'FM',
  ),
  _PlatformUser(
    id: 'u020',
    name: 'Agnes Lyimo',
    email: 'agnes@swiftmed.co.tz',
    phone: '+255 722 020 020',
    role: PlatformRole.deliveryDriver,
    status: UserStatus.active,
    orgName: 'Swift Med Logistics',
    orgId: 'o006',
    orgSlug: 'swift-med',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
    createdAt: DateTime(2024, 9, 6),
    emailVerified: true,
    avatarInitials: 'AL',
  ),
  _PlatformUser(
    id: 'u021',
    name: 'Benedict Sanga',
    email: 'ben@swiftmed.co.tz',
    phone: '+255 733 021 021',
    role: PlatformRole.deliveryDriver,
    status: UserStatus.suspended,
    orgName: 'Swift Med Logistics',
    orgId: 'o006',
    orgSlug: 'swift-med',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 20)),
    createdAt: DateTime(2024, 9, 10),
    emailVerified: true,
    avatarInitials: 'BS',
  ),
  // ── Njombe District Pharmacy ──────────────────────────────────────────────
  _PlatformUser(
    id: 'u022',
    name: 'Veronica Msigwa',
    email: 'vero@njombepharm.co.tz',
    phone: '+255 744 022 022',
    role: PlatformRole.orgAdmin,
    status: UserStatus.suspended,
    orgName: 'Njombe District Pharmacy',
    orgId: 'o007',
    orgSlug: 'njombe-pharmacy',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 30)),
    createdAt: DateTime(2024, 10, 1),
    emailVerified: true,
    avatarInitials: 'VM',
  ),
  _PlatformUser(
    id: 'u023',
    name: 'Daniel Urio',
    email: 'daniel@njombepharm.co.tz',
    phone: '+255 755 023 023',
    role: PlatformRole.customerRep,
    status: UserStatus.suspended,
    orgName: 'Njombe District Pharmacy',
    orgId: 'o007',
    orgSlug: 'njombe-pharmacy',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(days: 30)),
    createdAt: DateTime(2024, 10, 2),
    emailVerified: true,
    avatarInitials: 'DU',
  ),
  // ── Super Admin ───────────────────────────────────────────────────────────
  _PlatformUser(
    id: 'u000',
    name: 'Platform Admin',
    email: 'admin@pharmoos.io',
    phone: '+255 700 000 000',
    role: PlatformRole.superAdmin,
    status: UserStatus.active,
    orgName: 'PharmaOS Platform',
    orgId: 'platform',
    orgSlug: 'platform',
    tenantName: 'PharmaOS',
    lastLogin: DateTime.now().subtract(const Duration(minutes: 5)),
    createdAt: DateTime(2024, 1, 1),
    emailVerified: true,
    avatarInitials: 'PA',
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class PlatformUsersPage extends StatefulWidget {
  const PlatformUsersPage({super.key});

  @override
  State<PlatformUsersPage> createState() => _PlatformUsersPageState();
}

class _PlatformUsersPageState extends State<PlatformUsersPage> {
  String _search = '';
  PlatformRole? _roleFilter;
  UserStatus? _statusFilter;
  String? _orgFilter;
  SortOption _sort = SortOption.lastLoginDesc;
  final Set<String> _selected = {};
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Filtering + sorting ────────────────────────────────────────────────────

  List<_PlatformUser> get _filtered {
    var list = _allUsers.where((u) {
      final q = _search.toLowerCase();
      final matchSearch =
          q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.orgName.toLowerCase().contains(q);
      final matchRole = _roleFilter == null || u.role == _roleFilter;
      final matchStatus = _statusFilter == null || u.status == _statusFilter;
      final matchOrg = _orgFilter == null || u.orgId == _orgFilter;
      return matchSearch && matchRole && matchStatus && matchOrg;
    }).toList();

    switch (_sort) {
      case SortOption.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.lastLoginDesc:
        list.sort((a, b) {
          if (a.lastLogin == null && b.lastLogin == null) return 0;
          if (a.lastLogin == null) return 1;
          if (b.lastLogin == null) return -1;
          return b.lastLogin!.compareTo(a.lastLogin!);
        });
      case SortOption.createdDesc:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.orgName:
        list.sort((a, b) => a.orgName.compareTo(b.orgName));
    }
    return list;
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  int get _total => _allUsers.length;
  int get _activeCount =>
      _allUsers.where((u) => u.status == UserStatus.active).length;
  int get _suspendedCount =>
      _allUsers.where((u) => u.status == UserStatus.suspended).length;
  int get _pendingCount =>
      _allUsers.where((u) => u.status == UserStatus.pending).length;
  int get _newThisMonth {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _allUsers.where((u) => u.createdAt.isAfter(cutoff)).length;
  }

  Map<PlatformRole, int> get _roleCounts {
    final m = <PlatformRole, int>{};
    for (final u in _allUsers) {
      m[u.role] = (m[u.role] ?? 0) + 1;
    }
    return m;
  }

  List<String> get _orgList {
    final seen = <String>{};
    final result = <String>[];
    for (final u in _allUsers) {
      if (seen.add(u.orgId)) result.add(u.orgId);
    }
    return result;
  }

  Map<String, String> get _orgNames {
    final m = <String, String>{};
    for (final u in _allUsers) {
      m[u.orgId] = u.orgName;
    }
    return m;
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void _toggleSelect(String id) => setState(
    () => _selected.contains(id) ? _selected.remove(id) : _selected.add(id),
  );

  void _selectAll() => setState(() {
    if (_selected.length == _filtered.length) {
      _selected.clear();
    } else {
      _selected.addAll(_filtered.map((u) => u.id));
    }
  });

  bool get _allSelected =>
      _filtered.isNotEmpty && _selected.length == _filtered.length;

  // ── Actions ────────────────────────────────────────────────────────────────

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _impersonate(_PlatformUser u) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.switch_account_outlined, size: 32),
        title: const Text('Impersonate User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'You will log in as '),
                  TextSpan(
                    text: u.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' ('),
                  TextSpan(
                    text: _roleLabel(u.role),
                    style: TextStyle(
                      color: _roleColor(u.role),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ') at '),
                  TextSpan(
                    text: u.orgName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                    text:
                        '.\n\nAll actions will be performed under their account. '
                        'This session is logged.',
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _snack('🔐 Impersonating ${u.name} — session active');
            },
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text('Impersonate'),
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showBulkSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BulkActionSheet(
        count: _selected.length,
        onAction: (action) {
          Navigator.pop(context);
          setState(() => _selected.clear());
          _snack(
            '$action applied to ${_selected.length > 0 ? _selected.length : "selected"} users',
          );
        },
      ),
    );
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InviteUserSheet(
        orgNames: _orgNames,
        onInvite: (name, email, role, orgId) {
          Navigator.pop(context);
          _snack('Invitation sent to $email as ${_roleLabel(role)}');
        },
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        current: _sort,
        onSelect: (s) {
          setState(() => _sort = s);
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
        currentRole: _roleFilter,
        currentStatus: _statusFilter,
        currentOrg: _orgFilter,
        orgNames: _orgNames,
        orgIds: _orgList,
        onApply: (role, status, org) {
          setState(() {
            _roleFilter = role;
            _statusFilter = status;
            _orgFilter = org;
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _roleFilter = null;
            _statusFilter = null;
            _orgFilter = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  bool get _hasFilters =>
      _roleFilter != null || _statusFilter != null || _orgFilter != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: _selected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkSheet,
              icon: const Icon(Icons.checklist_rounded),
              label: Text('${_selected.length} selected'),
            )
          : FloatingActionButton(
              onPressed: _showInviteDialog,
              tooltip: 'Invite User',
              child: const Icon(Icons.person_add_outlined),
            ),
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(
              showSearch: _showSearch,
              searchCtrl: _searchCtrl,
              hasFilters: _hasFilters,
              activeFilterCount: [
                _roleFilter,
                _statusFilter,
                _orgFilter,
              ].where((f) => f != null).length,
              onToggleSearch: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _search = '';
                    _searchCtrl.clear();
                  }
                });
              },
              onSearch: (q) => setState(() => _search = q),
              onSort: _showSortSheet,
              onFilter: _showFilterSheet,
              currentSort: _sort,
            ),
          ),

          // ── KPI cards ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _KpiStrip(
              total: _total,
              active: _activeCount,
              suspended: _suspendedCount,
              pending: _pendingCount,
              newThisMonth: _newThisMonth,
            ),
          ),

          // ── Role distribution bar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _RoleDistribution(
              counts: _roleCounts,
              selectedRole: _roleFilter,
              onRoleTap: (r) =>
                  setState(() => _roleFilter = _roleFilter == r ? null : r),
            ),
          ),

          // ── Org filter pills ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _OrgPills(
              orgIds: _orgList,
              orgNames: _orgNames,
              selectedOrg: _orgFilter,
              onSelect: (id) =>
                  setState(() => _orgFilter = _orgFilter == id ? null : id),
            ),
          ),

          // ── List controls ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _ListControls(
              total: filtered.length,
              selectedCount: _selected.length,
              allSelected: _allSelected,
              hasFilters: _hasFilters,
              onSelectAll: _selectAll,
              onClearFilters: () => setState(() {
                _roleFilter = null;
                _statusFilter = null;
                _orgFilter = null;
                _search = '';
                _searchCtrl.clear();
              }),
            ),
          ),

          // ── User list ─────────────────────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                hasFilters: _hasFilters || _search.isNotEmpty,
                onClear: () => setState(() {
                  _roleFilter = null;
                  _statusFilter = null;
                  _orgFilter = null;
                  _search = '';
                  _searchCtrl.clear();
                }),
              ),
            )
          else
            SliverList.separated(
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final u = filtered[i];
                return _UserTile(
                  user: u,
                  isSelected: _selected.contains(u.id),
                  onTap: () => _selected.isNotEmpty
                      ? _toggleSelect(u.id)
                      : _showUserDetail(u),
                  onLongPress: () => _toggleSelect(u.id),
                  onImpersonate: () => _impersonate(u),
                  onSuspend: () => _snack(
                    u.status == UserStatus.suspended
                        ? 'Reactivated ${u.name}'
                        : 'Suspended ${u.name}',
                  ),
                  onResetPassword: () =>
                      _snack('Password reset email sent to ${u.email}'),
                  onCopyEmail: () {
                    Clipboard.setData(ClipboardData(text: u.email));
                    _snack('Copied ${u.email}');
                  },
                  onViewOrg: () => _snack('Navigate to ${u.orgName}'),
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  void _showUserDetail(_PlatformUser u) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UserDetailSheet(
        user: u,
        onImpersonate: () {
          Navigator.pop(context);
          _impersonate(u);
        },
        onSuspend: () {
          Navigator.pop(context);
          _snack(
            u.status == UserStatus.suspended
                ? 'Reactivated ${u.name}'
                : 'Suspended ${u.name}',
          );
        },
        onResetPassword: () {
          Navigator.pop(context);
          _snack('Password reset sent to ${u.email}');
        },
        onViewOrg: () {
          Navigator.pop(context);
          _snack('Navigate to ${u.orgName}');
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool showSearch;
  final TextEditingController searchCtrl;
  final bool hasFilters;
  final int activeFilterCount;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearch;
  final VoidCallback onSort;
  final VoidCallback onFilter;
  final SortOption currentSort;

  const _Header({
    required this.showSearch,
    required this.searchCtrl,
    required this.hasFilters,
    required this.activeFilterCount,
    required this.onToggleSearch,
    required this.onSearch,
    required this.onSort,
    required this.onFilter,
    required this.currentSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title block
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
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Platform Users',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'All users across every organization',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton.outlined(
                onPressed: onToggleSearch,
                icon: Icon(
                  showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  size: 20,
                ),
                tooltip: 'Search',
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                onPressed: onSort,
                icon: const Icon(Icons.sort_rounded, size: 20),
                tooltip: 'Sort',
              ),
              const SizedBox(width: 6),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton.outlined(
                    onPressed: onFilter,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: 'Filter',
                  ),
                  if (activeFilterCount > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$activeFilterCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Search bar (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: showSearch
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: onSearch,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search name, email, phone, org…',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  onSearch('');
                                },
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
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
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
}

// ─── KPI Strip ────────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final int total, active, suspended, pending, newThisMonth;

  const _KpiStrip({
    required this.total,
    required this.active,
    required this.suspended,
    required this.pending,
    required this.newThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Row 1: main stats
          Row(
            children: [
              _KpiCard(
                value: '$total',
                label: 'Total Users',
                icon: Icons.group_outlined,
                color: Colors.blue,
                flex: 3,
                sublabel: 'Platform-wide',
              ),
              const SizedBox(width: 10),
              _KpiCard(
                value: '$active',
                label: 'Active',
                icon: Icons.check_circle_outline,
                color: Colors.green,
                flex: 2,
                sublabel: '${((active / total) * 100).toStringAsFixed(0)}%',
                showBar: true,
                barValue: active / total,
              ),
              const SizedBox(width: 10),
              _KpiCard(
                value: '$suspended',
                label: 'Suspended',
                icon: Icons.block_outlined,
                color: Colors.red,
                flex: 2,
                sublabel: 'Access off',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _KpiCard(
                value: '$pending',
                label: 'Pending',
                icon: Icons.hourglass_empty_rounded,
                color: Colors.orange,
                flex: 1,
                sublabel: 'Not verified',
              ),
              const SizedBox(width: 10),
              _KpiCard(
                value: '+$newThisMonth',
                label: 'New (30d)',
                icon: Icons.person_add_outlined,
                color: Colors.teal,
                flex: 1,
                sublabel: 'This month',
              ),
              const SizedBox(width: 10),
              _KpiCard(
                value: '7',
                label: 'Orgs',
                icon: Icons.domain_outlined,
                color: Colors.indigo,
                flex: 1,
                sublabel: 'Active tenants',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final int flex;
  final bool showBar;
  final double barValue;

  const _KpiCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.flex,
    required this.sublabel,
    this.showBar = false,
    this.barValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sublabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showBar) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: barValue,
                  minHeight: 3,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Role Distribution ────────────────────────────────────────────────────────

class _RoleDistribution extends StatelessWidget {
  final Map<PlatformRole, int> counts;
  final PlatformRole? selectedRole;
  final ValueChanged<PlatformRole> onRoleTap;

  const _RoleDistribution({
    required this.counts,
    required this.selectedRole,
    required this.onRoleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = counts.values.fold(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Role Distribution',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· tap to filter',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 24),
                if (selectedRole != null)
                  TextButton(
                    onPressed: () => onRoleTap(selectedRole!),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Segmented bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: PlatformRole.values
                      .where((r) => (counts[r] ?? 0) > 0)
                      .map((r) {
                        final cnt = counts[r]!;
                        final isSelected =
                            selectedRole == null || selectedRole == r;
                        return Expanded(
                          flex: cnt,
                          child: GestureDetector(
                            onTap: () => onRoleTap(r),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              color: isSelected
                                  ? _roleColor(r)
                                  : _roleColor(r).withValues(alpha: 0.2),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Role legend chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: PlatformRole.values
                  .where((r) => (counts[r] ?? 0) > 0)
                  .map((r) {
                    final cnt = counts[r]!;
                    final isHighlighted =
                        selectedRole == null || selectedRole == r;
                    final pct = ((cnt / total) * 100).round();
                    return GestureDetector(
                      onTap: () => onRoleTap(r),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isHighlighted ? 1 : 0.35,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selectedRole == r
                                ? _roleColor(r).withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selectedRole == r
                                  ? _roleColor(r).withValues(alpha: 0.4)
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.5,
                                    ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _roleColor(r),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _roleShortLabel(r),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cnt ($pct%)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Org Pills ────────────────────────────────────────────────────────────────

class _OrgPills extends StatelessWidget {
  final List<String> orgIds;
  final Map<String, String> orgNames;
  final String? selectedOrg;
  final ValueChanged<String> onSelect;

  const _OrgPills({
    required this.orgIds,
    required this.orgNames,
    required this.selectedOrg,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Organization',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('All Orgs'),
                    selected: selectedOrg == null,
                    onSelected: (_) =>
                        selectedOrg != null ? onSelect(selectedOrg!) : null,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                ...orgIds
                    .where((id) => id != 'platform')
                    .map(
                      (id) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(orgNames[id] ?? id),
                          selected: selectedOrg == id,
                          onSelected: (_) => onSelect(id),
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 12),
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

// ─── List Controls ─────────────────────────────────────────────────────────────

class _ListControls extends StatelessWidget {
  final int total;
  final int selectedCount;
  final bool allSelected;
  final bool hasFilters;
  final VoidCallback onSelectAll;
  final VoidCallback onClearFilters;

  const _ListControls({
    required this.total,
    required this.selectedCount,
    required this.allSelected,
    required this.hasFilters,
    required this.onSelectAll,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          Text(
            selectedCount > 0
                ? '$selectedCount of $total selected'
                : '$total user${total == 1 ? '' : 's'}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          const SizedBox(width: 24),
          if (selectedCount > 0)
            TextButton.icon(
              onPressed: onSelectAll,
              icon: Icon(
                allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                size: 14,
              ),
              label: Text(allSelected ? 'Deselect all' : 'Select all'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (hasFilters && selectedCount == 0)
            TextButton(
              onPressed: onClearFilters,
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
    );
  }
}

// ─── User Tile ────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final _PlatformUser user;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onImpersonate;
  final VoidCallback onSuspend;
  final VoidCallback onResetPassword;
  final VoidCallback onCopyEmail;
  final VoidCallback onViewOrg;

  const _UserTile({
    required this.user,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onImpersonate,
    required this.onSuspend,
    required this.onResetPassword,
    required this.onCopyEmail,
    required this.onViewOrg,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSuspended = user.status == UserStatus.suspended;
    final isPending = user.status == UserStatus.pending;
    final isSuperAdmin = user.role == PlatformRole.superAdmin;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar / check
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? _CheckAvatar(key: const ValueKey('chk'))
                  : _UserAvatar(
                      key: const ValueKey('av'),
                      initials: user.avatarInitials ?? user.name[0],
                      color: _roleColor(user.role),
                      isOnline:
                          user.lastLogin != null &&
                          DateTime.now().difference(user.lastLogin!).inHours <
                              1,
                      isSuperAdmin: isSuperAdmin,
                    ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSuspended
                                ? colorScheme.onSurface.withValues(alpha: 0.5)
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusPill(status: user.status),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Email
                  Text(
                    user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Role + Org row
                  Row(
                    children: [
                      _RoleBadge(role: user.role),
                      const SizedBox(width: 6),
                      if (!isSuperAdmin) ...[
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: GestureDetector(
                            onTap: onViewOrg,
                            child: Text(
                              user.orgName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Last login + email verified
                  Row(
                    children: [
                      if (isPending)
                        Text(
                          'Never logged in',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (user.lastLogin != null)
                        Text(
                          'Last login ${_timeAgo(user.lastLogin!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      const SizedBox(width: 24),
                      if (!user.emailVerified)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mark_email_unread_outlined,
                              size: 11,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Unverified',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) => switch (v) {
                'impersonate' => onImpersonate(),
                'suspend' => onSuspend(),
                'reset' => onResetPassword(),
                'copy_email' => onCopyEmail(),
                'view_org' => onViewOrg(),
                _ => null,
              },
              itemBuilder: (_) => [
                if (!isSuperAdmin)
                  _menuItem(
                    'impersonate',
                    Icons.switch_account_outlined,
                    'Impersonate',
                    color: Colors.indigo,
                  ),
                _menuItem('copy_email', Icons.copy_outlined, 'Copy Email'),
                if (!isSuperAdmin)
                  _menuItem('view_org', Icons.domain_outlined, 'View Org'),
                _menuItem('reset', Icons.lock_reset_outlined, 'Reset Password'),
                const PopupMenuDivider(),
                _menuItem(
                  'suspend',
                  isSuspended
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                  isSuspended ? 'Reactivate' : 'Suspend',
                  color: isSuspended ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) => PopupMenuItem(
    value: value,
    height: 44,
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: color != null ? FontWeight.w600 : null,
          ),
        ),
      ],
    ),
  );
}

// ─── Avatar widgets ───────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final bool isOnline;
  final bool isSuperAdmin;

  const _UserAvatar({
    super.key,
    required this.initials,
    required this.color,
    required this.isOnline,
    required this.isSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: isSuperAdmin
                ? Border.all(color: Colors.red.withValues(alpha: 0.4), width: 2)
                : null,
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
        if (isOnline)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
          ),
        if (isSuperAdmin)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 12,
                color: Colors.red.shade600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CheckAvatar extends StatelessWidget {
  const _CheckAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
    );
  }
}

// ─── Inline badges ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final UserStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      UserStatus.active => (Colors.green, 'Active'),
      UserStatus.suspended => (Colors.red, 'Suspended'),
      UserStatus.pending => (Colors.orange, 'Pending'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final PlatformRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        _roleShortLabel(role),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _roleColor(role),
        ),
      ),
    );
  }
}

// ─── User Detail Sheet ────────────────────────────────────────────────────────

class _UserDetailSheet extends StatelessWidget {
  final _PlatformUser user;
  final VoidCallback onImpersonate;
  final VoidCallback onSuspend;
  final VoidCallback onResetPassword;
  final VoidCallback onViewOrg;

  const _UserDetailSheet({
    required this.user,
    required this.onImpersonate,
    required this.onSuspend,
    required this.onResetPassword,
    required this.onViewOrg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSuperAdmin = user.role == PlatformRole.superAdmin;
    final isSuspended = user.status == UserStatus.suspended;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Avatar + name
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _roleColor(user.role).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: isSuperAdmin
                      ? Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                          width: 2,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.avatarInitials ?? user.name[0],
                  style: TextStyle(
                    color: _roleColor(user.role),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RoleBadge(role: user.role),
                        const SizedBox(width: 6),
                        _StatusPill(status: user.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Details grid
          _DetailGrid(user: user, onViewOrg: onViewOrg),
          const SizedBox(height: 24),

          // Impersonate — full width, prominent
          if (!isSuperAdmin)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.withValues(alpha: 0.08),
                    Colors.purple.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.switch_account_outlined,
                        color: Colors.indigo.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Impersonate',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Log in as this user and experience the platform exactly '
                    'as they see it. All actions will be logged.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onImpersonate,
                      icon: const Icon(Icons.login_rounded, size: 16),
                      label: Text('Impersonate ${user.name.split(' ').first}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Secondary actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onResetPassword,
                  icon: const Icon(Icons.lock_reset_outlined, size: 16),
                  label: const Text('Reset Password'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSuspend,
                  icon: Icon(
                    isSuspended
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                    size: 16,
                  ),
                  label: Text(isSuspended ? 'Reactivate' : 'Suspend'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isSuspended ? Colors.green : Colors.orange,
                    side: BorderSide(
                      color: isSuspended
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  final _PlatformUser user;
  final VoidCallback onViewOrg;

  const _DetailGrid({required this.user, required this.onViewOrg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formatDate(DateTime dt) =>
        '${dt.day} ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1]} ${dt.year}';

    String timeAgo(DateTime dt) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: user.phone,
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: Icons.domain_outlined,
            label: 'Organization',
            value: user.orgName,
            onTap: onViewOrg,
            isLink: true,
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: Icons.cloud_outlined,
            label: 'Tenant',
            value: user.tenantName,
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: Icons.login_rounded,
            label: 'Last Login',
            value: user.lastLogin != null
                ? '${formatDate(user.lastLogin!)} · ${timeAgo(user.lastLogin!)}'
                : 'Never',
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Joined',
            value: formatDate(user.createdAt),
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: user.emailVerified
                ? Icons.verified_outlined
                : Icons.mark_email_unread_outlined,
            label: 'Email',
            value: user.emailVerified ? 'Verified' : 'Not verified',
            valueColor: user.emailVerified ? Colors.green : Colors.orange,
          ),
          const Divider(height: 1, indent: 44),
          _DetailRow(
            icon: Icons.language_outlined,
            label: 'Language',
            value: user.preferredLanguage == 'sw'
                ? 'Swahili (sw)'
                : 'English (en)',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      valueColor ??
                      (isLink ? colorScheme.primary : colorScheme.onSurface),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLink)
              Icon(
                Icons.open_in_new_rounded,
                size: 12,
                color: colorScheme.primary,
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
          Text(
            '$count user${count == 1 ? '' : 's'} selected',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an action to apply to all selected users.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _BulkTile(
            Icons.play_circle_outline,
            'Activate All',
            Colors.green,
            () => onAction('Activate'),
          ),
          _BulkTile(
            Icons.pause_circle_outline,
            'Suspend All',
            Colors.orange,
            () => onAction('Suspend'),
          ),
          _BulkTile(
            Icons.lock_reset_outlined,
            'Reset Passwords',
            Colors.blue,
            () => onAction('Password reset sent'),
          ),
          _BulkTile(
            Icons.mark_email_read_outlined,
            'Resend Verification',
            Colors.teal,
            () => onAction('Verification emails sent'),
          ),
          _BulkTile(
            Icons.download_outlined,
            'Export CSV',
            Colors.indigo,
            () => onAction('Export started'),
          ),
          const SizedBox(height: 8),
          const Divider(),
          _BulkTile(
            Icons.delete_outline_rounded,
            'Delete Selected',
            Colors.red,
            () => onAction('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BulkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BulkTile(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// ─── Invite User Sheet ────────────────────────────────────────────────────────

class _InviteUserSheet extends StatefulWidget {
  final Map<String, String> orgNames;
  final void Function(
    String name,
    String email,
    PlatformRole role,
    String orgId,
  )
  onInvite;

  const _InviteUserSheet({required this.orgNames, required this.onInvite});

  @override
  State<_InviteUserSheet> createState() => _InviteUserSheetState();
}

class _InviteUserSheetState extends State<_InviteUserSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  PlatformRole _role = PlatformRole.marketingOfficer;
  String? _orgId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
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
          Text(
            'Invite New User',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'An invitation email will be sent to the provided address.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: _inputDeco('Full name', Icons.person_outline),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailCtrl,
            decoration: _inputDeco('Email address', Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Role picker
          DropdownButtonFormField<PlatformRole>(
            value: _role,
            decoration: _inputDeco('Role', Icons.badge_outlined),
            items: PlatformRole.values
                .where((r) => r != PlatformRole.superAdmin)
                .map(
                  (r) => DropdownMenuItem(value: r, child: Text(_roleLabel(r))),
                )
                .toList(),
            onChanged: (v) => setState(() => _role = v!),
          ),
          const SizedBox(height: 12),
          // Org picker
          DropdownButtonFormField<String>(
            value: _orgId,
            decoration: _inputDeco('Organization', Icons.domain_outlined),
            hint: const Text('Select organization'),
            items: widget.orgNames.entries
                .where((e) => e.key != 'platform')
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(
                      e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _orgId = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _orgId != null &&
                      _nameCtrl.text.isNotEmpty &&
                      _emailCtrl.text.isNotEmpty
                  ? () => widget.onInvite(
                      _nameCtrl.text,
                      _emailCtrl.text,
                      _role,
                      _orgId!,
                    )
                  : null,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Invitation'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
  );
}

// ─── Sort Sheet ───────────────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  final SortOption current;
  final ValueChanged<SortOption> onSelect;

  const _SortSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final options = [
      (SortOption.lastLoginDesc, Icons.login_rounded, 'Most Recently Active'),
      (SortOption.createdDesc, Icons.calendar_today_outlined, 'Newest First'),
      (SortOption.nameAsc, Icons.sort_by_alpha_rounded, 'Name A → Z'),
      (SortOption.orgName, Icons.domain_outlined, 'By Organization'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
          Text(
            'Sort Users',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final (option, icon, label) = opt;
            final isSelected = current == option;
            return ListTile(
              leading: Icon(
                icon,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: colorScheme.primary)
                  : null,
              onTap: () => onSelect(option),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              selected: isSelected,
              selectedTileColor: colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Filter Sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final PlatformRole? currentRole;
  final UserStatus? currentStatus;
  final String? currentOrg;
  final Map<String, String> orgNames;
  final List<String> orgIds;
  final void Function(PlatformRole?, UserStatus?, String?) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.currentRole,
    required this.currentStatus,
    required this.currentOrg,
    required this.orgNames,
    required this.orgIds,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  PlatformRole? _role;
  UserStatus? _status;
  String? _org;

  @override
  void initState() {
    super.initState();
    _role = widget.currentRole;
    _status = widget.currentStatus;
    _org = widget.currentOrg;
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
                  'Filter Users',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _role = null;
                      _status = null;
                      _org = null;
                    });
                    widget.onClear();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Text(
              'Status',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: UserStatus.values
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

            // Role
            Text(
              'Role',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: PlatformRole.values
                  .map(
                    (r) => FilterChip(
                      avatar: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _roleColor(r),
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: Text(_roleShortLabel(r)),
                      selected: _role == r,
                      onSelected: (_) =>
                          setState(() => _role = _role == r ? null : r),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Organization
            Text(
              'Organization',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: widget.orgIds
                  .where((id) => id != 'platform')
                  .map(
                    (id) => FilterChip(
                      label: Text(
                        widget.orgNames[id] ?? id,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _org == id,
                      onSelected: (_) =>
                          setState(() => _org = _org == id ? null : id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onApply(_role, _status, _org),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(UserStatus s) => switch (s) {
    UserStatus.active => 'Active',
    UserStatus.suspended => 'Suspended',
    UserStatus.pending => 'Pending',
  };
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
                  : Icons.group_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No users match' : 'No users yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters.'
                  : 'Invite the first user to get started.',
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

// ─── Shared role helpers (module-level) ───────────────────────────────────────

Color _roleColor(PlatformRole r) => switch (r) {
  PlatformRole.superAdmin => Colors.red,
  PlatformRole.orgAdmin => Colors.indigo,
  PlatformRole.salesSupervisor => Colors.blue,
  PlatformRole.marketingOfficer => Colors.teal,
  PlatformRole.warehouseStaff => Colors.orange,
  PlatformRole.financeAccountant => Colors.purple,
  PlatformRole.deliveryDriver => Colors.brown,
  PlatformRole.customerRep => Colors.green,
};

String _roleLabel(PlatformRole r) => switch (r) {
  PlatformRole.superAdmin => 'Super Admin',
  PlatformRole.orgAdmin => 'Org Admin',
  PlatformRole.salesSupervisor => 'Sales Supervisor',
  PlatformRole.marketingOfficer => 'Marketing Officer',
  PlatformRole.warehouseStaff => 'Warehouse Staff',
  PlatformRole.financeAccountant => 'Finance / Accountant',
  PlatformRole.deliveryDriver => 'Delivery Driver',
  PlatformRole.customerRep => 'Customer Rep',
};

String _roleShortLabel(PlatformRole r) => switch (r) {
  PlatformRole.superAdmin => 'Super Admin',
  PlatformRole.orgAdmin => 'Org Admin',
  PlatformRole.salesSupervisor => 'Supervisor',
  PlatformRole.marketingOfficer => 'Mktg Officer',
  PlatformRole.warehouseStaff => 'Warehouse',
  PlatformRole.financeAccountant => 'Finance',
  PlatformRole.deliveryDriver => 'Driver',
  PlatformRole.customerRep => 'Customer Rep',
};
