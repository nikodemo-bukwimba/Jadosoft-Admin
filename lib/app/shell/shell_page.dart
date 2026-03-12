// shell_page_home_tab.dart
// ─────────────────────────────────────────────────────────────
// Admin command centre — the authenticated landing page.
//
// Displays all system modules organized by functional group.
// Each card navigates to its feature's list/dashboard page.
// Integration monitoring pages are accessible from here even
// though they don't have dedicated sidebar nav entries.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/string_extensions.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../routes/app_router.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        return _HomeContent(auth: state);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Main scrollable content
// ─────────────────────────────────────────────────────────────

class _HomeContent extends StatelessWidget {
  final AuthAuthenticated auth;
  const _HomeContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────
          SliverToBoxAdapter(child: _GreetingHeader(auth: auth)),

          // ── Feature sections ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _FeatureSection(
                  title: 'Field Operations',
                  subtitle: 'Officers, customers, visits & reporting',
                  accentColor: scheme.primary,
                  items: [
                    _FeatureItem(icon: Icons.badge_outlined,              label: 'Officers',      path: AppRouter.officerList,    accent: const Color(0xFF2196F3)),
                    _FeatureItem(icon: Icons.store_outlined,              label: 'Customers',     path: AppRouter.customerList,   accent: const Color(0xFF4CAF50)),
                    _FeatureItem(icon: Icons.place_outlined,              label: 'Visits',        path: AppRouter.visitList,      accent: const Color(0xFFFF9800)),
                    _FeatureItem(icon: Icons.calendar_month_outlined,     label: 'Weekly Plans',  path: AppRouter.weeklyPlanList, accent: const Color(0xFF9C27B0)),
                    _FeatureItem(icon: Icons.summarize_outlined,          label: 'Daily Reports', path: AppRouter.dailyReportList,accent: const Color(0xFF00BCD4)),
                  ],
                ),

                const SizedBox(height: 28),

                _FeatureSection(
                  title: 'Products & Commerce',
                  subtitle: 'Catalog, promotions, orders & payments',
                  accentColor: const Color(0xFFFF9800),
                  items: [
                    _FeatureItem(icon: Icons.category_outlined,           label: 'Categories',  path: AppRouter.categoryList,  accent: const Color(0xFF607D8B)),
                    _FeatureItem(icon: Icons.inventory_2_outlined,        label: 'Products',    path: AppRouter.productList,   accent: const Color(0xFF3F51B5)),
                    _FeatureItem(icon: Icons.campaign_outlined,           label: 'Promotions',  path: AppRouter.promotionList, accent: const Color(0xFFE91E63)),
                    _FeatureItem(icon: Icons.receipt_long_outlined,       label: 'Orders',      path: AppRouter.orderList,     accent: const Color(0xFF009688)),
                    _FeatureItem(icon: Icons.payments_outlined,           label: 'Payments',    path: AppRouter.paymentList,   accent: const Color(0xFF4CAF50)),
                  ],
                ),

                const SizedBox(height: 28),

                _FeatureSection(
                  title: 'Communication',
                  subtitle: 'Messages & notification centre',
                  accentColor: const Color(0xFF9C27B0),
                  items: [
                    _FeatureItem(icon: Icons.forum_outlined,              label: 'Messages',      path: AppRouter.conversationList, accent: const Color(0xFF2196F3)),
                    _FeatureItem(icon: Icons.notifications_outlined,      label: 'Notifications', path: AppRouter.notificationList, accent: const Color(0xFFFF5722)),
                  ],
                ),

                const SizedBox(height: 28),

                _FeatureSection(
                  title: 'Analytics & Reports',
                  subtitle: 'Dashboards, exports & audit trail',
                  accentColor: const Color(0xFF4CAF50),
                  items: [
                    _FeatureItem(icon: Icons.insights_outlined,           label: 'Marketing',     path: AppRouter.marketingDashboard, accent: const Color(0xFF2196F3)),
                    _FeatureItem(icon: Icons.trending_up_outlined,        label: 'Sales',         path: AppRouter.salesDashboard,     accent: const Color(0xFF4CAF50)),
                    _FeatureItem(icon: Icons.file_download_outlined,      label: 'Export',        path: AppRouter.reportExport,       accent: const Color(0xFF607D8B)),
                    _FeatureItem(icon: Icons.history_outlined,            label: 'Activity Logs', path: AppRouter.activityLogList,    accent: const Color(0xFF795548)),
                  ],
                ),

                const SizedBox(height: 28),

                _FeatureSection(
                  title: 'Integrations',
                  subtitle: 'SMS, WhatsApp & mobile money status',
                  accentColor: const Color(0xFF607D8B),
                  items: [
                    _FeatureItem(icon: Icons.sms_outlined,                label: 'SMS Gateway',   path: AppRouter.smsGateway,  accent: const Color(0xFF009688)),
                    _FeatureItem(icon: Icons.chat_outlined,               label: 'WhatsApp',      path: AppRouter.whatsapp,    accent: const Color(0xFF4CAF50)),
                    _FeatureItem(icon: Icons.phone_android_outlined,      label: 'Mobile Money',  path: AppRouter.mobileMoney, accent: const Color(0xFFFF9800)),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Greeting header
// ─────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final AuthAuthenticated auth;
  const _GreetingHeader({required this.auth});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = auth.activeSession.user;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                user.displayName.initials,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // ── Text block ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: textTheme.bodyLarge?.copyWith(
                    color: scheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.displayName.split(' ').first,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                if (user.primaryRole != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.primaryRole!.name,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Pharmacy brand mark ─────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_pharmacy_outlined,
              color: scheme.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature section — title + grid of cards
// ─────────────────────────────────────────────────────────────

class _FeatureSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<_FeatureItem> items;

  const _FeatureSection({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Card grid ──────────────────────────────────────────
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Responsive columns: 2 on small, 3 on medium, 4+ on wide
            final crossAxisCount = width < 400 ? 2 : width < 700 ? 3 : 4;
            final childAspectRatio = width < 400 ? 1.15 : 1.2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items
                  .map((item) => _FeatureCard(item: item))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual feature card
// ─────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.path),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon container ────────────────────────────
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.accent,
                    size: 24,
                  ),
                ),

                const SizedBox(height: 10),

                // ── Label ─────────────────────────────────────
                Text(
                  item.label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Data model for a feature card
// ─────────────────────────────────────────────────────────────

class _FeatureItem {
  final IconData icon;
  final String label;
  final String path;
  final Color accent;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.accent,
  });
}