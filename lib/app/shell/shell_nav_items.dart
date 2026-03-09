// shell_nav_items.dart
// ─────────────────────────────────────────────────────────────
// Produces the ordered List<NavItem> consumed by AdaptiveNavShell.
//
// Each NavItem.path must match a GoRoute inside AppRouter's ShellRoute.
//
// GATING: Uses permission slugs (auth.can('slug')), never role names.
// Permission slugs match the backend's PlatformPermissionSeeder.
//
// Rules:
//   - Home  is always [0]  (first)
//   - Profile is always last
//   - Permission-gated items use if(auth.can('module.action'))
//   - Generator appends between GENERATOR TABS markers only
//   - Generator reads the "permission" key from feature.config.json
//     and wires: if (auth.can('feature_name.view'))
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
  /// Items gated by permission are excluded when the check fails.
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
      // Generator wires entries here as:
      //   if (auth.can('feature_name.view'))
      //     NavItem(id: '...', label: '...', icon: ..., path: AppRouter.featureList),

      // ── END GENERATOR TABS ────────────────────────────────

      // ── Permission-gated — Dashboard ──────────────────────
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




