import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'customnav/navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models — used to test `extra` object passing
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
  observers: [_NavLogger()], // logs every hop to the debug console
  routes: [
    ShellRoute(
      builder: (context, state, child) => AdaptiveNavShell(
        router: _router,
        breakpoint: 768,
        items: _navItems,
        logo: const _AppLogo(),
        appBarActions: const [_NotificationBell(), _UserAvatar()],
        appBarCenterWidget: const _SearchBar(),
        railHeader: const _ProfileCard(),
        railFooter: const _RailFooter(),
        child: child,
      ),
      routes: [
        // ── Dashboard ─────────────────────────────────────────────────
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),

        // ── Analytics ────────────────────────────────────────────────
        GoRoute(
          path: '/analytics',
          builder: (_, __) => const _PlaceholderPage(title: 'Analytics'),
        ),
        GoRoute(
          path: '/analytics/reports',
          builder: (_, state) {
            // Query param: /analytics/reports?period=monthly
            final period = state.uri.queryParameters['period'] ?? 'weekly';
            return _PlaceholderPage(title: 'Reports ($period)');
          },
        ),
        GoRoute(
          path: '/analytics/realtime',
          builder: (_, __) => const _PlaceholderPage(title: 'Real-time'),
        ),

        // ── Products ──────────────────────────────────────────────────
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

        // PATH PARAM — /products/:id
        // IMPORTANT: specific sub-paths (/new, /categories) must be
        // declared BEFORE the :id wildcard so go_router matches them first.
        GoRoute(
          path: '/products/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            final product = state.extra as Product?;
            return ProductDetailPage(productId: id, product: product);
          },
        ),

        // PATH PARAM + QUERY — /products/:id/reviews?sort=recent
        GoRoute(
          path: '/products/:id/reviews',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            final sort = state.uri.queryParameters['sort'] ?? 'recent';
            final product = state.extra as Product?;
            return ProductReviewsPage(
              productId: id,
              sort: sort,
              product: product,
            );
          },
        ),

        // ── Settings ──────────────────────────────────────────────────
        GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),

        // PATH PARAM — /settings/:section
        GoRoute(
          path: '/settings/:section',
          builder: (_, state) {
            final key = state.pathParameters['section']!;
            final section = state.extra as SettingSection?;
            return SettingsSectionPage(sectionKey: key, section: section);
          },
        ),

        // DEEP — /settings/:section/edit  (3 levels from /settings)
        GoRoute(
          path: '/settings/:section/edit',
          builder: (_, state) {
            final key = state.pathParameters['section']!;
            final section = state.extra as SettingSection?;
            return SettingsSectionEditPage(sectionKey: key, section: section);
          },
        ),
      ],
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Nav items
// Ghost items (label: '') register deep paths for rail highlight anchoring
// without appearing in any flyout.
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
      // Ghost anchors — keep Products highlighted on detail + review pages
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
      // Ghost anchors — keep Settings highlighted on section + edit pages
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
    return _PageWrapper(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('Navigate from here — depth test'),
          const SizedBox(height: 12),

          // 1. Plain path navigation
          _NavTestCard(
            label: '① Plain go — Settings',
            description: "context.go('/settings')",
            color: Colors.blue,
            onTap: () => context.go('/settings'),
          ),

          // 2. Query parameter
          _NavTestCard(
            label: '② Query param — Reports (monthly)',
            description: "context.go('/analytics/reports?period=monthly')",
            color: Colors.teal,
            onTap: () => context.go('/analytics/reports?period=monthly'),
          ),

          // 3. Path param + extra object
          _NavTestCard(
            label: '③ Path param + extra — Product detail',
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

          // 4. 3 levels deep
          _NavTestCard(
            label: '④ 3 levels deep — Product Reviews',
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

          // 5. Settings section (path param + extra)
          _NavTestCard(
            label: '⑤ Settings section — Security',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Product list
// ─────────────────────────────────────────────────────────────────────────────

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Product detail — path param + extra
// ─────────────────────────────────────────────────────────────────────────────

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId, this.product});
  final String productId;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final name = product?.name ?? 'Product $productId';
    final price = product?.price ?? 0.0;

    return _PageWrapper(
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
            description:
                "context.go('/products/$productId/reviews?sort=recent', extra: product)",
            color: Colors.green,
            onTap: () => context.go(
              '/products/$productId/reviews?sort=recent',
              extra: product,
            ),
          ),
          _NavTestCard(
            label: 'View Reviews (sort: rating)',
            description:
                'Same page, different query param — notice URL updates',
            color: Colors.green.shade800,
            onTap: () => context.go(
              '/products/$productId/reviews?sort=rating',
              extra: product,
            ),
          ),
          _NavTestCard(
            label: '→ Jump to Settings (cross-section)',
            description:
                'Back button still traces the full history across the jump',
            color: Colors.grey,
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Product reviews — deepest product route (Dashboard → List → Detail → Reviews)
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
    return _PageWrapper(
      title: '${product?.name ?? productId} — Reviews',
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
            description: 'context.go() to same path with different query param',
            color: Colors.teal,
            onTap: () => context.go(
              '/products/$productId/reviews?sort=helpful',
              extra: product,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Settings
// ─────────────────────────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageWrapper(
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Settings section — /settings/:section
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

    return _PageWrapper(
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
            description:
                "context.go('/settings/$sectionKey/edit', extra: section)",
            color: Colors.deepPurple.shade700,
            onTap: () =>
                context.go('/settings/$sectionKey/edit', extra: section),
          ),
          _NavTestCard(
            label: '→ Jump to Products (cross-section)',
            description: 'Back button still works across the jump',
            color: Colors.grey,
            onTap: () => context.go('/products'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE: Settings section edit — deepest settings route
// Settings → Section → Edit  (3 levels)
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
    return _PageWrapper(
      title: 'Edit ${section?.title ?? sectionKey}',
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
              'Settings  →  Section  →  Edit\n'
              'Back button retraces each hop.',
              style: TextStyle(height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.check),
            label: const Text('Save & return to Settings'),
          ),
        ],
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
  Widget build(BuildContext context) => _PageWrapper(
    title: title,
    child: Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    ),
  );
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
// Reusable UI atoms
// ─────────────────────────────────────────────────────────────────────────────

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
// AppBar support widgets (unchanged)
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
// Navigation observer — logs every route change in debug console
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
