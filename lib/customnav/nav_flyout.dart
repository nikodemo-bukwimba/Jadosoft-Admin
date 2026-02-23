import 'package:flutter/material.dart';

import 'nav_item.dart';
import 'nav_rail_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

/// Manages a single [OverlayEntry]-based flyout for a nav item's children.
///
/// Only one top-level flyout is open at a time. Each [_FlyoutItem] within the
/// panel can open its own sub-flyout recursively.
class NavFlyoutController {
  OverlayEntry? _entry;
  String? _openItemId;

  bool get isOpen => _entry != null;
  String? get openItemId => _openItemId;

  bool isOpenFor(String itemId) => _openItemId == itemId;

  /// Opens a flyout for [item] anchored to [anchorOffset].
  void show({
    required BuildContext context,
    required NavItem item,
    required Offset anchorOffset,
    required NavRailThemeData navTheme,
    required String selectedPath,
    required void Function(String path) onNavigate,
  }) {
    close();
    _openItemId = item.id;

    _entry = OverlayEntry(
      builder: (_) => _FlyoutRoot(
        item: item,
        anchorOffset: anchorOffset,
        navTheme: navTheme,
        selectedPath: selectedPath,
        onNavigate: (path) {
          onNavigate(path);
          close();
        },
        onDismiss: close,
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  /// Removes the active flyout (and any sub-flyouts within it).
  void close() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _openItemId = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root overlay widget
// ─────────────────────────────────────────────────────────────────────────────

class _FlyoutRoot extends StatefulWidget {
  const _FlyoutRoot({
    required this.item,
    required this.anchorOffset,
    required this.navTheme,
    required this.selectedPath,
    required this.onNavigate,
    required this.onDismiss,
  });

  final NavItem item;
  final Offset anchorOffset;
  final NavRailThemeData navTheme;
  final String selectedPath;
  final void Function(String path) onNavigate;
  final VoidCallback onDismiss;

  @override
  State<_FlyoutRoot> createState() => _FlyoutRootState();
}

class _FlyoutRootState extends State<_FlyoutRoot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _scale = Tween(
      begin: 0.93,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clamp position so the flyout doesn't overflow screen edges.
    final screen = MediaQuery.of(context).size;
    final maxY = screen.height - 8;
    final dx = widget.anchorOffset.dx.clamp(0, screen.width - 204).toDouble();
    final dy = widget.anchorOffset.dy.clamp(8, maxY).toDouble();

    return Stack(
      children: [
        // Barrier — tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: dx,
          top: dy,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.topLeft,
              child: FlyoutPanel(
                item: widget.item,
                navTheme: widget.navTheme,
                selectedPath: widget.selectedPath,
                onNavigate: widget.onNavigate,
                onDismiss: widget.onDismiss,
                depth: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flyout panel — recursive
// ─────────────────────────────────────────────────────────────────────────────

/// The card that contains a list of child items. Rendered recursively for
/// sub-flyouts (unlimited depth).
@visibleForTesting
class FlyoutPanel extends StatelessWidget {
  const FlyoutPanel({
    super.key,
    required this.item,
    required this.navTheme,
    required this.selectedPath,
    required this.onNavigate,
    required this.onDismiss,
    this.depth = 0,
  });

  final NavItem item;
  final NavRailThemeData navTheme;
  final String selectedPath;
  final void Function(String path) onNavigate;
  final VoidCallback onDismiss;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: navTheme.flyoutElevation!,
      borderRadius: navTheme.flyoutBorderRadius,
      color: navTheme.flyoutBackgroundColor,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Group header label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  item.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: navTheme.unselectedItemColor?.withOpacity(0.55),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(height: 1, color: navTheme.dividerColor),
              const SizedBox(height: 4),
              ...item.children.map(
                (child) => _FlyoutItem(
                  item: child,
                  navTheme: navTheme,
                  selectedPath: selectedPath,
                  onNavigate: onNavigate,
                  onDismiss: onDismiss,
                  depth: depth + 1,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual flyout item — supports hover-based sub-flyouts recursively
// ─────────────────────────────────────────────────────────────────────────────

class _FlyoutItem extends StatefulWidget {
  const _FlyoutItem({
    required this.item,
    required this.navTheme,
    required this.selectedPath,
    required this.onNavigate,
    required this.onDismiss,
    required this.depth,
  });

  final NavItem item;
  final NavRailThemeData navTheme;
  final String selectedPath;
  final void Function(String path) onNavigate;
  final VoidCallback onDismiss;
  final int depth;

  @override
  State<_FlyoutItem> createState() => _FlyoutItemState();
}

class _FlyoutItemState extends State<_FlyoutItem> {
  bool _hovered = false;
  OverlayEntry? _subEntry;

  bool get _isActive =>
      widget.item.path == widget.selectedPath ||
      widget.item.allDescendantPaths.contains(widget.selectedPath);

  void _openSubFlyout(BuildContext context) {
    _closeSubFlyout();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.localToGlobal(Offset(box.size.width + 4, -4));

    _subEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeSubFlyout,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy,
            child: FlyoutPanel(
              item: widget.item,
              navTheme: widget.navTheme,
              selectedPath: widget.selectedPath,
              onNavigate: (path) {
                widget.onNavigate(path);
                _closeSubFlyout();
              },
              onDismiss: () {
                _closeSubFlyout();
                widget.onDismiss();
              },
              depth: widget.depth,
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_subEntry!);

    // The sub-flyout OverlayEntry covers this item, so MouseRegion.onExit
    // won't fire — clear _hovered now to prevent the color freezing.
    setState(() => _hovered = false);
  }

  void _closeSubFlyout() {
    _subEntry?.remove();
    _subEntry?.dispose();
    _subEntry = null;
  }

  @override
  void dispose() {
    _closeSubFlyout();
    super.dispose();
  }

  void _handleTap() {
    if (widget.item.isButton) {
      widget.item.onTap?.call();
      widget.onDismiss();
    } else if (widget.item.hasChildren) {
      // On touch: toggle sub-flyout
      if (_subEntry != null) {
        _closeSubFlyout();
      } else {
        _openSubFlyout(context);
      }
    } else if (widget.item.path != null) {
      widget.onNavigate(widget.item.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nt = widget.navTheme;
    final isActive = _isActive;

    final fgColor = widget.item.isButton
        ? nt.buttonItemColor!
        : isActive
        ? nt.selectedItemColor!
        : nt.unselectedItemColor!;

    final bgColor = widget.item.isButton
        ? nt.buttonItemBackgroundColor!
        : isActive
        ? nt.selectedItemBackgroundColor!
        : _hovered
        ? nt.unselectedItemColor!.withOpacity(0.08)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        if (widget.item.hasChildren) _openSubFlyout(context);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(
                  isActive
                      ? (widget.item.selectedIcon ?? widget.item.icon)
                      : widget.item.icon,
                  size: 18,
                  color: fgColor,
                ),
                const SizedBox(width: 12),
              ],
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
                ),
              ),
              if (widget.item.badge != null) ...[
                const SizedBox(width: 8),
                widget.item.badge!,
              ],
              if (widget.item.hasChildren) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: nt.unselectedItemColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
