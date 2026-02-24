/// Adaptive Navigation Rail for Flutter
///
/// Drop-in navigation shell with:
/// - Responsive rail ↔ drawer switching at a configurable breakpoint
/// - Recursive flyout sub-menus (unlimited depth) on hover / tap
/// - go_router integration with automatic selection tracking
/// - 3-mode display toggle: icons / labels / icons+labels
/// - Button-style CTA items with distinct visual treatment
/// - Full Material 3 theming via [NavRailThemeData] ThemeExtension
/// - Custom AppBar with logo, back-nav, actions, and a free center slot
/// - Screen-level AppBar injection via [NavPageConfig] / [NavAppBarConfig]
///
/// ### Quick start
///
/// ```dart
/// AdaptiveNavShell(
///   router: myGoRouter,
///   breakpoint: 768,
///   logo: const FlutterLogo(),
///   appBarActions: [IconButton(icon: Icon(Icons.person), onPressed: () {})],
///   items: [
///     NavItem(id: 'home', label: 'Home', icon: Icons.home, path: '/'),
///     NavItem(
///       id: 'products',
///       label: 'Products',
///       icon: Icons.inventory,
///       children: [
///         NavItem(id: 'all', label: 'All Products', path: '/products'),
///         NavItem(id: 'new', label: 'New Arrivals', path: '/products/new'),
///       ],
///     ),
///     NavItem(
///       id: 'upgrade',
///       label: 'Upgrade',
///       icon: Icons.star,
///       isButton: true,
///       onTap: () => showUpgradeDialog(),
///     ),
///   ],
///   child: child, // from ShellRoute
/// )
/// ```
///
/// ### Screen-level AppBar customisation
///
/// ```dart
/// // In any page's build():
/// return NavPageConfig(
///   centerWidget: const Text('Orders'),
///   actions: [IconButton(icon: Icon(Icons.filter_list), onPressed: _filter)],
///   child: const OrdersBody(),
/// );
/// ```
library adaptive_nav;

export 'adaptive_nav_shell.dart';
export 'nav_appbar_config.dart';
export 'nav_cubit.dart';
export 'nav_item.dart';
export 'nav_page_config.dart';
export 'nav_rail_theme.dart';
export 'custom_app_bar.dart';
export 'nav_flyout.dart' show NavFlyoutController;
export 'nav_item_tile.dart';
export 'nav_rail_body.dart';
