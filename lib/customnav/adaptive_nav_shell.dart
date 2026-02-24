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
/// ### Screen-level AppBar customisation
///
/// Wrap any page's content with [NavPageConfig] to inject a custom title or
/// actions into the shared AppBar for the duration of that page's lifetime:
///
/// ```dart
/// // Inside a page's build method:
/// return NavPageConfig(
///   centerWidget: const Text('My Page'),
///   actions: [IconButton(icon: Icon(Icons.share), onPressed: _share)],
///   child: MyPageBody(),
/// );
/// ```
///
/// ### Responsive behaviour
///
/// | Screen width     | Layout              |
/// |------------------|---------------------|
/// | ≥ [breakpoint]   | Side rail + content |
/// | < [breakpoint]   | Drawer + content    |
///
/// The breakpoint defaults to 768 but you can pass any value.
///
/// ### Theming
///
/// ```dart
/// ThemeData(
///   extensions: [
///     NavRailThemeData(railWidth: 260, flyoutElevation: 6),
///   ],
/// )
/// ```
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
    this.railHeaderCollapsed,
    this.railFooter,
    this.navTheme,
    this.initialDisplayMode = NavRailDisplayMode.iconsAndLabels,
    this.showAppBar = true,
    this.showBackButton = true,
  });

  // ── Required ──────────────────────────────────────────────────────────────

  final GoRouter router;
  final List<NavItem> items;
  final Widget child;

  // ── Layout ────────────────────────────────────────────────────────────────

  /// Width (in logical pixels) below which the layout switches from a
  /// persistent rail to a hamburger-triggered drawer. Default: 768.
  final double breakpoint;

  // ── AppBar customization ──────────────────────────────────────────────────

  final Widget? logo;

  /// Default action widgets on the right side of the AppBar.
  /// Replaced by [NavPageConfig.actions] when non-empty.
  final List<Widget> appBarActions;

  /// Default center widget for the AppBar.
  /// Replaced by [NavPageConfig.centerWidget] when non-null.
  final Widget? appBarCenterWidget;

  final bool showAppBar;
  final bool showBackButton;

  // ── Rail customization ────────────────────────────────────────────────────

  /// Widget pinned above the nav items in the rail / drawer when **expanded**.
  ///
  /// Keep it intrinsically sized — it will be clipped to the rail width
  /// as the rail animates between expanded and collapsed states.
  final Widget? railHeader;

  /// Widget shown in the header area when the rail is **collapsed to icons-only**.
  ///
  /// Typically a compact logo or avatar that fits within
  /// [NavRailThemeData.railCollapsedWidth]. If null, the header area is hidden
  /// when the rail is collapsed.
  final Widget? railHeaderCollapsed;

  /// Widget pinned below the nav items in the rail / drawer.
  final Widget? railFooter;

  // ── Theming ───────────────────────────────────────────────────────────────

  final NavRailThemeData? navTheme;
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
                  // Drawer is always expanded, so no collapsed header.
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
                  railHeaderCollapsed: widget.railHeaderCollapsed,
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
    this.railHeaderCollapsed,
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
  final Widget? railHeaderCollapsed;
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
          NavRailBody(
            items: items,
            navTheme: navTheme,
            isDrawerMode: false,
            header: railHeader,
            headerCollapsed: railHeaderCollapsed,
            footer: railFooter,
          ),
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
