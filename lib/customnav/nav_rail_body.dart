import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nav_cubit.dart';
import 'nav_flyout.dart';
import 'nav_item.dart';
import 'nav_item_tile.dart';
import 'nav_rail_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Width snap helper
// ─────────────────────────────────────────────────────────────────────────────

class _WidthBreakpoints {
  const _WidthBreakpoints({required this.collapsed, required this.expanded});

  final double collapsed;
  final double expanded;

  static const _snapThreshold = 20.0;

  double clamp(double w) => w.clamp(collapsed, expanded);

  double snap(double w) {
    if ((w - collapsed).abs() < _snapThreshold) return collapsed;
    if ((w - expanded).abs() < _snapThreshold) return expanded;
    return clamp(w);
  }

  NavRailDisplayMode modeFor(double w) => w <= collapsed + _snapThreshold / 2
      ? NavRailDisplayMode.iconsOnly
      : NavRailDisplayMode.iconsAndLabels;
}

// ─────────────────────────────────────────────────────────────────────────────
// NavRailBody
// ─────────────────────────────────────────────────────────────────────────────

class NavRailBody extends StatefulWidget {
  const NavRailBody({
    super.key,
    required this.items,
    required this.navTheme,
    required this.isDrawerMode,
    this.header,
    this.headerCollapsed,
    this.footer,
  });

  final List<NavItem> items;
  final NavRailThemeData navTheme;
  final bool isDrawerMode;
  final Widget? header;
  final Widget? headerCollapsed;
  final Widget? footer;

  @override
  State<NavRailBody> createState() => _NavRailBodyState();
}

class _NavRailBodyState extends State<NavRailBody> {
  final _flyoutController = NavFlyoutController();
  final Map<String, bool> _hoverStates = {};
  final _scrollController = ScrollController();

  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    _registerIds(widget.items);
  }

  @override
  void didUpdateWidget(NavRailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _hoverStates.clear();
      _registerIds(widget.items);
    }
  }

  @override
  void dispose() {
    _flyoutController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _registerIds(List<NavItem> items) {
    for (final item in items) {
      _hoverStates.putIfAbsent(item.id, () => false);
      if (item.children.isNotEmpty) _registerIds(item.children);
    }
  }

  VoidCallback _onEnter(String id) =>
      () => setState(() => _hoverStates[id] = true);

  VoidCallback _onExit(String id) =>
      () => setState(() => _hoverStates[id] = false);

  // ── Width calculation ─────────────────────────────────────────────────────

  double _currentWidth(NavState state, NavRailThemeData nt) {
    if (state.customWidth != null) return state.customWidth!;
    return state.displayMode == NavRailDisplayMode.iconsOnly
        ? nt.railCollapsedWidth!
        : nt.railWidth!;
  }

  // ── Resize callbacks ──────────────────────────────────────────────────────

  void _onDragUpdate(double delta, NavState state, NavRailThemeData nt) {
    if (!_isResizing) setState(() => _isResizing = true);
    final bp = _WidthBreakpoints(
      collapsed: nt.railCollapsedWidth!,
      expanded: nt.railWidth!,
    );
    final next = bp.clamp(_currentWidth(state, nt) + delta);
    context.read<NavCubit>().setCustomWidth(next);
  }

  void _onDragEnd(NavState state, NavRailThemeData nt) {
    setState(() => _isResizing = false);

    final cubit = context.read<NavCubit>();
    final bp = _WidthBreakpoints(
      collapsed: nt.railCollapsedWidth!,
      expanded: nt.railWidth!,
    );
    final snapped = bp.snap(_currentWidth(state, nt));
    final newMode = bp.modeFor(snapped);

    if (newMode != state.displayMode) {
      cubit.setDisplayMode(newMode, clearCustomWidth: false);
    }
    cubit.commitCustomWidth(snapped);
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isIconsOnly, NavRailThemeData nt) {
    if (widget.isDrawerMode) {
      return widget.header ?? const SizedBox.shrink();
    }
    if (isIconsOnly) {
      return widget.headerCollapsed ?? const SizedBox.shrink();
    }
    if (widget.header == null) return const SizedBox.shrink();

    return UnconstrainedBox(
      constrainedAxis: Axis.vertical,
      alignment: Alignment.topLeft,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: nt.railWidth!, child: widget.header!),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCubit, NavState>(
      buildWhen: (prev, next) =>
          prev.displayMode != next.displayMode ||
          prev.customWidth != next.customWidth,
      builder: (context, state) {
        final nt = widget.navTheme;
        final isIconsOnly =
            !widget.isDrawerMode &&
            state.displayMode == NavRailDisplayMode.iconsOnly;

        final currentWidth = _currentWidth(state, nt);

        final rail = AnimatedContainer(
          duration: _isResizing
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          width: currentWidth,
          decoration: BoxDecoration(
            color: nt.backgroundColor,
            border: Border(
              right: BorderSide(color: nt.dividerColor!, width: 1),
            ),
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(isIconsOnly, nt),
                Divider(height: 1, color: nt.dividerColor),
                const SizedBox(height: 4),

                // ── Scrollable items list ─────────────────────────────────
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: false,
                    thickness: isIconsOnly ? 3 : 4,
                    radius: const Radius.circular(4),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: widget.items.length,
                      itemBuilder: (_, i) =>
                          _buildTile(widget.items[i], state.displayMode),
                    ),
                  ),
                ),

                if (widget.footer != null) ...[
                  Divider(height: 1, color: nt.dividerColor),
                  widget.footer!,
                ],
              ],
            ),
          ),
        );

        if (widget.isDrawerMode || !(nt.enableResize ?? true)) return rail;

        return Stack(
          children: [
            rail,
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _ResizeHandle(
                navTheme: nt,
                onDragUpdate: (delta) => _onDragUpdate(delta, state, nt),
                onDragEnd: () => _onDragEnd(state, nt),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile(NavItem item, NavRailDisplayMode displayMode) {
    return NavItemTile(
      item: item,
      displayMode: displayMode,
      flyoutController: _flyoutController,
      navTheme: widget.navTheme,
      isDrawerMode: widget.isDrawerMode,
      isHovered: _hoverStates[item.id] ?? false,
      onHoverEnter: _onEnter(item.id),
      onHoverExit: _onExit(item.id),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resize handle
// ─────────────────────────────────────────────────────────────────────────────

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.navTheme,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final NavRailThemeData navTheme;
  final void Function(double delta) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _dragging;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDragUpdate(d.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.navTheme.resizeHandleWidth ?? 6,
          color: active
              ? widget.navTheme.resizeHandleHoverColor
              : widget.navTheme.resizeHandleColor,
        ),
      ),
    );
  }
}
