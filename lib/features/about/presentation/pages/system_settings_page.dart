// system_settings_page.dart
// System Settings — Super Admin platform configuration.
//
// Maps to schema:
//   tenant_settings    — key/value platform config store (JSONB)
//   product_categories — hierarchical pharmaceutical category tree
//   territories        — Tanzania region/district/zone hierarchy
//
// Covers five sections via tab navigation:
//   1. General       — platform name, timezone, language, limits
//   2. Categories    — master product category tree (CRUD)
//   3. Territories   — Tanzania geographic hierarchy (CRUD)
//   4. Integrations  — WhatsApp, M-Pesa, Airtel, Firebase, S3, Sentry
//   5. Security      — 2FA policy, session timeout, IP whitelist, rate limits
//
// No AppBar. No Drawer. Pure page content.
// Location: features/platform_admin/presentation/pages/system_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum IntegrationStatus { connected, error, disconnected, pending }

// ─── Models ───────────────────────────────────────────────────────────────────

class _Category {
  final String id;
  final String name;
  final String emoji;
  final String? parentId;
  int productCount;
  bool isActive;

  _Category({
    required this.id,
    required this.name,
    required this.emoji,
    this.parentId,
    required this.productCount,
    required this.isActive,
  });
}

class _Territory {
  final String id;
  final String name;
  final String level; // region | district | zone
  final String? parentId;
  int orgCount;
  bool isActive;

  _Territory({
    required this.id,
    required this.name,
    required this.level,
    this.parentId,
    required this.orgCount,
    required this.isActive,
  });
}

class _Integration {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  IntegrationStatus status;
  final String? connectedAs;
  final String? lastSyncLabel;
  final bool isRequired;
  final List<_IntField> fields;

  _Integration({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.status,
    this.connectedAs,
    this.lastSyncLabel,
    required this.isRequired,
    required this.fields,
  });
}

class _IntField {
  final String key;
  final String label;
  final bool isSecret;
  final String value;
  const _IntField(this.key, this.label, this.value, {this.isSecret = false});
}

// ─── Mock data ────────────────────────────────────────────────────────────────

List<_Category> _categories = [
  _Category(
    id: 'cat1',
    name: 'Antibiotics',
    emoji: '🦠',
    productCount: 10,
    isActive: true,
  ),
  _Category(
    id: 'cat1a',
    name: 'Penicillins',
    emoji: '💊',
    parentId: 'cat1',
    productCount: 3,
    isActive: true,
  ),
  _Category(
    id: 'cat1b',
    name: 'Cephalosporins',
    emoji: '💊',
    parentId: 'cat1',
    productCount: 3,
    isActive: true,
  ),
  _Category(
    id: 'cat1c',
    name: 'Macrolides',
    emoji: '💊',
    parentId: 'cat1',
    productCount: 2,
    isActive: true,
  ),
  _Category(
    id: 'cat1d',
    name: 'Fluoroquinolones',
    emoji: '💊',
    parentId: 'cat1',
    productCount: 2,
    isActive: true,
  ),
  _Category(
    id: 'cat2',
    name: 'Analgesics',
    emoji: '💊',
    productCount: 8,
    isActive: true,
  ),
  _Category(
    id: 'cat2a',
    name: 'NSAIDs',
    emoji: '💊',
    parentId: 'cat2',
    productCount: 4,
    isActive: true,
  ),
  _Category(
    id: 'cat2b',
    name: 'Opioids',
    emoji: '🔒',
    parentId: 'cat2',
    productCount: 2,
    isActive: true,
  ),
  _Category(
    id: 'cat2c',
    name: 'Paracetamol-based',
    emoji: '💊',
    parentId: 'cat2',
    productCount: 2,
    isActive: true,
  ),
  _Category(
    id: 'cat3',
    name: 'Vitamins & Supplements',
    emoji: '🌿',
    productCount: 7,
    isActive: true,
  ),
  _Category(
    id: 'cat4',
    name: 'Antifungals',
    emoji: '🍄',
    productCount: 4,
    isActive: true,
  ),
  _Category(
    id: 'cat5',
    name: 'Cardiovascular',
    emoji: '❤️',
    productCount: 5,
    isActive: true,
  ),
  _Category(
    id: 'cat6',
    name: 'Antimalarials',
    emoji: '🦟',
    productCount: 4,
    isActive: true,
  ),
  _Category(
    id: 'cat7',
    name: 'Gastrointestinal',
    emoji: '🫃',
    productCount: 4,
    isActive: true,
  ),
  _Category(
    id: 'cat8',
    name: 'Dermatology',
    emoji: '🧴',
    productCount: 0,
    isActive: false,
  ),
];

List<_Territory> _territories = [
  // Regions
  _Territory(
    id: 't1',
    name: 'Southern Highlands',
    level: 'region',
    orgCount: 4,
    isActive: true,
  ),
  _Territory(
    id: 't2',
    name: 'Dar es Salaam',
    level: 'region',
    orgCount: 2,
    isActive: true,
  ),
  _Territory(
    id: 't3',
    name: 'Dodoma',
    level: 'region',
    orgCount: 1,
    isActive: true,
  ),
  _Territory(
    id: 't4',
    name: 'Mwanza',
    level: 'region',
    orgCount: 0,
    isActive: false,
  ),
  // Districts under Southern Highlands
  _Territory(
    id: 't1a',
    name: 'Mbeya District',
    level: 'district',
    parentId: 't1',
    orgCount: 3,
    isActive: true,
  ),
  _Territory(
    id: 't1b',
    name: 'Njombe District',
    level: 'district',
    parentId: 't1',
    orgCount: 1,
    isActive: true,
  ),
  _Territory(
    id: 't1c',
    name: 'Iringa District',
    level: 'district',
    parentId: 't1',
    orgCount: 0,
    isActive: true,
  ),
  // Zones under Mbeya District
  _Territory(
    id: 't1a1',
    name: 'Mwanjelwa Zone',
    level: 'zone',
    parentId: 't1a',
    orgCount: 2,
    isActive: true,
  ),
  _Territory(
    id: 't1a2',
    name: 'Uyole Zone',
    level: 'zone',
    parentId: 't1a',
    orgCount: 1,
    isActive: true,
  ),
  _Territory(
    id: 't1a3',
    name: 'Kariakoo Zone',
    level: 'zone',
    parentId: 't1a',
    orgCount: 0,
    isActive: true,
  ),
  // Districts under Dar
  _Territory(
    id: 't2a',
    name: 'Ilala District',
    level: 'district',
    parentId: 't2',
    orgCount: 1,
    isActive: true,
  ),
  _Territory(
    id: 't2b',
    name: 'Kinondoni District',
    level: 'district',
    parentId: 't2',
    orgCount: 1,
    isActive: true,
  ),
];

List<_Integration> _integrations = [
  _Integration(
    id: 'whatsapp',
    name: 'WhatsApp Business API',
    description:
        'Promotional broadcasts, order updates, and customer messaging via Meta Business API.',
    icon: Icons.chat_bubble_outlined,
    color: Colors.green,
    status: IntegrationStatus.connected,
    connectedAs: '+255 712 000 000',
    lastSyncLabel: 'Webhook active',
    isRequired: false,
    fields: [
      const _IntField(
        'api_token',
        'API Token',
        'EAAx7...************',
        isSecret: true,
      ),
      const _IntField('phone_id', 'Phone Number ID', '102847361924837'),
      const _IntField(
        'waba_id',
        'WhatsApp Business Account ID',
        '209817364012983',
      ),
    ],
  ),
  _Integration(
    id: 'mpesa',
    name: 'M-Pesa Daraja API',
    description:
        'Mobile money payment processing for Tanzania. C2B STK Push and B2C payouts.',
    icon: Icons.phone_android_outlined,
    color: Color(0xFF00A550),
    status: IntegrationStatus.connected,
    connectedAs: 'Shortcode 888900',
    lastSyncLabel: 'Webhook verified',
    isRequired: false,
    fields: [
      const _IntField(
        'consumer_key',
        'Consumer Key',
        'aG7d...************',
        isSecret: true,
      ),
      const _IntField(
        'consumer_secret',
        'Consumer Secret',
        'bX9k...************',
        isSecret: true,
      ),
      const _IntField('shortcode', 'Business Shortcode', '888900'),
      const _IntField(
        'passkey',
        'Lipa Na M-Pesa Passkey',
        '************',
        isSecret: true,
      ),
    ],
  ),
  _Integration(
    id: 'airtel',
    name: 'Airtel Money API',
    description: 'Airtel Money C2B collection and disbursement for Tanzania.',
    icon: Icons.sim_card_outlined,
    color: Colors.red,
    status: IntegrationStatus.error,
    connectedAs: null,
    lastSyncLabel: 'Auth failed 2h ago',
    isRequired: false,
    fields: [
      const _IntField(
        'client_id',
        'Client ID',
        'airtel_live_cl_...',
        isSecret: false,
      ),
      const _IntField(
        'client_secret',
        'Client Secret',
        '************',
        isSecret: true,
      ),
      const _IntField('env', 'Environment', 'production'),
    ],
  ),
  _Integration(
    id: 'firebase',
    name: 'Firebase Cloud Messaging',
    description:
        'Push notifications to iOS and Android apps. Used for order updates and alerts.',
    icon: Icons.notifications_outlined,
    color: Colors.orange,
    status: IntegrationStatus.connected,
    connectedAs: 'pharmoos-prod',
    lastSyncLabel: '1,240 tokens registered',
    isRequired: true,
    fields: [
      const _IntField('project_id', 'Project ID', 'pharmoos-prod'),
      const _IntField(
        'credentials_path',
        'Service Account JSON',
        '/secrets/firebase-credentials.json',
      ),
    ],
  ),
  _Integration(
    id: 'r2',
    name: 'Cloudflare R2 Storage',
    description:
        'S3-compatible object storage for invoices, product images, photos and backups.',
    icon: Icons.cloud_outlined,
    color: Colors.deepOrange,
    status: IntegrationStatus.connected,
    connectedAs: 'pharmoos-prod bucket',
    lastSyncLabel: '12.4 GB used',
    isRequired: true,
    fields: [
      const _IntField('account_id', 'Account ID', 'abc123def456...'),
      const _IntField(
        'access_key_id',
        'Access Key ID',
        'R2_ACCESS_...',
        isSecret: true,
      ),
      const _IntField(
        'secret_access_key',
        'Secret Access Key',
        '************',
        isSecret: true,
      ),
      const _IntField(
        'endpoint',
        'Endpoint URL',
        'https://abc123.r2.cloudflarestorage.com',
      ),
      const _IntField('bucket', 'Bucket Name', 'pharmoos-prod'),
    ],
  ),
  _Integration(
    id: 'sentry',
    name: 'Sentry Error Tracking',
    description:
        'Real-time error monitoring and performance tracking for API and mobile apps.',
    icon: Icons.bug_report_outlined,
    color: Colors.purple,
    status: IntegrationStatus.disconnected,
    connectedAs: null,
    lastSyncLabel: null,
    isRequired: false,
    fields: [
      const _IntField('dsn', 'Sentry DSN', ''),
      const _IntField('environment', 'Environment', 'production'),
    ],
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _unsaved = false;

  // ── General settings state ─────────────────────────────────────────────────
  final _platformNameCtrl = TextEditingController(text: 'PharmaOS');
  final _supportEmailCtrl = TextEditingController(text: 'support@pharmoos.io');
  final _apiUrlCtrl = TextEditingController(text: 'https://api.pharmoos.io');
  String _timezone = 'Africa/Nairobi';
  String _language = 'Swahili (sw)';
  int _maxUsersStarter = 10;
  int _maxUsersPro = 25;
  int _nearExpiryDays = 90;
  int _lowStockThreshold = 10;
  bool _maintenanceMode = false;
  bool _allowSelfOnboard = false;
  bool _enableWhatsApp = true;
  bool _enableMobileMoney = true;

  // ── Category state ─────────────────────────────────────────────────────────
  String? _expandedCatId;

  // ── Territory state ────────────────────────────────────────────────────────
  String? _expandedTerritoryId;
  String _territoryLevel = 'region';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    for (final ctrl in [_platformNameCtrl, _supportEmailCtrl, _apiUrlCtrl]) {
      ctrl.addListener(() => setState(() => _unsaved = true));
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _platformNameCtrl.dispose();
    _supportEmailCtrl.dispose();
    _apiUrlCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? null : Colors.red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveGeneral() {
    setState(() => _unsaved = false);
    _snack('Settings saved successfully');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _buildHeader(context),

          // ── Tab bar ────────────────────────────────────────────────────────
          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                _tab(Icons.tune_rounded, 'General'),
                _tab(Icons.category_outlined, 'Categories'),
                _tab(Icons.map_outlined, 'Territories'),
                _tab(Icons.electrical_services_outlined, 'Integrations'),
                _tab(Icons.security_outlined, 'Security'),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Tab views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildGeneralTab(context),
                _buildCategoriesTab(context),
                _buildTerritoriesTab(context),
                _buildIntegrationsTab(context),
                _buildSecurityTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab _tab(IconData icon, String label) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
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
                        color: Colors.blueGrey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blueGrey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 12,
                            color: Colors.blueGrey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'SUPER ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.blueGrey.shade700,
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
                  'System Settings',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Platform configuration, categories & integrations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_unsaved)
            FilledButton.icon(
              onPressed: _saveGeneral,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 1 — General
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildGeneralTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Platform identity
        _SettingsSection(
          title: 'Platform Identity',
          icon: Icons.business_outlined,
          iconColor: Colors.indigo,
          children: [
            _SettingsField(
              label: 'Platform Name',
              hint: 'PharmaOS',
              controller: _platformNameCtrl,
              icon: Icons.label_outlined,
            ),
            const SizedBox(height: 12),
            _SettingsField(
              label: 'Support Email',
              hint: 'support@pharmoos.io',
              controller: _supportEmailCtrl,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _SettingsField(
              label: 'API Base URL',
              hint: 'https://api.pharmoos.io',
              controller: _apiUrlCtrl,
              icon: Icons.link_outlined,
            ),
            const SizedBox(height: 12),
            _DropdownSetting(
              label: 'Default Timezone',
              icon: Icons.schedule_outlined,
              value: _timezone,
              options: const [
                'Africa/Nairobi',
                'Africa/Dar_es_Salaam',
                'Africa/Kampala',
                'UTC',
              ],
              onChanged: (v) => setState(() {
                _timezone = v!;
                _unsaved = true;
              }),
            ),
            const SizedBox(height: 12),
            _DropdownSetting(
              label: 'Default Language',
              icon: Icons.language_outlined,
              value: _language,
              options: const ['Swahili (sw)', 'English (en)'],
              onChanged: (v) => setState(() {
                _language = v!;
                _unsaved = true;
              }),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Limits
        _SettingsSection(
          title: 'Plan Limits',
          icon: Icons.tune_rounded,
          iconColor: Colors.teal,
          subtitle: 'Default limits per subscription tier',
          children: [
            _StepperSetting(
              label: 'Max Users — Starter plan',
              value: _maxUsersStarter,
              min: 5,
              max: 50,
              step: 5,
              onChanged: (v) => setState(() {
                _maxUsersStarter = v;
                _unsaved = true;
              }),
            ),
            const Divider(height: 20),
            _StepperSetting(
              label: 'Max Users — Professional plan',
              value: _maxUsersPro,
              min: 10,
              max: 100,
              step: 5,
              onChanged: (v) => setState(() {
                _maxUsersPro = v;
                _unsaved = true;
              }),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Inventory defaults
        _SettingsSection(
          title: 'Inventory Defaults',
          icon: Icons.inventory_2_outlined,
          iconColor: Colors.amber.shade700,
          children: [
            _StepperSetting(
              label: 'Near-Expiry Alert Threshold',
              value: _nearExpiryDays,
              suffix: 'days',
              min: 30,
              max: 180,
              step: 15,
              onChanged: (v) => setState(() {
                _nearExpiryDays = v;
                _unsaved = true;
              }),
            ),
            const Divider(height: 20),
            _StepperSetting(
              label: 'Low Stock Alert Threshold',
              value: _lowStockThreshold,
              suffix: 'units',
              min: 5,
              max: 100,
              step: 5,
              onChanged: (v) => setState(() {
                _lowStockThreshold = v;
                _unsaved = true;
              }),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Feature toggles
        _SettingsSection(
          title: 'Feature Flags',
          icon: Icons.toggle_on_outlined,
          iconColor: Colors.purple,
          children: [
            _ToggleSetting(
              label: 'WhatsApp Integration',
              sublabel: 'Enable WhatsApp Business API platform-wide',
              value: _enableWhatsApp,
              icon: Icons.chat_bubble_outlined,
              activeColor: Colors.green,
              onChanged: (v) => setState(() {
                _enableWhatsApp = v;
                _unsaved = true;
              }),
            ),
            const Divider(height: 1),
            _ToggleSetting(
              label: 'Mobile Money Payments',
              sublabel: 'M-Pesa and Airtel Money processing',
              value: _enableMobileMoney,
              icon: Icons.phone_android_outlined,
              activeColor: Colors.green,
              onChanged: (v) => setState(() {
                _enableMobileMoney = v;
                _unsaved = true;
              }),
            ),
            const Divider(height: 1),
            _ToggleSetting(
              label: 'Self-Service Onboarding',
              sublabel: 'Allow orgs to onboard without Super Admin approval',
              value: _allowSelfOnboard,
              icon: Icons.how_to_reg_outlined,
              activeColor: Colors.blue,
              onChanged: (v) => setState(() {
                _allowSelfOnboard = v;
                _unsaved = true;
              }),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Danger zone
        _SettingsSection(
          title: 'Danger Zone',
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
          borderColor: Colors.red.withValues(alpha: 0.3),
          children: [
            _ToggleSetting(
              label: 'Maintenance Mode',
              sublabel: 'Blocks all non-admin access to the platform',
              value: _maintenanceMode,
              icon: Icons.construction_outlined,
              activeColor: Colors.red,
              onChanged: (v) {
                if (v) {
                  _showMaintenanceConfirm(v);
                } else {
                  setState(() {
                    _maintenanceMode = false;
                    _unsaved = true;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showMaintenanceConfirm(bool value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 36,
        ),
        title: const Text(
          'Enable Maintenance Mode?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'This will immediately block all non-Super Admin access to the platform. '
          'All active sessions will be terminated.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _maintenanceMode = true;
                _unsaved = true;
              });
              _snack('⚠️ Maintenance mode ENABLED', success: false);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Enable Maintenance Mode'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 2 — Categories
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCategoriesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Root categories
    final roots = _categories.where((c) => c.parentId == null).toList();

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Text(
                '${_categories.length} categories · ${_categories.where((c) => c.parentId != null).length} sub-categories',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCategoryForm(null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Category'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        // Tree
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: roots.length,
            itemBuilder: (_, i) {
              final root = roots[i];
              final children = _categories
                  .where((c) => c.parentId == root.id)
                  .toList();
              final isExpanded = _expandedCatId == root.id;

              return Column(
                children: [
                  _CategoryTile(
                    cat: root,
                    isRoot: true,
                    hasChildren: children.isNotEmpty,
                    isExpanded: isExpanded,
                    onToggle: () => setState(
                      () => _expandedCatId = isExpanded ? null : root.id,
                    ),
                    onEdit: () => _showCategoryForm(root),
                    onToggleActive: () =>
                        setState(() => root.isActive = !root.isActive),
                    onAddChild: () =>
                        _showCategoryForm(null, parentId: root.id),
                  ),
                  if (isExpanded)
                    ...children.map(
                      (child) => _CategoryTile(
                        cat: child,
                        isRoot: false,
                        hasChildren: false,
                        isExpanded: false,
                        onToggle: () {},
                        onEdit: () => _showCategoryForm(child),
                        onToggleActive: () =>
                            setState(() => child.isActive = !child.isActive),
                        onAddChild: () {},
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCategoryForm(_Category? cat, {String? parentId}) {
    final nameCtrl = TextEditingController(text: cat?.name);
    final emojiCtrl = TextEditingController(text: cat?.emoji ?? '💊');
    final isEdit = cat != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
            _SheetHandle(),
            const SizedBox(height: 16),
            Text(
              isEdit
                  ? 'Edit Category'
                  : parentId != null
                  ? 'Add Sub-Category'
                  : 'Add Category',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (parentId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Under: ${_categories.firstWhere((c) => c.id == parentId).name}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: _FieldBox(
                    label: 'Emoji',
                    controller: emojiCtrl,
                    hint: '💊',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FieldBox(
                    label: 'Name *',
                    controller: nameCtrl,
                    hint: 'e.g. Antibiotics',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _snack(isEdit ? 'Category updated' : 'Category added');
                },
                icon: Icon(
                  isEdit ? Icons.save_outlined : Icons.add_rounded,
                  size: 16,
                ),
                label: Text(isEdit ? 'Save Changes' : 'Add Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 3 — Territories
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTerritoriesTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter by level tab
    final roots = _territories.where((t) => t.parentId == null).toList();

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: colorScheme.surfaceContainerLow,
          child: Row(
            children: [
              Text(
                '${_territories.length} territories',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showTerritoryForm(null),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Territory'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        // Level legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              _LevelBadge('region', Colors.indigo),
              const SizedBox(width: 8),
              _LevelBadge('district', Colors.teal),
              const SizedBox(width: 8),
              _LevelBadge('zone', Colors.orange),
            ],
          ),
        ),
        // Tree
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: roots.length,
            itemBuilder: (_, i) {
              final root = roots[i];
              final districts = _territories
                  .where((t) => t.parentId == root.id)
                  .toList();
              final isExpanded = _expandedTerritoryId == root.id;

              return Column(
                children: [
                  _TerritoryTile(
                    territory: root,
                    indent: 0,
                    hasChildren: districts.isNotEmpty,
                    isExpanded: isExpanded,
                    onToggle: () => setState(
                      () => _expandedTerritoryId = isExpanded ? null : root.id,
                    ),
                    onEdit: () => _showTerritoryForm(root),
                    onToggleActive: () =>
                        setState(() => root.isActive = !root.isActive),
                    onAddChild: () => _showTerritoryForm(
                      null,
                      parentId: root.id,
                      level: 'district',
                    ),
                  ),
                  if (isExpanded)
                    ...districts.map((district) {
                      final zones = _territories
                          .where((t) => t.parentId == district.id)
                          .toList();
                      return Column(
                        children: [
                          _TerritoryTile(
                            territory: district,
                            indent: 1,
                            hasChildren: zones.isNotEmpty,
                            isExpanded: false,
                            onToggle: () {},
                            onEdit: () => _showTerritoryForm(district),
                            onToggleActive: () => setState(
                              () => district.isActive = !district.isActive,
                            ),
                            onAddChild: () => _showTerritoryForm(
                              null,
                              parentId: district.id,
                              level: 'zone',
                            ),
                          ),
                          ...zones.map(
                            (zone) => _TerritoryTile(
                              territory: zone,
                              indent: 2,
                              hasChildren: false,
                              isExpanded: false,
                              onToggle: () {},
                              onEdit: () => _showTerritoryForm(zone),
                              onToggleActive: () => setState(
                                () => zone.isActive = !zone.isActive,
                              ),
                              onAddChild: () {},
                            ),
                          ),
                        ],
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTerritoryForm(_Territory? t, {String? parentId, String? level}) {
    final nameCtrl = TextEditingController(text: t?.name);
    final lvl = t?.level ?? level ?? 'region';
    final isEdit = t != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
            _SheetHandle(),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Territory' : 'Add Territory',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            _LevelBadge(lvl, _levelColor(lvl)),
            const SizedBox(height: 16),
            _FieldBox(
              label: 'Territory Name *',
              controller: nameCtrl,
              hint: 'e.g. Mbeya District',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _snack(isEdit ? 'Territory updated' : 'Territory added');
                },
                icon: Icon(
                  isEdit ? Icons.save_outlined : Icons.add_rounded,
                  size: 16,
                ),
                label: Text(isEdit ? 'Save Changes' : 'Add Territory'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 4 — Integrations
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildIntegrationsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final connected = _integrations
        .where((i) => i.status == IntegrationStatus.connected)
        .length;
    final errors = _integrations
        .where((i) => i.status == IntegrationStatus.error)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              _IntSummaryItem(
                value: '$connected',
                label: 'Connected',
                color: Colors.green,
              ),
              const SizedBox(width: 20),
              _IntSummaryItem(
                value: '$errors',
                label: 'Errors',
                color: Colors.red,
              ),
              const SizedBox(width: 20),
              _IntSummaryItem(
                value: '${_integrations.length - connected - errors}',
                label: 'Not configured',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ..._integrations.map(
          (intg) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IntegrationCard(
              integration: intg,
              onConfigure: () => _showIntegrationConfig(intg),
              onTest: () => _snack('Testing ${intg.name}…'),
              onDisconnect: () =>
                  setState(() => intg.status = IntegrationStatus.disconnected),
            ),
          ),
        ),
      ],
    );
  }

  void _showIntegrationConfig(_Integration intg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _IntegrationConfigSheet(
        integration: intg,
        onSave: () {
          Navigator.pop(context);
          setState(() => intg.status = IntegrationStatus.connected);
          _snack('${intg.name} configured successfully');
        },
        onTest: () => _snack('Testing connection…'),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 5 — Security
  // ════════════════════════════════════════════════════════════════════════════

  bool _require2FA = false;
  int _sessionTimeout = 60;
  int _maxLoginAttempts = 5;
  int _rateLimitPerMin = 60;
  bool _ipWhitelistEnabled = false;
  final _ipCtrl = TextEditingController(text: '41.220.15.0/24');

  Widget _buildSecurityTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SettingsSection(
          title: 'Authentication',
          icon: Icons.lock_outline_rounded,
          iconColor: Colors.indigo,
          children: [
            _ToggleSetting(
              label: 'Require 2FA Platform-Wide',
              sublabel: 'All Super Admin accounts must enable 2FA',
              value: _require2FA,
              icon: Icons.verified_user_outlined,
              activeColor: Colors.indigo,
              onChanged: (v) => setState(() {
                _require2FA = v;
                _unsaved = true;
              }),
            ),
            const Divider(height: 20),
            _StepperSetting(
              label: 'Session Timeout',
              suffix: 'minutes',
              value: _sessionTimeout,
              min: 15,
              max: 480,
              step: 15,
              onChanged: (v) => setState(() {
                _sessionTimeout = v;
                _unsaved = true;
              }),
            ),
            const Divider(height: 20),
            _StepperSetting(
              label: 'Max Login Attempts Before Lockout',
              suffix: 'attempts',
              value: _maxLoginAttempts,
              min: 3,
              max: 10,
              step: 1,
              onChanged: (v) => setState(() {
                _maxLoginAttempts = v;
                _unsaved = true;
              }),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _SettingsSection(
          title: 'Rate Limiting',
          icon: Icons.speed_outlined,
          iconColor: Colors.orange,
          subtitle: 'API request limits per user',
          children: [
            _StepperSetting(
              label: 'Max API Requests',
              suffix: 'per minute',
              value: _rateLimitPerMin,
              min: 30,
              max: 300,
              step: 30,
              onChanged: (v) => setState(() {
                _rateLimitPerMin = v;
                _unsaved = true;
              }),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _SettingsSection(
          title: 'IP Allowlist',
          icon: Icons.location_on_outlined,
          iconColor: Colors.teal,
          subtitle: 'Restrict Super Admin access to specific IP ranges',
          children: [
            _ToggleSetting(
              label: 'Enable IP Allowlist',
              sublabel: 'Only allowlisted IPs can access admin panel',
              value: _ipWhitelistEnabled,
              icon: Icons.shield_outlined,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() {
                _ipWhitelistEnabled = v;
                _unsaved = true;
              }),
            ),
            if (_ipWhitelistEnabled) ...[
              const Divider(height: 20),
              _SettingsField(
                label: 'Allowed IP Ranges (CIDR)',
                hint: '41.220.0.0/16',
                controller: _ipCtrl,
                icon: Icons.router_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'One CIDR range per line. Current access IP: 41.220.15.4',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        _SettingsSection(
          title: 'Token Management',
          icon: Icons.key_outlined,
          iconColor: Colors.purple,
          children: [
            _ActionSettingRow(
              label: 'Revoke All Sanctum Tokens',
              sublabel: 'Forces all users to log in again',
              icon: Icons.logout_rounded,
              color: Colors.red,
              buttonLabel: 'Revoke All',
              onTap: () => _snack('All tokens revoked', success: false),
            ),
            const Divider(height: 1),
            _ActionSettingRow(
              label: 'Clean Expired Tokens',
              sublabel: 'Remove expired tokens from database',
              icon: Icons.cleaning_services_outlined,
              color: Colors.teal,
              buttonLabel: 'Clean Now',
              onTap: () => _snack('Expired tokens cleaned'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Reusable settings widgets ────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  final Color? borderColor;

  const _SettingsSection({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.children,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ?? colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SettingsField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownSetting({
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label, sublabel;
  final bool value;
  final IconData icon;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.icon,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        sublabel,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      secondary: Icon(
        icon,
        color: value
            ? activeColor
            : Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _StepperSetting extends StatelessWidget {
  final String label;
  final String? suffix;
  final int value, min, max, step;
  final ValueChanged<int> onChanged;

  const _StepperSetting({
    required this.label,
    this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton.outlined(
              onPressed: value > min ? () => onChanged(value - step) : null,
              icon: const Icon(Icons.remove_rounded, size: 16),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Container(
              width: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '$value',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              onPressed: value < max ? () => onChanged(value + step) : null,
              icon: const Icon(Icons.add_rounded, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionSettingRow extends StatelessWidget {
  final String label, sublabel, buttonLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionSettingRow({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(foregroundColor: color),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category tile ────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final _Category cat;
  final bool isRoot, hasChildren, isExpanded;
  final VoidCallback onToggle, onEdit, onToggleActive, onAddChild;

  const _CategoryTile({
    required this.cat,
    required this.isRoot,
    required this.hasChildren,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.onToggleActive,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: hasChildren ? onToggle : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(isRoot ? 16 : 32, 10, 12, 10),
        child: Row(
          children: [
            if (!isRoot)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            Text(cat.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                      color: cat.isActive
                          ? null
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${cat.productCount} products',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!cat.isActive) ...[
                        const SizedBox(width: 6),
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
                            'Inactive',
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
            if (hasChildren)
              Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
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
              onSelected: (v) => switch (v) {
                'edit' => onEdit(),
                'toggle' => onToggleActive(),
                'add_child' => onAddChild(),
                _ => null,
              },
              itemBuilder: (_) => [
                if (isRoot)
                  PopupMenuItem(
                    value: 'add_child',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded, size: 15),
                        const SizedBox(width: 8),
                        const Text(
                          'Add Sub-category',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 15),
                      const SizedBox(width: 8),
                      const Text('Edit', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        cat.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                        color: cat.isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                          fontSize: 13,
                          color: cat.isActive ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Territory tile ───────────────────────────────────────────────────────────

class _TerritoryTile extends StatelessWidget {
  final _Territory territory;
  final int indent;
  final bool hasChildren, isExpanded;
  final VoidCallback onToggle, onEdit, onToggleActive, onAddChild;

  const _TerritoryTile({
    required this.territory,
    required this.indent,
    required this.hasChildren,
    required this.isExpanded,
    required this.onToggle,
    required this.onEdit,
    required this.onToggleActive,
    required this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _levelColor(territory.level);

    return InkWell(
      onTap: hasChildren ? onToggle : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.0 + indent * 20, 10, 12, 10),
        child: Row(
          children: [
            if (indent > 0)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.subdirectory_arrow_right_rounded,
                  size: 13,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                ),
              ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    territory.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: indent == 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: territory.isActive
                          ? null
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                  Row(
                    children: [
                      _LevelBadge(territory.level, color),
                      const SizedBox(width: 6),
                      Text(
                        '${territory.orgCount} orgs',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!territory.isActive) ...[
                        const SizedBox(width: 6),
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
                            'Inactive',
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
            if (hasChildren)
              Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
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
              onSelected: (v) => switch (v) {
                'edit' => onEdit(),
                'toggle' => onToggleActive(),
                'add_child' => onAddChild(),
                _ => null,
              },
              itemBuilder: (_) => [
                if (territory.level != 'zone')
                  PopupMenuItem(
                    value: 'add_child',
                    height: 40,
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded, size: 15),
                        const SizedBox(width: 8),
                        Text(
                          'Add ${territory.level == 'region' ? 'District' : 'Zone'}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 15),
                      const SizedBox(width: 8),
                      const Text('Edit', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        territory.isActive
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 15,
                        color: territory.isActive
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        territory.isActive ? 'Deactivate' : 'Activate',
                        style: TextStyle(
                          fontSize: 13,
                          color: territory.isActive
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Integration card ─────────────────────────────────────────────────────────

class _IntegrationCard extends StatelessWidget {
  final _Integration integration;
  final VoidCallback onConfigure, onTest, onDisconnect;

  const _IntegrationCard({
    required this.integration,
    required this.onConfigure,
    required this.onTest,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final intg = integration;
    final statusColor = _statusColor(intg.status);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: intg.status == IntegrationStatus.error
              ? Colors.red.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: intg.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(intg.icon, color: intg.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            intg.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (intg.isRequired) ...[
                            const SizedBox(width: 6),
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
                                'Required',
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
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel(intg.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                          if (intg.connectedAs != null) ...[
                            Text(
                              ' · ',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              intg.connectedAs!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
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

            // Description
            const SizedBox(height: 10),
            Text(
              intg.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            // Last sync
            if (intg.lastSyncLabel != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    intg.lastSyncLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            // Error banner
            if (intg.status == IntegrationStatus.error) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Authentication failed. Please re-enter credentials and test connection.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Actions
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onConfigure,
                  icon: const Icon(Icons.settings_outlined, size: 14),
                  label: Text(
                    intg.status == IntegrationStatus.disconnected
                        ? 'Configure'
                        : 'Edit Config',
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (intg.status == IntegrationStatus.connected ||
                    intg.status == IntegrationStatus.error)
                  OutlinedButton.icon(
                    onPressed: onTest,
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 14),
                    label: const Text('Test'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                const Spacer(),
                if (intg.status == IntegrationStatus.connected)
                  TextButton(
                    onPressed: onDisconnect,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(IntegrationStatus s) => switch (s) {
    IntegrationStatus.connected => Colors.green,
    IntegrationStatus.error => Colors.red,
    IntegrationStatus.disconnected => Colors.grey,
    IntegrationStatus.pending => Colors.orange,
  };

  String _statusLabel(IntegrationStatus s) => switch (s) {
    IntegrationStatus.connected => 'Connected',
    IntegrationStatus.error => 'Error',
    IntegrationStatus.disconnected => 'Not connected',
    IntegrationStatus.pending => 'Pending',
  };
}

// ─── Integration config sheet ─────────────────────────────────────────────────

class _IntegrationConfigSheet extends StatefulWidget {
  final _Integration integration;
  final VoidCallback onSave, onTest;

  const _IntegrationConfigSheet({
    required this.integration,
    required this.onSave,
    required this.onTest,
  });

  @override
  State<_IntegrationConfigSheet> createState() =>
      _IntegrationConfigSheetState();
}

class _IntegrationConfigSheetState extends State<_IntegrationConfigSheet> {
  late final Map<String, TextEditingController> _ctrls;
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final f in widget.integration.fields)
        f.key: TextEditingController(text: f.value),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final intg = widget.integration;

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
            _SheetHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: intg.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(intg.icon, color: intg.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        intg.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'API credentials & configuration',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            ...intg.fields.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          f.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (f.isSecret) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'SECRET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _ctrls[f.key],
                      obscureText: f.isSecret && !_revealed.contains(f.key),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: f.isSecret
                            ? IconButton(
                                icon: Icon(
                                  _revealed.contains(f.key)
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 16,
                                ),
                                onPressed: () => setState(
                                  () => _revealed.contains(f.key)
                                      ? _revealed.remove(f.key)
                                      : _revealed.add(f.key),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onTest,
                    icon: const Icon(Icons.wifi_tethering_rounded, size: 15),
                    label: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onSave,
                    icon: const Icon(Icons.save_outlined, size: 15),
                    label: const Text('Save Config'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;

  const _FieldBox({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final Color color;

  const _LevelBadge(this.level, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _IntSummaryItem extends StatelessWidget {
  final String value, label;
  final Color color;
  const _IntSummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

Color _levelColor(String level) => switch (level) {
  'region' => Colors.indigo,
  'district' => Colors.teal,
  'zone' => Colors.orange,
  _ => Colors.grey,
};
