import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TERRITORIES PAGE
// Super Admin — Pharma SaaS Platform
// Hierarchical Region → District → Zone tree with detail panel
// No external dependencies beyond flutter/material.dart
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
const _cTeal = Color(0xFF00695C);
const _cTealLight = Color(0xFFE0F2F1);
const _cSurface = Color(0xFFF4F6FA);
const _cCard = Colors.white;
const _cTextPrimary = Color(0xFF1A1A2E);
const _cTextSecondary = Color(0xFF6B7280);
const _cBorder = Color(0xFFE5E7EB);
const _cTreeLine = Color(0xFFD1D5DB);

// ── Card decoration ───────────────────────────────────────────────────────────
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

enum TerritoryLevel { region, district, zone }

class TerritoryNode {
  final String id;
  final String name;
  final TerritoryLevel level;
  final List<TerritoryNode> children;
  final int orgCount;
  final int officerCount;
  final int customerCount;
  final int orderCount;
  final bool isActive;
  final String? code;

  const TerritoryNode({
    required this.id,
    required this.name,
    required this.level,
    this.children = const [],
    this.orgCount = 0,
    this.officerCount = 0,
    this.customerCount = 0,
    this.orderCount = 0,
    this.isActive = true,
    this.code,
  });
}

class _AssignedOrg {
  final String name;
  final String type;
  final String status;
  final int users;
  const _AssignedOrg({
    required this.name,
    required this.type,
    required this.status,
    required this.users,
  });
}

class _AssignedOfficer {
  final String name;
  final String email;
  final String org;
  final int visits;
  final int customers;
  const _AssignedOfficer({
    required this.name,
    required this.email,
    required this.org,
    required this.visits,
    required this.customers,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — Tanzania territory hierarchy
// ─────────────────────────────────────────────────────────────────────────────

const _territories = [
  TerritoryNode(
    id: 'r1',
    name: 'Southern Highlands',
    level: TerritoryLevel.region,
    code: 'SH',
    orgCount: 18,
    officerCount: 22,
    customerCount: 134,
    orderCount: 1847,
    children: [
      TerritoryNode(
        id: 'd1',
        name: 'Mbeya District',
        level: TerritoryLevel.district,
        code: 'MBY',
        orgCount: 12,
        officerCount: 14,
        customerCount: 87,
        orderCount: 1203,
        children: [
          TerritoryNode(
            id: 'z1',
            name: 'Mwanjelwa Zone',
            level: TerritoryLevel.zone,
            code: 'MWJ',
            orgCount: 4,
            officerCount: 5,
            customerCount: 32,
            orderCount: 412,
          ),
          TerritoryNode(
            id: 'z2',
            name: 'Uyole Zone',
            level: TerritoryLevel.zone,
            code: 'UYL',
            orgCount: 3,
            officerCount: 4,
            customerCount: 28,
            orderCount: 387,
          ),
          TerritoryNode(
            id: 'z3',
            name: 'Mbeya City Centre',
            level: TerritoryLevel.zone,
            code: 'MCC',
            orgCount: 5,
            officerCount: 5,
            customerCount: 27,
            orderCount: 404,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd2',
        name: 'Rungwe District',
        level: TerritoryLevel.district,
        code: 'RNG',
        orgCount: 4,
        officerCount: 5,
        customerCount: 31,
        orderCount: 398,
        children: [
          TerritoryNode(
            id: 'z4',
            name: 'Tukuyu Zone',
            level: TerritoryLevel.zone,
            code: 'TKY',
            orgCount: 2,
            officerCount: 3,
            customerCount: 18,
            orderCount: 224,
          ),
          TerritoryNode(
            id: 'z5',
            name: 'Kiwira Zone',
            level: TerritoryLevel.zone,
            code: 'KWR',
            orgCount: 2,
            officerCount: 2,
            customerCount: 13,
            orderCount: 174,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd3',
        name: 'Chunya District',
        level: TerritoryLevel.district,
        code: 'CHN',
        orgCount: 2,
        officerCount: 3,
        customerCount: 16,
        orderCount: 246,
        isActive: true,
        children: [
          TerritoryNode(
            id: 'z6',
            name: 'Chunya Township',
            level: TerritoryLevel.zone,
            code: 'CTP',
            orgCount: 2,
            officerCount: 3,
            customerCount: 16,
            orderCount: 246,
          ),
        ],
      ),
    ],
  ),
  TerritoryNode(
    id: 'r2',
    name: 'Dar es Salaam',
    level: TerritoryLevel.region,
    code: 'DSM',
    orgCount: 14,
    officerCount: 18,
    customerCount: 198,
    orderCount: 3124,
    children: [
      TerritoryNode(
        id: 'd4',
        name: 'Kinondoni District',
        level: TerritoryLevel.district,
        code: 'KND',
        orgCount: 6,
        officerCount: 8,
        customerCount: 89,
        orderCount: 1402,
        children: [
          TerritoryNode(
            id: 'z7',
            name: 'Mbezi Luis Zone',
            level: TerritoryLevel.zone,
            code: 'MBZ',
            orgCount: 3,
            officerCount: 4,
            customerCount: 44,
            orderCount: 712,
          ),
          TerritoryNode(
            id: 'z8',
            name: 'Sinza Zone',
            level: TerritoryLevel.zone,
            code: 'SNZ',
            orgCount: 3,
            officerCount: 4,
            customerCount: 45,
            orderCount: 690,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd5',
        name: 'Ilala District',
        level: TerritoryLevel.district,
        code: 'ILA',
        orgCount: 5,
        officerCount: 6,
        customerCount: 72,
        orderCount: 1134,
        children: [
          TerritoryNode(
            id: 'z9',
            name: 'Kariakoo Zone',
            level: TerritoryLevel.zone,
            code: 'KRK',
            orgCount: 3,
            officerCount: 3,
            customerCount: 41,
            orderCount: 654,
          ),
          TerritoryNode(
            id: 'z10',
            name: 'Gerezani Zone',
            level: TerritoryLevel.zone,
            code: 'GRZ',
            orgCount: 2,
            officerCount: 3,
            customerCount: 31,
            orderCount: 480,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd6',
        name: 'Temeke District',
        level: TerritoryLevel.district,
        code: 'TMK',
        orgCount: 3,
        officerCount: 4,
        customerCount: 37,
        orderCount: 588,
        children: [
          TerritoryNode(
            id: 'z11',
            name: 'Temeke Zone',
            level: TerritoryLevel.zone,
            code: 'TMZ',
            orgCount: 3,
            officerCount: 4,
            customerCount: 37,
            orderCount: 588,
          ),
        ],
      ),
    ],
  ),
  TerritoryNode(
    id: 'r3',
    name: 'Kilimanjaro',
    level: TerritoryLevel.region,
    code: 'KJR',
    orgCount: 7,
    officerCount: 9,
    customerCount: 64,
    orderCount: 842,
    children: [
      TerritoryNode(
        id: 'd7',
        name: 'Moshi District',
        level: TerritoryLevel.district,
        code: 'MSH',
        orgCount: 5,
        officerCount: 6,
        customerCount: 46,
        orderCount: 612,
        children: [
          TerritoryNode(
            id: 'z12',
            name: 'Moshi Urban Zone',
            level: TerritoryLevel.zone,
            code: 'MUZ',
            orgCount: 3,
            officerCount: 4,
            customerCount: 28,
            orderCount: 387,
          ),
          TerritoryNode(
            id: 'z13',
            name: 'Moshi Rural Zone',
            level: TerritoryLevel.zone,
            code: 'MRZ',
            orgCount: 2,
            officerCount: 2,
            customerCount: 18,
            orderCount: 225,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd8',
        name: 'Hai District',
        level: TerritoryLevel.district,
        code: 'HAI',
        orgCount: 2,
        officerCount: 3,
        customerCount: 18,
        orderCount: 230,
        children: [
          TerritoryNode(
            id: 'z14',
            name: 'Hai Zone',
            level: TerritoryLevel.zone,
            code: 'HZN',
            orgCount: 2,
            officerCount: 3,
            customerCount: 18,
            orderCount: 230,
          ),
        ],
      ),
    ],
  ),
  TerritoryNode(
    id: 'r4',
    name: 'Arusha',
    level: TerritoryLevel.region,
    code: 'ARU',
    orgCount: 9,
    officerCount: 11,
    customerCount: 78,
    orderCount: 1024,
    children: [
      TerritoryNode(
        id: 'd9',
        name: 'Arusha District',
        level: TerritoryLevel.district,
        code: 'ARD',
        orgCount: 7,
        officerCount: 8,
        customerCount: 58,
        orderCount: 784,
        children: [
          TerritoryNode(
            id: 'z15',
            name: 'Arusha City Zone',
            level: TerritoryLevel.zone,
            code: 'ACZ',
            orgCount: 4,
            officerCount: 5,
            customerCount: 36,
            orderCount: 498,
          ),
          TerritoryNode(
            id: 'z16',
            name: 'Njiro Zone',
            level: TerritoryLevel.zone,
            code: 'NJZ',
            orgCount: 3,
            officerCount: 3,
            customerCount: 22,
            orderCount: 286,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd10',
        name: 'Arumeru District',
        level: TerritoryLevel.district,
        code: 'ARM',
        orgCount: 2,
        officerCount: 3,
        customerCount: 20,
        orderCount: 240,
        children: [
          TerritoryNode(
            id: 'z17',
            name: 'Usa River Zone',
            level: TerritoryLevel.zone,
            code: 'URZ',
            orgCount: 2,
            officerCount: 3,
            customerCount: 20,
            orderCount: 240,
          ),
        ],
      ),
    ],
  ),
  TerritoryNode(
    id: 'r5',
    name: 'Coast Region',
    level: TerritoryLevel.region,
    code: 'CST',
    orgCount: 5,
    officerCount: 7,
    customerCount: 48,
    orderCount: 612,
    children: [
      TerritoryNode(
        id: 'd11',
        name: 'Bagamoyo District',
        level: TerritoryLevel.district,
        code: 'BGM',
        orgCount: 3,
        officerCount: 4,
        customerCount: 28,
        orderCount: 362,
        children: [
          TerritoryNode(
            id: 'z18',
            name: 'Bagamoyo Zone',
            level: TerritoryLevel.zone,
            code: 'BGZ',
            orgCount: 3,
            officerCount: 4,
            customerCount: 28,
            orderCount: 362,
          ),
        ],
      ),
      TerritoryNode(
        id: 'd12',
        name: 'Kibaha District',
        level: TerritoryLevel.district,
        code: 'KBH',
        orgCount: 2,
        officerCount: 3,
        customerCount: 20,
        orderCount: 250,
        isActive: false,
        children: [
          TerritoryNode(
            id: 'z19',
            name: 'Kibaha Zone',
            level: TerritoryLevel.zone,
            code: 'KBZ',
            orgCount: 2,
            officerCount: 3,
            customerCount: 20,
            orderCount: 250,
            isActive: false,
          ),
        ],
      ),
    ],
  ),
];

// Per-territory detail data (keyed by id)
final _detailOrgs = <String, List<_AssignedOrg>>{
  'r1': [
    const _AssignedOrg(
      name: 'Bariki Pharma Ltd',
      type: 'distributor',
      status: 'active',
      users: 34,
    ),
    const _AssignedOrg(
      name: 'Mbeya MedHub',
      type: 'pharmacy',
      status: 'active',
      users: 6,
    ),
    const _AssignedOrg(
      name: 'Southern Highlands Suppliers',
      type: 'supplier',
      status: 'active',
      users: 8,
    ),
  ],
  'd1': [
    const _AssignedOrg(
      name: 'Bariki Pharma Ltd',
      type: 'distributor',
      status: 'active',
      users: 34,
    ),
    const _AssignedOrg(
      name: 'Mbeya MedHub',
      type: 'pharmacy',
      status: 'active',
      users: 6,
    ),
  ],
  'z1': [
    const _AssignedOrg(
      name: 'Bariki Pharma Ltd',
      type: 'distributor',
      status: 'active',
      users: 34,
    ),
  ],
  'z2': [
    const _AssignedOrg(
      name: 'Uyole Pharmacy',
      type: 'pharmacy',
      status: 'active',
      users: 4,
    ),
  ],
  'r2': [
    const _AssignedOrg(
      name: 'MedPlus Pharmacy Dar',
      type: 'pharmacy',
      status: 'active',
      users: 8,
    ),
    const _AssignedOrg(
      name: 'Dar Distributors Ltd',
      type: 'distributor',
      status: 'active',
      users: 15,
    ),
  ],
};

final _detailOfficers = <String, List<_AssignedOfficer>>{
  'r1': [
    const _AssignedOfficer(
      name: 'John Mwakasege',
      email: 'j.mwakasege@bariki.co.tz',
      org: 'Bariki Pharma',
      visits: 124,
      customers: 32,
    ),
    const _AssignedOfficer(
      name: 'Agnes Mwakyusa',
      email: 'a.mwakyusa@bariki.co.tz',
      org: 'Bariki Pharma',
      visits: 98,
      customers: 28,
    ),
    const _AssignedOfficer(
      name: 'Peter Mwanga',
      email: 'p.mwanga@mbeya.co.tz',
      org: 'Mbeya MedHub',
      visits: 76,
      customers: 19,
    ),
  ],
  'd1': [
    const _AssignedOfficer(
      name: 'John Mwakasege',
      email: 'j.mwakasege@bariki.co.tz',
      org: 'Bariki Pharma',
      visits: 124,
      customers: 32,
    ),
    const _AssignedOfficer(
      name: 'Agnes Mwakyusa',
      email: 'a.mwakyusa@bariki.co.tz',
      org: 'Bariki Pharma',
      visits: 98,
      customers: 28,
    ),
  ],
  'z1': [
    const _AssignedOfficer(
      name: 'John Mwakasege',
      email: 'j.mwakasege@bariki.co.tz',
      org: 'Bariki Pharma',
      visits: 124,
      customers: 32,
    ),
    const _AssignedOfficer(
      name: 'Daniel Mwema',
      email: 'd.mwema@bariki.co.tz',
      org: 'Bariki Pharma',
      visits: 87,
      customers: 24,
    ),
  ],
  'r2': [
    const _AssignedOfficer(
      name: 'Fatuma Ally',
      email: 'f.ally@medplus.co.tz',
      org: 'MedPlus',
      visits: 156,
      customers: 48,
    ),
    const _AssignedOfficer(
      name: 'Said Juma',
      email: 's.juma@dar.co.tz',
      org: 'Dar Distributors',
      visits: 112,
      customers: 38,
    ),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// TERRITORIES PAGE — STATEFUL (for tree expand/collapse & selection)
// ─────────────────────────────────────────────────────────────────────────────

class TerritoriesPage extends StatefulWidget {
  const TerritoriesPage({super.key});

  @override
  State<TerritoriesPage> createState() => _TerritoriesPageState();
}

class _TerritoriesPageState extends State<TerritoriesPage> {
  // Expanded nodes by id
  final Set<String> _expanded = {'r1', 'd1'};
  // Selected node
  TerritoryNode? _selected;
  // Search query
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Default: select Mbeya District on load
    _selected = _findNode('d1', _territories);
  }

  TerritoryNode? _findNode(String id, List<TerritoryNode> nodes) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final found = _findNode(id, n.children);
      if (found != null) return found;
    }
    return null;
  }

  void _toggleExpand(String id) {
    setState(() {
      _expanded.contains(id) ? _expanded.remove(id) : _expanded.add(id);
    });
  }

  void _selectNode(TerritoryNode node) {
    setState(() {
      _selected = node;
      // Auto-expand parent on selection
      if (node.level != TerritoryLevel.region) {
        _expanded.add(node.id);
      }
    });
  }

  List<TerritoryNode> get _filteredTerritories {
    if (_search.isEmpty) return _territories;
    return _filterNodes(_territories, _search.toLowerCase());
  }

  List<TerritoryNode> _filterNodes(List<TerritoryNode> nodes, String q) {
    final result = <TerritoryNode>[];
    for (final n in nodes) {
      final nameMatch = n.name.toLowerCase().contains(q);
      final filteredChildren = _filterNodes(n.children, q);
      if (nameMatch || filteredChildren.isNotEmpty) {
        result.add(
          TerritoryNode(
            id: n.id,
            name: n.name,
            level: n.level,
            code: n.code,
            orgCount: n.orgCount,
            officerCount: n.officerCount,
            customerCount: n.customerCount,
            orderCount: n.orderCount,
            isActive: n.isActive,
            children: filteredChildren,
          ),
        );
        if (filteredChildren.isNotEmpty) _expanded.add(n.id);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      color: _cSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: _TerritoriesHeader(),
          ),
          const SizedBox(height: 20),
          // ── Summary stat strip ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _TerritoryStatsStrip(),
          ),
          const SizedBox(height: 20),
          // ── Main body: tree + detail ─────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT: tree panel
                  SizedBox(
                    width: 340,
                    child: Container(
                      decoration: _card(),
                      child: Column(
                        children: [
                          _TreePanelHeader(
                            search: _search,
                            onSearch: (v) => setState(() => _search = v),
                          ),
                          Expanded(
                            child: _filteredTerritories.isEmpty
                                ? const _TreeEmptyState()
                                : ListView(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 16,
                                    ),
                                    children: _filteredTerritories
                                        .map(
                                          (r) => _TerritoryTreeNode(
                                            node: r,
                                            depth: 0,
                                            expanded: _expanded,
                                            selectedId: _selected?.id,
                                            onTap: _selectNode,
                                            onToggle: _toggleExpand,
                                          ),
                                        )
                                        .toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // RIGHT: detail panel
                  Expanded(
                    child: _selected == null
                        ? const _DetailEmptyState()
                        : _TerritoryDetailPanel(
                            key: ValueKey(_selected!.id),
                            node: _selected!,
                            orgs: _detailOrgs[_selected!.id] ?? [],
                            officers: _detailOfficers[_selected!.id] ?? [],
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

class _TerritoriesHeader extends StatelessWidget {
  const _TerritoriesHeader();

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
                    color: _cTeal,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Territory Management',
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
                '5 regions  ·  12 districts  ·  19 zones  ·  Tanzania',
                style: text.bodySmall?.copyWith(color: _cTextSecondary),
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _cTealLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cTeal.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: _cTeal, size: 14),
              const SizedBox(width: 6),
              Text(
                '396 pharmacies covered',
                style: text.labelSmall?.copyWith(
                  color: _cTeal,
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
          label: const Text('Export Map'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _cTextPrimary,
            side: const BorderSide(color: _cBorder),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_location_alt_rounded, size: 16),
          label: const Text('Add Territory'),
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
// STATS STRIP
// ─────────────────────────────────────────────────────────────────────────────

class _TerritoryStatsStrip extends StatelessWidget {
  const _TerritoryStatsStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MiniStat(
            icon: Icons.map_rounded,
            iconColor: _cTeal,
            iconBg: _cTealLight,
            label: 'Regions',
            value: '5',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.location_city_rounded,
            iconColor: _cPrimary,
            iconBg: _cPrimaryLight,
            label: 'Districts',
            value: '12',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.my_location_rounded,
            iconColor: _cAccent,
            iconBg: _cAccentLight,
            label: 'Zones',
            value: '19',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.business_rounded,
            iconColor: _cInfo,
            iconBg: _cInfoLight,
            label: 'Orgs Assigned',
            value: '53',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.badge_rounded,
            iconColor: _cWarning,
            iconBg: _cWarningLight,
            label: 'Field Officers',
            value: '67',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.local_pharmacy_rounded,
            iconColor: _cSuccess,
            iconBg: _cSuccessLight,
            label: 'Customers Mapped',
            value: '396',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            icon: Icons.block_rounded,
            iconColor: _cError,
            iconBg: _cErrorLight,
            label: 'Inactive Zones',
            value: '1',
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Column(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREE PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _TreePanelHeader extends StatelessWidget {
  final String search;
  final ValueChanged<String> onSearch;
  const _TreePanelHeader({required this.search, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded, color: _cTeal, size: 17),
              const SizedBox(width: 8),
              Text(
                'Territory Tree',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _cTextPrimary,
                ),
              ),
              const Spacer(),
              // Legend dots
              _LevelDot(color: _cTeal, label: 'R'),
              const SizedBox(width: 6),
              _LevelDot(color: _cPrimaryMid, label: 'D'),
              const SizedBox(width: 6),
              _LevelDot(color: _cAccent, label: 'Z'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search territories…',
              hintStyle: const TextStyle(fontSize: 12, color: _cTextSecondary),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 15,
                color: _cTextSecondary,
              ),
              suffixIcon: search.isNotEmpty
                  ? GestureDetector(
                      onTap: () => onSearch(''),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: _cTextSecondary,
                      ),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 9,
                horizontal: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _cTeal, width: 1.5),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LevelDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LevelDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TreeEmptyState extends StatelessWidget {
  const _TreeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 36,
            color: _cTextSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'No territories found',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _cTextSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TREE NODE WIDGET  (recursive)
// ─────────────────────────────────────────────────────────────────────────────

class _TerritoryTreeNode extends StatelessWidget {
  final TerritoryNode node;
  final int depth;
  final Set<String> expanded;
  final String? selectedId;
  final void Function(TerritoryNode) onTap;
  final void Function(String) onToggle;

  const _TerritoryTreeNode({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.selectedId,
    required this.onTap,
    required this.onToggle,
  });

  bool get _isExpanded => expanded.contains(node.id);
  bool get _isSelected => selectedId == node.id;
  bool get _hasChildren => node.children.isNotEmpty;

  // Per-level styling
  Color get _levelColor => switch (node.level) {
    TerritoryLevel.region => _cTeal,
    TerritoryLevel.district => _cPrimaryMid,
    TerritoryLevel.zone => _cAccent,
  };

  Color get _levelBg => switch (node.level) {
    TerritoryLevel.region => _cTealLight,
    TerritoryLevel.district => _cPrimaryLight,
    TerritoryLevel.zone => _cAccentLight,
  };

  IconData get _levelIcon => switch (node.level) {
    TerritoryLevel.region => Icons.map_rounded,
    TerritoryLevel.district => Icons.location_city_rounded,
    TerritoryLevel.zone => Icons.my_location_rounded,
  };

  String get _levelLabel => switch (node.level) {
    TerritoryLevel.region => 'Region',
    TerritoryLevel.district => 'District',
    TerritoryLevel.zone => 'Zone',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final indent = depth * 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Node row ──────────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            onTap(node);
            if (_hasChildren) onToggle(node.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(left: indent, right: 8, top: 1, bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: _isSelected
                  ? _levelColor.withOpacity(0.09)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isSelected
                    ? _levelColor.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // Expand / collapse icon
                if (_hasChildren)
                  GestureDetector(
                    onTap: () => onToggle(node.id),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        _isExpanded
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: _isSelected ? _levelColor : _cTextSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 22),
                // Level icon
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _isSelected
                        ? _levelColor.withOpacity(0.15)
                        : _levelBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_levelIcon, color: _levelColor, size: 13),
                ),
                const SizedBox(width: 9),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: text.bodySmall?.copyWith(
                          color: _isSelected ? _levelColor : _cTextPrimary,
                          fontWeight: _isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.code != null)
                        Text(
                          '${_levelLabel}  ·  ${node.code}',
                          style: text.labelSmall?.copyWith(
                            color: _isSelected
                                ? _levelColor.withOpacity(0.7)
                                : _cTextSecondary,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                // Badges: org count + inactive flag
                if (!node.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _cErrorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Inactive',
                      style: text.labelSmall?.copyWith(
                        color: _cError,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isSelected
                          ? _levelColor.withOpacity(0.12)
                          : const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${node.orgCount}',
                      style: text.labelSmall?.copyWith(
                        color: _isSelected ? _levelColor : _cTextSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Tree lines for children ────────────────────────────────────────
        if (_isExpanded && _hasChildren)
          Stack(
            children: [
              // Vertical guide line
              Positioned(
                left: indent + 28,
                top: 0,
                bottom: 4,
                child: Container(width: 1, color: _cTreeLine),
              ),
              Column(
                children: node.children
                    .map(
                      (child) => _TerritoryTreeNode(
                        node: child,
                        depth: depth + 1,
                        expanded: expanded,
                        selectedId: selectedId,
                        onTap: onTap,
                        onToggle: onToggle,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _TerritoryDetailPanel extends StatefulWidget {
  final TerritoryNode node;
  final List<_AssignedOrg> orgs;
  final List<_AssignedOfficer> officers;

  const _TerritoryDetailPanel({
    super.key,
    required this.node,
    required this.orgs,
    required this.officers,
  });

  @override
  State<_TerritoryDetailPanel> createState() => _TerritoryDetailPanelState();
}

class _TerritoryDetailPanelState extends State<_TerritoryDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color get _levelColor => switch (widget.node.level) {
    TerritoryLevel.region => _cTeal,
    TerritoryLevel.district => _cPrimaryMid,
    TerritoryLevel.zone => _cAccent,
  };
  Color get _levelBg => switch (widget.node.level) {
    TerritoryLevel.region => _cTealLight,
    TerritoryLevel.district => _cPrimaryLight,
    TerritoryLevel.zone => _cAccentLight,
  };
  IconData get _levelIcon => switch (widget.node.level) {
    TerritoryLevel.region => Icons.map_rounded,
    TerritoryLevel.district => Icons.location_city_rounded,
    TerritoryLevel.zone => Icons.my_location_rounded,
  };
  String get _levelLabel => switch (widget.node.level) {
    TerritoryLevel.region => 'Region',
    TerritoryLevel.district => 'District',
    TerritoryLevel.zone => 'Zone',
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final n = widget.node;

    return Container(
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Detail header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            decoration: BoxDecoration(
              color: _levelBg.withOpacity(0.5),
              border: const Border(bottom: BorderSide(color: _cBorder)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Big icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _levelColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _levelColor.withOpacity(0.25),
                        ),
                      ),
                      child: Icon(_levelIcon, color: _levelColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                n.name,
                                style: text.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _cTextPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (n.code != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _levelColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _levelColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    n.code!,
                                    style: text.labelSmall?.copyWith(
                                      color: _levelColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _levelBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _levelLabel.toUpperCase(),
                                  style: text.labelSmall?.copyWith(
                                    color: _levelColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ActiveBadge(active: n.isActive),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n.children.isEmpty
                                ? 'No child territories — leaf zone'
                                : '${n.children.length} child ${n.level == TerritoryLevel.region ? 'districts' : 'zones'}',
                            style: text.bodySmall?.copyWith(
                              color: _cTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick actions
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _cTextPrimary,
                            side: const BorderSide(color: _cBorder),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.add_location_alt_rounded,
                            size: 14,
                          ),
                          label: Text(
                            n.level == TerritoryLevel.region
                                ? 'Add District'
                                : n.level == TerritoryLevel.district
                                ? 'Add Zone'
                                : 'Assign Officer',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _levelColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── 4 stat chips in header ─────────────────────────────────
                Row(
                  children: [
                    _DetailStatChip(
                      icon: Icons.business_rounded,
                      label: 'Organizations',
                      value: '${n.orgCount}',
                      color: _levelColor,
                    ),
                    const SizedBox(width: 10),
                    _DetailStatChip(
                      icon: Icons.badge_rounded,
                      label: 'Field Officers',
                      value: '${n.officerCount}',
                      color: _cWarning,
                    ),
                    const SizedBox(width: 10),
                    _DetailStatChip(
                      icon: Icons.local_pharmacy_rounded,
                      label: 'Customers',
                      value: '${n.customerCount}',
                      color: _cSuccess,
                    ),
                    const SizedBox(width: 10),
                    _DetailStatChip(
                      icon: Icons.receipt_long_rounded,
                      label: 'Orders (total)',
                      value: '${n.orderCount}',
                      color: _cInfo,
                    ),
                    if (n.children.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _DetailStatChip(
                        icon: Icons.account_tree_rounded,
                        label: n.level == TerritoryLevel.region
                            ? 'Districts'
                            : 'Zones',
                        value: '${n.children.length}',
                        color: _cPrimary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // ── Tab bar ─────────────────────────────────────────────────
                TabBar(
                  controller: _tabs,
                  labelColor: _levelColor,
                  unselectedLabelColor: _cTextSecondary,
                  indicatorColor: _levelColor,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Organizations'),
                    Tab(text: 'Field Officers'),
                  ],
                ),
              ],
            ),
          ),
          // ── Tab body ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(node: n, levelColor: _levelColor),
                _OrgsTab(orgs: widget.orgs, node: n, levelColor: _levelColor),
                _OfficersTab(
                  officers: widget.officers,
                  node: n,
                  levelColor: _levelColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final bool active;
  const _ActiveBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? _cSuccessLight : _cErrorLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _cSuccess : _cError,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: active ? _cSuccess : _cError,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, color: color, size: 13),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _cTextPrimary,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: _cTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final TerritoryNode node;
  final Color levelColor;
  const _OverviewTab({required this.node, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoCard(node: node, levelColor: levelColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _CoverageCard(node: node, levelColor: levelColor),
              ),
            ],
          ),
          if (node.children.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              node.level == TerritoryLevel.region
                  ? 'Child Districts'
                  : 'Child Zones',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: _cTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...node.children.map((child) => _ChildTerritoryRow(child: child)),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final TerritoryNode node;
  final Color levelColor;
  const _InfoCard({required this.node, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Territory Details',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _cTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _KVRow(label: 'Territory ID', value: node.id.toUpperCase()),
          _KVRow(label: 'Code', value: node.code ?? '—'),
          _KVRow(
            label: 'Level',
            value:
                node.level.name.substring(0, 1).toUpperCase() +
                node.level.name.substring(1),
          ),
          _KVRow(label: 'Country', value: 'Tanzania'),
          _KVRow(label: 'Status', value: node.isActive ? 'Active' : 'Inactive'),
          _KVRow(
            label: 'Children',
            value: node.children.isEmpty
                ? 'None (leaf node)'
                : '${node.children.length}',
          ),
          _KVRow(label: 'GPS Boundary', value: 'Not configured'),
          _KVRow(label: 'Created', value: 'Jan 2026'),
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  const _KVRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(
                color: _cTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodySmall?.copyWith(
                color: _cTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  final TerritoryNode node;
  final Color levelColor;
  const _CoverageCard({required this.node, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coverage Metrics',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _cTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _CoverageBar(
            label: 'Organizations',
            value: node.orgCount,
            max: 20,
            color: levelColor,
          ),
          const SizedBox(height: 14),
          _CoverageBar(
            label: 'Field Officers',
            value: node.officerCount,
            max: 25,
            color: _cWarning,
          ),
          const SizedBox(height: 14),
          _CoverageBar(
            label: 'Customers',
            value: node.customerCount,
            max: 200,
            color: _cSuccess,
          ),
          const SizedBox(height: 14),
          _CoverageBar(
            label: 'Total Orders',
            value: node.orderCount,
            max: 3500,
            color: _cInfo,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: levelColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, color: levelColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Avg ${(node.orderCount / (node.officerCount == 0 ? 1 : node.officerCount)).toStringAsFixed(0)} orders per officer  ·  '
                    '${(node.customerCount / (node.officerCount == 0 ? 1 : node.officerCount)).toStringAsFixed(1)} customers per officer',
                    style: text.bodySmall?.copyWith(
                      color: levelColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
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

class _CoverageBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _CoverageBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.bodySmall?.copyWith(
                  color: _cTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value.toString(),
              style: text.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: _cBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _ChildTerritoryRow extends StatelessWidget {
  final TerritoryNode child;
  const _ChildTerritoryRow({required this.child});

  Color get _color =>
      child.level == TerritoryLevel.district ? _cPrimaryMid : _cAccent;
  Color get _bg =>
      child.level == TerritoryLevel.district ? _cPrimaryLight : _cAccentLight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _card(),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              child.level == TerritoryLevel.district
                  ? Icons.location_city_rounded
                  : Icons.my_location_rounded,
              color: _color,
              size: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: text.bodySmall?.copyWith(
                    color: _cTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${child.code ?? '—'}  ·  ${child.children.length} sub-zones',
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _StatPill(label: 'Orgs', value: '${child.orgCount}'),
          const SizedBox(width: 8),
          _StatPill(label: 'Officers', value: '${child.officerCount}'),
          const SizedBox(width: 8),
          _StatPill(label: 'Customers', value: '${child.customerCount}'),
          const SizedBox(width: 8),
          _ActiveBadge(active: child.isActive),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            color: _cTextSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _cSurface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: _cBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: text.labelSmall?.copyWith(
              color: _cTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: _cTextSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: ORGANIZATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _OrgsTab extends StatelessWidget {
  final List<_AssignedOrg> orgs;
  final TerritoryNode node;
  final Color levelColor;
  const _OrgsTab({
    required this.orgs,
    required this.node,
    required this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (orgs.isEmpty) {
      return _NoDataState(
        icon: Icons.business_rounded,
        message: 'No organizations assigned to ${node.name}',
        action: 'Assign Organization',
        color: levelColor,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${orgs.length} organization${orgs.length != 1 ? 's' : ''} in ${node.name}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _cTextPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Assign Org'),
                style: FilledButton.styleFrom(
                  backgroundColor: levelColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: _cBorder),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TH('ORGANIZATION')),
                Expanded(flex: 2, child: _TH('TYPE')),
                Expanded(flex: 2, child: _TH('STATUS')),
                Expanded(flex: 1, child: _TH('USERS')),
                SizedBox(width: 60),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: const Border(
                left: BorderSide(color: _cBorder),
                right: BorderSide(color: _cBorder),
                bottom: BorderSide(color: _cBorder),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Column(
              children: orgs.asMap().entries.map((e) {
                final org = e.value;
                final isEven = e.key.isEven;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isEven ? Colors.white : const Color(0xFFFAFBFC),
                    border: Border(
                      bottom: BorderSide(
                        color: e.key < orgs.length - 1
                            ? _cBorder
                            : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
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
                                  org.name.substring(0, 1),
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
                                org.name,
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
                      Expanded(flex: 2, child: _TypeChip(type: org.type)),
                      Expanded(flex: 2, child: _StatusDot(status: org.status)),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${org.users}',
                          style: text.bodySmall?.copyWith(
                            color: _cTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: _cPrimaryMid,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('View'),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB: FIELD OFFICERS
// ─────────────────────────────────────────────────────────────────────────────

class _OfficersTab extends StatelessWidget {
  final List<_AssignedOfficer> officers;
  final TerritoryNode node;
  final Color levelColor;
  const _OfficersTab({
    required this.officers,
    required this.node,
    required this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (officers.isEmpty) {
      return _NoDataState(
        icon: Icons.badge_rounded,
        message: 'No officers assigned to ${node.name}',
        action: 'Assign Officer',
        color: levelColor,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${officers.length} officer${officers.length != 1 ? 's' : ''} in ${node.name}',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _cTextPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_rounded, size: 14),
                label: const Text('Assign Officer'),
                style: FilledButton.styleFrom(
                  backgroundColor: levelColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...officers.map(
            (o) => _OfficerCard(officer: o, levelColor: levelColor),
          ),
        ],
      ),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  final _AssignedOfficer officer;
  final Color levelColor;
  const _OfficerCard({required this.officer, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: levelColor.withOpacity(0.12),
            child: Text(
              officer.name.split(' ').map((p) => p[0]).take(2).join(),
              style: TextStyle(
                color: levelColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  officer.name,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  officer.email,
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 11,
                      color: _cTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      officer.org,
                      style: text.labelSmall?.copyWith(
                        color: _cPrimaryMid,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Stats
          _OfficerStat(
            icon: Icons.directions_walk_rounded,
            label: 'Visits',
            value: '${officer.visits}',
            color: levelColor,
          ),
          const SizedBox(width: 12),
          _OfficerStat(
            icon: Icons.local_pharmacy_rounded,
            label: 'Customers',
            value: '${officer.customers}',
            color: _cSuccess,
          ),
          const SizedBox(width: 16),
          // Actions
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _cTextPrimary,
              side: const BorderSide(color: _cBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('View Profile'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _cError,
              side: const BorderSide(color: _cError, width: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Reassign'),
          ),
        ],
      ),
    );
  }
}

class _OfficerStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _OfficerStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: text.titleSmall?.copyWith(
                  color: _cTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: _cTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _TH extends StatelessWidget {
  final String label;
  const _TH(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: _cTextSecondary,
      fontWeight: FontWeight.w700,
      fontSize: 10,
      letterSpacing: 0.8,
    ),
  );
}

class _TypeChip extends StatelessWidget {
  final String type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (type) {
      'distributor' => (_cPrimary, _cPrimaryLight),
      'pharmacy' => (_cAccent, _cAccentLight),
      'supplier' => (_cSuccess, _cSuccessLight),
      _ => (_cTextSecondary, _cSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'active' => (_cSuccess, _cSuccessLight),
      'suspended' => (_cError, _cErrorLight),
      'trialing' => (_cInfo, _cInfoLight),
      _ => (_cTextSecondary, _cSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String action;
  final Color color;
  const _NoDataState({
    required this.icon,
    required this.message,
    required this.action,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: text.bodyMedium?.copyWith(
              color: _cTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 15),
            label: Text(action),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: _card(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _cTealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_tree_rounded,
                color: _cTeal,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select a territory',
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _cTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Click any region, district, or zone\nin the tree to view its details.',
              style: text.bodySmall?.copyWith(
                color: _cTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
