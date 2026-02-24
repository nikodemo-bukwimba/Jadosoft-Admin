import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../customnav/navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class Product {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

class SettingSection {
  const SettingSection({
    required this.key,
    required this.title,
    required this.description,
  });
  final String key;
  final String title;
  final String description;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock data
// ─────────────────────────────────────────────────────────────────────────────

const _products = [
  Product(id: 'p1', name: 'Wireless Headphones', price: 79.99),
  Product(id: 'p2', name: 'Mechanical Keyboard', price: 129.00),
  Product(id: 'p3', name: 'USB-C Hub', price: 49.95),
];

const _settingSections = [
  SettingSection(
    key: 'profile',
    title: 'Profile',
    description: 'Name, avatar, email',
  ),
  SettingSection(
    key: 'notifications',
    title: 'Notifications',
    description: 'Push, email, in-app',
  ),
  SettingSection(
    key: 'security',
    title: 'Security',
    description: 'Password, 2FA, sessions',
  ),
  SettingSection(
    key: 'billing',
    title: 'Billing',
    description: 'Plan, invoices, payment',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────────────────────

late final GoRouter _router;

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/dashboard',
  observers: [_NavLogger()],
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdaptiveNavShell(
        router: _router,
        breakpoint: 768,
        items: _navItems,
        logo: const _AppLogo(),
        appBarActions: const [_NotificationBell(), _UserAvatar()],
        // Shell-level default center — pages can override this via NavPageConfig
        appBarCenterWidget: const _SearchBar(),
        // FEATURE 3: Full header shown when rail is expanded
        railHeader: const _ProfileCard(),
        // FEATURE 3: Compact header shown when rail collapses to icons-only
        railHeaderCollapsed: const _CompactAvatar(),
        railFooter: const _RailFooter(),
        child: child,
      ),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
        GoRoute(
          path: '/analytics',
          builder: (_, __) => const _PlaceholderPage(title: 'Analytics'),
        ),
        GoRoute(
          path: '/analytics/reports',
          builder: (_, state) {
            final period = state.uri.queryParameters['period'] ?? 'weekly';
            return _PlaceholderPage(title: 'Reports ($period)');
          },
        ),
        GoRoute(
          path: '/analytics/realtime',
          builder: (_, __) => const _PlaceholderPage(title: 'Real-time'),
        ),
        GoRoute(path: '/products', builder: (_, __) => const ProductListPage()),
        GoRoute(
          path: '/products/new',
          builder: (_, __) => const _PlaceholderPage(title: 'New Arrivals'),
        ),
        GoRoute(
          path: '/products/categories',
          builder: (_, __) => const _PlaceholderPage(title: 'Categories'),
        ),
        GoRoute(
          path: '/products/categories/featured',
          builder: (_, __) => const _PlaceholderPage(title: 'Featured'),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) => ProductDetailPage(
            productId: state.pathParameters['id']!,
            product: state.extra as Product?,
          ),
        ),
        GoRoute(
          path: '/products/:id/reviews',
          builder: (_, state) => ProductReviewsPage(
            productId: state.pathParameters['id']!,
            sort: state.uri.queryParameters['sort'] ?? 'recent',
            product: state.extra as Product?,
          ),
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        GoRoute(
          path: '/settings/:section',
          builder: (_, state) => SettingsSectionPage(
            sectionKey: state.pathParameters['section']!,
            section: state.extra as SettingSection?,
          ),
        ),
        GoRoute(
          path: '/settings/:section/edit',
          builder: (_, state) => SettingsSectionEditPage(
            sectionKey: state.pathParameters['section']!,
            section: state.extra as SettingSection?,
          ),
        ),
      ],
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Nav items
// ─────────────────────────────────────────────────────────────────────────────

final _navItems = [
  const NavItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/dashboard',
  ),
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
      ),
    ],
  ),
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
      const NavItem(id: 'product_detail', label: '', path: '/products/:id'),
      const NavItem(
        id: 'product_reviews',
        label: '',
        path: '/products/:id/reviews',
      ),
    ],
  ),
  NavItem(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
    children: [
      const NavItem(
        id: 'settings_section',
        label: '',
        path: '/settings/:section',
      ),
      const NavItem(
        id: 'settings_section_edit',
        label: '',
        path: '/settings/:section/edit',
      ),
    ],
  ),
  NavItem(
    id: 'upgrade',
    label: 'Upgrade to Pro',
    icon: Icons.workspace_premium,
    isButton: true,
    onTap: () => debugPrint('Upgrade tapped!'),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// App
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  _router = _buildRouter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Adaptive Nav Demo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      extensions: const [NavRailThemeData(railWidth: 240, flyoutElevation: 4)],
    ),
    routerConfig: _router,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // FEATURE 4: NavPageConfig replaces the shell's default AppBar center+actions
    // for the lifetime of this page. Dispose automatically clears it.
    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.dashboard,
        label: 'Dashboard',
        color: Theme.of(context).colorScheme.primary,
      ),
      actions: const [
        _NotificationBell(),
        _UserAvatar(),
        _DashboardMenuButton(),
      ],
      child: _PageWrapper(
        title: 'Dashboard',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Feature callout cards ──────────────────────────────────────
            _FeatureCallout(
              icon: Icons.mouse_outlined,
              color: Colors.blue,
              title: 'Fix 1 — Hover debounce (desktop)',
              body:
                  'On a mouse-driven device, hover over "Analytics" or "Products" '
                  'in the side rail, then slowly move into the flyout panel. '
                  'The panel stays open because a 200 ms debounce timer is cancelled '
                  'the moment your cursor enters the flyout — no more accidental closes.',
            ),
            _FeatureCallout(
              icon: Icons.phone_android_outlined,
              color: Colors.green,
              title: 'Fix 2 — Accordion in drawer (mobile)',
              body:
                  'Resize the window below 768 px (or use a phone). '
                  'Tap the ☰ menu, then tap "Analytics" or "Products". '
                  'Children expand inline as an accordion — no off-screen '
                  'overlay, no clipping. The chevron rotates to show state.',
            ),
            _FeatureCallout(
              icon: Icons.view_sidebar_outlined,
              color: Colors.orange,
              title: 'Fix 3 — Collapsed header (desktop)',
              body:
                  'Click the ⊞ toggle button at the top of the side rail '
                  'to cycle through icons+labels → icons-only → labels-only. '
                  'When icons-only, the profile card is replaced by a compact '
                  'avatar that fits the narrow rail — no overflow.',
            ),
            _FeatureCallout(
              icon: Icons.tune_outlined,
              color: Colors.purple,
              title: 'Feature 4 — Screen-level AppBar (NavPageConfig)',
              body:
                  'Every page in this demo wraps its content with NavPageConfig. '
                  'Notice the AppBar title and action buttons change as you navigate. '
                  'Dashboard shows a coloured icon title + extra menu button. '
                  'Product List gets a filter button. Detail pages get share + bookmark. '
                  'Settings gets a help button. All revert automatically on dispose.',
            ),
            const SizedBox(height: 8),
            const _SectionHeader(
              'Navigate — watch the AppBar update on each page',
            ),
            const SizedBox(height: 12),
            _NavTestCard(
              label: '① Settings',
              description: "context.go('/settings')",
              color: Colors.blue,
              onTap: () => context.go('/settings'),
            ),
            _NavTestCard(
              label: '② Reports (monthly query param)',
              description: "context.go('/analytics/reports?period=monthly')",
              color: Colors.teal,
              onTap: () => context.go('/analytics/reports?period=monthly'),
            ),
            _NavTestCard(
              label: '③ Product detail + extra object',
              description: "context.go('/products/p1', extra: product)",
              color: Colors.orange,
              onTap: () => context.go(
                '/products/p1',
                extra: const Product(
                  id: 'p1',
                  name: 'Wireless Headphones',
                  price: 79.99,
                ),
              ),
            ),
            _NavTestCard(
              label: '④ Product reviews (4 levels deep)',
              description:
                  "context.go('/products/p2/reviews?sort=rating', extra: product)",
              color: Colors.purple,
              onTap: () => context.go(
                '/products/p2/reviews?sort=rating',
                extra: const Product(
                  id: 'p2',
                  name: 'Mechanical Keyboard',
                  price: 129.00,
                ),
              ),
            ),
            _NavTestCard(
              label: '⑤ Settings › Security section',
              description: "context.go('/settings/security', extra: section)",
              color: Colors.red,
              onTap: () => context.go(
                '/settings/security',
                extra: const SettingSection(
                  key: 'security',
                  title: 'Security',
                  description: 'Password, 2FA, sessions',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Product list — NavPageConfig with filter action
// ─────────────────────────────────────────────────────────────────────────────

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.inventory_2,
        label: 'All Products',
        color: Colors.indigo,
      ),
      // FEATURE 4: filter button replaces the default shell actions for this page
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filter products',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Filter tapped — injected by ProductListPage'),
            ),
          ),
        ),
        const _UserAvatar(),
      ],
      child: _PageWrapper(
        title: 'All Products',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              'Tap a product — passes the full object via extra',
            ),
            const SizedBox(height: 12),
            ..._products.map(
              (p) => _NavTestCard(
                label: p.name,
                description:
                    '\$${p.price.toStringAsFixed(2)}  •  /products/${p.id}',
                color: Colors.indigo,
                onTap: () => context.go('/products/${p.id}', extra: p),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Product detail — NavPageConfig with share + bookmark actions
// ─────────────────────────────────────────────────────────────────────────────

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId, this.product});
  final String productId;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final name = product?.name ?? 'Product $productId';
    final price = product?.price ?? 0.0;

    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.inventory_2,
        label: name,
        color: Colors.orange,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border_rounded),
          tooltip: 'Bookmark',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Bookmarked "$name" — action from ProductDetailPage',
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share tapped — action from ProductDetailPage'),
            ),
          ),
        ),
        const _UserAvatar(),
      ],
      child: _PageWrapper(
        title: name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DataRow('Route', '/products/$productId'),
            _DataRow(
              'Source',
              product != null
                  ? '✅ extra (no refetch needed)'
                  : '⚠️ URL only — would need a fetch',
            ),
            _DataRow('ID', productId),
            _DataRow('Name', name),
            _DataRow('Price', '\$${price.toStringAsFixed(2)}'),
            const SizedBox(height: 24),
            const _SectionHeader('Go deeper from here'),
            const SizedBox(height: 12),
            _NavTestCard(
              label: 'View Reviews (sort: recent)',
              description: '/products/$productId/reviews?sort=recent',
              color: Colors.green,
              onTap: () => context.go(
                '/products/$productId/reviews?sort=recent',
                extra: product,
              ),
            ),
            _NavTestCard(
              label: 'View Reviews (sort: rating)',
              description: 'Same page, different query param',
              color: Colors.green.shade800,
              onTap: () => context.go(
                '/products/$productId/reviews?sort=rating',
                extra: product,
              ),
            ),
            _NavTestCard(
              label: '→ Jump to Settings',
              description: 'Back button traces full history across the jump',
              color: Colors.grey,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Product reviews
// ─────────────────────────────────────────────────────────────────────────────

class ProductReviewsPage extends StatelessWidget {
  const ProductReviewsPage({
    super.key,
    required this.productId,
    required this.sort,
    this.product,
  });
  final String productId;
  final String sort;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final name = product?.name ?? productId;

    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.star_rounded,
        label: '$name — Reviews',
        color: Colors.amber.shade700,
      ),
      actions: [
        Chip(
          avatar: const Icon(Icons.sort, size: 14),
          label: Text('sort: $sort', style: const TextStyle(fontSize: 12)),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(width: 4),
        const _UserAvatar(),
      ],
      child: _PageWrapper(
        title: '$name — Reviews',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DataRow('Full URL', '/products/$productId/reviews?sort=$sort'),
            _DataRow('Path param', 'id = $productId'),
            _DataRow('Query param', 'sort = $sort'),
            _DataRow(
              'extra',
              product != null ? '✅ ${product!.name}' : '⚠️ null (deep-linked)',
            ),
            const SizedBox(height: 16),
            const _SectionHeader('📍 4 levels deep'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Dashboard  →  Product List  →  Product Detail  →  Reviews\n'
                'Each press of the AppBar back button retraces one step.',
                style: TextStyle(height: 1.6),
              ),
            ),
            _NavTestCard(
              label: "Switch sort → 'helpful'",
              description:
                  'context.go() to same path with different query param',
              color: Colors.teal,
              onTap: () => context.go(
                '/products/$productId/reviews?sort=helpful',
                extra: product,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Settings — NavPageConfig with help action
// ─────────────────────────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.settings,
        label: 'Settings',
        color: Colors.grey.shade700,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          tooltip: 'Help',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Help tapped — injected by SettingsPage'),
            ),
          ),
        ),
        const _UserAvatar(),
      ],
      child: _PageWrapper(
        title: 'Settings',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              'Each section passes a SettingSection object via extra',
            ),
            const SizedBox(height: 12),
            ..._settingSections.map(
              (s) => _NavTestCard(
                label: s.title,
                description: s.description,
                color: Colors.deepPurple,
                onTap: () => context.go('/settings/${s.key}', extra: s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Settings section — NavPageConfig with edit action
// ─────────────────────────────────────────────────────────────────────────────

class SettingsSectionPage extends StatelessWidget {
  const SettingsSectionPage({
    super.key,
    required this.sectionKey,
    this.section,
  });
  final String sectionKey;
  final SettingSection? section;

  @override
  Widget build(BuildContext context) {
    final title = section?.title ?? sectionKey;
    final desc = section?.description ?? '';

    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.tune_rounded,
        label: title,
        color: Colors.deepPurple,
      ),
      actions: [
        FilledButton.tonalIcon(
          onPressed: () =>
              context.go('/settings/$sectionKey/edit', extra: section),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit'),
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(width: 4),
        const _UserAvatar(),
      ],
      child: _PageWrapper(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DataRow('Path param', sectionKey),
            _DataRow('extra.title', title),
            _DataRow('extra.desc', desc),
            const SizedBox(height: 24),
            const _SectionHeader('Go one level deeper — Edit'),
            const SizedBox(height: 12),
            _NavTestCard(
              label: 'Edit $title settings',
              description: '/settings/$sectionKey/edit',
              color: Colors.deepPurple.shade700,
              onTap: () =>
                  context.go('/settings/$sectionKey/edit', extra: section),
            ),
            _NavTestCard(
              label: '→ Jump to Products',
              description: 'Back button still works across the jump',
              color: Colors.grey,
              onTap: () => context.go('/products'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Settings section edit
// ─────────────────────────────────────────────────────────────────────────────

class SettingsSectionEditPage extends StatelessWidget {
  const SettingsSectionEditPage({
    super.key,
    required this.sectionKey,
    this.section,
  });
  final String sectionKey;
  final SettingSection? section;

  @override
  Widget build(BuildContext context) {
    final title = section?.title ?? sectionKey;

    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.edit_rounded,
        label: 'Edit $title',
        color: Colors.deepPurple.shade700,
      ),
      actions: [
        FilledButton.icon(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Save'),
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        const SizedBox(width: 4),
        const _UserAvatar(),
      ],
      child: _PageWrapper(
        title: 'Edit $title',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DataRow('Full path', '/settings/$sectionKey/edit'),
            _DataRow('Section', sectionKey),
            _DataRow('extra', section?.title ?? '⚠️ null (deep-linked)'),
            const SizedBox(height: 16),
            const _SectionHeader('📍 3 levels deep inside Settings'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Settings  →  Section  →  Edit\nBack button retraces each hop.',
                style: TextStyle(height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared page chrome
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return NavPageConfig(
      centerWidget: _PageTitle(
        icon: Icons.article_outlined,
        label: title,
        color: Theme.of(context).colorScheme.primary,
      ),
      actions: const [_UserAvatar()],
      child: _PageWrapper(
        title: title,
        child: Center(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}

class _PageWrapper extends StatelessWidget {
  const _PageWrapper({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            sliver: SliverToBoxAdapter(child: child),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature callout card
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureCallout extends StatelessWidget {
  const _FeatureCallout({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.55,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
// Reusable UI atoms
// ─────────────────────────────────────────────────────────────────────────────

/// Inline page title shown in the AppBar center slot via NavPageConfig.
class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _NavTestCard extends StatelessWidget {
  const _NavTestCard({
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DataRow extends StatelessWidget {
  const _DataRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar support widgets
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const FlutterLogo(size: 28),
      const SizedBox(width: 8),
      Text(
        'MyApp',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
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
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// Extra menu button — only shown on the Dashboard page via NavPageConfig.
class _DashboardMenuButton extends StatelessWidget {
  const _DashboardMenuButton();
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert_rounded),
    tooltip: 'Dashboard options',
    onSelected: (v) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$v" tapped — injected by DashboardPage')),
    ),
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'Export', child: Text('Export')),
      PopupMenuItem(value: 'Refresh', child: Text('Refresh')),
      PopupMenuItem(value: 'Fullscreen', child: Text('Fullscreen')),
    ],
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
      ),
    ),
  );
}

// FEATURE 3: Full profile card shown when rail is expanded
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
            child: Text(
              'A',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alex Johnson',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Admin',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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

// FEATURE 3: Compact avatar shown when the rail collapses to icons-only mode
class _CompactAvatar extends StatelessWidget {
  const _CompactAvatar();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Tooltip(
          message: 'Alex Johnson — Admin',
          child: CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text(
              'A',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Navigation logger
// ─────────────────────────────────────────────────────────────────────────────

class _NavLogger extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) => debugPrint(
    '🟢 PUSH   ${previousRoute?.settings.name ?? '(none)'} → ${route.settings.name}',
  );
  @override
  void didPop(Route route, Route? previousRoute) => debugPrint(
    '🔴 POP    ${route.settings.name} → ${previousRoute?.settings.name}',
  );
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => debugPrint(
    '🔵 GO     ${oldRoute?.settings.name} → ${newRoute?.settings.name}',
  );
}
