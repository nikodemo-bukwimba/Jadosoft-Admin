 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'custom_app_bar.dart';
import 'nav_cubit.dart';
import 'nav_item.dart';
import 'nav_rail_body.dart';
import 'nav_rail_theme.dart';


/// The top-level shell widget that wraps your app's page content with an
/// adaptive navigation rail / drawer.
///
/// ---
///
/// ### Basic usage with go_router
///
/// ```dart
/// final router = GoRouter(
///   routes: [
///     ShellRoute(
///       builder: (context, state, child) => AdaptiveNavShell(
///         router: router,
///         items: _navItems,
///         child: child,
///       ),
///       routes: [...],
///     ),
///   ],
/// );
/// ```
///
/// ### Responsive behaviour
///
/// | Screen width     | Layout         |
/// |------------------|----------------|
/// | ≥ [breakpoint]   | Side rail + content |
/// | < [breakpoint]   | Drawer + content |
///
/// The breakpoint defaults to 768 but you can pass any value.
///
/// ### Theming
///
/// Theme the rail globally via [ThemeData.extensions]:
///
/// ```dart
/// ThemeData(
///   useMaterial3: true,
///   extensions: [
///     NavRailThemeData(railWidth: 260, flyoutElevation: 6),
///   ],
/// )
/// ```
///
/// Or override per-instance with the [navTheme] parameter.
class AdaptiveNavShell extends StatefulWidget {
  const AdaptiveNavShell({
    super.key,
    required this.router,
    required this.items,
    required this.child,
    this.breakpoint = 768,
    this.logo,
    this.appBarActions = const [],
    this.appBarCenterWidget,
    this.railHeader,
    this.railFooter,
    this.navTheme,
    this.initialDisplayMode = NavRailDisplayMode.iconsAndLabels,
    this.showAppBar = true,
    this.showBackButton = true,
  });

  // ── Required ──────────────────────────────────────────────────────────────

  /// The [GoRouter] instance powering your app's routing.
  final GoRouter router;

  /// Top-level navigation items. Each item can recursively contain [NavItem.children].
  final List<NavItem> items;

  /// The current page content — typically the `child` from a `ShellRoute`.
  final Widget child;

  // ── Layout ────────────────────────────────────────────────────────────────

  /// Width (in logical pixels) below which the layout switches from a
  /// persistent rail to a hamburger-triggered drawer. Default: 768.
  final double breakpoint;

  // ── AppBar customization ──────────────────────────────────────────────────

  /// Branding / logo widget displayed in the AppBar's leading area.
  final Widget? logo;

  /// Action widgets on the right side of the AppBar
  /// (e.g. `[NotificationBell(), UserAvatar()]`).
  final List<Widget> appBarActions;

  /// Widget occupying the AppBar's center area — search bar, page title, etc.
  final Widget? appBarCenterWidget;

  /// Set to `false` to remove the AppBar entirely.
  final bool showAppBar;

  /// Whether the AppBar shows a back-arrow when [NavState.canGoBack] is true.
  final bool showBackButton;

  // ── Rail customization ────────────────────────────────────────────────────

  /// Widget pinned above the nav items in the rail / drawer.
  /// Great for a user profile card or app logo.
  final Widget? railHeader;

  /// Widget pinned below the nav items in the rail / drawer.
  /// Great for settings, help, logout, or a version label.
  final Widget? railFooter;

  // ── Theming ───────────────────────────────────────────────────────────────

  /// Per-instance theme override.
  /// Falls back to [NavRailThemeData] from [ThemeData.extensions], then M3 tokens.
  final NavRailThemeData? navTheme;

  /// Initial display mode of the rail. Default: [NavRailDisplayMode.iconsAndLabels].
  final NavRailDisplayMode initialDisplayMode;

  @override
  State<AdaptiveNavShell> createState() => _AdaptiveNavShellState();
}

class _AdaptiveNavShellState extends State<AdaptiveNavShell> {
  late final NavCubit _cubit;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _cubit = NavCubit(
      router: widget.router,
      items: widget.items,
      initialDisplayMode: widget.initialDisplayMode,
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  /// Resolves the effective theme for this shell instance.
  NavRailThemeData _resolveTheme(BuildContext context) {
    final theme = Theme.of(context);
    return (widget.navTheme ??
            theme.extension<NavRailThemeData>() ??
            const NavRailThemeData())
        .resolve(theme);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDrawerMode = constraints.maxWidth < widget.breakpoint;
          final navTheme = _resolveTheme(context);

          return isDrawerMode
              ? _DrawerLayout(
                  scaffoldKey: _scaffoldKey,
                  items: widget.items,
                  navTheme: navTheme,
                  logo: widget.logo,
                  appBarActions: widget.appBarActions,
                  appBarCenterWidget: widget.appBarCenterWidget,
                  railHeader: widget.railHeader,
                  railFooter: widget.railFooter,
                  showAppBar: widget.showAppBar,
                  showBackButton: widget.showBackButton,
                  child: widget.child,
                )
              : _RailLayout(
                  items: widget.items,
                  navTheme: navTheme,
                  logo: widget.logo,
                  appBarActions: widget.appBarActions,
                  appBarCenterWidget: widget.appBarCenterWidget,
                  railHeader: widget.railHeader,
                  railFooter: widget.railFooter,
                  showAppBar: widget.showAppBar,
                  showBackButton: widget.showBackButton,
                  child: widget.child,
                );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide-screen layout: persistent side rail
// ─────────────────────────────────────────────────────────────────────────────

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.items,
    required this.navTheme,
    required this.child,
    required this.showAppBar,
    required this.showBackButton,
    this.logo,
    this.appBarActions = const [],
    this.appBarCenterWidget,
    this.railHeader,
    this.railFooter,
  });

  final List<NavItem> items;
  final NavRailThemeData navTheme;
  final Widget child;
  final bool showAppBar;
  final bool showBackButton;
  final Widget? logo;
  final List<Widget> appBarActions;
  final Widget? appBarCenterWidget;
  final Widget? railHeader;
  final Widget? railFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? NavCustomAppBar(
              logo: logo,
              actions: appBarActions,
              centerWidget: appBarCenterWidget,
              showBackButton: showBackButton,
              isDrawerMode: false,
            )
          : null,
      body: Row(
        children: [
          // ── Navigation rail ───────────────────────────────────────────
          NavRailBody(
            items: items,
            navTheme: navTheme,
            isDrawerMode: false,
            header: railHeader,
            footer: railFooter,
          ),

          // ── Divider ───────────────────────────────────────────────────
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: navTheme.dividerColor,
          ),

          // ── Page content ──────────────────────────────────────────────
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Narrow-screen layout: drawer
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerLayout extends StatelessWidget {
  const _DrawerLayout({
    required this.scaffoldKey,
    required this.items,
    required this.navTheme,
    required this.child,
    required this.showAppBar,
    required this.showBackButton,
    this.logo,
    this.appBarActions = const [],
    this.appBarCenterWidget,
    this.railHeader,
    this.railFooter,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<NavItem> items;
  final NavRailThemeData navTheme;
  final Widget child;
  final bool showAppBar;
  final bool showBackButton;
  final Widget? logo;
  final List<Widget> appBarActions;
  final Widget? appBarCenterWidget;
  final Widget? railHeader;
  final Widget? railFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: showAppBar
          ? NavCustomAppBar(
              logo: logo,
              actions: appBarActions,
              centerWidget: appBarCenterWidget,
              showBackButton: showBackButton,
              isDrawerMode: true,
              onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      drawer: Drawer(
        backgroundColor: navTheme.backgroundColor,
        child: SafeArea(
          child: NavRailBody(
            items: items,
            navTheme: navTheme,
            isDrawerMode: true,
            header: railHeader,
            footer: railFooter,
          ),
        ),
      ),
      body: child,
    );
  }
}
