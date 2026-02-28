import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ROLES & PERMISSIONS PAGE
// Super Admin — Pharma SaaS Platform
// Platform-level RBAC configuration via Spatie Laravel Permission
// Zero external dependencies — pure flutter/material.dart
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
const _cViolet = Color(0xFF6A1B9A);
const _cVioletLight = Color(0xFFF3E5F5);
const _cOrange = Color(0xFFE65100);
const _cOrangeLight = Color(0xFFFBE9E7);
const _cTeal = Color(0xFF00695C);
const _cTealLight = Color(0xFFE0F2F1);
const _cSurface = Color(0xFFF4F6FA);
const _cCard = Colors.white;
const _cTextPrimary = Color(0xFF1A1A2E);
const _cTextSecondary = Color(0xFF6B7280);
const _cBorder = Color(0xFFE5E7EB);
const _cTableHeader = Color(0xFFF8F9FB);

BoxDecoration _card({double radius = 12, Color? color, Color? border}) =>
    BoxDecoration(
      color: color ?? _cCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? _cBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum RoleTier { platform, organization }

class RoleModel {
  final String slug;
  final String displayName;
  final RoleTier tier;
  final String description;
  final String primaryApp;
  final Color color;
  final Color colorLight;
  final IconData icon;
  final int userCount;
  final bool isEditable;

  const RoleModel({
    required this.slug,
    required this.displayName,
    required this.tier,
    required this.description,
    required this.primaryApp,
    required this.color,
    required this.colorLight,
    required this.icon,
    required this.userCount,
    this.isEditable = true,
  });
}

class PermissionModule {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final List<PermissionAction> actions;

  const PermissionModule({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.actions,
  });
}

class PermissionAction {
  final String key; // e.g. 'view', 'create'
  final String fullKey; // e.g. 'users.view'
  final String label;
  const PermissionAction({
    required this.key,
    required this.fullKey,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// STATIC DATA
// ─────────────────────────────────────────────────────────────────────────────

const _roles = [
  RoleModel(
    slug: 'super_admin',
    displayName: 'Super Admin',
    tier: RoleTier.platform,
    description:
        'Platform owner — unrestricted god-mode across all organizations and tenants.',
    primaryApp: 'Admin Panel',
    color: _cError,
    colorLight: _cErrorLight,
    icon: Icons.shield_rounded,
    userCount: 2,
    isEditable: false,
  ),
  RoleModel(
    slug: 'org_admin',
    displayName: 'Org Admin',
    tier: RoleTier.organization,
    description:
        'Full control within their organization. The internal CEO of the system.',
    primaryApp: 'Admin App',
    color: _cPrimary,
    colorLight: _cPrimaryLight,
    icon: Icons.admin_panel_settings_rounded,
    userCount: 47,
  ),
  RoleModel(
    slug: 'sales_supervisor',
    displayName: 'Sales Supervisor',
    tier: RoleTier.organization,
    description:
        'Oversees marketing officer teams. Territory and performance oversight.',
    primaryApp: 'Admin + Field',
    color: _cViolet,
    colorLight: _cVioletLight,
    icon: Icons.supervisor_account_rounded,
    userCount: 38,
  ),
  RoleModel(
    slug: 'marketing_officer',
    displayName: 'Marketing Officer',
    tier: RoleTier.organization,
    description:
        'Front-line field role. GPS visits, customer registration, orders.',
    primaryApp: 'Marketing App',
    color: _cAccent,
    colorLight: _cAccentLight,
    icon: Icons.directions_walk_rounded,
    userCount: 212,
  ),
  RoleModel(
    slug: 'warehouse_staff',
    displayName: 'Warehouse Staff',
    tier: RoleTier.organization,
    description:
        'Manages stock batches, expiry dates, FEFO fulfillment, inventory movements.',
    primaryApp: 'Inventory App',
    color: _cOrange,
    colorLight: _cOrangeLight,
    icon: Icons.inventory_2_rounded,
    userCount: 84,
  ),
  RoleModel(
    slug: 'finance_accountant',
    displayName: 'Finance / Accountant',
    tier: RoleTier.organization,
    description:
        'Payments, invoices, commissions, reconciliation, financial reports.',
    primaryApp: 'Admin App',
    color: _cSuccess,
    colorLight: _cSuccessLight,
    icon: Icons.account_balance_wallet_rounded,
    userCount: 56,
  ),
  RoleModel(
    slug: 'delivery_driver',
    displayName: 'Delivery / Driver',
    tier: RoleTier.organization,
    description:
        'Order pickup, delivery confirmation, GPS tracking, on-delivery payment.',
    primaryApp: 'Delivery App',
    color: _cWarning,
    colorLight: _cWarningLight,
    icon: Icons.local_shipping_rounded,
    userCount: 73,
  ),
  RoleModel(
    slug: 'customer_rep',
    displayName: 'Customer Rep',
    tier: RoleTier.organization,
    description:
        'Pharmacy buyer — places orders, tracks deliveries, pays, communicates.',
    primaryApp: 'Customer App',
    color: _cTeal,
    colorLight: _cTealLight,
    icon: Icons.store_rounded,
    userCount: 396,
  ),
];

const _modules = [
  PermissionModule(
    key: 'users',
    label: 'User Management',
    icon: Icons.people_alt_rounded,
    color: _cPrimary,
    actions: [
      PermissionAction(key: 'view', fullKey: 'users.view', label: 'View'),
      PermissionAction(key: 'create', fullKey: 'users.create', label: 'Create'),
      PermissionAction(key: 'edit', fullKey: 'users.edit', label: 'Edit'),
      PermissionAction(key: 'delete', fullKey: 'users.delete', label: 'Delete'),
      PermissionAction(
        key: 'suspend',
        fullKey: 'users.suspend',
        label: 'Suspend',
      ),
    ],
  ),
  PermissionModule(
    key: 'orgs',
    label: 'Organizations',
    icon: Icons.business_rounded,
    color: _cViolet,
    actions: [
      PermissionAction(key: 'view', fullKey: 'orgs.view', label: 'View'),
      PermissionAction(key: 'create', fullKey: 'orgs.create', label: 'Create'),
      PermissionAction(key: 'edit', fullKey: 'orgs.edit', label: 'Edit'),
      PermissionAction(key: 'delete', fullKey: 'orgs.delete', label: 'Delete'),
      PermissionAction(
        key: 'manage_relationships',
        fullKey: 'orgs.manage_relationships',
        label: 'Relationships',
      ),
    ],
  ),
  PermissionModule(
    key: 'customers',
    label: 'CRM / Customers',
    icon: Icons.store_rounded,
    color: _cTeal,
    actions: [
      PermissionAction(key: 'view', fullKey: 'customers.view', label: 'View'),
      PermissionAction(
        key: 'create',
        fullKey: 'customers.create',
        label: 'Create',
      ),
      PermissionAction(key: 'edit', fullKey: 'customers.edit', label: 'Edit'),
      PermissionAction(
        key: 'assign',
        fullKey: 'customers.assign',
        label: 'Assign',
      ),
    ],
  ),
  PermissionModule(
    key: 'visits',
    label: 'Visit Logging',
    icon: Icons.directions_walk_rounded,
    color: _cAccent,
    actions: [
      PermissionAction(key: 'view', fullKey: 'visits.view', label: 'View'),
      PermissionAction(
        key: 'view_team',
        fullKey: 'visits.view_team',
        label: 'View Team',
      ),
      PermissionAction(
        key: 'create',
        fullKey: 'visits.create',
        label: 'Create',
      ),
      PermissionAction(key: 'edit', fullKey: 'visits.edit', label: 'Edit'),
      PermissionAction(
        key: 'delete',
        fullKey: 'visits.delete',
        label: 'Delete',
      ),
    ],
  ),
  PermissionModule(
    key: 'products',
    label: 'Product Catalog',
    icon: Icons.medication_rounded,
    color: _cInfo,
    actions: [
      PermissionAction(key: 'view', fullKey: 'products.view', label: 'View'),
      PermissionAction(
        key: 'create',
        fullKey: 'products.create',
        label: 'Create',
      ),
      PermissionAction(key: 'edit', fullKey: 'products.edit', label: 'Edit'),
      PermissionAction(
        key: 'delete',
        fullKey: 'products.delete',
        label: 'Delete',
      ),
      PermissionAction(
        key: 'promote',
        fullKey: 'products.promote',
        label: 'Promote',
      ),
    ],
  ),
  PermissionModule(
    key: 'inventory',
    label: 'Inventory & Stock',
    icon: Icons.inventory_2_rounded,
    color: _cOrange,
    actions: [
      PermissionAction(key: 'view', fullKey: 'inventory.view', label: 'View'),
      PermissionAction(
        key: 'create',
        fullKey: 'inventory.create',
        label: 'Create',
      ),
      PermissionAction(key: 'edit', fullKey: 'inventory.edit', label: 'Edit'),
      PermissionAction(
        key: 'adjust',
        fullKey: 'inventory.adjust',
        label: 'Adjust',
      ),
      PermissionAction(
        key: 'delete',
        fullKey: 'inventory.delete',
        label: 'Delete',
      ),
    ],
  ),
  PermissionModule(
    key: 'orders',
    label: 'Order Management',
    icon: Icons.receipt_long_rounded,
    color: _cPrimaryMid,
    actions: [
      PermissionAction(key: 'view', fullKey: 'orders.view', label: 'View'),
      PermissionAction(
        key: 'view_team',
        fullKey: 'orders.view_team',
        label: 'View Team',
      ),
      PermissionAction(
        key: 'create',
        fullKey: 'orders.create',
        label: 'Create',
      ),
      PermissionAction(
        key: 'approve',
        fullKey: 'orders.approve',
        label: 'Approve',
      ),
      PermissionAction(
        key: 'cancel',
        fullKey: 'orders.cancel',
        label: 'Cancel',
      ),
      PermissionAction(
        key: 'fulfill',
        fullKey: 'orders.fulfill',
        label: 'Fulfill',
      ),
    ],
  ),
  PermissionModule(
    key: 'payments',
    label: 'Payments',
    icon: Icons.payments_rounded,
    color: _cSuccess,
    actions: [
      PermissionAction(key: 'view', fullKey: 'payments.view', label: 'View'),
      PermissionAction(
        key: 'create',
        fullKey: 'payments.create',
        label: 'Create',
      ),
      PermissionAction(
        key: 'reconcile',
        fullKey: 'payments.reconcile',
        label: 'Reconcile',
      ),
      PermissionAction(
        key: 'refund',
        fullKey: 'payments.refund',
        label: 'Refund',
      ),
    ],
  ),
  PermissionModule(
    key: 'promotions',
    label: 'Promotions',
    icon: Icons.local_offer_rounded,
    color: _cError,
    actions: [
      PermissionAction(key: 'view', fullKey: 'promotions.view', label: 'View'),
      PermissionAction(
        key: 'create',
        fullKey: 'promotions.create',
        label: 'Create',
      ),
      PermissionAction(key: 'edit', fullKey: 'promotions.edit', label: 'Edit'),
      PermissionAction(
        key: 'delete',
        fullKey: 'promotions.delete',
        label: 'Delete',
      ),
    ],
  ),
  PermissionModule(
    key: 'reports',
    label: 'Reports / Analytics',
    icon: Icons.bar_chart_rounded,
    color: _cViolet,
    actions: [
      PermissionAction(
        key: 'view_own',
        fullKey: 'reports.view_own',
        label: 'Own',
      ),
      PermissionAction(
        key: 'view_team',
        fullKey: 'reports.view_team',
        label: 'Team',
      ),
      PermissionAction(
        key: 'view_org',
        fullKey: 'reports.view_org',
        label: 'Org',
      ),
      PermissionAction(
        key: 'export',
        fullKey: 'reports.export',
        label: 'Export',
      ),
    ],
  ),
  PermissionModule(
    key: 'messaging',
    label: 'Chat / Messaging',
    icon: Icons.chat_rounded,
    color: _cAccent,
    actions: [
      PermissionAction(key: 'view', fullKey: 'messaging.view', label: 'View'),
      PermissionAction(key: 'send', fullKey: 'messaging.send', label: 'Send'),
      PermissionAction(
        key: 'broadcast',
        fullKey: 'messaging.broadcast',
        label: 'Broadcast',
      ),
      PermissionAction(
        key: 'delete',
        fullKey: 'messaging.delete',
        label: 'Delete',
      ),
    ],
  ),
  PermissionModule(
    key: 'commissions',
    label: 'Commissions',
    icon: Icons.monetization_on_rounded,
    color: _cSuccess,
    actions: [
      PermissionAction(key: 'view', fullKey: 'commissions.view', label: 'View'),
      PermissionAction(
        key: 'configure',
        fullKey: 'commissions.configure',
        label: 'Configure',
      ),
      PermissionAction(
        key: 'approve',
        fullKey: 'commissions.approve',
        label: 'Approve',
      ),
    ],
  ),
  PermissionModule(
    key: 'billing',
    label: 'Billing',
    icon: Icons.credit_card_rounded,
    color: _cWarning,
    actions: [
      PermissionAction(key: 'view', fullKey: 'billing.view', label: 'View'),
      PermissionAction(
        key: 'manage',
        fullKey: 'billing.manage',
        label: 'Manage',
      ),
      PermissionAction(
        key: 'export',
        fullKey: 'billing.export',
        label: 'Export',
      ),
    ],
  ),
];

// Default permissions per role — Set<fullKey>
const Map<String, Set<String>> _defaultPerms = {
  'super_admin': {
    // All permissions — handled specially (shown as "Full Platform Access")
    'users.view', 'users.create', 'users.edit', 'users.delete', 'users.suspend',
    'orgs.view',
    'orgs.create',
    'orgs.edit',
    'orgs.delete',
    'orgs.manage_relationships',
    'customers.view', 'customers.create', 'customers.edit', 'customers.assign',
    'visits.view',
    'visits.view_team',
    'visits.create',
    'visits.edit',
    'visits.delete',
    'products.view',
    'products.create',
    'products.edit',
    'products.delete',
    'products.promote',
    'inventory.view',
    'inventory.create',
    'inventory.edit',
    'inventory.adjust',
    'inventory.delete',
    'orders.view',
    'orders.view_team',
    'orders.create',
    'orders.approve',
    'orders.cancel',
    'orders.fulfill',
    'payments.view', 'payments.create', 'payments.reconcile', 'payments.refund',
    'promotions.view',
    'promotions.create',
    'promotions.edit',
    'promotions.delete',
    'reports.view_own',
    'reports.view_team',
    'reports.view_org',
    'reports.export',
    'messaging.view',
    'messaging.send',
    'messaging.broadcast',
    'messaging.delete',
    'commissions.view', 'commissions.configure', 'commissions.approve',
    'billing.view', 'billing.manage', 'billing.export',
  },
  'org_admin': {
    'users.view',
    'users.create',
    'users.edit',
    'users.delete',
    'users.suspend',
    'orgs.view',
    'orgs.edit',
    'orgs.manage_relationships',
    'customers.view',
    'customers.create',
    'customers.edit',
    'customers.assign',
    'visits.view',
    'visits.view_team',
    'products.view',
    'products.create',
    'products.edit',
    'products.delete',
    'products.promote',
    'inventory.view',
    'orders.view',
    'orders.view_team',
    'orders.approve',
    'orders.cancel',
    'payments.view',
    'payments.create',
    'payments.reconcile',
    'payments.refund',
    'promotions.view',
    'promotions.create',
    'promotions.edit',
    'promotions.delete',
    'reports.view_own',
    'reports.view_team',
    'reports.view_org',
    'reports.export',
    'messaging.view',
    'messaging.send',
    'messaging.broadcast',
    'commissions.view',
    'commissions.configure',
    'commissions.approve',
    'billing.view',
  },
  'sales_supervisor': {
    'users.view',
    'customers.view',
    'customers.assign',
    'visits.view',
    'visits.view_team',
    'products.view',
    'orders.view',
    'orders.view_team',
    'orders.approve',
    'reports.view_own',
    'reports.view_team',
    'messaging.view',
    'messaging.send',
  },
  'marketing_officer': {
    'customers.view',
    'customers.create',
    'customers.edit',
    'visits.view',
    'visits.create',
    'visits.edit',
    'products.view',
    'products.promote',
    'orders.view',
    'orders.create',
    'reports.view_own',
    'messaging.view',
    'messaging.send',
  },
  'warehouse_staff': {
    'products.view',
    'inventory.view',
    'inventory.create',
    'inventory.edit',
    'inventory.adjust',
    'orders.view',
    'orders.fulfill',
    'reports.view_own',
  },
  'finance_accountant': {
    'orders.view',
    'payments.view',
    'payments.create',
    'payments.reconcile',
    'payments.refund',
    'reports.view_own',
    'reports.view_org',
    'reports.export',
    'commissions.view',
    'commissions.configure',
    'commissions.approve',
  },
  'delivery_driver': {'orders.view', 'messaging.view', 'messaging.send'},
  'customer_rep': {
    'customers.view',
    'products.view',
    'orders.view',
    'orders.create',
    'payments.view',
    'messaging.view',
    'messaging.send',
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// PAGE — STATEFUL
// ─────────────────────────────────────────────────────────────────────────────

class RolesPermissionsPage extends StatefulWidget {
  const RolesPermissionsPage({super.key});

  @override
  State<RolesPermissionsPage> createState() => _RolesPermissionsPageState();
}

class _RolesPermissionsPageState extends State<RolesPermissionsPage> {
  RoleModel _selectedRole = _roles[1]; // org_admin default
  // Mutable permission set for selected role (copy of defaults for editing)
  late Set<String> _activePerms;
  bool _hasChanges = false;
  bool _showOrgOverride = false;
  String? _selectedOrgOverride;

  @override
  void initState() {
    super.initState();
    _activePerms = Set.from(_defaultPerms[_selectedRole.slug] ?? {});
  }

  void _selectRole(RoleModel role) {
    setState(() {
      _selectedRole = role;
      _activePerms = Set.from(_defaultPerms[role.slug] ?? {});
      _hasChanges = false;
      _showOrgOverride = false;
      _selectedOrgOverride = null;
    });
  }

  void _togglePermission(String permKey) {
    if (_selectedRole.slug == 'super_admin') return; // immutable
    setState(() {
      _activePerms.contains(permKey)
          ? _activePerms.remove(permKey)
          : _activePerms.add(permKey);
      _hasChanges = true;
    });
  }

  void _grantAll(PermissionModule module) {
    if (_selectedRole.slug == 'super_admin') return;
    setState(() {
      for (final a in module.actions) {
        _activePerms.add(a.fullKey);
      }
      _hasChanges = true;
    });
  }

  void _revokeAll(PermissionModule module) {
    if (_selectedRole.slug == 'super_admin') return;
    setState(() {
      for (final a in module.actions) {
        _activePerms.remove(a.fullKey);
      }
      _hasChanges = true;
    });
  }

  void _resetToDefault() {
    setState(() {
      _activePerms = Set.from(_defaultPerms[_selectedRole.slug] ?? {});
      _hasChanges = false;
    });
  }

  int get _totalPermissions => _modules.fold(0, (s, m) => s + m.actions.length);

  int get _grantedCount => _activePerms.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: _RolesHeader(
              hasChanges: _hasChanges,
              onSave: () => setState(() => _hasChanges = false),
              onDiscard: _resetToDefault,
            ),
          ),
          const SizedBox(height: 20),
          // Stats strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _RbacStatsStrip(
              grantedCount: _grantedCount,
              totalPermissions: _totalPermissions,
              selectedRole: _selectedRole,
            ),
          ),
          const SizedBox(height: 20),
          // Main body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: Role list
                  SizedBox(
                    width: 280,
                    child: _RoleListPanel(
                      roles: _roles,
                      selected: _selectedRole,
                      onSelect: _selectRole,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // RIGHT: Permission matrix
                  Expanded(
                    child: _PermissionMatrixPanel(
                      role: _selectedRole,
                      modules: _modules,
                      activePerms: _activePerms,
                      onToggle: _togglePermission,
                      onGrantAll: _grantAll,
                      onRevokeAll: _revokeAll,
                      onResetDefault: _resetToDefault,
                      hasChanges: _hasChanges,
                      grantedCount: _grantedCount,
                      totalCount: _totalPermissions,
                      showOrgOverride: _showOrgOverride,
                      onToggleOrgOverride: () =>
                          setState(() => _showOrgOverride = !_showOrgOverride),
                      selectedOrg: _selectedOrgOverride,
                      onOrgSelected: (o) =>
                          setState(() => _selectedOrgOverride = o),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _RolesHeader extends StatelessWidget {
  final bool hasChanges;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _RolesHeader({
    required this.hasChanges,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _cViolet,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Roles & Permissions',
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
                '8 roles  ·  60+ permissions  ·  13 modules  ·  Powered by Spatie Laravel Permission',
                style: text.bodySmall?.copyWith(color: _cTextSecondary),
              ),
            ),
          ],
        ),
        const Spacer(),
        // Unsaved changes banner
        if (hasChanges)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _cWarningLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cWarning.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit_rounded, color: _cWarning, size: 14),
                const SizedBox(width: 7),
                Text(
                  'Unsaved changes',
                  style: text.labelSmall?.copyWith(
                    color: _cWarning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _cVioletLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cViolet.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security_rounded, color: _cViolet, size: 14),
              const SizedBox(width: 6),
              Text(
                'Spatie Team-Scoped',
                style: text.labelSmall?.copyWith(
                  color: _cViolet,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (hasChanges) ...[
          OutlinedButton(
            onPressed: onDiscard,
            style: OutlinedButton.styleFrom(
              foregroundColor: _cError,
              side: const BorderSide(color: _cError, width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Discard'),
          ),
          const SizedBox(width: 10),
        ],
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_rounded, size: 16),
          label: const Text('Save Changes'),
          style: FilledButton.styleFrom(
            backgroundColor: hasChanges ? _cViolet : _cPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _RbacStatsStrip extends StatelessWidget {
  final int grantedCount;
  final int totalPermissions;
  final RoleModel selectedRole;

  const _RbacStatsStrip({
    required this.grantedCount,
    required this.totalPermissions,
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (grantedCount / totalPermissions * 100).toStringAsFixed(0);
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.people_alt_rounded,
            iconColor: _cPrimary,
            iconBg: _cPrimaryLight,
            label: 'Total Roles',
            value: '8',
            sub: '1 platform  ·  7 org',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            icon: Icons.lock_rounded,
            iconColor: _cViolet,
            iconBg: _cVioletLight,
            label: 'Total Permissions',
            value: '$totalPermissions',
            sub: '13 modules',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_rounded,
            iconColor: selectedRole.color,
            iconBg: selectedRole.colorLight,
            label: 'Granted to ${selectedRole.displayName}',
            value: '$grantedCount',
            sub: '$pct% of all permissions',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            icon: Icons.groups_rounded,
            iconColor: _cAccent,
            iconBg: _cAccentLight,
            label: 'Platform Users',
            value: '908',
            sub: 'Across all org roles',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            icon: Icons.business_rounded,
            iconColor: _cSuccess,
            iconBg: _cSuccessLight,
            label: 'Org-Level Overrides',
            value: '3',
            sub: 'Custom role configs',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            icon: Icons.history_rounded,
            iconColor: _cWarning,
            iconBg: _cWarningLight,
            label: 'Last Permission Change',
            value: '2h ago',
            sub: 'By superadmin@pharmaos.tz',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String sub;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _cTextPrimary,
                  ),
                ),
                Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub,
                  style: text.labelSmall?.copyWith(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROLE LIST PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _RoleListPanel extends StatelessWidget {
  final List<RoleModel> roles;
  final RoleModel selected;
  final void Function(RoleModel) onSelect;

  const _RoleListPanel({
    required this.roles,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final platformRoles = roles
        .where((r) => r.tier == RoleTier.platform)
        .toList();
    final orgRoles = roles
        .where((r) => r.tier == RoleTier.organization)
        .toList();

    return Container(
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _cBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.manage_accounts_rounded,
                  color: _cViolet,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Text(
                  'All Roles',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cTextPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _cVioletLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${roles.length}',
                    style: text.labelSmall?.copyWith(
                      color: _cViolet,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              children: [
                // Platform tier section
                _SectionLabel('PLATFORM TIER', _cError),
                ...platformRoles.map(
                  (r) => _RoleListItem(
                    role: r,
                    isSelected: r.slug == selected.slug,
                    onTap: () => onSelect(r),
                  ),
                ),
                const SizedBox(height: 4),
                // Org tier section
                _SectionLabel('ORGANIZATION TIER', _cPrimary),
                ...orgRoles.map(
                  (r) => _RoleListItem(
                    role: r,
                    isSelected: r.slug == selected.slug,
                    onTap: () => onSelect(r),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _RoleListItem extends StatelessWidget {
  final RoleModel role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleListItem({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final totalPerms = _defaultPerms[role.slug]?.length ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? role.color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? role.color.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Role icon
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? role.color.withOpacity(0.15)
                    : role.colorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(role.icon, color: role.color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.displayName,
                    style: text.bodySmall?.copyWith(
                      color: isSelected ? role.color : _cTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '$totalPerms perms',
                        style: text.labelSmall?.copyWith(
                          color: isSelected
                              ? role.color.withOpacity(0.7)
                              : _cTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '·',
                        style: TextStyle(color: _cTextSecondary, fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${role.userCount} users',
                        style: text.labelSmall?.copyWith(
                          color: isSelected
                              ? role.color.withOpacity(0.7)
                              : _cTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // User count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? role.color.withOpacity(0.12)
                    : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${role.userCount}',
                style: text.labelSmall?.copyWith(
                  color: isSelected ? role.color : _cTextSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            if (!role.isEditable) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_rounded, size: 12, color: _cError),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERMISSION MATRIX PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionMatrixPanel extends StatelessWidget {
  final RoleModel role;
  final List<PermissionModule> modules;
  final Set<String> activePerms;
  final void Function(String) onToggle;
  final void Function(PermissionModule) onGrantAll;
  final void Function(PermissionModule) onRevokeAll;
  final VoidCallback onResetDefault;
  final bool hasChanges;
  final int grantedCount;
  final int totalCount;
  final bool showOrgOverride;
  final VoidCallback onToggleOrgOverride;
  final String? selectedOrg;
  final void Function(String?) onOrgSelected;

  const _PermissionMatrixPanel({
    required this.role,
    required this.modules,
    required this.activePerms,
    required this.onToggle,
    required this.onGrantAll,
    required this.onRevokeAll,
    required this.onResetDefault,
    required this.hasChanges,
    required this.grantedCount,
    required this.totalCount,
    required this.showOrgOverride,
    required this.onToggleOrgOverride,
    required this.selectedOrg,
    required this.onOrgSelected,
  });

  bool get _isLocked => role.slug == 'super_admin';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Matrix top bar
          _MatrixTopBar(
            role: role,
            grantedCount: grantedCount,
            totalCount: totalCount,
            isLocked: _isLocked,
            hasChanges: hasChanges,
            onReset: onResetDefault,
            showOrgOverride: showOrgOverride,
            onToggleOrgOverride: onToggleOrgOverride,
            selectedOrg: selectedOrg,
            onOrgSelected: onOrgSelected,
          ),
          // Super admin special view
          if (_isLocked)
            _SuperAdminBanner()
          else
          // Org override picker
          if (showOrgOverride)
            _OrgOverridePicker(
              selectedOrg: selectedOrg,
              onSelect: onOrgSelected,
              roleColor: role.color,
            ),
          // Permission matrix
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              child: Column(
                children: modules
                    .map(
                      (m) => _ModulePermissionRow(
                        module: m,
                        activePerms: activePerms,
                        onToggle: onToggle,
                        onGrantAll: () => onGrantAll(m),
                        onRevokeAll: () => onRevokeAll(m),
                        isLocked: _isLocked,
                        roleColor: role.color,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Matrix top bar ────────────────────────────────────────────────────────────

class _MatrixTopBar extends StatelessWidget {
  final RoleModel role;
  final int grantedCount;
  final int totalCount;
  final bool isLocked;
  final bool hasChanges;
  final VoidCallback onReset;
  final bool showOrgOverride;
  final VoidCallback onToggleOrgOverride;
  final String? selectedOrg;
  final void Function(String?) onOrgSelected;

  const _MatrixTopBar({
    required this.role,
    required this.grantedCount,
    required this.totalCount,
    required this.isLocked,
    required this.hasChanges,
    required this.onReset,
    required this.showOrgOverride,
    required this.onToggleOrgOverride,
    required this.selectedOrg,
    required this.onOrgSelected,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pct = grantedCount / totalCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: _cBorder)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: role.colorLight.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Role badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: role.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: role.color.withOpacity(0.3)),
                ),
                child: Icon(role.icon, color: role.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          role.displayName,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _cTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _TierBadge(tier: role.tier, color: role.color),
                        const SizedBox(width: 8),
                        if (isLocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _cErrorLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  size: 10,
                                  color: _cError,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Immutable',
                                  style: text.labelSmall?.copyWith(
                                    color: _cError,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        // App badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_android_rounded,
                                size: 10,
                                color: _cTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                role.primaryApp,
                                style: text.labelSmall?.copyWith(
                                  color: _cTextSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.description,
                      style: text.bodySmall?.copyWith(color: _cTextSecondary),
                    ),
                  ],
                ),
              ),
              // Actions
              if (!isLocked) ...[
                OutlinedButton.icon(
                  onPressed: onToggleOrgOverride,
                  icon: Icon(
                    showOrgOverride ? Icons.close_rounded : Icons.tune_rounded,
                    size: 14,
                  ),
                  label: Text(
                    showOrgOverride ? 'Close Override' : 'Org Override',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: showOrgOverride ? _cError : _cViolet,
                    side: BorderSide(
                      color: showOrgOverride
                          ? _cError.withOpacity(0.5)
                          : _cViolet.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 14),
                  label: const Text('Reset Default'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cTextPrimary,
                    side: const BorderSide(color: _cBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // Permission coverage bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$grantedCount of $totalCount permissions granted',
                          style: text.labelSmall?.copyWith(
                            color: _cTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${(pct * 100).toStringAsFixed(0)}%)',
                          style: text.labelSmall?.copyWith(
                            color: role.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        // User count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: role.colorLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people_rounded,
                                size: 11,
                                color: role.color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${role.userCount} users with this role',
                                style: text.labelSmall?.copyWith(
                                  color: role.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: _cBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(role.color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final RoleTier tier;
  final Color color;
  const _TierBadge({required this.tier, required this.color});

  @override
  Widget build(BuildContext context) {
    final isPlatform = tier == RoleTier.platform;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isPlatform ? 'PLATFORM TIER' : 'ORG TIER',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Super Admin special banner ────────────────────────────────────────────────

class _SuperAdminBanner extends StatelessWidget {
  const _SuperAdminBanner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_cError.withOpacity(0.07), _cViolet.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cError.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cErrorLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: _cError, size: 24),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin — Full Platform Access',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _cError,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Super Admin role has unrestricted access to every permission on the platform. '
                  'This role operates outside any tenant or organization scope and cannot be modified. '
                  'Assign this role only to trusted platform operators.',
                  style: text.bodySmall?.copyWith(
                    color: _cTextSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          // All permissions listed as chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _modules
                .map(
                  (m) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _cErrorLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _cError.withOpacity(0.3)),
                    ),
                    child: Text(
                      m.label,
                      style: text.labelSmall?.copyWith(
                        color: _cError,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Org override picker ───────────────────────────────────────────────────────

class _OrgOverridePicker extends StatelessWidget {
  final String? selectedOrg;
  final void Function(String?) onSelect;
  final Color roleColor;

  const _OrgOverridePicker({
    required this.selectedOrg,
    required this.onSelect,
    required this.roleColor,
  });

  static const _orgs = [
    'Bariki Pharma Ltd',
    'MedPlus Pharmacy Dar',
    'Coastal Distributors',
    'Arusha Health Chain',
    'Kilimanjaro MedHub',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cVioletLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cViolet.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _cViolet, size: 15),
              const SizedBox(width: 7),
              Text(
                'Organization-Level Override',
                style: text.titleSmall?.copyWith(
                  color: _cViolet,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '— Select an org to configure custom permissions for this role within that org only.',
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selectedOrg != null)
                TextButton(
                  onPressed: () => onSelect(null),
                  style: TextButton.styleFrom(
                    foregroundColor: _cError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Clear Org',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _orgs
                .map(
                  (org) => GestureDetector(
                    onTap: () => onSelect(org == selectedOrg ? null : org),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: org == selectedOrg ? _cViolet : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: org == selectedOrg ? _cViolet : _cBorder,
                        ),
                      ),
                      child: Text(
                        org,
                        style: text.labelSmall?.copyWith(
                          color: org == selectedOrg
                              ? Colors.white
                              : _cTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          if (selectedOrg != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _cViolet.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _cViolet,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Editing permissions for $selectedOrg — '
                      'changes override platform defaults for this org only. '
                      'Other orgs are not affected.',
                      style: text.bodySmall?.copyWith(
                        color: _cViolet,
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Permission module row ────────────────────────────────────────────────────

class _ModulePermissionRow extends StatelessWidget {
  final PermissionModule module;
  final Set<String> activePerms;
  final void Function(String) onToggle;
  final VoidCallback onGrantAll;
  final VoidCallback onRevokeAll;
  final bool isLocked;
  final Color roleColor;

  const _ModulePermissionRow({
    required this.module,
    required this.activePerms,
    required this.onToggle,
    required this.onGrantAll,
    required this.onRevokeAll,
    required this.isLocked,
    required this.roleColor,
  });

  int get _grantedInModule =>
      module.actions.where((a) => activePerms.contains(a.fullKey)).length;
  bool get _allGranted => _grantedInModule == module.actions.length;
  bool get _noneGranted => _grantedInModule == 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final grantedCount = _grantedInModule;
    final totalCount = module.actions.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cBorder, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Module label column
            SizedBox(
              width: 220,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: module.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(module.icon, color: module.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.label,
                          style: text.bodySmall?.copyWith(
                            color: _cTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$grantedCount / $totalCount granted',
                          style: text.labelSmall?.copyWith(
                            color: _noneGranted
                                ? _cTextSecondary
                                : module.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Permission toggles
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: module.actions
                    .map(
                      (action) => _PermissionToggle(
                        action: action,
                        isActive: activePerms.contains(action.fullKey),
                        onTap: isLocked ? null : () => onToggle(action.fullKey),
                        activeColor: roleColor,
                        moduleColor: module.color,
                        isLocked: isLocked,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(width: 16),
            // Grant all / Revoke all
            if (!isLocked)
              SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_allGranted)
                      InkWell(
                        onTap: onGrantAll,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: roleColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            'Grant All',
                            style: text.labelSmall?.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    if (!_allGranted && !_noneGranted) const SizedBox(width: 6),
                    if (!_noneGranted)
                      InkWell(
                        onTap: onRevokeAll,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _cErrorLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _cError.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Revoke All',
                            style: text.labelSmall?.copyWith(
                              color: _cError,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(width: 140),
          ],
        ),
      ),
    );
  }
}

// ── Individual permission toggle ──────────────────────────────────────────────

class _PermissionToggle extends StatelessWidget {
  final PermissionAction action;
  final bool isActive;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color moduleColor;
  final bool isLocked;

  const _PermissionToggle({
    required this.action,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    required this.moduleColor,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Tooltip(
      message: isLocked
          ? '${action.fullKey}  —  Locked (Super Admin)'
          : isActive
          ? 'Click to revoke: ${action.fullKey}'
          : 'Click to grant: ${action.fullKey}',
      preferBelow: false,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withOpacity(0.1)
                : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive
                  ? activeColor.withOpacity(0.45)
                  : const Color(0xFFE5E7EB),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Check / X icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isActive
                    ? Icon(
                        Icons.check_rounded,
                        key: const ValueKey(true),
                        color: activeColor,
                        size: 13,
                      )
                    : Icon(
                        Icons.remove_rounded,
                        key: const ValueKey(false),
                        color: _cTextSecondary,
                        size: 13,
                      ),
              ),
              const SizedBox(width: 5),
              Text(
                action.label,
                style: text.labelSmall?.copyWith(
                  color: isActive ? activeColor : _cTextSecondary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
