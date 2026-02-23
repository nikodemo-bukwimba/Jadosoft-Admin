import 'package:flutter/material.dart';

/// Represents a single item in the navigation rail.
///
/// Items can be:
/// - **Regular nav items**: have a [path], update the selected route on tap.
/// - **Parent group items**: have [children] but no [path], show a flyout on hover/tap.
/// - **Button items**: [isButton] is true, fire [onTap] only, never update selection.
///
/// Children can themselves have children — nesting is unlimited and recursive.
class NavItem {
  const NavItem({
    required this.id,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.path,
    this.children = const [],
    this.isButton = false,
    this.onTap,
    this.badge,
  }) : assert(
          !isButton || path == null,
          'Button items should not have a path — use onTap instead.',
        );

  /// Unique identifier used for state tracking (flyout open/close, selection).
  final String id;

  /// Text label shown in the rail and flyouts.
  final String label;

  /// Icon displayed when the item is not selected.
  final IconData? icon;

  /// Icon displayed when the item is selected. Falls back to [icon] if null.
  final IconData? selectedIcon;

  /// The go_router route path this item navigates to.
  ///
  /// Null for group items (which only show flyouts) and button items.
  final String? path;

  /// Nested child items. A non-empty list triggers flyout behavior.
  final List<NavItem> children;

  /// When true, this item renders as a CTA button:
  /// - Uses [buttonItemColor] / [buttonItemBackgroundColor] from the theme.
  /// - Fires [onTap] but does **not** update active selection state.
  final bool isButton;

  /// Callback invoked when a button-style item is tapped.
  final VoidCallback? onTap;

  /// Optional badge widget (e.g. a notification count dot).
  final Widget? badge;

  bool get hasChildren => children.isNotEmpty;

  /// Recursively collects every path under this item.
  /// Used to highlight a parent rail entry when a nested child is active.
  List<String> get allDescendantPaths {
    final paths = <String>[];
    if (path != null) paths.add(path!);
    for (final child in children) {
      paths.addAll(child.allDescendantPaths);
    }
    return paths;
  }
}
