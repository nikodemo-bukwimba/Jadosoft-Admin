import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'adaptive_nav_shell.dart';
import 'nav_item.dart';
import 'nav_rail_theme.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

late final GoRouter _router;

GoRouter _buildRouter() => GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => AdaptiveNavShell(
            router: _router,
            breakpoint: 768,               // ← your custom breakpoint
            items: _navItems,
            logo: const _AppLogo(),
            appBarActions: const [
              _NotificationBell(),
              _UserAvatar(),
            ],
            appBarCenterWidget: const _SearchBar(),
            railHeader: const _ProfileCard(),
            railFooter: const _RailFooter(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const _PageShell(title: 'Dashboard'),
            ),
            GoRoute(
              path: '/analytics',
              builder: (_, __) => const _PageShell(title: 'Analytics'),
            ),
            GoRoute(
              path: '/analytics/reports',
              builder: (_, __) => const _PageShell(title: 'Reports'),
            ),
            GoRoute(
              path: '/analytics/realtime',
              builder: (_, __) => const _PageShell(title: 'Real-time'),
            ),
            GoRoute(
              path: '/products',
              builder: (_, __) => const _PageShell(title: 'All Products'),
            ),
            GoRoute(
              path: '/products/new',
              builder: (_, __) => const _PageShell(title: 'New Arrivals'),
            ),
            GoRoute(
              path: '/products/categories',
              builder: (_, __) => const _PageShell(title: 'Categories'),
            ),
            GoRoute(
              path: '/products/categories/featured',
              builder: (_, __) => const _PageShell(title: 'Featured'),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const _PageShell(title: 'Settings'),
            ),
          ],
        ),
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Nav items — demonstrates all features: nesting, buttons, badges, deep paths
// ─────────────────────────────────────────────────────────────────────────────

final _navItems = [
  const NavItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/dashboard',
  ),

  // Parent with flyout sub-menu (2 levels)
  NavItem(
    id: 'analytics',
    label: 'Analytics',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    children: [
      const NavItem(
        id: 'analytics_reports',
        label: 'Reports',
        icon: Icons.description_outlined,
        path: '/analytics/reports',
      ),
      const NavItem(
        id: 'analytics_realtime',
        label: 'Real-time',
        icon: Icons.bolt_outlined,
        path: '/analytics/realtime',
        badge: _Badge(label: 'Live'),
      ),
    ],
  ),

  // Deep nesting — 3 levels
  NavItem(
    id: 'products',
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    children: [
      const NavItem(
        id: 'products_all',
        label: 'All Products',
        icon: Icons.list_alt_outlined,
        path: '/products',
      ),
      const NavItem(
        id: 'products_new',
        label: 'New Arrivals',
        icon: Icons.new_releases_outlined,
        path: '/products/new',
      ),
      NavItem(
        id: 'products_categories',
        label: 'Categories',
        icon: Icons.category_outlined,
        // No path — this parent only shows a sub-flyout
        children: [
          const NavItem(
            id: 'categories_featured',
            label: 'Featured',
            icon: Icons.star_outline,
            path: '/products/categories/featured',
          ),
          const NavItem(
            id: 'categories_all',
            label: 'All Categories',
            icon: Icons.grid_view_outlined,
            path: '/products/categories',
          ),
        ],
      ),
    ],
  ),

  const NavItem(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
  ),

  // Button-style item — CTA, fires callback, never selected
  NavItem(
    id: 'upgrade',
    label: 'Upgrade to Pro',
    icon: Icons.workspace_premium,
    isButton: true,
    onTap: () => debugPrint('Upgrade tapped!'),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// App entry point
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  _router = _buildRouter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Adaptive Nav Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        // ── Optional: override any rail token globally ──
        extensions: const [
          NavRailThemeData(
            railWidth: 240,
            flyoutElevation: 4,
          ),
        ],
      ),
      routerConfig: _router,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Example supporting widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlutterLogo(size: 28),
          const SizedBox(width: 8),
          Text('MyApp',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      );
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();
  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            'A',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold),
          ),
        ),
      );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
      );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text('A',
                style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alex Johnson',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text('Admin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailFooter extends StatelessWidget {
  const _RailFooter();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'v2.4.0',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: cs.onErrorContainer, fontSize: 10)),
    );
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      );
}
