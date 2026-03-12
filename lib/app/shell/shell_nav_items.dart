// shell_nav_items.dart
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

import 'package:flutter/material.dart';
import '../../core/rbac/rbac_extensions.dart';
import '../../customnav/nav_item.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../routes/app_router.dart';

// â”€â”€ GENERATOR FEATURE IMPORTS â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// â”€â”€ END GENERATOR FEATURE IMPORTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

abstract class ShellNavItems {
  /// Returns the ordered [NavItem] list for the current session.
  ///
  /// [auth] is the resolved [AuthAuthenticated] state.
  /// Items gated by permission are excluded when the check fails.
  static List<NavItem> buildNavItems({required AuthAuthenticated auth}) {
    return [
      // â”€â”€ Always visible â€” Home â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      NavItem(
        id: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        path: AppRouter.home,
      ),

      // â”€â”€ GENERATOR TABS â€” append only â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Generator wires entries here as:
      //   if (auth.can('feature_name.view'))
      //     NavItem(id: '...', label: '...', icon: ..., path: AppRouter.featureList),

      
      // Actors (Level 1, generated 2026-03-10)
      if (auth.can('actors.view'))
        NavItem(
          id:    'actor',
          label: 'Actors',
          icon:  Icons.people_outlined,
          path:  AppRouter.actorList,
        ),
      // â”€â”€ END GENERATOR TABS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

      // â”€â”€ Permission-gated â€” Dashboard â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (auth.canViewDashboard)
        NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          path: AppRouter.dashboard,
        ),

      // â”€â”€ Always visible â€” Profile (always last) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      NavItem(
        id: 'profile',
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        path: AppRouter.profile,
      ),
    ];
  }
}





















