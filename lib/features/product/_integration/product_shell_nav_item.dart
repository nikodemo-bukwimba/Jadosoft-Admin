// ============================================================================
// PRODUCT FEATURE — SHELL NAV ITEM REGISTRATION
// ============================================================================
//
// Add this entry to: lib/app/shell/shell_nav_items.dart
//
// Insert after the category nav item (Seq 8). Products (Seq 9) should
// appear in the Product Management group in the navigation.
//
// If using the custom nav system (lib/customnav/), add a NavItem entry
// to the nav items list.
// ============================================================================

import 'package:flutter/material.dart';

// ── Option A: If using shell_nav_items.dart with a simple list ──────

// Add to the navItems list:
//
// NavItem(
//   label: 'Products',
//   icon: Icons.inventory_2_outlined,
//   activeIcon: Icons.inventory_2,
//   route: '/products',
//   permission: 'products',
//   group: 'Product Management',
//   sortOrder: 9,  // Seq 9
// ),

// ── Option B: If using shell_tab_config.dart ────────────────────────

// Add to the tabs list:
//
// ShellTabConfig(
//   label: 'Products',
//   icon: Icons.inventory_2_outlined,
//   activeIcon: Icons.inventory_2,
//   routePath: '/products',
//   permission: 'products',
// ),

// ── Option C: If using the custom nav system (lib/customnav/) ───────

// Add to the NavItem list in navigation.dart:
//
// NavItem(
//   title: 'Products',
//   icon: Icons.inventory_2_outlined,
//   selectedIcon: Icons.inventory_2,
//   route: '/products',
//   permission: 'products',
// ),

// ── RBAC Note ───────────────────────────────────────────────────────
//
// The product nav item requires the 'products' permission key.
// Ensure this permission is registered in the RBAC system so the
// PermissionGuard can gate access. The guard at lib/core/rbac/
// permission_guard.dart handles this check.
