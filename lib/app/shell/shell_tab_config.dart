// shell_tab_config.dart
// Data model for a single navigation tab entry.
//
// Extracted from the private _TabItem class that lived inside ShellPage.
// Making it public here allows shell_nav_items.dart to reference it and
// allows the generator to append new entries without touching shell_page.dart.
//
// The [requiredPermission] field is intentionally absent here — tab visibility
// is controlled by the AuthState extensions in rbac_extensions.dart, not
// by string-matching permissions in this value object. See shell_nav_items.dart
// for how [ShellTabBuilder] handles the conditional logic.

import 'package:flutter/material.dart';

/// A single navigation tab entry: label, icons, and the widget to display.
/// Build instances via [ShellNavItems.buildTabs].
class ShellTabConfig {
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  final Widget   page;

  const ShellTabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}