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
import 'package:fca/features/about/presentation/pages/analytics_page.dart';
import 'package:fca/features/about/presentation/pages/audit_logs_page.dart';
import 'package:fca/features/about/presentation/pages/master_product_catalog_page.dart';
import 'package:fca/features/about/presentation/pages/organization_dashboard_page.dart';
import 'package:fca/features/about/presentation/pages/organization_detail_page.dart';
import 'package:fca/features/about/presentation/pages/platform_users_page.dart';
import 'package:fca/features/about/presentation/pages/system_health_page.dart';
import 'package:fca/features/about/presentation/pages/system_settings_page.dart';
import 'package:fca/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fca/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:fca/features/profile/presentation/bloc/profile_event.dart';
import 'package:fca/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'shell_tab_config.dart';

// ── GENERATOR FEATURE IMPORTS — append only ───────────────────────────────────
import 'package:fca/features/category/presentation/pages/category_list_page.dart';
import 'package:fca/features/category/presentation/bloc/category_bloc.dart';

import 'package:fca/features/visit/presentation/pages/visit_list_page.dart';
import 'package:fca/features/visit/presentation/bloc/visit_bloc.dart';

import '../../features/hello/presentation/pages/hello_list_page.dart';
import '../../features/hello/presentation/bloc/hello_bloc.dart';
import '../../features/hello/presentation/bloc/hello_event.dart';

// ── END GENERATOR FEATURE IMPORTS ────────────────────────────────────────────

abstract class ShellNavItems {
  /// Returns the ordered list of visible tabs for the current session.
  ///
  /// [isAdmin] comes from state.canViewDashboard (rbac_extensions.dart).
  /// The generator appends new feature tabs in the GENERATOR TABS block below.
  static List<ShellTabConfig> buildTabs({required bool isAdmin}) {
    final tabs = <ShellTabConfig>[
      // Tab 0 — Home (always first, always visible)

      // About tab (Level 0 — static, generated 2026-02-27)
      ShellTabConfig(
        label: 'Organizations',
        icon: Icons.domain_outlined,
        activeIcon: Icons.domain_rounded,
        page: const OrganizationDashboardPage(),
      ),
      ShellTabConfig(
        label: 'Organizations Detail',
        icon: Icons.domain_outlined,
        activeIcon: Icons.domain_rounded,
        page: const OrganizationDetailPage(),
      ),
      ShellTabConfig(
        label: 'Platform Users',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        page: const PlatformUsersPage(),
      ),
      ShellTabConfig(
        label: 'Master Product Catalog',
        icon: Icons.list_outlined,
        activeIcon: Icons.list,
        page: const MasterProductCatalogPage(),
      ),
      ShellTabConfig(
        label: 'Audit Logs',
        icon: Icons.list_outlined,
        activeIcon: Icons.list,
        page: const AuditLogsPage(),
      ),
      ShellTabConfig(
        label: 'Analytics',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        page: const AnalyticsPage(),
      ),
      ShellTabConfig(
        label: 'System Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        page: const SystemSettingsPage(),
      ),
      ShellTabConfig(
        label: 'System Health',
        icon: Icons.health_and_safety_outlined,
        activeIcon: Icons.health_and_safety,
        page: const SystemHealthPage(),
      ),

      /** 
      ShellTabConfig(
        label: 'Dashboard',
        icon: Icons.info_outlined,
        activeIcon: Icons.info,
        page: const DashboardPage(),
      ),


 ShellTabConfig(
        label: 'Roles & Permissions',
        icon: Icons.security_outlined,
        activeIcon: Icons.security,
        page: const RolesPermissionsPage(),
      ),


  ShellTabConfig(
        label: 'Territories',
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
        page: const TerritoriesPage(),
      ),
      
        ShellTabConfig(
        label: 'Billing',
        icon: Icons.payment_outlined,
        activeIcon: Icons.payment,
        page: const BillingPage(),
      ),
*/
      // ── GENERATOR TABS — append only ─────────────────────────────────────
      // Generator inserts new feature tabs here.
      // Wrap role-gated tabs in if(isAdmin) or if(hasPermission) as needed.
      // Do NOT reorder — index alignment with IndexedStack is order-sensitive.
      // Category tab (generated 2026-02-27)
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
