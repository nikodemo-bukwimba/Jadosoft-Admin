// permission_guard.dart
// ─────────────────────────────────────────────────────────────
// Wraps any widget and renders NOTHING if the current user
// does not satisfy the given role/permission requirement.
//
// Usage examples:
//
//   // Hide unless user has 'users.view' permission
//   PermissionGuard(
//     permission: 'users.view',
//     child: AdminUserListButton(),
//   )
//
//   // Hide unless user has 'admin' or 'super-admin' role
//   PermissionGuard(
//     roles: ['admin', 'super-admin'],
//     child: DashboardNavItem(),
//   )
//
//   // Hide unless user has ALL listed permissions
//   PermissionGuard(
//     permissions: ['users.view', 'users.edit'],
//     requireAll: true,
//     child: EditUserButton(),
//   )
// ─────────────────────────────────────────────────────────────

import 'package:fca/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fca/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'rbac_extensions.dart';

class PermissionGuard extends StatelessWidget {
  /// Single permission slug required (OR logic with [permissions]).
  final String? permission;

  /// Multiple permission slugs. Combined with [requireAll].
  final List<String>? permissions;

  /// Single role slug required (OR logic with [roles]).
  final String? role;

  /// Multiple role slugs. Combined with [requireAllRoles].
  final List<String>? roles;

  /// If true, user must have ALL [permissions]. Default: any one is enough.
  final bool requireAll;

  /// If true, user must have ALL [roles]. Default: any one is enough.
  final bool requireAllRoles;

  /// Widget to show if check passes.
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.child,
    this.permission,
    this.permissions,
    this.role,
    this.roles,
    this.requireAll = false,
    this.requireAllRoles = false,
  }) : assert(
         permission != null ||
             permissions != null ||
             role != null ||
             roles != null,
         'PermissionGuard requires at least one of: permission, permissions, role, roles',
       );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          prev.runtimeType != curr.runtimeType ||
          (curr is AuthAuthenticated &&
              prev is AuthAuthenticated &&
              curr.activeSession.user.email != prev.activeSession.user.email),
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        if (_passes(state)) return child;
        return const SizedBox.shrink(); // hidden entirely
      },
    );
  }

  bool _passes(AuthAuthenticated auth) {
    // ── Permission checks ────────────────────────────────
    if (permission != null) {
      if (!auth.can(permission!)) return false;
    }

    if (permissions != null && permissions!.isNotEmpty) {
      final passes = requireAll
          ? auth.canAll(permissions!)
          : auth.canAny(permissions!);
      if (!passes) return false;
    }

    // ── Role checks ──────────────────────────────────────
    if (role != null) {
      if (!auth.hasRole(role!)) return false;
    }

    if (roles != null && roles!.isNotEmpty) {
      final passes = requireAllRoles
          ? auth.hasAllRoles(roles!)
          : auth.hasAnyRole(roles!);
      if (!passes) return false;
    }

    return true;
  }
}

// ── Convenience subclasses ────────────────────────────────────

/// Hides child if user is NOT an admin or super-admin.
class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      PermissionGuard(roles: ['admin', 'super-admin'], child: child);
}

/// Hides child if user is NOT a super-admin.
class SuperAdminGuard extends StatelessWidget {
  final Widget child;
  const SuperAdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      PermissionGuard(role: 'super-admin', child: child);
}
