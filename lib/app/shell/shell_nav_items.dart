// shell_nav_items.dart
// ─────────────────────────────────────────────────────────────
// FIX: Organization tab was gated on auth.can('org.manage')
// which does NOT exist in the backend PlatformPermissionSeeder.
//
// The correct approach: show Organization to anyone who has
// ANY membership permission. The backend org_permission_definitions
// seeds 'members.view' for all roles including viewer/staff.
// For users with NO permissions at all (owner role at root with
// no explicit permission set), we fall back to checking the
// role slug directly via auth.isAdminAppRole.
//
// GATING RULES:
//   org tab  → members.view OR isAdminAppRole (owner/manager/etc)
//   others   → keep existing permission slugs
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/rbac/rbac_extensions.dart';
import '../../customnav/nav_item.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../routes/app_router.dart';

// ── GENERATOR FEATURE IMPORTS — append only ──────────────────

// ── END GENERATOR FEATURE IMPORTS ────────────────────────────

abstract class ShellNavItems {
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

      // ┌──────────────────────────────────────────────────────
      // │ ORGANIZATION MANAGEMENT
      // │ FIX: was auth.can('org.manage') — slug doesn't exist.
      // │ Show if user has members.view OR is an admin-role user
      // │ (owner, manager, staff, etc.) who may have no explicit
      // │ permissions seeded yet.
      // └──────────────────────────────────────────────────────
      if (auth.can('members.view') || auth.isAdminAppRole)
        NavItem(
          id: 'organization',
          label: 'Organization',
          icon: Icons.business_outlined,
          path: AppRouter.orgHub,
        ),

      // ┌──────────────────────────────────────────────────────
      // │ FIELD OPERATIONS
      // └──────────────────────────────────────────────────────
      if (auth.can('officers.view'))
        NavItem(
          id: 'officer',
          label: 'Officers',
          icon: Icons.badge_outlined,
          path: AppRouter.officerList,
        ),

      if (auth.can('customers.view'))
        NavItem(
          id: 'customer',
          label: 'Customers',
          icon: Icons.store_outlined,
          path: AppRouter.customerList,
        ),

      if (auth.can('visits.view'))
        NavItem(
          id: 'visit',
          label: 'Visits',
          icon: Icons.place_outlined,
          path: AppRouter.visitList,
        ),

      if (auth.can('weeklyplans.view'))
        NavItem(
          id: 'weekly_plan',
          label: 'Weekly Plans',
          icon: Icons.calendar_month_outlined,
          path: AppRouter.weeklyPlanList,
        ),

      if (auth.can('reports.view'))
        NavItem(
          id: 'daily_report',
          label: 'Daily Reports',
          icon: Icons.summarize_outlined,
          path: AppRouter.dailyReportList,
        ),

      // ┌──────────────────────────────────────────────────────
      // │ PRODUCTS & COMMERCE
      // └──────────────────────────────────────────────────────
      if (auth.can('categories.view'))
        NavItem(
          id: 'category',
          label: 'Categories',
          icon: Icons.category_outlined,
          path: AppRouter.categoryList,
        ),

      if (auth.can('products.view'))
        NavItem(
          id: 'product',
          label: 'Products',
          icon: Icons.inventory_2_outlined,
          path: AppRouter.productList,
        ),

      if (auth.can('promotions.view'))
        NavItem(
          id: 'promotion',
          label: 'Promotions',
          icon: Icons.campaign_outlined,
          path: AppRouter.promotionList,
        ),

      if (auth.can('orders.view'))
        NavItem(
          id: 'order',
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          path: AppRouter.orderList,
        ),

      if (auth.can('payments.view'))
        NavItem(
          id: 'payment',
          label: 'Payments',
          icon: Icons.payments_outlined,
          path: AppRouter.paymentList,
        ),

      // ┌──────────────────────────────────────────────────────
      // │ COMMUNICATION
      // └──────────────────────────────────────────────────────
      if (auth.can('conversations.view'))
        NavItem(
          id: 'conversation',
          label: 'Messages',
          icon: Icons.forum_outlined,
          path: AppRouter.conversationList,
        ),

      if (auth.can('notifications.view'))
        NavItem(
          id: 'notification',
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          path: AppRouter.notificationList,
        ),

      // ┌──────────────────────────────────────────────────────
      // │ ANALYTICS & REPORTS
      // └──────────────────────────────────────────────────────
      if (auth.can('marketing_dashboard.view'))
        NavItem(
          id: 'marketing_dashboard',
          label: 'Marketing',
          icon: Icons.insights_outlined,
          path: AppRouter.marketingDashboard,
        ),

      if (auth.can('sales_dashboard.view'))
        NavItem(
          id: 'sales_dashboard',
          label: 'Sales',
          icon: Icons.trending_up_outlined,
          path: AppRouter.salesDashboard,
        ),

      if (auth.can('report_export.view'))
        NavItem(
          id: 'report_export',
          label: 'Export',
          icon: Icons.file_download_outlined,
          path: AppRouter.reportExport,
        ),

      if (auth.can('activity_logs.view'))
        NavItem(
          id: 'activity_log',
          label: 'Activity Logs',
          icon: Icons.history_outlined,
          path: AppRouter.activityLogList,
        ),

      // Actor (HMSCP core)
      if (auth.can('actors.view'))
        NavItem(
          id: 'actor',
          label: 'Actors',
          icon: Icons.people_outlined,
          path: AppRouter.actorList,
        ),

      // ── END GENERATOR TABS ─────────────────────────────────

      // ── Permission-gated — Dashboard ───────────────────────
      if (auth.canViewDashboard)
        NavItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          path: AppRouter.dashboard,
        ),

      // ── Always visible — Profile (always last) ──────────────
      NavItem(
        id: 'profile',
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        path: AppRouter.profile,
      ),
    ];
  }
}
