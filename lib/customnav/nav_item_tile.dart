import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nav_flyout.dart';
import 'navigation.dart';

/// Renders a single [NavItem] inside the navigation rail or drawer.
///
/// ## Hover state ownership — mirrors HalaNavigationRail
///
/// Hover state is NOT stored here. It lives in [NavRailBody] as
/// `Map<String, bool> _hoverStates`, exactly like `HalaNavigationRail`
/// stores its hover map in the parent state. The parent calls `setState`
/// on itself when hover changes, which rebuilds all tiles consistently.
/// [isHovered], [onHoverEnter], and [onHoverExit] are passed in as props.
///
/// ## Accordion (both rail and drawer)
/// Inline expand/collapse is used in both wide and narrow modes.
/// [_expanded] stays local because it is purely UI state that no other
/// widget needs to observe. Flyouts are no longer used for nested items.
class NavItemTile extends StatefulWidget {
  const NavItemTile({
    super.key,
    required this.item,
    required this.displayMode,
    required this.flyoutController,
    required this.navTheme,
    required this.isDrawerMode,
    // ── Hover props (owned by NavRailBody, like HalaNavigationRail) ──────
    required this.isHovered,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  final NavItem item;
  final NavRailDisplayMode displayMode;
  final NavFlyoutController flyoutController;
  final NavRailThemeData navTheme;
  final bool isDrawerMode;

  /// Whether the cursor is currently over this tile.
  final bool isHovered;

  /// Called when the cursor enters this tile.
  final VoidCallback onHoverEnter;

  /// Called when the cursor exits this tile.
  final VoidCallback onHoverExit;

  @override
  State<NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<NavItemTile> {
  bool _expanded = false; // accordion — used in both modes

  // ── Ghost / children helpers ──────────────────────────────────────────────

  bool get _isGhost => widget.item.label == null || widget.item.label!.isEmpty;

  bool get _hasVisibleChildren =>
      widget.item.children.any((c) => c.label != null && c.label!.isNotEmpty);

  List<NavItem> get _visibleChildren => widget.item.children
      .where((c) => c.label != null && c.label!.isNotEmpty)
      .toList();

  // ── Display mode helpers ──────────────────────────────────────────────────

  NavRailDisplayMode get _effectiveMode => widget.isDrawerMode
      ? NavRailDisplayMode.iconsAndLabels
      : widget.displayMode;

  bool get _showIcon =>
      _effectiveMode == NavRailDisplayMode.iconsOnly ||
      _effectiveMode == NavRailDisplayMode.iconsAndLabels;

  bool get _showLabel =>
      _effectiveMode == NavRailDisplayMode.labelsOnly ||
      _effectiveMode == NavRailDisplayMode.iconsAndLabels;

  // ── Mouse handlers ────────────────────────────────────────────────────────

  void _handleMouseEnter() {
    widget.onHoverEnter();
  }

  void _handleMouseExit() {
    widget.onHoverExit();
  }

  // ── Tap handler ───────────────────────────────────────────────────────────

  void _handleTap(BuildContext context, NavState state) {
    final cubit = context.read<NavCubit>();

    if (widget.item.isButton) {
      widget.item.onTap?.call();
      return;
    }

    if (_hasVisibleChildren) {
      // Accordion in both wide and drawer modes.
      setState(() => _expanded = !_expanded);
      return;
    }

    if (widget.item.path != null) {
      cubit.navigateTo(widget.item.path!);
      if (widget.isDrawerMode) Navigator.of(context).maybePop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isGhost) return const SizedBox.shrink();

    return BlocBuilder<NavCubit, NavState>(
      builder: (context, state) {
        final cubit = context.read<NavCubit>();
        final isActive = cubit.isItemActive(widget.item);
        final nt = widget.navTheme;

        // ── Color priority ─────────────────────────────────────────────────
        // 1. Button palette
        // 2. Active route / expanded accordion → selected
        // 3. Cursor over tile → hover
        // 4. Idle
        final Color fgColor;
        final Color bgColor;

        if (widget.item.isButton) {
          fgColor = nt.buttonItemColor!;
          bgColor = nt.buttonItemBackgroundColor!;
        } else if (isActive || _expanded) {
          fgColor = nt.selectedItemColor!;
          bgColor = nt.selectedItemBackgroundColor!;
        } else if (widget.isHovered) {
          fgColor = nt.unselectedItemColor!;
          bgColor = nt.unselectedItemColor!.withOpacity(0.08);
        } else {
          fgColor = nt.unselectedItemColor!;
          bgColor = Colors.transparent;
        }

        final padding = _effectiveMode == NavRailDisplayMode.iconsOnly
            ? const EdgeInsets.all(12.0)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

        final tile = Tooltip(
          message: _effectiveMode == NavRailDisplayMode.iconsOnly
              ? (widget.item.label ?? '')
              : '',
          preferBelow: false,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _handleMouseEnter(),
            onExit: (_) => _handleMouseExit(),
            child: GestureDetector(
              onTap: () => _handleTap(context, state),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                padding: padding,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: nt.itemBorderRadius,
                ),
                child: Row(
                  mainAxisSize: _effectiveMode == NavRailDisplayMode.iconsOnly
                      ? MainAxisSize.min
                      : MainAxisSize.max,
                  children: [
                    if (_showIcon && widget.item.icon != null)
                      _ItemIcon(
                        item: widget.item,
                        isActive: isActive,
                        color: fgColor,
                        showBadge: !_showLabel,
                      ),
                    if (_showIcon && _showLabel && widget.item.icon != null)
                      const SizedBox(width: 14),
                    if (_showLabel) ...[
                      Expanded(
                        child: Text(
                          widget.item.label ?? '',
                          style: nt.labelStyle?.copyWith(
                            color: fgColor,
                            fontWeight: isActive || widget.item.isButton
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (widget.item.badge != null) ...[
                        const SizedBox(width: 8),
                        widget.item.badge!,
                      ],
                      if (_hasVisibleChildren) ...[
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          // Same chevron rotation for both wide and drawer.
                          turns: _expanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more_rounded,
                            size: 16,
                            color: nt.unselectedItemColor,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );

        // Accordion wrapper — used for both wide rail and drawer.
        if (_hasVisibleChildren) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tile,
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _visibleChildren.map((child) {
                            return _AccordionChildTile(
                              item: child,
                              displayMode: widget.displayMode,
                              flyoutController: widget.flyoutController,
                              navTheme: widget.navTheme,
                            );
                          }).toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }

        return tile;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({
    required this.item,
    required this.isActive,
    required this.color,
    required this.showBadge,
  });

  final NavItem item;
  final bool isActive;
  final Color color;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isActive ? (item.selectedIcon ?? item.icon) : item.icon,
      color: color,
      size: 22,
    );

    if (!showBadge || item.badge == null) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(top: -5, right: -5, child: item.badge!),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accordion child tile
//
// Used inside NavItemTile's inline accordion in both wide and drawer modes.
// Owns its own hover bool since it lives inside a Column (not the ListView),
// so it's not wired into NavRailBody's central _hoverStates map.
// ─────────────────────────────────────────────────────────────────────────────

class _AccordionChildTile extends StatefulWidget {
  const _AccordionChildTile({
    required this.item,
    required this.displayMode,
    required this.flyoutController,
    required this.navTheme,
  });

  final NavItem item;
  final NavRailDisplayMode displayMode;
  final NavFlyoutController flyoutController;
  final NavRailThemeData navTheme;

  @override
  State<_AccordionChildTile> createState() => _AccordionChildTileState();
}

class _AccordionChildTileState extends State<_AccordionChildTile> {
  bool _hovered = false;
  bool _expanded = false;

  bool get _isGhost => widget.item.label == null || widget.item.label!.isEmpty;

  bool get _hasVisibleChildren =>
      widget.item.children.any((c) => c.label != null && c.label!.isNotEmpty);

  List<NavItem> get _visibleChildren => widget.item.children
      .where((c) => c.label != null && c.label!.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_isGhost) return const SizedBox.shrink();

    return BlocBuilder<NavCubit, NavState>(
      builder: (context, state) {
        final cubit = context.read<NavCubit>();
        final isActive = cubit.isItemActive(widget.item);
        final nt = widget.navTheme;

        final Color fgColor;
        final Color bgColor;

        if (isActive || _expanded) {
          fgColor = nt.selectedItemColor!;
          bgColor = nt.selectedItemBackgroundColor!;
        } else if (_hovered) {
          fgColor = nt.unselectedItemColor!;
          bgColor = nt.unselectedItemColor!.withOpacity(0.08);
        } else {
          fgColor = nt.unselectedItemColor!;
          bgColor = Colors.transparent;
        }

        final tile = MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () {
              if (_hasVisibleChildren) {
                setState(() => _expanded = !_expanded);
              } else if (widget.item.path != null) {
                cubit.navigateTo(widget.item.path!);
                // Pop drawer if applicable (safe no-op in rail mode).
                Navigator.of(context).maybePop();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: nt.itemBorderRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (widget.item.icon != null) ...[
                    Icon(
                      isActive
                          ? (widget.item.selectedIcon ?? widget.item.icon)
                          : widget.item.icon,
                      color: fgColor,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Text(
                      widget.item.label ?? '',
                      style: nt.labelStyle?.copyWith(
                        color: fgColor,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (widget.item.badge != null) ...[
                    const SizedBox(width: 8),
                    widget.item.badge!,
                  ],
                  if (_hasVisibleChildren) ...[
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: nt.unselectedItemColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        if (!_hasVisibleChildren) return tile;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tile,
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _visibleChildren.map((child) {
                          return _AccordionChildTile(
                            item: child,
                            displayMode: widget.displayMode,
                            flyoutController: widget.flyoutController,
                            navTheme: widget.navTheme,
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
