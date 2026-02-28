// organization_detail_page.dart
// Organization Detail — deep single-org view.
//
// Sections (tab-based):
//   [0] Overview    — header card, KPIs, territory, commission configs
//   [1] Users       — all users in this org, roles, status, quick actions
//   [2] Relationships — supply chain links (parent + child orgs), pricing tiers
//   [3] Billing     — subscription plan, payment status, usage limits
//
// Usage:
//   Navigator.pushNamed(context, AppRouter.organizationDetail,
//     arguments: {'id': org.id});
//
// No AppBar. No Drawer. Pure page content — caller's shell provides chrome.
//
// Location: features/organization/presentation/pages/organization_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Local models (swap for real domain entities) ────────────────────────────

enum OrgType { pharmacy, distributor, supplier, manufacturer, logistics }

enum OrgStatus { active, inactive, pending, suspended }

enum UserRole {
  orgAdmin,
  salesSupervisor,
  marketingOfficer,
  warehouseStaff,
  financeAccountant,
  deliveryDriver,
  customerRep,
}

enum UserStatus { active, suspended, pending }

enum RelationshipType { supplies, serves, partners, ownsBranch, franchises }

enum PlanTier { starter, professional, enterprise }

enum BillingStatus { active, trialing, pastDue, cancelled }

// ─── Models ──────────────────────────────────────────────────────────────────

class _OrgDetail {
  final String id;
  final String name;
  final String slug;
  final String email;
  final String phone;
  final String address;
  final String registrationNumber;
  final List<OrgType> types;
  final OrgType primaryType;
  final OrgStatus status;
  final String territory;
  final bool isVerified;
  final DateTime? verifiedAt;
  final DateTime onboardedAt;
  final DateTime createdAt;
  final double? gpsLat;
  final double? gpsLng;

  const _OrgDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.email,
    required this.phone,
    required this.address,
    required this.registrationNumber,
    required this.types,
    required this.primaryType,
    required this.status,
    required this.territory,
    required this.isVerified,
    this.verifiedAt,
    required this.onboardedAt,
    required this.createdAt,
    this.gpsLat,
    this.gpsLng,
  });
}

class _OrgUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final UserStatus status;
  final DateTime? lastLogin;
  final String? avatarInitials;

  const _OrgUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.lastLogin,
    this.avatarInitials,
  });
}

class _OrgRelationship {
  final String id;
  final String partnerName;
  final String partnerSlug;
  final List<OrgType> partnerTypes;
  final RelationshipType type;
  final bool isParent; // true = they are our supplier/parent
  final String? assignedOfficer;
  final String? pricingTier;
  final double? creditLimit;
  final int? paymentTermsDays;
  final bool isActive;
  final String territory;

  const _OrgRelationship({
    required this.id,
    required this.partnerName,
    required this.partnerSlug,
    required this.partnerTypes,
    required this.type,
    required this.isParent,
    this.assignedOfficer,
    this.pricingTier,
    this.creditLimit,
    this.paymentTermsDays,
    required this.isActive,
    required this.territory,
  });
}

class _PricingTier {
  final String name;
  final String discountType;
  final double discountValue;
  final double? minOrderValue;
  final bool isDefault;
  final int orgCount;

  const _PricingTier({
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.minOrderValue,
    required this.isDefault,
    required this.orgCount,
  });
}

class _CommissionConfig {
  final String roleName;
  final String calculationBasis;
  final double rate;
  final bool isActive;
  final DateTime effectiveFrom;

  const _CommissionConfig({
    required this.roleName,
    required this.calculationBasis,
    required this.rate,
    required this.isActive,
    required this.effectiveFrom,
  });
}

class _BillingInfo {
  final PlanTier tier;
  final BillingStatus status;
  final double monthlyPrice;
  final String billingCycle;
  final DateTime periodEnd;
  final int maxUsers;
  final int currentUsers;
  final bool hasWhatsApp;
  final bool hasMobileMoney;
  final bool hasAdvancedAnalytics;

  const _BillingInfo({
    required this.tier,
    required this.status,
    required this.monthlyPrice,
    required this.billingCycle,
    required this.periodEnd,
    required this.maxUsers,
    required this.currentUsers,
    required this.hasWhatsApp,
    required this.hasMobileMoney,
    required this.hasAdvancedAnalytics,
  });
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final _mockOrg = _OrgDetail(
  id: '01HX001',
  name: 'Bariki Pharmaceuticals',
  slug: 'bariki-pharma',
  email: 'admin@barikipharma.co.tz',
  phone: '+255 744 123 456',
  address: 'Plot 45, Mwanjelwa Zone, Mbeya District, Mbeya Region',
  registrationNumber: 'TFDA/REG/2021/00342',
  types: [OrgType.distributor, OrgType.pharmacy],
  primaryType: OrgType.distributor,
  status: OrgStatus.active,
  territory: 'Mbeya Region',
  isVerified: true,
  verifiedAt: DateTime(2024, 3, 10),
  onboardedAt: DateTime(2024, 3, 15),
  createdAt: DateTime(2024, 3, 1),
  gpsLat: -8.9094,
  gpsLng: 33.4608,
);

final _mockUsers = [
  _OrgUser(
    id: 'u001',
    name: 'Amina Mwangi',
    email: 'amina@barikipharma.co.tz',
    phone: '+255 744 001 001',
    role: UserRole.orgAdmin,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
    avatarInitials: 'AM',
  ),
  _OrgUser(
    id: 'u002',
    name: 'James Kilonzo',
    email: 'james@barikipharma.co.tz',
    phone: '+255 756 002 002',
    role: UserRole.salesSupervisor,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(hours: 3)),
    avatarInitials: 'JK',
  ),
  _OrgUser(
    id: 'u003',
    name: 'Fatuma Hassan',
    email: 'fatuma@barikipharma.co.tz',
    phone: '+255 712 003 003',
    role: UserRole.marketingOfficer,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(hours: 5)),
    avatarInitials: 'FH',
  ),
  _OrgUser(
    id: 'u004',
    name: 'Peter Ngowi',
    email: 'peter@barikipharma.co.tz',
    phone: '+255 768 004 004',
    role: UserRole.marketingOfficer,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(days: 1)),
    avatarInitials: 'PN',
  ),
  _OrgUser(
    id: 'u005',
    name: 'Grace Malale',
    email: 'grace@barikipharma.co.tz',
    phone: '+255 723 005 005',
    role: UserRole.warehouseStaff,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
    avatarInitials: 'GM',
  ),
  _OrgUser(
    id: 'u006',
    name: 'Ali Msangi',
    email: 'ali@barikipharma.co.tz',
    phone: '+255 745 006 006',
    role: UserRole.financeAccountant,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(hours: 4)),
    avatarInitials: 'AM',
  ),
  _OrgUser(
    id: 'u007',
    name: 'David Temba',
    email: 'david@barikipharma.co.tz',
    phone: '+255 754 007 007',
    role: UserRole.deliveryDriver,
    status: UserStatus.active,
    lastLogin: DateTime.now().subtract(const Duration(minutes: 30)),
    avatarInitials: 'DT',
  ),
  _OrgUser(
    id: 'u008',
    name: 'Sarah Juma',
    email: 'sarah@barikipharma.co.tz',
    phone: '+255 789 008 008',
    role: UserRole.marketingOfficer,
    status: UserStatus.suspended,
    lastLogin: DateTime.now().subtract(const Duration(days: 14)),
    avatarInitials: 'SJ',
  ),
];

final _mockRelationships = [
  _OrgRelationship(
    id: 'r001',
    partnerName: 'Mwanjelwa Pharmacy',
    partnerSlug: 'mwanjelwa-pharmacy',
    partnerTypes: [OrgType.pharmacy],
    type: RelationshipType.supplies,
    isParent: false,
    assignedOfficer: 'Fatuma Hassan',
    pricingTier: 'Gold',
    creditLimit: 2000000,
    paymentTermsDays: 30,
    isActive: true,
    territory: 'Mbeya District',
  ),
  _OrgRelationship(
    id: 'r002',
    partnerName: 'Kariakoo MedStore',
    partnerSlug: 'kariakoo-med',
    partnerTypes: [OrgType.pharmacy],
    type: RelationshipType.supplies,
    isParent: false,
    assignedOfficer: 'Peter Ngowi',
    pricingTier: 'Standard',
    creditLimit: null,
    paymentTermsDays: null,
    isActive: true,
    territory: 'Dar es Salaam',
  ),
  _OrgRelationship(
    id: 'r003',
    partnerName: 'Uyole Health Supplies',
    partnerSlug: 'uyole-health',
    partnerTypes: [OrgType.supplier, OrgType.distributor],
    type: RelationshipType.supplies,
    isParent: true,
    assignedOfficer: null,
    pricingTier: 'Wholesale',
    creditLimit: 10000000,
    paymentTermsDays: 45,
    isActive: true,
    territory: 'Mbeya District',
  ),
  _OrgRelationship(
    id: 'r004',
    partnerName: 'Njombe District Pharmacy',
    partnerSlug: 'njombe-pharmacy',
    partnerTypes: [OrgType.pharmacy],
    type: RelationshipType.serves,
    isParent: false,
    assignedOfficer: 'Fatuma Hassan',
    pricingTier: 'Walk-In',
    creditLimit: null,
    paymentTermsDays: null,
    isActive: false,
    territory: 'Njombe Region',
  ),
];

final _mockPricingTiers = [
  _PricingTier(
    name: 'Gold',
    discountType: 'percentage',
    discountValue: 15,
    minOrderValue: 500000,
    isDefault: false,
    orgCount: 3,
  ),
  _PricingTier(
    name: 'Standard',
    discountType: 'percentage',
    discountValue: 8,
    minOrderValue: 100000,
    isDefault: true,
    orgCount: 7,
  ),
  _PricingTier(
    name: 'Walk-In',
    discountType: 'none',
    discountValue: 0,
    minOrderValue: null,
    isDefault: false,
    orgCount: 2,
  ),
  _PricingTier(
    name: 'Wholesale',
    discountType: 'percentage',
    discountValue: 20,
    minOrderValue: 2000000,
    isDefault: false,
    orgCount: 1,
  ),
];

final _mockCommissions = [
  _CommissionConfig(
    roleName: 'Marketing Officer',
    calculationBasis: 'percentage_of_order_value',
    rate: 2.5,
    isActive: true,
    effectiveFrom: DateTime(2024, 1, 1),
  ),
  _CommissionConfig(
    roleName: 'Sales Supervisor',
    calculationBasis: 'per_order',
    rate: 5000,
    isActive: true,
    effectiveFrom: DateTime(2024, 1, 1),
  ),
  _CommissionConfig(
    roleName: 'Delivery Driver',
    calculationBasis: 'per_order',
    rate: 3000,
    isActive: true,
    effectiveFrom: DateTime(2024, 3, 1),
  ),
];

final _mockBilling = _BillingInfo(
  tier: PlanTier.professional,
  status: BillingStatus.active,
  monthlyPrice: 450000,
  billingCycle: 'annual',
  periodEnd: DateTime(2026, 3, 15),
  maxUsers: 25,
  currentUsers: 8,
  hasWhatsApp: true,
  hasMobileMoney: true,
  hasAdvancedAnalytics: false,
);

// ─── Page ─────────────────────────────────────────────────────────────────────

class OrganizationDetailPage extends StatefulWidget {
  /// In real use, receive the org ID and load via bloc.
  /// Passing null uses mock data.
  final String? orgId;

  const OrganizationDetailPage({super.key, this.orgId});

  @override
  State<OrganizationDetailPage> createState() => _OrganizationDetailPageState();
}

class _OrganizationDetailPageState extends State<OrganizationDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = _mockOrg;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Sticky org header card ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _OrgHeaderCard(
              org: org,
              onEdit: () => _showSnack('Open edit form for ${org.name}'),
              onSuspend: () => _showSnack('Suspend ${org.name}'),
              onImpersonate: () =>
                  _showSnack('Impersonate admin of ${org.name}'),
              onCopyId: () {
                Clipboard.setData(ClipboardData(text: org.id));
                _showSnack('Copied org ID');
              },
            ),
          ),
          // ── Stat ribbon ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StatRibbon(
              userCount: _mockUsers.length,
              activeUserCount: _mockUsers
                  .where((u) => u.status == UserStatus.active)
                  .length,
              relationshipCount: _mockRelationships.length,
              activeRelCount: _mockRelationships
                  .where((r) => r.isActive)
                  .length,
              pricingTierCount: _mockPricingTiers.length,
            ),
          ),
          // ── Tab bar ────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Users'),
                  Tab(text: 'Relationships'),
                  Tab(text: 'Billing'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(
              org: org,
              commissions: _mockCommissions,
              onAction: _showSnack,
            ),
            _UsersTab(users: _mockUsers, onAction: _showSnack),
            _RelationshipsTab(
              relationships: _mockRelationships,
              pricingTiers: _mockPricingTiers,
              onAction: _showSnack,
            ),
            _BillingTab(billing: _mockBilling, onAction: _showSnack),
          ],
        ),
      ),
    );
  }
}

// ─── Sticky tab bar delegate ──────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}

// ─── Org Header Card ──────────────────────────────────────────────────────────

class _OrgHeaderCard extends StatelessWidget {
  final _OrgDetail org;
  final VoidCallback onEdit;
  final VoidCallback onSuspend;
  final VoidCallback onImpersonate;
  final VoidCallback onCopyId;

  const _OrgHeaderCard({
    required this.org,
    required this.onEdit,
    required this.onSuspend,
    required this.onImpersonate,
    required this.onCopyId,
  });

  Color get _primaryTypeColor => switch (org.primaryType) {
    OrgType.pharmacy => Colors.teal,
    OrgType.distributor => Colors.indigo,
    OrgType.supplier => Colors.orange,
    OrgType.manufacturer => Colors.purple,
    OrgType.logistics => Colors.blue,
  };

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryTypeColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _primaryTypeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _primaryTypeColor.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  org.name.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: _primaryTypeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (org.isVerified)
                          Tooltip(
                            message:
                                'Verified on '
                                '${_formatDate(org.verifiedAt!)}',
                            child: Icon(
                              Icons.verified_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${org.slug}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
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
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...org.types
                            .take(2)
                            .map(
                              (t) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _TypeBadge(type: t),
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
                  ],
                ),
              ),
              // Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) => switch (v) {
                  'edit' => onEdit(),
                  'impersonate' => onImpersonate(),
                  'copy_id' => onCopyId(),
                  'suspend' => onSuspend(),
                  _ => null,
                },
                itemBuilder: (_) => [
                  _menuItem('edit', Icons.edit_outlined, 'Edit Organization'),
                  _menuItem(
                    'impersonate',
                    Icons.switch_account_outlined,
                    'Impersonate Admin',
                  ),
                  _menuItem('copy_id', Icons.copy_outlined, 'Copy Org ID'),
                  const PopupMenuDivider(),
                  _menuItem(
                    'suspend',
                    Icons.pause_circle_outline,
                    org.status == OrgStatus.suspended
                        ? 'Reactivate'
                        : 'Suspend',
                    color: org.status == OrgStatus.suspended
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Contact info row
          _InfoRow(icon: Icons.email_outlined, text: org.email),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.phone_outlined, text: org.phone),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.location_on_outlined, text: org.address),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.badge_outlined,
            text: org.registrationNumber,
            mono: true,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            text:
                'Onboarded ${_formatDate(org.onboardedAt)} · Created ${_formatDate(org.createdAt)}',
          ),
        ],
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
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: color != null ? TextStyle(color: color) : null),
      ],
    ),
  );

  String _formatDate(DateTime dt) => '${dt.day} ${_month(dt.month)} ${dt.year}';

  String _month(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool mono;

  const _InfoRow({required this.icon, required this.text, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stat Ribbon ─────────────────────────────────────────────────────────────

class _StatRibbon extends StatelessWidget {
  final int userCount;
  final int activeUserCount;
  final int relationshipCount;
  final int activeRelCount;
  final int pricingTierCount;

  const _StatRibbon({
    required this.userCount,
    required this.activeUserCount,
    required this.relationshipCount,
    required this.activeRelCount,
    required this.pricingTierCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _RibbonStat(
              value: '$activeUserCount',
              label: 'Active Users',
              sublabel: 'of $userCount total',
              icon: Icons.people_outline,
              color: Colors.blue,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            _RibbonStat(
              value: '$activeRelCount',
              label: 'Active Links',
              sublabel: 'of $relationshipCount orgs',
              icon: Icons.hub_outlined,
              color: Colors.indigo,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            _RibbonStat(
              value: '$pricingTierCount',
              label: 'Pricing Tiers',
              sublabel: 'configured',
              icon: Icons.sell_outlined,
              color: Colors.teal,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            _RibbonStat(
              value: '23',
              label: 'Orders',
              sublabel: 'in progress',
              icon: Icons.receipt_long_outlined,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonStat extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;

  const _RibbonStat({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              sublabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 0 — OVERVIEW
// ══════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final _OrgDetail org;
  final List<_CommissionConfig> commissions;
  final void Function(String) onAction;

  const _OverviewTab({
    required this.org,
    required this.commissions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Organization Types
        _SectionHeader(
          title: 'Organization Types',
          action: 'Manage',
          onAction: () => onAction('Manage types'),
        ),
        const SizedBox(height: 10),
        _OrgTypesCard(types: org.types, primaryType: org.primaryType),
        const SizedBox(height: 20),

        // Territory
        _SectionHeader(
          title: 'Territory',
          action: 'Reassign',
          onAction: () => onAction('Reassign territory'),
        ),
        const SizedBox(height: 10),
        _TerritoryCard(
          territory: org.territory,
          gpsLat: org.gpsLat,
          gpsLng: org.gpsLng,
          onViewMap: () => onAction('Open map'),
        ),
        const SizedBox(height: 20),

        // Commission Configs
        _SectionHeader(
          title: 'Commission Configuration',
          action: 'Add Config',
          onAction: () => onAction('Add commission config'),
        ),
        const SizedBox(height: 10),
        ...commissions.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CommissionConfigCard(
              config: c,
              onEdit: () => onAction('Edit commission for ${c.roleName}'),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // GPS location card
        if (org.gpsLat != null) ...[
          _SectionHeader(title: 'Location', action: null, onAction: null),
          const SizedBox(height: 10),
          _GpsCard(lat: org.gpsLat!, lng: org.gpsLng!),
          const SizedBox(height: 20),
        ],

        // Danger zone
        _DangerZoneCard(
          orgName: org.name,
          status: org.status,
          onSuspend: () => onAction('Suspend org'),
          onDelete: () => onAction('Delete org — confirmation required'),
        ),
      ],
    );
  }
}

class _OrgTypesCard extends StatelessWidget {
  final List<OrgType> types;
  final OrgType primaryType;

  const _OrgTypesCard({required this.types, required this.primaryType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: OrgType.values
            .where((t) => types.contains(t))
            .map(
              (t) => _TypeRow(
                type: t,
                isPrimary: t == primaryType,
                isAssigned: true,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  final OrgType type;
  final bool isPrimary;
  final bool isAssigned;

  const _TypeRow({
    required this.type,
    required this.isPrimary,
    required this.isAssigned,
  });

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
    OrgType.pharmacy => 'Pharmacy',
    OrgType.distributor => 'Distributor',
    OrgType.supplier => 'Supplier',
    OrgType.manufacturer => 'Manufacturer',
    OrgType.logistics => 'Logistics',
  };

  String get _description => switch (type) {
    OrgType.pharmacy => 'Retail pharmacy — places orders, serves customers',
    OrgType.distributor => 'Distributes products to pharmacies & other orgs',
    OrgType.supplier => 'Supplies stock to distributors & manufacturers',
    OrgType.manufacturer => 'Manufactures pharmaceutical products',
    OrgType.logistics => 'Manages delivery and transport operations',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 18, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Primary',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, size: 18, color: _color),
        ],
      ),
    );
  }
}

class _TerritoryCard extends StatelessWidget {
  final String territory;
  final double? gpsLat;
  final double? gpsLng;
  final VoidCallback onViewMap;

  const _TerritoryCard({
    required this.territory,
    this.gpsLat,
    this.gpsLng,
    required this.onViewMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.map_outlined,
              size: 24,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  territory,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (gpsLat != null)
                  Text(
                    '${gpsLat!.toStringAsFixed(4)}, ${gpsLng!.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onViewMap,
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Map'),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

class _CommissionConfigCard extends StatelessWidget {
  final _CommissionConfig config;
  final VoidCallback onEdit;

  const _CommissionConfigCard({required this.config, required this.onEdit});

  String get _basisLabel => switch (config.calculationBasis) {
    'percentage_of_order_value' => '${config.rate}% of order value',
    'per_order' => 'TZS ${_fmt(config.rate)} per order',
    'per_visit' => 'TZS ${_fmt(config.rate)} per visit',
    'fixed_monthly' => 'TZS ${_fmt(config.rate)} fixed monthly',
    _ => config.calculationBasis,
  };

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.roleName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _basisLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  final double lat;
  final double lng;

  const _GpsCard({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Placeholder map tile — replace with actual map widget
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // Map placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.withValues(alpha: 0.05),
                    Colors.blue.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: _MapGridPainter(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                size: const Size(double.infinity, 120),
              ),
            ),
          ),
          // Pin
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, color: Colors.red, size: 28),
                SizedBox(height: 2),
              ],
            ),
          ),
          // Coords overlay
          Positioned(
            left: 12,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color color;

  _MapGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => color != old.color;
}

class _DangerZoneCard extends StatelessWidget {
  final String orgName;
  final OrgStatus status;
  final VoidCallback onSuspend;
  final VoidCallback onDelete;

  const _DangerZoneCard({
    required this.orgName,
    required this.status,
    required this.onSuspend,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                'Danger Zone',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSuspend,
                  icon: Icon(
                    status == OrgStatus.suspended
                        ? Icons.play_circle_outline
                        : Icons.pause_circle_outline,
                    size: 16,
                  ),
                  label: Text(
                    status == OrgStatus.suspended
                        ? 'Reactivate'
                        : 'Suspend Org',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                    side: BorderSide(
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete Org'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
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

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — USERS
// ══════════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatefulWidget {
  final List<_OrgUser> users;
  final void Function(String) onAction;

  const _UsersTab({required this.users, required this.onAction});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  UserRole? _roleFilter;

  List<_OrgUser> get _filtered => _roleFilter == null
      ? widget.users
      : widget.users.where((u) => u.role == _roleFilter).toList();

  Map<UserRole, int> get _roleCounts {
    final map = <UserRole, int>{};
    for (final u in widget.users) {
      map[u.role] = (map[u.role] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header actions
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.users.length} Users',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            /**FilledButton.icon(
              onPressed: () => widget.onAction('Invite new user'),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Invite'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ), */
          ],
        ),
        const SizedBox(height: 12),

        // Role filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              ...UserRole.values
                  .where((r) => (_roleCounts[r] ?? 0) > 0)
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          '${_roleShortLabel(r)} (${_roleCounts[r]})',
                        ),
                        selected: _roleFilter == r,
                        onSelected: (_) => setState(
                          () => _roleFilter = _roleFilter == r ? null : r,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Role breakdown summary
        _RoleBreakdownBar(users: widget.users),
        const SizedBox(height: 16),

        // User list
        ..._filtered.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _UserCard(
              user: u,
              onEdit: () => widget.onAction('Edit ${u.name}'),
              onSuspend: () => widget.onAction(
                u.status == UserStatus.suspended
                    ? 'Activate ${u.name}'
                    : 'Suspend ${u.name}',
              ),
              onResetPassword: () =>
                  widget.onAction('Reset password for ${u.name}'),
            ),
          ),
        ),
      ],
    );
  }

  String _roleShortLabel(UserRole r) => switch (r) {
    UserRole.orgAdmin => 'Admin',
    UserRole.salesSupervisor => 'Supervisor',
    UserRole.marketingOfficer => 'Officer',
    UserRole.warehouseStaff => 'Warehouse',
    UserRole.financeAccountant => 'Finance',
    UserRole.deliveryDriver => 'Driver',
    UserRole.customerRep => 'Customer',
  };
}

class _RoleBreakdownBar extends StatelessWidget {
  final List<_OrgUser> users;

  const _RoleBreakdownBar({required this.users});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final roles = {
      UserRole.orgAdmin: (color: Colors.indigo, label: 'Admin'),
      UserRole.salesSupervisor: (color: Colors.blue, label: 'Supervisor'),
      UserRole.marketingOfficer: (color: Colors.teal, label: 'Officer'),
      UserRole.warehouseStaff: (color: Colors.orange, label: 'Warehouse'),
      UserRole.financeAccountant: (color: Colors.purple, label: 'Finance'),
      UserRole.deliveryDriver: (color: Colors.brown, label: 'Driver'),
      UserRole.customerRep: (color: Colors.green, label: 'Customer'),
    };

    final counts = <UserRole, int>{};
    for (final u in users) {
      counts[u.role] = (counts[u.role] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Role Distribution',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: roles.entries
                    .where((e) => (counts[e.key] ?? 0) > 0)
                    .map(
                      (e) => Expanded(
                        flex: counts[e.key]!,
                        child: Container(color: e.value.color),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: roles.entries
                .where((e) => (counts[e.key] ?? 0) > 0)
                .map(
                  (e) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: e.value.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${e.value.label} (${counts[e.key]})',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final _OrgUser user;
  final VoidCallback onEdit;
  final VoidCallback onSuspend;
  final VoidCallback onResetPassword;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onSuspend,
    required this.onResetPassword,
  });

  Color get _roleColor => switch (user.role) {
    UserRole.orgAdmin => Colors.indigo,
    UserRole.salesSupervisor => Colors.blue,
    UserRole.marketingOfficer => Colors.teal,
    UserRole.warehouseStaff => Colors.orange,
    UserRole.financeAccountant => Colors.purple,
    UserRole.deliveryDriver => Colors.brown,
    UserRole.customerRep => Colors.green,
  };

  String get _roleLabel => switch (user.role) {
    UserRole.orgAdmin => 'Org Admin',
    UserRole.salesSupervisor => 'Sales Supervisor',
    UserRole.marketingOfficer => 'Marketing Officer',
    UserRole.warehouseStaff => 'Warehouse Staff',
    UserRole.financeAccountant => 'Finance / Accountant',
    UserRole.deliveryDriver => 'Delivery Driver',
    UserRole.customerRep => 'Customer Rep',
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
    final isSuspended = user.status == UserStatus.suspended;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSuspended
            ? Colors.red.withValues(alpha: 0.03)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuspended
              ? Colors.red.withValues(alpha: 0.2)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  user.avatarInitials ?? user.name[0],
                  style: TextStyle(
                    color: _roleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (user.status == UserStatus.active)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
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
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSuspended
                              ? colorScheme.onSurface.withValues(alpha: 0.6)
                              : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _roleLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isSuspended)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Suspended',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
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
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (v) => switch (v) {
              'edit' => onEdit(),
              'suspend' => onSuspend(),
              'reset' => onResetPassword(),
              _ => null,
            },
            itemBuilder: (_) => [
              _popItem('edit', Icons.edit_outlined, 'Edit User'),
              _popItem('reset', Icons.lock_reset_outlined, 'Reset Password'),
              _popItem(
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
    );
  }

  PopupMenuItem<String> _popItem(
    String value,
    IconData icon,
    String label, {
    Color? color,
  }) => PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: color != null ? TextStyle(color: color) : null),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — RELATIONSHIPS
// ══════════════════════════════════════════════════════════════════════════════

class _RelationshipsTab extends StatelessWidget {
  final List<_OrgRelationship> relationships;
  final List<_PricingTier> pricingTiers;
  final void Function(String) onAction;

  const _RelationshipsTab({
    required this.relationships,
    required this.pricingTiers,
    required this.onAction,
  });

  List<_OrgRelationship> get _parents =>
      relationships.where((r) => r.isParent).toList();
  List<_OrgRelationship> get _children =>
      relationships.where((r) => !r.isParent).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Supply chain diagram hint
        _SupplyChainBanner(
          parentCount: _parents.length,
          childCount: _children.length,
        ),
        const SizedBox(height: 20),

        // Suppliers / parents
        if (_parents.isNotEmpty) ...[
          _SectionHeader(
            title: 'Our Suppliers (${_parents.length})',
            action: 'Link Supplier',
            onAction: () => onAction('Link new supplier'),
          ),
          const SizedBox(height: 10),
          ..._parents.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RelationshipCard(rel: r, onAction: onAction),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Customers / children
        _SectionHeader(
          title: 'Customers We Serve (${_children.length})',
          action: 'Add Customer',
          onAction: () => onAction('Add pharmacy customer'),
        ),
        const SizedBox(height: 10),
        ..._children.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RelationshipCard(rel: r, onAction: onAction),
          ),
        ),
        const SizedBox(height: 20),

        // Pricing tiers
        _SectionHeader(
          title: 'Pricing Tiers (${pricingTiers.length})',
          action: 'Add Tier',
          onAction: () => onAction('Add pricing tier'),
        ),
        const SizedBox(height: 10),
        ...pricingTiers.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PricingTierCard(
              tier: t,
              onEdit: () => onAction('Edit ${t.name} tier'),
            ),
          ),
        ),
      ],
    );
  }
}

class _SupplyChainBanner extends StatelessWidget {
  final int parentCount;
  final int childCount;

  const _SupplyChainBanner({
    required this.parentCount,
    required this.childCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withValues(alpha: 0.08),
            Colors.teal.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Suppliers
          Column(
            children: [
              Icon(
                Icons.factory_outlined,
                color: Colors.orange.shade600,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                '$parentCount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Supplier${parentCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Arrow
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 2,
                    color: Colors.indigo.withValues(alpha: 0.3),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.indigo.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'supplies',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Us
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.hub_outlined,
                  color: Colors.indigo.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bariki',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // Arrow
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 2,
                    color: Colors.teal.withValues(alpha: 0.3),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.teal.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'serves',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Customers
          Column(
            children: [
              Icon(
                Icons.local_pharmacy_outlined,
                color: Colors.teal.shade600,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                '$childCount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Pharmacies',
                style: theme.textTheme.labelSmall?.copyWith(
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

class _RelationshipCard extends StatelessWidget {
  final _OrgRelationship rel;
  final void Function(String) onAction;

  const _RelationshipCard({required this.rel, required this.onAction});

  String get _relTypeLabel => switch (rel.type) {
    RelationshipType.supplies => 'Supplies',
    RelationshipType.serves => 'Serves',
    RelationshipType.partners => 'Partners',
    RelationshipType.ownsBranch => 'Owns Branch',
    RelationshipType.franchises => 'Franchises',
  };

  Color get _partnerColor => switch (rel.partnerTypes.first) {
    OrgType.pharmacy => Colors.teal,
    OrgType.distributor => Colors.indigo,
    OrgType.supplier => Colors.orange,
    OrgType.manufacturer => Colors.purple,
    OrgType.logistics => Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rel.isActive
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rel.isActive
              ? colorScheme.outlineVariant.withValues(alpha: 0.5)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Partner avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _partnerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  rel.partnerName.substring(0, 2).toUpperCase(),
                  style: TextStyle(
                    color: _partnerColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rel.partnerName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (!rel.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _relTypeLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Text(' · '),
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rel.territory,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) => onAction('$v ${rel.partnerName}'),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'View', child: Text('View')),
                  const PopupMenuItem(
                    value: 'Edit relationship with',
                    child: Text('Edit Relationship'),
                  ),
                  const PopupMenuItem(
                    value: 'Deactivate link with',
                    child: Text('Deactivate Link'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Meta chips
          Row(
            children: [
              if (rel.pricingTier != null)
                _MetaChip(
                  icon: Icons.sell_outlined,
                  label: rel.pricingTier!,
                  color: Colors.teal,
                ),
              if (rel.creditLimit != null) ...[
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.credit_card_outlined,
                  label: 'Credit TZS ${_fmt(rel.creditLimit!)}',
                  color: Colors.purple,
                ),
              ],
              if (rel.paymentTermsDays != null) ...[
                const SizedBox(width: 8),
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label: 'Net ${rel.paymentTermsDays}d',
                  color: Colors.orange,
                ),
              ],
              const SizedBox(width: 24),
              if (rel.assignedOfficer != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rel.assignedOfficer!.split(' ').first,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingTierCard extends StatelessWidget {
  final _PricingTier tier;
  final VoidCallback onEdit;

  const _PricingTierCard({required this.tier, required this.onEdit});

  String get _discountText {
    if (tier.discountType == 'none') return 'No discount — full price';
    if (tier.discountType == 'percentage')
      return '${tier.discountValue.toStringAsFixed(0)}% off';
    return 'TZS ${tier.discountValue.toStringAsFixed(0)} flat discount';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tier.isDefault
              ? Colors.teal.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              tier.name[0],
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (tier.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Default',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _discountText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (tier.minOrderValue != null)
                  Text(
                    'Min order TZS ${_fmt(tier.minOrderValue!)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tier.orgCount}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'orgs',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — BILLING
// ══════════════════════════════════════════════════════════════════════════════

class _BillingTab extends StatelessWidget {
  final _BillingInfo billing;
  final void Function(String) onAction;

  const _BillingTab({required this.billing, required this.onAction});

  String get _planName => switch (billing.tier) {
    PlanTier.starter => 'Starter',
    PlanTier.professional => 'Professional',
    PlanTier.enterprise => 'Enterprise',
  };

  Color get _planColor => switch (billing.tier) {
    PlanTier.starter => Colors.grey,
    PlanTier.professional => Colors.indigo,
    PlanTier.enterprise => Colors.amber.shade700,
  };

  Color get _statusColor => switch (billing.status) {
    BillingStatus.active => Colors.green,
    BillingStatus.trialing => Colors.blue,
    BillingStatus.pastDue => Colors.red,
    BillingStatus.cancelled => Colors.grey,
  };

  String get _statusLabel => switch (billing.status) {
    BillingStatus.active => 'Active',
    BillingStatus.trialing => 'Trialing',
    BillingStatus.pastDue => 'Past Due',
    BillingStatus.cancelled => 'Cancelled',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final daysLeft = billing.periodEnd.difference(DateTime.now()).inDays;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Plan card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _planColor.withValues(alpha: 0.12),
                _planColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _planColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _planColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      billing.tier == PlanTier.enterprise
                          ? Icons.workspace_premium_outlined
                          : Icons.verified_outlined,
                      color: _planColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_planName Plan',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _planColor,
                          ),
                        ),
                        Text(
                          billing.billingCycle == 'annual'
                              ? 'Billed annually'
                              : 'Billed monthly',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Price + renewal
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TZS ${_fmtPrice(billing.monthlyPrice)}/mo',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          billing.billingCycle == 'annual'
                              ? 'TZS ${_fmtPrice(billing.monthlyPrice * 12)} billed annually'
                              : 'Billed each month',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Renews in $daysLeft days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: daysLeft < 30
                              ? Colors.orange
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatDate(billing.periodEnd),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Usage bar
        _UsageSection(billing: billing),
        const SizedBox(height: 20),

        // Features included
        _SectionHeader(
          title: 'Features Included',
          action: null,
          onAction: null,
        ),
        const SizedBox(height: 10),
        _FeaturesList(billing: billing),
        const SizedBox(height: 20),

        // Billing actions
        _SectionHeader(title: 'Manage Billing', action: null, onAction: null),
        const SizedBox(height: 10),
        _BillingActions(
          onUpgrade: () => onAction('Upgrade plan'),
          onChangeCycle: () => onAction('Change billing cycle'),
          onViewInvoices: () => onAction('View billing invoices'),
          onCancel: () => onAction('Cancel subscription'),
        ),
      ],
    );
  }

  String _fmtPrice(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _formatDate(DateTime dt) => '${dt.day} ${_month(dt.month)} ${dt.year}';

  String _month(int m) => [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

class _UsageSection extends StatelessWidget {
  final _BillingInfo billing;

  const _UsageSection({required this.billing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userPct = billing.currentUsers / billing.maxUsers;
    final nearLimit = userPct > 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            'Plan Usage',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _UsageRow(
            label: 'Users',
            current: billing.currentUsers,
            max: billing.maxUsers,
            color: nearLimit ? Colors.orange : Colors.blue,
          ),
          const SizedBox(height: 10),
          _UsageRow(
            label: 'Organizations',
            current: 1,
            max: 1,
            color: Colors.teal,
          ),
          if (nearLimit) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Approaching user limit. Consider upgrading to '
                      'Enterprise for unlimited users.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange.shade800,
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

class _UsageRow extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final Color color;

  const _UsageRow({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pct = current / max;

    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 24),
            Text(
              '$current / $max',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: pct > 0.8 ? color : colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _FeaturesList extends StatelessWidget {
  final _BillingInfo billing;

  const _FeaturesList({required this.billing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final features = [
      (label: 'CRM & Field Visits', included: true),
      (label: 'Order Management', included: true),
      (label: 'Inventory (Batch Level)', included: true),
      (label: 'In-App Messaging', included: true),
      (label: 'WhatsApp Business API', included: billing.hasWhatsApp),
      (
        label: 'Mobile Money (M-Pesa / Airtel)',
        included: billing.hasMobileMoney,
      ),
      (
        label: 'Advanced Analytics & Heatmaps',
        included: billing.hasAdvancedAnalytics,
      ),
      (
        label: 'Dedicated Support SLA',
        included: billing.tier == PlanTier.enterprise,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: features.map((f) {
          return ListTile(
            dense: true,
            leading: Icon(
              f.included ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 18,
              color: f.included
                  ? Colors.green
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            title: Text(
              f.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: f.included
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BillingActions extends StatelessWidget {
  final VoidCallback onUpgrade;
  final VoidCallback onChangeCycle;
  final VoidCallback onViewInvoices;
  final VoidCallback onCancel;

  const _BillingActions({
    required this.onUpgrade,
    required this.onChangeCycle,
    required this.onViewInvoices,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onUpgrade,
            icon: const Icon(Icons.workspace_premium_outlined, size: 18),
            label: const Text('Upgrade to Enterprise'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChangeCycle,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Change Cycle'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewInvoices,
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Invoices'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: const Text('Cancel Subscription'),
          ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(width: 24),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
            child: Text(action!, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final OrgType type;

  const _TypeBadge({required this.type});

  Color get _color => switch (type) {
    OrgType.pharmacy => Colors.teal,
    OrgType.distributor => Colors.indigo,
    OrgType.supplier => Colors.orange,
    OrgType.manufacturer => Colors.purple,
    OrgType.logistics => Colors.blue,
  };

  String get _label => switch (type) {
    OrgType.pharmacy => 'Pharmacy',
    OrgType.distributor => 'Distributor',
    OrgType.supplier => 'Supplier',
    OrgType.manufacturer => 'Manufacturer',
    OrgType.logistics => 'Logistics',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
