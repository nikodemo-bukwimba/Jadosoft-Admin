import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nav_appbar_config.dart';
import 'nav_cubit.dart';

/// Injects custom AppBar content into [AdaptiveNavShell] for the lifetime of
/// the page it wraps, then automatically clears it on disposal.
///
/// Place it at the root of any page that needs a custom title or actions:
///
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return NavPageConfig(
///     centerWidget: const Text('Dashboard'),
///     actions: [
///       IconButton(
///         icon: const Icon(Icons.notifications_outlined),
///         onPressed: _showNotifications,
///       ),
///     ],
///     child: const _DashboardBody(),
///   );
/// }
/// ```
///
/// When this widget leaves the tree (navigation, tab switch, etc.) the AppBar
/// automatically reverts to the shell's defaults — no manual cleanup needed.
class NavPageConfig extends StatefulWidget {
  const NavPageConfig({
    super.key,
    this.centerWidget,
    this.actions = const [],
    required this.child,
  });

  /// Replaces [AdaptiveNavShell.appBarCenterWidget] for this page.
  final Widget? centerWidget;

  /// Replaces [AdaptiveNavShell.appBarActions] for this page.
  final List<Widget> actions;

  final Widget child;

  @override
  State<NavPageConfig> createState() => _NavPageConfigState();
}

class _NavPageConfigState extends State<NavPageConfig> {
  @override
  void initState() {
    super.initState();
    // Defer until after the first frame so the cubit is already in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _push();
    });
  }

  @override
  void didUpdateWidget(NavPageConfig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.centerWidget != widget.centerWidget ||
        oldWidget.actions != widget.actions) {
      _push();
    }
  }

  @override
  void dispose() {
    // Use a post-frame callback so that if the *incoming* page's NavPageConfig
    // already pushed its config during the same frame, we don't stomp it.
    final cubit = context.read<NavCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.clearAppBarConfig();
    });
    super.dispose();
  }

  void _push() {
    context.read<NavCubit>().setAppBarConfig(
          NavAppBarConfig(
            centerWidget: widget.centerWidget,
            actions: widget.actions,
          ),
        );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}