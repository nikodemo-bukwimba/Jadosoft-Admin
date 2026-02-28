import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SUBSCRIPTIONS & BILLING PAGE
// Super Admin — Pharma SaaS Platform
// Depends on: fl_chart (add to pubspec.yaml: fl_chart: ^0.68.0)
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
const _cAmber = Color(0xFFFF8F00);
const _cAmberLight = Color(0xFFFFF8E1);
const _cSurface = Color(0xFFF4F6FA);
const _cCard = Colors.white;
const _cTextPrimary = Color(0xFF1A1A2E);
const _cTextSecondary = Color(0xFF6B7280);
const _cBorder = Color(0xFFE5E7EB);
const _cTableHeader = Color(0xFFF8F9FB);

// ── Card helper ───────────────────────────────────────────────────────────────
BoxDecoration _card({double radius = 12, Color? color, Color? borderColor}) =>
    BoxDecoration(
      color: color ?? _cCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? _cBorder, width: 1),
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

class _PlanData {
  final String name;
  final String slug;
  final String priceMonthly;
  final String priceAnnual;
  final int orgCount;
  final int maxUsers;
  final String maxUsersLabel;
  final List<String> features;
  final Color accentColor;
  final Color accentLight;
  final bool isPopular;
  const _PlanData({
    required this.name,
    required this.slug,
    required this.priceMonthly,
    required this.priceAnnual,
    required this.orgCount,
    required this.maxUsers,
    required this.maxUsersLabel,
    required this.features,
    required this.accentColor,
    required this.accentLight,
    this.isPopular = false,
  });
}

class _SubRow {
  final String orgName;
  final List<String> orgTypes;
  final String plan;
  final Color planColor;
  final String status;
  final String billingCycle;
  final String amount;
  final String periodStart;
  final String periodEnd;
  final String renewsIn;
  final bool isOverdue;
  const _SubRow({
    required this.orgName,
    required this.orgTypes,
    required this.plan,
    required this.planColor,
    required this.status,
    required this.billingCycle,
    required this.amount,
    required this.periodStart,
    required this.periodEnd,
    required this.renewsIn,
    this.isOverdue = false,
  });
}

class _TxnRow {
  final String ref;
  final String org;
  final String plan;
  final String amount;
  final String method;
  final String date;
  final String status;
  const _TxnRow({
    required this.ref,
    required this.org,
    required this.plan,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA
// ─────────────────────────────────────────────────────────────────────────────

const _plans = [
  _PlanData(
    name: 'Starter',
    slug: 'starter',
    priceMonthly: 'TZS 150,000',
    priceAnnual: 'TZS 1,440,000',
    orgCount: 18,
    maxUsers: 10,
    maxUsersLabel: 'Up to 10 users',
    accentColor: _cInfo,
    accentLight: _cInfoLight,
    features: [
      'CRM & Visit Logging',
      'Order Management',
      'Basic Inventory',
      'In-app Messaging',
      'Standard Reports',
    ],
  ),
  _PlanData(
    name: 'Professional',
    slug: 'professional',
    priceMonthly: 'TZS 350,000',
    priceAnnual: 'TZS 3,360,000',
    orgCount: 21,
    maxUsers: 50,
    maxUsersLabel: 'Up to 50 users',
    accentColor: _cPrimary,
    accentLight: _cPrimaryLight,
    isPopular: true,
    features: [
      'Everything in Starter',
      'WhatsApp Integration',
      'Mobile Money Payments',
      'GPS Visit Verification',
      'Advanced Analytics',
      'Commission Management',
    ],
  ),
  _PlanData(
    name: 'Enterprise',
    slug: 'enterprise',
    priceMonthly: 'TZS 750,000',
    priceAnnual: 'TZS 7,200,000',
    orgCount: 8,
    maxUsers: 0,
    maxUsersLabel: 'Unlimited users',
    accentColor: _cAmber,
    accentLight: _cAmberLight,
    features: [
      'Everything in Professional',
      'Dedicated Support & SLA',
      'Custom Integrations',
      'Multi-warehouse Support',
      'Priority Queue Processing',
      'Custom Domain / Branding',
    ],
  ),
];

const _subscriptions = [
  _SubRow(
    orgName: 'Bariki Pharma Ltd',
    orgTypes: ['distributor', 'pharmacy'],
    plan: 'Enterprise',
    planColor: _cAmber,
    status: 'active',
    billingCycle: 'annual',
    amount: 'TZS 7,200,000',
    periodStart: '01 Jan 2026',
    periodEnd: '31 Dec 2026',
    renewsIn: '306 days',
  ),
  _SubRow(
    orgName: 'Arusha Health Chain',
    orgTypes: ['pharmacy', 'distributor'],
    plan: 'Enterprise',
    planColor: _cAmber,
    status: 'active',
    billingCycle: 'annual',
    amount: 'TZS 7,200,000',
    periodStart: '15 Jan 2026',
    periodEnd: '14 Jan 2027',
    renewsIn: '320 days',
  ),
  _SubRow(
    orgName: 'MedPlus Pharmacy Dar',
    orgTypes: ['pharmacy'],
    plan: 'Professional',
    planColor: _cPrimary,
    status: 'active',
    billingCycle: 'monthly',
    amount: 'TZS 350,000',
    periodStart: '01 Feb 2026',
    periodEnd: '28 Feb 2026',
    renewsIn: '1 day',
  ),
  _SubRow(
    orgName: 'Coastal Distributors',
    orgTypes: ['distributor', 'supplier'],
    plan: 'Professional',
    planColor: _cPrimary,
    status: 'active',
    billingCycle: 'annual',
    amount: 'TZS 3,360,000',
    periodStart: '01 Mar 2025',
    periodEnd: '28 Feb 2026',
    renewsIn: '1 day',
  ),
  _SubRow(
    orgName: 'Kilimanjaro MedHub',
    orgTypes: ['pharmacy'],
    plan: 'Starter',
    planColor: _cInfo,
    status: 'trialing',
    billingCycle: 'monthly',
    amount: 'TZS 0',
    periodStart: '20 Feb 2026',
    periodEnd: '20 Mar 2026',
    renewsIn: '20 days',
  ),
  _SubRow(
    orgName: 'Dodoma Central Pharm',
    orgTypes: ['pharmacy'],
    plan: 'Starter',
    planColor: _cInfo,
    status: 'past_due',
    billingCycle: 'monthly',
    amount: 'TZS 150,000',
    periodStart: '01 Jan 2026',
    periodEnd: '31 Jan 2026',
    renewsIn: 'Overdue 28d',
    isOverdue: true,
  ),
  _SubRow(
    orgName: 'Morogoro PharmaCo',
    orgTypes: ['pharmacy'],
    plan: 'Professional',
    planColor: _cPrimary,
    status: 'active',
    billingCycle: 'monthly',
    amount: 'TZS 350,000',
    periodStart: '01 Feb 2026',
    periodEnd: '28 Feb 2026',
    renewsIn: '1 day',
  ),
  _SubRow(
    orgName: 'Tanga HealthMart',
    orgTypes: ['pharmacy', 'supplier'],
    plan: 'Starter',
    planColor: _cInfo,
    status: 'cancelled',
    billingCycle: 'monthly',
    amount: 'TZS 0',
    periodStart: '01 Dec 2025',
    periodEnd: '31 Dec 2025',
    renewsIn: '—',
  ),
];

const _transactions = [
  _TxnRow(
    ref: 'INV-2026-00891',
    org: 'Bariki Pharma Ltd',
    plan: 'Enterprise',
    amount: 'TZS 7,200,000',
    method: 'Bank Transfer',
    date: '01 Jan 2026',
    status: 'paid',
  ),
  _TxnRow(
    ref: 'INV-2026-00890',
    org: 'Arusha Health Chain',
    plan: 'Enterprise',
    amount: 'TZS 7,200,000',
    method: 'Bank Transfer',
    date: '15 Jan 2026',
    status: 'paid',
  ),
  _TxnRow(
    ref: 'INV-2026-00912',
    org: 'MedPlus Pharmacy Dar',
    plan: 'Professional',
    amount: 'TZS 350,000',
    method: 'M-Pesa',
    date: '01 Feb 2026',
    status: 'paid',
  ),
  _TxnRow(
    ref: 'INV-2026-00913',
    org: 'Morogoro PharmaCo',
    plan: 'Professional',
    amount: 'TZS 350,000',
    method: 'Airtel Money',
    date: '01 Feb 2026',
    status: 'paid',
  ),
  _TxnRow(
    ref: 'INV-2026-00901',
    org: 'Dodoma Central Pharm',
    plan: 'Starter',
    amount: 'TZS 150,000',
    method: 'M-Pesa',
    date: '01 Feb 2026',
    status: 'failed',
  ),
  _TxnRow(
    ref: 'INV-2026-00888',
    org: 'Coastal Distributors',
    plan: 'Professional',
    amount: 'TZS 3,360,000',
    method: 'Bank Transfer',
    date: '01 Mar 2025',
    status: 'paid',
  ),
];

// Revenue bar chart data — monthly TZS revenue (in millions)
final _revenueMonths = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb'];
final _revenueValues = [6.8, 7.2, 7.9, 8.5, 9.1, 10.2, 12.4];

// Plan distribution donut data
final _planDist = [
  (label: 'Enterprise', value: 8.0, color: _cAmber),
  (label: 'Professional', value: 21.0, color: _cPrimary),
  (label: 'Starter', value: 18.0, color: _cInfo),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PAGE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _cSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BillingHeader(),
                  SizedBox(height: 28),
                  _BillingStatsRow(),
                  SizedBox(height: 28),
                  _PlansSection(),
                  SizedBox(height: 28),
                  _ChartsRow(),
                  SizedBox(height: 28),
                  _SubscriptionsTable(),
                  SizedBox(height: 28),
                  _RecentTransactionsTable(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _BillingHeader extends StatelessWidget {
  const _BillingHeader();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // LEFT SECTION
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _cAmber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Subscriptions & Billing',
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
                '47 organizations  ·  3 active plans  ·  Billing period: February 2026',
                style: text.bodySmall?.copyWith(color: _cTextSecondary),
              ),
            ),
          ],
        ),

        const SizedBox(width: 24),

        // RIGHT SECTION (bounded + aligned)
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // MRR badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _cSuccessLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cSuccess.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: _cSuccess,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MRR  TZS 4.12M',
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
                label: const Text('Export Billing'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _cTextPrimary,
                  side: const BorderSide(color: _cBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_card_rounded, size: 16),
                label: const Text('New Plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: _cPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// BILLING STATS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _BillingStatsRow extends StatelessWidget {
  const _BillingStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BillingStatCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Monthly Recurring Revenue',
            value: 'TZS 4.12M',
            sub: '+18.4% vs last month',
            subPositive: true,
            iconColor: _cSuccess,
            iconBg: _cSuccessLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BillingStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Annual Recurring Revenue',
            value: 'TZS 49.4M',
            sub: 'Projected full year',
            subPositive: true,
            iconColor: _cPrimary,
            iconBg: _cPrimaryLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BillingStatCard(
            icon: Icons.business_rounded,
            label: 'Paying Organizations',
            value: '44',
            sub: '3 in free trial',
            subPositive: true,
            iconColor: _cAccent,
            iconBg: _cAccentLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BillingStatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Past Due',
            value: '1',
            sub: 'TZS 150,000 outstanding',
            subPositive: false,
            iconColor: _cError,
            iconBg: _cErrorLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BillingStatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Renewals This Month',
            value: '3',
            sub: 'TZS 700,000 expected',
            subPositive: true,
            iconColor: _cWarning,
            iconBg: _cWarningLight,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _BillingStatCard(
            icon: Icons.cancel_outlined,
            label: 'Churned (30 days)',
            value: '1',
            sub: 'Tanga HealthMart',
            subPositive: false,
            iconColor: _cTextSecondary,
            iconBg: _cSurface,
          ),
        ),
      ],
    );
  }
}

class _BillingStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final bool subPositive;
  final Color iconColor;
  final Color iconBg;

  const _BillingStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.subPositive,
    required this.iconColor,
    required this.iconBg,
  });

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
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 24),
              Icon(
                subPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: subPositive ? _cSuccess : _cError,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: _cTextPrimary,
              letterSpacing: -0.5,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: _cTextSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: _cBorder),
          const SizedBox(height: 10),
          Text(
            sub,
            style: text.labelSmall?.copyWith(
              color: subPositive ? _cSuccess : _cError,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLANS SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _PlansSection extends StatelessWidget {
  const _PlansSection();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Plans',
                  style: text.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage plan pricing, features, and limits',
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                ),
              ],
            ),
            const SizedBox(width: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit Plans'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _cTextPrimary,
                side: const BorderSide(color: _cBorder),
                textStyle: const TextStyle(fontSize: 13),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _plans
              .map(
                (p) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: p == _plans.last ? 0 : 16),
                    child: _PlanCard(plan: p),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: _card(
        borderColor: plan.isPopular
            ? plan.accentColor.withOpacity(0.5)
            : _cBorder,
      ),
      child: Column(
        children: [
          // Plan header
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            decoration: BoxDecoration(
              color: plan.isPopular
                  ? plan.accentLight
                  : const Color(0xFFF8F9FB),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: _cBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: plan.accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        plan.name.toUpperCase(),
                        style: text.labelSmall?.copyWith(
                          color: plan.accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    if (plan.isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: plan.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '★ POPULAR',
                          style: text.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Monthly price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.priceMonthly,
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _cTextPrimary,
                        fontSize: 18,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3, left: 4),
                      child: Text(
                        '/ month',
                        style: text.bodySmall?.copyWith(color: _cTextSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${plan.priceAnnual} / year (save 20%)',
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Stats + features
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Org count meter
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: plan.accentLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: plan.accentColor,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${plan.orgCount} organizations',
                            style: text.labelSmall?.copyWith(
                              color: plan.accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _cSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            color: _cTextSecondary,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            plan.maxUsersLabel,
                            style: text.labelSmall?.copyWith(
                              color: _cTextSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Features list
                ...plan.features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: plan.accentColor,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: text.bodySmall?.copyWith(
                              color: _cTextPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Edit plan button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: plan.accentColor,
                      side: BorderSide(
                        color: plan.accentColor.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: Text(
                      'Edit ${plan.name} Plan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// CHARTS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ChartsRow extends StatelessWidget {
  const _ChartsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Revenue bar chart
          Expanded(
            flex: 6,
            child: Container(
              decoration: _card(),
              padding: const EdgeInsets.all(24),
              child: const _RevenueBarChart(),
            ),
          ),
          const SizedBox(width: 20),
          // Plan distribution donut
          Expanded(
            flex: 3,
            child: Container(
              decoration: _card(),
              padding: const EdgeInsets.all(24),
              child: const _PlanDistributionChart(),
            ),
          ),
          const SizedBox(width: 20),
          // Quick billing stats
          Expanded(
            flex: 3,
            child: Container(
              decoration: _card(),
              child: const _BillingBreakdownPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Trend',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _cTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Monthly subscription revenue (TZS millions)',
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _cSuccessLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '↑ 82% growth (6 months)',
                style: text.labelSmall?.copyWith(
                  color: _cSuccess,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceEvenly,
              maxY: 15,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => _cPrimary,
                  tooltipBorderRadius: BorderRadius.circular(8),
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                    'TZS ${rod.toY}M\n${_revenueMonths[group.x]}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: 3,
                    getTitlesWidget: (v, m) => Text(
                      '${v.toInt()}M',
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
                    getTitlesWidget: (v, m) {
                      final i = v.toInt();
                      if (i < 0 || i >= _revenueMonths.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        _revenueMonths[i],
                        style: const TextStyle(
                          fontSize: 12,
                          color: _cTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      );
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 3,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: _cBorder,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                _revenueValues.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: _revenueValues[i],
                      width: 28,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      gradient: LinearGradient(
                        colors: i == _revenueValues.length - 1
                            ? [_cPrimaryMid, _cPrimary]
                            : [
                                _cPrimary.withOpacity(0.35),
                                _cPrimary.withOpacity(0.55),
                              ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanDistributionChart extends StatelessWidget {
  const _PlanDistributionChart();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const total = 47.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan Distribution',
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _cTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '47 organizations by plan',
          style: text.bodySmall?.copyWith(color: _cTextSecondary),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 44,
                    sections: _planDist
                        .map(
                          (p) => PieChartSectionData(
                            value: p.value,
                            color: p.color,
                            radius: 34,
                            showTitle: false,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        ..._planDist.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.label,
                    style: text.bodySmall?.copyWith(
                      color: _cTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${p.value.toInt()}',
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${(p.value / total * 100).toStringAsFixed(0)}%)',
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BillingBreakdownPanel extends StatelessWidget {
  const _BillingBreakdownPanel();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            'Revenue Breakdown',
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _cTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Text(
            'Feb 2026 — by plan',
            style: text.bodySmall?.copyWith(color: _cTextSecondary),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(height: 1, color: _cBorder),
        ),
        const SizedBox(height: 8),
        _BreakdownRow(
          label: 'Enterprise',
          orgCount: 8,
          monthly: 'TZS 6,000,000',
          color: _cAmber,
          share: 0.72,
        ),
        _BreakdownRow(
          label: 'Professional',
          orgCount: 21,
          monthly: 'TZS 1,575,000',
          color: _cPrimary,
          share: 0.19,
        ),
        _BreakdownRow(
          label: 'Starter',
          orgCount: 18,
          monthly: 'TZS 450,000',
          color: _cInfo,
          share: 0.054,
        ),
        _BreakdownRow(
          label: 'Transaction Fees',
          orgCount: null,
          monthly: 'TZS 95,000',
          color: _cSuccess,
          share: 0.011,
        ),
        const SizedBox(width: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: _cPrimary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Feb Revenue',
                    style: text.labelSmall?.copyWith(
                      color: _cPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'TZS 12,420,000',
                    style: text.titleSmall?.copyWith(
                      color: _cPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int? orgCount;
  final String monthly;
  final Color color;
  final double share;

  const _BreakdownRow({
    required this.label,
    required this.orgCount,
    required this.monthly,
    required this.color,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    color: _cTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (orgCount != null)
                Text(
                  '$orgCount orgs  ·  ',
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 10,
                  ),
                ),
              Text(
                monthly,
                style: text.labelSmall?.copyWith(
                  color: _cTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: share,
                    backgroundColor: _cBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(share * 100).toStringAsFixed(1)}%',
                style: text.labelSmall?.copyWith(
                  color: _cTextSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
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
// SUBSCRIPTIONS TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _SubscriptionsTable extends StatelessWidget {
  const _SubscriptionsTable();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Organization Subscriptions',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_subscriptions.length} organizations  ·  sorted by renewal date',
                      style: text.bodySmall?.copyWith(color: _cTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Filter chips
                _FilterChip(label: 'All', active: true),
                const SizedBox(width: 6),
                _FilterChip(label: 'Active'),
                const SizedBox(width: 6),
                _FilterChip(label: 'Past Due'),
                const SizedBox(width: 6),
                _FilterChip(label: 'Trialing'),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search organization…',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: _cTextSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: _cTextSecondary,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 12,
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
                        borderSide: const BorderSide(
                          color: _cPrimary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: const BoxDecoration(
              color: _cTableHeader,
              border: Border(
                top: BorderSide(color: _cBorder),
                bottom: BorderSide(color: _cBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: _ColHeader('ORGANIZATION')),
                Expanded(flex: 2, child: _ColHeader('PLAN')),
                Expanded(flex: 2, child: _ColHeader('STATUS')),
                Expanded(flex: 2, child: _ColHeader('BILLING')),
                Expanded(flex: 2, child: _ColHeader('AMOUNT')),
                Expanded(flex: 2, child: _ColHeader('PERIOD')),
                Expanded(flex: 2, child: _ColHeader('RENEWS / EXPIRES')),
                const SizedBox(width: 100),
              ],
            ),
          ),
          // Rows
          ..._subscriptions.asMap().entries.map(
            (e) => _SubTableRow(row: e.value, isEven: e.key.isEven),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  const _ColHeader(this.label, {super.key});

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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _cPrimaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? _cPrimary.withOpacity(0.4) : _cBorder,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: active ? _cPrimary : _cTextSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SubTableRow extends StatelessWidget {
  final _SubRow row;
  final bool isEven;
  const _SubTableRow({required this.row, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: row.isOverdue
            ? _cErrorLight.withOpacity(0.4)
            : isEven
            ? Colors.white
            : const Color(0xFFFAFBFC),
        border: const Border(bottom: BorderSide(color: _cBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Org name + types
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: row.isOverdue ? _cErrorLight : _cPrimaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      row.orgName.substring(0, 1),
                      style: text.labelMedium?.copyWith(
                        color: row.isOverdue ? _cError : _cPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.orgName,
                        style: text.bodySmall?.copyWith(
                          color: _cTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 4,
                        children: row.orgTypes
                            .map((t) => _MiniTypeChip(type: t))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Plan
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: row.planColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  row.plan,
                  style: text.bodySmall?.copyWith(
                    color: _cTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Status
          Expanded(flex: 2, child: _SubStatusChip(status: row.status)),
          // Billing cycle
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  row.billingCycle == 'annual'
                      ? Icons.autorenew_rounded
                      : Icons.calendar_month_rounded,
                  size: 13,
                  color: _cTextSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  row.billingCycle == 'annual' ? 'Annual' : 'Monthly',
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                ),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              row.amount,
              style: text.bodySmall?.copyWith(
                color: _cTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Period
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.periodStart,
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '→  ${row.periodEnd}',
                  style: text.labelSmall?.copyWith(
                    color: _cTextSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Renews in
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: row.isOverdue
                    ? _cErrorLight
                    : row.renewsIn.contains('1 day')
                    ? _cWarningLight
                    : _cSurface,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                row.renewsIn,
                style: text.labelSmall?.copyWith(
                  color: row.isOverdue
                      ? _cError
                      : row.renewsIn.contains('1 day')
                      ? _cWarning
                      : _cTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (row.status == 'past_due')
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _cError,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Resolve'),
                  )
                else if (row.status == 'trialing')
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _cInfo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Convert'),
                  )
                else if (row.status == 'cancelled')
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _cSuccess,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Reactivate'),
                  )
                else
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _cPrimaryMid,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Manage'),
                  ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 16),
                  onPressed: () {},
                  color: _cTextSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubStatusChip extends StatelessWidget {
  final String status;
  const _SubStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg, icon) = switch (status) {
      'active' => (
        'Active',
        _cSuccess,
        _cSuccessLight,
        Icons.check_circle_rounded,
      ),
      'trialing' => (
        'Trialing',
        _cInfo,
        _cInfoLight,
        Icons.hourglass_top_rounded,
      ),
      'past_due' => ('Past Due', _cError, _cErrorLight, Icons.error_rounded),
      'cancelled' => (
        'Cancelled',
        _cTextSecondary,
        _cSurface,
        Icons.cancel_rounded,
      ),
      _ => (status, _cTextSecondary, _cSurface, Icons.circle_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
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

class _MiniTypeChip extends StatelessWidget {
  final String type;
  const _MiniTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (type) {
      'distributor' => (_cPrimary, _cPrimaryLight),
      'pharmacy' => (_cAccent, _cAccentLight),
      'supplier' => (_cSuccess, _cSuccessLight),
      _ => (_cTextSecondary, _cSurface),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT TRANSACTIONS TABLE
// ─────────────────────────────────────────────────────────────────────────────

class _RecentTransactionsTable extends StatelessWidget {
  const _RecentTransactionsTable();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Billing Transactions',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last 30 days — subscription payments',
                      style: text.bodySmall?.copyWith(color: _cTextSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View All Transactions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cTextPrimary,
                    side: const BorderSide(color: _cBorder),
                    textStyle: const TextStyle(fontSize: 13),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: const BoxDecoration(
              color: _cTableHeader,
              border: Border(
                top: BorderSide(color: _cBorder),
                bottom: BorderSide(color: _cBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _ColHeader('INVOICE REF')),
                Expanded(flex: 4, child: _ColHeader('ORGANIZATION')),
                Expanded(flex: 2, child: _ColHeader('PLAN')),
                Expanded(flex: 2, child: _ColHeader('AMOUNT')),
                Expanded(flex: 2, child: _ColHeader('METHOD')),
                Expanded(flex: 2, child: _ColHeader('DATE')),
                Expanded(flex: 2, child: _ColHeader('STATUS')),
                const SizedBox(width: 60),
              ],
            ),
          ),
          ..._transactions.asMap().entries.map(
            (e) => _TxnTableRow(row: e.value, isEven: e.key.isEven),
          ),
        ],
      ),
    );
  }
}

class _TxnTableRow extends StatelessWidget {
  final _TxnRow row;
  final bool isEven;
  const _TxnTableRow({required this.row, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isPaid = row.status == 'paid';
    final isFailed = row.status == 'failed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        color: isFailed
            ? _cErrorLight.withOpacity(0.3)
            : isEven
            ? Colors.white
            : const Color(0xFFFAFBFC),
        border: const Border(bottom: BorderSide(color: _cBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Invoice ref
          Expanded(
            flex: 2,
            child: Text(
              row.ref,
              style: text.bodySmall?.copyWith(
                color: _cPrimaryMid,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          // Org name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _cPrimaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      row.org.substring(0, 1),
                      style: text.labelSmall?.copyWith(
                        color: _cPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.org,
                    style: text.bodySmall?.copyWith(
                      color: _cTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Plan
          Expanded(
            flex: 2,
            child: Text(
              row.plan,
              style: text.bodySmall?.copyWith(color: _cTextSecondary),
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              row.amount,
              style: text.bodySmall?.copyWith(
                color: _cTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Method
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(_methodIcon(row.method), size: 13, color: _cTextSecondary),
                const SizedBox(width: 5),
                Text(
                  row.method,
                  style: text.bodySmall?.copyWith(color: _cTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              row.date,
              style: text.bodySmall?.copyWith(color: _cTextSecondary),
            ),
          ),
          // Status
          Expanded(flex: 2, child: _TxnStatusChip(status: row.status)),
          // Action
          SizedBox(
            width: 60,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _cPrimaryMid,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  }

  IconData _methodIcon(String method) => switch (method) {
    'M-Pesa' => Icons.phone_android_rounded,
    'Airtel Money' => Icons.phone_android_rounded,
    'Bank Transfer' => Icons.account_balance_rounded,
    'Cash' => Icons.payments_rounded,
    _ => Icons.payment_rounded,
  };
}

class _TxnStatusChip extends StatelessWidget {
  final String status;
  const _TxnStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg, icon) = switch (status) {
      'paid' => ('Paid', _cSuccess, _cSuccessLight, Icons.check_circle_rounded),
      'failed' => ('Failed', _cError, _cErrorLight, Icons.cancel_rounded),
      'pending' => (
        'Pending',
        _cWarning,
        _cWarningLight,
        Icons.hourglass_top_rounded,
      ),
      'refunded' => ('Refunded', _cInfo, _cInfoLight, Icons.undo_rounded),
      _ => (status, _cTextSecondary, _cSurface, Icons.circle_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 5),
          Text(
            label,
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
