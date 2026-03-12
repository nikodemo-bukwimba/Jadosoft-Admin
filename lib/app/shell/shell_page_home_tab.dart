// shell_page_home_tab.dart
// ─────────────────────────────────────────────────────────────
// Admin command centre — authenticated landing page.
// Responsive: mobile (bottom nav) + desktop (side rail).
// AdaptiveNavShell owns the Scaffold & SafeArea — no nesting here.
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

class _HomeContent extends StatelessWidget {
  final AuthAuthenticated auth;
  const _HomeContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 840;

    if (isWide) {
      return Row(
        children: [
          SizedBox(width: 280, child: _SidePanel(auth: auth)),
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(child: _FeatureGrid(auth: auth)),
        ],
      );
    }

    return _FeatureGrid(auth: auth);
  }
}

// ─────────────────────────────────────────────────────────────
// Desktop: left panel with greeting + quick stats
// ─────────────────────────────────────────────────────────────

class _SidePanel extends StatelessWidget {
  final AuthAuthenticated auth;
  const _SidePanel({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = auth.activeSession.user;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                (user.displayName as String).initials,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$greeting,',
            style: textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
           (user.displayName as String).split(' ').first,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (user.primaryRole != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.primaryRole!.name,
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Pharmacy brand
          Row(
            children: [
              Icon(
                Icons.local_pharmacy_outlined,
                color: scheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Barick Pharmacy',
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Main scrollable feature grid (mobile + desktop right panel)
// ─────────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  final AuthAuthenticated auth;
  const _FeatureGrid({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = auth.activeSession.user;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 840;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return CustomScrollView(
      slivers: [
        // ── Greeting header (mobile only — desktop uses side panel) ──
        if (!isWide)
          SliverToBoxAdapter(
            child: _GreetingHeader(
              greeting: greeting,
              user: user,
              scheme: scheme,
              textTheme: textTheme,
            ),
          ),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            isWide ? 24 : 16,
            8,
            isWide ? 24 : 16,
            32,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _FeatureSection(
                title: 'Field Operations',
                subtitle: 'Officers, customers, visits & reporting',
                accentColor: scheme.primary,
                items: const [
                  _FeatureItem(
                    icon: Icons.badge_outlined,
                    label: 'Officers',
                    path: AppRouter.officerList,
                    accent: Color(0xFF2196F3),
                  ),
                  _FeatureItem(
                    icon: Icons.store_outlined,
                    label: 'Customers',
                    path: AppRouter.customerList,
                    accent: Color(0xFF4CAF50),
                  ),
                  _FeatureItem(
                    icon: Icons.place_outlined,
                    label: 'Visits',
                    path: AppRouter.visitList,
                    accent: Color(0xFFFF9800),
                  ),
                  _FeatureItem(
                    icon: Icons.calendar_month_outlined,
                    label: 'Weekly Plans',
                    path: AppRouter.weeklyPlanList,
                    accent: Color(0xFF9C27B0),
                  ),
                  _FeatureItem(
                    icon: Icons.summarize_outlined,
                    label: 'Daily Reports',
                    path: AppRouter.dailyReportList,
                    accent: Color(0xFF00BCD4),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _FeatureSection(
                title: 'Products & Commerce',
                subtitle: 'Catalog, promotions, orders & payments',
                accentColor: const Color(0xFFFF9800),
                items: const [
                  _FeatureItem(
                    icon: Icons.category_outlined,
                    label: 'Categories',
                    path: AppRouter.categoryList,
                    accent: Color(0xFF607D8B),
                  ),
                  _FeatureItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    path: AppRouter.productList,
                    accent: Color(0xFF3F51B5),
                  ),
                  _FeatureItem(
                    icon: Icons.campaign_outlined,
                    label: 'Promotions',
                    path: AppRouter.promotionList,
                    accent: Color(0xFFE91E63),
                  ),
                  _FeatureItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    path: AppRouter.orderList,
                    accent: Color(0xFF009688),
                  ),
                  _FeatureItem(
                    icon: Icons.payments_outlined,
                    label: 'Payments',
                    path: AppRouter.paymentList,
                    accent: Color(0xFF4CAF50),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _FeatureSection(
                title: 'Communication',
                subtitle: 'Messages & notification centre',
                accentColor: const Color(0xFF9C27B0),
                items: const [
                  _FeatureItem(
                    icon: Icons.forum_outlined,
                    label: 'Messages',
                    path: AppRouter.conversationList,
                    accent: Color(0xFF2196F3),
                  ),
                  _FeatureItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    path: AppRouter.notificationList,
                    accent: Color(0xFFFF5722),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _FeatureSection(
                title: 'Analytics & Reports',
                subtitle: 'Dashboards, exports & audit trail',
                accentColor: const Color(0xFF4CAF50),
                items: const [
                  _FeatureItem(
                    icon: Icons.insights_outlined,
                    label: 'Marketing',
                    path: AppRouter.marketingDashboard,
                    accent: Color(0xFF2196F3),
                  ),
                  _FeatureItem(
                    icon: Icons.trending_up_outlined,
                    label: 'Sales',
                    path: AppRouter.salesDashboard,
                    accent: Color(0xFF4CAF50),
                  ),
                  _FeatureItem(
                    icon: Icons.file_download_outlined,
                    label: 'Export',
                    path: AppRouter.reportExport,
                    accent: Color(0xFF607D8B),
                  ),
                  _FeatureItem(
                    icon: Icons.history_outlined,
                    label: 'Activity Logs',
                    path: AppRouter.activityLogList,
                    accent: Color(0xFF795548),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _FeatureSection(
                title: 'Integrations',
                subtitle: 'SMS, WhatsApp & mobile money status',
                accentColor: const Color(0xFF607D8B),
                items: const [
                  _FeatureItem(
                    icon: Icons.sms_outlined,
                    label: 'SMS Gateway',
                    path: AppRouter.smsGateway,
                    accent: Color(0xFF009688),
                  ),
                  _FeatureItem(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    path: AppRouter.whatsapp,
                    accent: Color(0xFF4CAF50),
                  ),
                  _FeatureItem(
                    icon: Icons.phone_android_outlined,
                    label: 'Mobile Money',
                    path: AppRouter.mobileMoney,
                    accent: Color(0xFFFF9800),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mobile greeting header
// ─────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final dynamic user;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _GreetingHeader({
    required this.greeting,
    required this.user,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withOpacity(0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                (user.displayName as String).initials,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
                Text(
                  (user.displayName as String).split(' ').first,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                if (user.primaryRole != null)
                  Text(
                    user.primaryRole!.name,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.local_pharmacy_outlined, color: scheme.primary, size: 22),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature section
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
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
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
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w < 360
                ? 2
                : w < 600
                ? 3
                : w < 900
                ? 4
                : 5;
            return GridView.count(
              crossAxisCount: cols,
              childAspectRatio: 1.1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: items.map((i) => _FeatureCard(item: i)).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature card
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
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.accent, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  style: textTheme.labelSmall?.copyWith(
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
// Data model
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
