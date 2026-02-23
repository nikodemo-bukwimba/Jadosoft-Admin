import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 
import 'nav_cubit.dart';
import 'nav_flyout.dart';
import 'nav_item.dart';
import 'nav_item_tile.dart';
import 'nav_rail_theme.dart';

/// The scrollable navigation panel rendered inside the rail or drawer.
///
/// Owns the [NavFlyoutController] lifecycle so all flyouts are cleaned up
/// when this widget is disposed (e.g. when the drawer is closed).
class NavRailBody extends StatefulWidget {
  const NavRailBody({
    super.key,
    required this.items,
    required this.navTheme,
    required this.isDrawerMode,
    this.header,
    this.footer,
  });

  final List<NavItem> items;
  final NavRailThemeData navTheme;
  final bool isDrawerMode;

  /// Custom widget pinned above the nav items (e.g. user profile card).
  final Widget? header;

  /// Custom widget pinned below the nav items (e.g. settings, version label).
  final Widget? footer;

  @override
  State<NavRailBody> createState() => _NavRailBodyState();
}

class _NavRailBodyState extends State<NavRailBody> {
  final _flyoutController = NavFlyoutController();

  @override
  void dispose() {
    _flyoutController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, NavState>(
      buildWhen: (prev, next) => prev.displayMode != next.displayMode,
      builder: (context, state) {
        final nt = widget.navTheme;

        // In drawer mode, always show full width (no collapse).
        final isIconsOnly = !widget.isDrawerMode &&
            state.displayMode == NavRailDisplayMode.iconsOnly;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          width: isIconsOnly ? nt.railCollapsedWidth! : nt.railWidth!,
          color: nt.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Optional header slot ────────────────────────────────────
              if (widget.header != null) widget.header!,

              // ── Display mode toggle ─────────────────────────────────────
              // Hidden in drawer mode (always expanded there)
              if (!widget.isDrawerMode)
                _DisplayModeToggle(navTheme: nt, isCollapsed: isIconsOnly),

              Divider(height: 1, color: nt.dividerColor),
              const SizedBox(height: 4),

              // ── Nav items ───────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: widget.items.length,
                  itemBuilder: (_, i) => NavItemTile(
                    item: widget.items[i],
                    displayMode: state.displayMode,
                    flyoutController: _flyoutController,
                    navTheme: nt,
                    isDrawerMode: widget.isDrawerMode,
                  ),
                ),
              ),

              // ── Optional footer slot ────────────────────────────────────
              if (widget.footer != null) ...[
                Divider(height: 1, color: nt.dividerColor),
                widget.footer!,
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Display mode toggle button
// ─────────────────────────────────────────────────────────────────────────────

class _DisplayModeToggle extends StatelessWidget {
  const _DisplayModeToggle({
    required this.navTheme,
    required this.isCollapsed,
  });

  final NavRailThemeData navTheme;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, NavState>(
      buildWhen: (prev, next) => prev.displayMode != next.displayMode,
      builder: (context, state) {
        final (icon, tooltip) = switch (state.displayMode) {
          NavRailDisplayMode.iconsOnly => (
              Icons.label_outline_rounded,
              'Show labels'
            ),
          NavRailDisplayMode.labelsOnly => (
              Icons.widgets_outlined,
              'Show icons & labels'
            ),
          NavRailDisplayMode.iconsAndLabels => (
              Icons.view_sidebar_outlined,
              'Collapse to icons'
            ),
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
          child: Align(
            // In collapsed mode center the button; otherwise push to right
            alignment:
                isCollapsed ? Alignment.center : Alignment.centerRight,
            child: IconButton(
              icon: Icon(icon, size: 18),
              color: navTheme.unselectedItemColor,
              tooltip: tooltip,
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: context.read<NavCubit>().cycleDisplayMode,
            ),
          ),
        );
      },
    );
  }
}
