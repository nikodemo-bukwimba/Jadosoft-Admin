import 'package:flutter/material.dart';

/// Describes screen-level customisations that a page can inject into
/// [AdaptiveNavShell]'s AppBar via [NavPageConfig].
///
/// Only the fields you set take effect; everything else falls back to the
/// shell-level defaults passed to [AdaptiveNavShell].
@immutable
class NavAppBarConfig {
  const NavAppBarConfig({
    this.centerWidget,
    this.actions = const [],
  });

  /// Replaces [AdaptiveNavShell.appBarCenterWidget] while this config is active.
  final Widget? centerWidget;

  /// Replaces [AdaptiveNavShell.appBarActions] while this config is active.
  /// Leave empty to keep the shell's default actions.
  final List<Widget> actions;

  static const empty = NavAppBarConfig();
}