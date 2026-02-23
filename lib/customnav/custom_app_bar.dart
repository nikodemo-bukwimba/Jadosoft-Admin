import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'navigation.dart';

/// The top app bar used by [AdaptiveNavShell].
///
/// Supports:
/// - **Logo/branding** — any widget in the leading slot.
/// - **Back button** — auto-shown when [NavState.canGoBack] is true.
/// - **Hamburger menu** — shown in drawer mode (narrow screens).
/// - **Custom center widget** — search bar, page title, tabs, etc.
/// - **Action buttons** — notifications, avatar, etc. (any `List<Widget>`).
///
/// Resolves its height and colors from [NavRailThemeData] / M3 tokens.
class NavCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NavCustomAppBar({
    super.key,
    this.logo,
    this.actions = const [],
    this.centerWidget,
    this.showBackButton = true,
    this.isDrawerMode = false,
    this.onMenuTap,
  });

  /// Branding/logo widget shown in the leading area.
  /// Hidden when a back button or hamburger is shown instead.
  final Widget? logo;

  /// Widgets rendered on the right side of the bar.
  final List<Widget> actions;

  /// Widget occupying the expanded center area.
  /// Pass a search bar, page title, or any custom widget.
  final Widget? centerWidget;

  /// When true, renders a back arrow whenever [NavState.canGoBack] is true.
  final bool showBackButton;

  /// True on narrow screens — renders a hamburger menu to open the Drawer.
  final bool isDrawerMode;

  /// Called when the hamburger icon is tapped (drawer mode only).
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(_kAppBarHeight);

  // Use a fixed default here; the actual resolved value comes from the theme
  // but PreferredSizeWidget.preferredSize must be const.
  static const double _kAppBarHeight = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme =
        (theme.extension<NavRailThemeData>() ?? const NavRailThemeData())
            .resolve(theme);

    return BlocBuilder<NavCubit, NavState>(
      builder: (context, state) {
        final cubit = context.read<NavCubit>();
        final showBack = showBackButton && state.canGoBack;

        return Container(
          height: navTheme.appBarHeight,
          color: navTheme.appBarBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // ── Leading slot ─────────────────────────────────────────────
              // Drawer mode: hamburger is ALWAYS visible.
              //   When canGoBack is also true, back button appears beside it
              //   so users never lose access to either.
              // Rail mode: logo is shown; back button replaces it when active.
              if (isDrawerMode) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open menu',
                  onPressed: onMenuTap,
                ),
                // Back button slides in alongside the hamburger — no replacement
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: showBack
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: cubit.goBack,
                        )
                      : const SizedBox.shrink(),
                ),
              ] else ...[
                // Rail mode: logo ↔ back button (one at a time is fine here)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: showBack
                      ? IconButton(
                          key: const ValueKey('back'),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: cubit.goBack,
                        )
                      : logo != null
                      ? Padding(
                          key: const ValueKey('logo'),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: logo,
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),
              ],

              // ── Center / title slot ───────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: centerWidget ?? const SizedBox.shrink(),
                ),
              ),

              // ── Action buttons ────────────────────────────────────────────
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: action,
                ),
              ),

              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}
