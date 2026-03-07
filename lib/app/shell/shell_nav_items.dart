// shell_nav_items.dart
// ─────────────────────────────────────────────────────────────
// Produces the ordered List<NavItem> consumed by AdaptiveNavShell.
//
// MIGRATION: Replaced List<ShellTabConfig> (IndexedStack approach)
// with List<NavItem> (go_router path-based approach).
// Each NavItem.path must match a GoRoute inside AppRouter's ShellRoute.
//
// Rules:
//   - Home  is always [0]  (first)
//   - Profile is always last
//   - Admin-gated items use if(auth.canViewDashboard) / if(auth.can(...))
//   - Never duplicate permission logic here — use rbac_extensions.dart
//   - Generator appends between GENERATOR TABS markers only
//
// Adding a tab manually:
//   1. Add a NavItem entry below between the generator markers.
//   2. Add the matching GoRoute in app_router.dart.
//   3. Add the page import above.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../core/rbac/rbac_extensions.dart';
import '../../customnav/nav_item.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../routes/app_router.dart';

// ── GENERATOR FEATURE IMPORTS — append only ──────────────────
// ── END GENERATOR FEATURE IMPORTS ────────────────────────────

abstract class ShellNavItems {
  /// Returns the ordered [NavItem] list for the current session.
  ///
  /// [auth] is the resolved [AuthAuthenticated] state.
  /// Items gated by role/permission are excluded when the check fails.
  static List<NavItem> buildNavItems({required AuthAuthenticated auth}) {
    return [
      // ── Always visible — Home ─────────────────────────────
      NavItem(
        id: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        path: AppRouter.home,
      ),

      // ── GENERATOR TABS — append only ──────────────────────
      // ── END GENERATOR TABS ────────────────────────────────

      // ── Admin only — Dashboard ────────────────────────────
      if (auth.canViewDashboard)
        NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          path: AppRouter.dashboard,
        ),

      // ── Always visible — Profile (always last) ────────────
      NavItem(
        id: 'profile',
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        path: AppRouter.profile,
      ),
    ];
  }
}
