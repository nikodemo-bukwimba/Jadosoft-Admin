// shell_nav_items.dart
// Defines which navigation tabs appear and in what order.
//
// This file owns the full tab roster. ShellPage calls
// ShellNavItems.buildTabs(isAdmin) and renders whatever comes back.
//
// Why extracted from ShellPage:
//   - ShellPage should only know HOW to render tabs, not WHICH tabs exist.
//   - The generator appends new feature tabs here without touching ShellPage.
//   - Adding a tab manually: add a ShellTabConfig entry in _buildTabs below
//     AND add the corresponding route constant in AppRouter.
//
// Role-aware tabs:
//   Tabs gated by role are wrapped in an if(isAdmin) / if(hasPermission) check.
//   The AuthState RBAC extensions (rbac_extensions.dart) are the source of
//   truth for those checks. Never duplicate permission logic here.
//
// Tab order matters:
//   [0] is the first visible tab. IndexedStack uses the list index directly.
//   Reordering breaks the active tab index. Append new feature tabs between
//   the GENERATOR TABS markers — never above Home, never below Profile.

import 'package:fca/app/shell/shell_page_home_tab.dart';
import 'package:fca/config/di/injection_container.dart';
import 'package:fca/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fca/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:fca/features/profile/presentation/bloc/profile_event.dart';
import 'package:fca/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shell_tab_config.dart';

// ── GENERATOR FEATURE IMPORTS — append only ───────────────────────────────────

// ── END GENERATOR FEATURE IMPORTS ────────────────────────────────────────────

abstract class ShellNavItems {
  /// Returns the ordered list of visible tabs for the current session.
  ///
  /// [isAdmin] comes from state.canViewDashboard (rbac_extensions.dart).
  /// The generator appends new feature tabs in the GENERATOR TABS block below.
  static List<ShellTabConfig> buildTabs({required bool isAdmin}) {
    final tabs = <ShellTabConfig>[
      const ShellTabConfig(
        label: 'Info',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        page: HomeTab(),
      ),
      // ── END GENERATOR TABS ───────────────────────────────────────────────
    ];

    // Dashboard — visible to admins only
    if (isAdmin) {
      tabs.add(
        ShellTabConfig(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          page: BlocProvider(
            create: (_) => sl<ProfileBloc>(),
            child: const DashboardPage(),
          ),
        ),
      );
    }

    // Profile — always last, always visible
    tabs.add(
      ShellTabConfig(
        label: 'Profile',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        page: BlocProvider(
          create: (_) => sl<ProfileBloc>()..add(ProfileLoadRequested()),
          child: const ProfilePage(),
        ),
      ),
    );

    return tabs;
  }
}


