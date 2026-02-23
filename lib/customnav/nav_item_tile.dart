import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nav_flyout.dart';
import 'navigation.dart';

/// Renders a single [NavItem] inside the navigation rail or drawer.
///
/// Responsibilities:
/// - Adapts its layout to [NavRailDisplayMode] (icons / labels / both).
/// - On **desktop**: triggers the flyout on mouse hover for items with children.
/// - On **touch/mobile**: triggers the flyout on tap for items with children.
/// - Applies CTA styling for [NavItem.isButton] items.
/// - Highlights itself (and any parent items) based on the active route.
class NavItemTile extends StatefulWidget {
  const NavItemTile({
    super.key,
    required this.item,
    required this.displayMode,
    required this.flyoutController,
    required this.navTheme,
    required this.isDrawerMode,
  });

  final NavItem item;
  final NavRailDisplayMode displayMode;
  final NavFlyoutController flyoutController;
  final NavRailThemeData navTheme;

  /// True when rendered inside the mobile Drawer — always uses iconsAndLabels
  /// and triggers flyout on tap instead of hover.
  final bool isDrawerMode;

  @override
  State<NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<NavItemTile> {
  bool _hovered = false;

  NavRailDisplayMode get _effectiveMode => widget.isDrawerMode
      ? NavRailDisplayMode.iconsAndLabels
      : widget.displayMode;

  bool get _showIcon =>
      _effectiveMode == NavRailDisplayMode.iconsOnly ||
      _effectiveMode == NavRailDisplayMode.iconsAndLabels;

  bool get _showLabel =>
      _effectiveMode == NavRailDisplayMode.labelsOnly ||
      _effectiveMode == NavRailDisplayMode.iconsAndLabels;

  void _handleTap(BuildContext context, NavState state) {
    final cubit = context.read<NavCubit>();

    if (widget.item.isButton) {
      widget.item.onTap?.call();
      return;
    }

    if (widget.item.hasChildren) {
      _openFlyout(context, state);
      return;
    }

    if (widget.item.path != null) {
      cubit.navigateTo(widget.item.path!);
      // Close drawer on mobile after navigation
      if (widget.isDrawerMode) Navigator.of(context).maybePop();
    }
  }

  void _openFlyout(BuildContext context, NavState state) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Anchor the flyout to the right edge of this tile
    final offset = box.localToGlobal(Offset(box.size.width + 4, 0));

    widget.flyoutController.show(
      context: context,
      item: widget.item,
      anchorOffset: offset,
      navTheme: widget.navTheme,
      selectedPath: state.selectedPath,
      onNavigate: (path) {
        context.read<NavCubit>().navigateTo(path);
        if (widget.isDrawerMode) Navigator.of(context).maybePop();
        setState(() {});
      },
    );

    // The OverlayEntry now sits on top of this tile, so MouseRegion.onExit
    // will never fire — _hovered would freeze at true indefinitely.
    // Clear it here; the highlight is now driven by isFlyoutOpen instead.
    setState(() => _hovered = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, NavState>(
      builder: (context, state) {
        final cubit = context.read<NavCubit>();
        final isActive = cubit.isItemActive(widget.item);
        final isFlyoutOpen = widget.flyoutController.isOpenFor(widget.item.id);
        final nt = widget.navTheme;

        // ── Colors ────────────────────────────────────────────────────────
        final Color fgColor;
        final Color bgColor;

        if (widget.item.isButton) {
          fgColor = nt.buttonItemColor!;
          bgColor = nt.buttonItemBackgroundColor!;
        } else if (isActive || isFlyoutOpen) {
          fgColor = nt.selectedItemColor!;
          bgColor = nt.selectedItemBackgroundColor!;
        } else if (_hovered) {
          fgColor = nt.unselectedItemColor!;
          bgColor = nt.unselectedItemColor!.withOpacity(0.08);
        } else {
          fgColor = nt.unselectedItemColor!;
          bgColor = Colors.transparent;
        }

        // ── Padding ───────────────────────────────────────────────────────
        final padding = _effectiveMode == NavRailDisplayMode.iconsOnly
            ? const EdgeInsets.all(12.0)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

        return Tooltip(
          // Show tooltip only in icons-only mode where label is hidden
          message: _effectiveMode == NavRailDisplayMode.iconsOnly
              ? widget.item.label
              : '',
          preferBelow: false,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              setState(() => _hovered = true);
              // Desktop: open flyout on hover
              if (widget.item.hasChildren && !widget.isDrawerMode) {
                _openFlyout(context, state);
              }
            },
            onExit: (_) => setState(() => _hovered = false),
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
                    // ── Icon ───────────────────────────────────────────────
                    if (_showIcon && widget.item.icon != null)
                      _ItemIcon(
                        item: widget.item,
                        isActive: isActive,
                        color: fgColor,
                        showBadge: !_showLabel, // badge on icon in icons-only
                      ),

                    if (_showIcon && _showLabel && widget.item.icon != null)
                      const SizedBox(width: 14),

                    // ── Label ──────────────────────────────────────────────
                    if (_showLabel) ...[
                      Expanded(
                        child: Text(
                          widget.item.label,
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
                      // Badge visible in expanded modes
                      if (widget.item.badge != null) ...[
                        const SizedBox(width: 8),
                        widget.item.badge!,
                      ],
                      // Chevron for items with children
                      if (widget.item.hasChildren) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: nt.unselectedItemColor,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
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
