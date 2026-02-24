import 'package:flutter/material.dart';

import 'nav_item.dart';
import 'nav_rail_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

/// Manages a single [OverlayEntry]-based flyout for a nav item's children.
///
/// Extends [ChangeNotifier] so [NavItemTile]s can subscribe and call
/// `setState` whenever the flyout opens or closes — this is the only reliable
/// way to keep each tile's visual state (highlighted / normal) in sync,
/// because the flyout can close from a debounce timer, a navigation event, or
/// a tap on the dismiss barrier, none of which trigger a [BlocBuilder] rebuild.
class NavFlyoutController extends ChangeNotifier {
  OverlayEntry? _entry;
  String? _openItemId;

  bool get isOpen => _entry != null;
  String? get openItemId => _openItemId;
  bool isOpenFor(String itemId) => _openItemId == itemId;

  void show({
    required BuildContext context,
    required NavItem item,
    required Offset anchorOffset,
    required NavRailThemeData navTheme,
    required String selectedPath,
    required void Function(String path) onNavigate,
    VoidCallback? onHoverEnter,
    VoidCallback? onHoverExit,
  }) {
    _removeEntry();
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
        onHoverEnter: onHoverEnter,
        onHoverExit: onHoverExit,
      ),
    );

    Overlay.of(context).insert(_entry!);
    notifyListeners(); // tiles subscribed to this controller rebuild
  }

  void close() {
    if (_entry == null) return; // already closed — avoid spurious notifications
    _removeEntry();
    notifyListeners();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    _openItemId = null;
  }

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
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
    this.onHoverEnter,
    this.onHoverExit,
  });

  final NavItem item;
  final Offset anchorOffset;
  final NavRailThemeData navTheme;
  final String selectedPath;
  final void Function(String path) onNavigate;
  final VoidCallback onDismiss;
  final VoidCallback? onHoverEnter;
  final VoidCallback? onHoverExit;

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
    _scale = Tween(begin: 0.93, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dx = widget.anchorOffset.dx.clamp(0.0, screen.width - 204.0);
    final dy = widget.anchorOffset.dy.clamp(8.0, screen.height - 8.0);

    return Stack(
      children: [
        // Tap-anywhere barrier — does NOT intercept mouse-hover events
        // (no MouseRegion here), so tile MouseRegions still receive onEnter/onExit.
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
              // MouseRegion on the panel so the owning tile can cancel its
              // close-debounce while the cursor is inside the flyout.
              child: MouseRegion(
                onEnter: (_) => widget.onHoverEnter?.call(),
                onExit: (_) => widget.onHoverExit?.call(),
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
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flyout panel — recursive
// ─────────────────────────────────────────────────────────────────────────────

/// Ghost items (empty [NavItem.label]) are filtered out before rendering —
/// they only exist as ancestor-highlight anchors.
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
    final visibleChildren = item.children
        .where((c) => c.label != null && c.label!.isNotEmpty)
        .toList();

    if (visibleChildren.isEmpty) return const SizedBox.shrink();

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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Text(
                  (item.label ?? '').toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: navTheme.unselectedItemColor?.withOpacity(0.55),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Divider(height: 1, color: navTheme.dividerColor),
              const SizedBox(height: 4),
              ...visibleChildren.map(
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
// Individual flyout item — supports hover sub-flyouts recursively
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

  bool get _hasVisibleChildren => widget.item.children
      .any((c) => c.label != null && c.label!.isNotEmpty);

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
    } else if (_hasVisibleChildren) {
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
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        if (_hasVisibleChildren) _openSubFlyout(context);
      },
      onExit: (_) {
        setState(() => _hovered = false);
      },
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
                  widget.item.label ?? '',
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
              if (_hasVisibleChildren) ...[
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