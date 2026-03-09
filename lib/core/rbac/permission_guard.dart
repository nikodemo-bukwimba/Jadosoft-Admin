// permission_guard.dart
// ─────────────────────────────────────────────────────────────
// Wraps any widget and renders NOTHING if the current user
// does not satisfy the given permission requirement.
//
// DESIGN: Gates on PERMISSIONS, not roles. Roles are display-only.
// Permission slugs match the backend's PlatformPermissionSeeder.
//
// Usage:
//
//   // Hide unless user has 'actors.view' permission
//   PermissionGuard(
//     permission: 'actors.view',
//     child: ActorListButton(),
//   )
//
//   // Hide unless user has ANY of these permissions
//   PermissionGuard(
//     permissions: ['orders.view', 'orders.create'],
//     child: OrderSection(),
//   )
//
//   // Hide unless user has ALL of these permissions
//   PermissionGuard(
//     permissions: ['orders.view', 'orders.approve'],
//     requireAll: true,
//     child: ApproveOrderButton(),
//   )
//
// Generator integration:
//   Generated features use the config's "permission" key:
//     PermissionGuard(
//       permission: 'actor_types.view',  // from feature.config.json
//       child: ...,
//     )
// ─────────────────────────────────────────────────────────────

import 'package:fca/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fca/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'rbac_extensions.dart';

class PermissionGuard extends StatelessWidget {
  /// Single permission slug required.
  final String? permission;

  /// Multiple permission slugs. Combined with [requireAll].
  final List<String>? permissions;

  /// If true, user must have ALL [permissions]. Default: any one is enough.
  final bool requireAll;

  /// Widget to show if check passes.
  final Widget child;

  /// Optional widget to show if check fails (instead of hiding entirely).
  /// Useful for showing a "no access" message in place.
  final Widget? fallback;

  const PermissionGuard({
    super.key,
    required this.child,
    this.permission,
    this.permissions,
    this.requireAll = false,
    this.fallback,
  }) : assert(
         permission != null || permissions != null,
         'PermissionGuard requires at least one of: permission, permissions',
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
        if (state is! AuthAuthenticated) {
          return fallback ?? const SizedBox.shrink();
        }
        if (_passes(state)) return child;
        return fallback ?? const SizedBox.shrink();
      },
    );
  }

  bool _passes(AuthAuthenticated auth) {
    if (permission != null) {
      if (!auth.can(permission!)) return false;
    }

    if (permissions != null && permissions!.isNotEmpty) {
      final passes = requireAll
          ? auth.canAll(permissions!)
          : auth.canAny(permissions!);
      if (!passes) return false;
    }

    return true;
  }
}

// ── Convenience: Dashboard guard ─────────────────────────────
// Uses the 'dashboard.view' permission slug.

class DashboardGuard extends StatelessWidget {
  final Widget child;
  const DashboardGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) =>
      PermissionGuard(permission: 'dashboard.view', child: child);
}
