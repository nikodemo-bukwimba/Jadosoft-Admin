// dashboard_page.dart
// ─────────────────────────────────────────────────────────────
// Generic dashboard template — replace the stat cards and
// content sections with your actual domain widgets.
//
// Access: admin + super-admin only (customRole:admin,super-admin
// on the Laravel side). The shell hides the tab entirely for
// non-admins, but this page also self-guards as a second layer.
//
// Demonstrates:
//   - AdminGuard widget wrapping sensitive content
//   - PermissionGuard wrapping individual action buttons
//   - Reading active session roles/permissions
// ─────────────────────────────────────────────────────────────

import 'package:fca/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fca/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/rbac/permission_guard.dart';
import '../../../../core/rbac/rbac_extensions.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Second-layer guard — page renders nothing if not admin.
        // The shell tab is already hidden for non-admins.
        if (state is! AuthAuthenticated || !state.canViewDashboard) {
          return const SizedBox.shrink();
        }

        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              // Only super-admins see the settings action
              SuperAdminGuard(
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Admin settings',
                  onPressed: () {
                    // TODO: navigate to admin settings
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              // TODO: trigger your dashboard data reload here
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome row ──────────────────────
                      _WelcomeRow(
                        auth: state,
                        scheme: scheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 24),

                      // ── Role badge ────────────────────────
                      _RoleBanner(
                        auth: state,
                        scheme: scheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 24),

                      // ── Stat cards (template placeholders) ─
                      Text(
                        'Overview',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatCardGrid(scheme: scheme, textTheme: textTheme),
                      const SizedBox(height: 24),

                      // ── Permission-gated action buttons ───
                      Text(
                        'Quick Actions',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _QuickActions(scheme: scheme),
                      const SizedBox(height: 24),

                      // ── RBAC debug panel ──────────────────
                      // Shows in debug mode to test access control.
                      // Remove or gate behind kDebugMode in production.
                      _RbacDebugPanel(
                        auth: state,
                        scheme: scheme,
                        textTheme: textTheme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Welcome row ───────────────────────────────────────────────
class _WelcomeRow extends StatelessWidget {
  final AuthAuthenticated auth;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _WelcomeRow({
    required this.auth,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            _initials(auth.displayName),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${auth.activeSession.user.name.split(' ').first}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                auth.primaryRoleName,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Role banner ───────────────────────────────────────────────
class _RoleBanner extends StatelessWidget {
  final AuthAuthenticated auth;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _RoleBanner({
    required this.auth,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    IconData roleIcon;

    if (auth.isSuperAdmin) {
      bgColor = scheme.errorContainer;
      fgColor = scheme.onErrorContainer;
      roleIcon = Icons.security;
    } else {
      bgColor = scheme.secondaryContainer;
      fgColor = scheme.onSecondaryContainer;
      roleIcon = Icons.admin_panel_settings_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(roleIcon, color: fgColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              auth.isSuperAdmin
                  ? 'Super Admin — full system access'
                  : 'Admin — management access',
              style: textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card grid (template) ─────────────────────────────────
class _StatCardGrid extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _StatCardGrid({required this.scheme, required this.textTheme});

  // Replace these with real data from your dashboard BLoC/use case
  static const _cards = [
    (label: 'Total Users', value: '—', icon: Icons.people_outline),
    (label: 'Revenue', value: '—', icon: Icons.attach_money),
    (label: 'Subscriptions', value: '—', icon: Icons.card_membership_outlined),
    (label: 'Payments', value: '—', icon: Icons.payment_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 500 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: _cards
              .map(
                (card) => _StatCard(
                  label: card.label,
                  value: card.value,
                  icon: card.icon,
                  scheme: scheme,
                  textTheme: textTheme,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick actions (permission-gated) ──────────────────────────
class _QuickActions extends StatelessWidget {
  final ColorScheme scheme;
  const _QuickActions({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Visible to anyone with users.view
        PermissionGuard(
          permission: 'users.view',
          child: _ActionChip(
            icon: Icons.people_outline,
            label: 'View Users',
            onTap: () {
              /* TODO */
            },
          ),
        ),

        // Visible to anyone with users.create
        PermissionGuard(
          permission: 'users.create',
          child: _ActionChip(
            icon: Icons.person_add_outlined,
            label: 'Create User',
            onTap: () {
              /* TODO */
            },
          ),
        ),

        // Visible to anyone with subscriptions.view
        PermissionGuard(
          permission: 'subscriptions.view',
          child: _ActionChip(
            icon: Icons.card_membership_outlined,
            label: 'Subscriptions',
            onTap: () {
              /* TODO */
            },
          ),
        ),

        // Visible to anyone with payments.view
        PermissionGuard(
          permission: 'payments.view',
          child: _ActionChip(
            icon: Icons.payment_outlined,
            label: 'Payments',
            onTap: () {
              /* TODO */
            },
          ),
        ),

        // Super-admin only
        SuperAdminGuard(
          child: _ActionChip(
            icon: Icons.shield_outlined,
            label: 'Manage Roles',
            onTap: () {
              /* TODO */
            },
          ),
        ),

        // Analytics permission
        PermissionGuard(
          permission: 'analytics.view',
          child: _ActionChip(
            icon: Icons.bar_chart_outlined,
            label: 'Analytics',
            onTap: () {
              /* TODO */
            },
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── RBAC debug panel ──────────────────────────────────────────
// Shows current user's roles and a sample permission check.
// Useful during development to verify access control is working.
class _RbacDebugPanel extends StatelessWidget {
  final AuthAuthenticated auth;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _RbacDebugPanel({
    required this.auth,
    required this.scheme,
    required this.textTheme,
  });

  // Permissions to test — a representative sample
  static const _testPerms = [
    'users.view',
    'users.create',
    'users.edit',
    'users.delete',
    'roles.manage',
    'subscriptions.view',
    'subscriptions.manage',
    'payments.view',
    'payments.manage',
    'analytics.view',
    'settings.manage',
    'feedback.manage',
    'help.manage',
    'financial.view',
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  size: 18,
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'RBAC Debug Panel',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.tertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${auth.activeSession.permissions.length} permissions',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Remove this panel before production.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Roles
            Text(
              'Roles:',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: auth.activeSession.user.roles
                  .map(
                    (r) => Chip(
                      label: Text(r.slug),
                      backgroundColor: scheme.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: scheme.onPrimaryContainer,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 12),

            // Permission check table
            Text(
              'Permission checks:',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ..._testPerms.map((slug) {
              final has = auth.can(slug);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      has ? Icons.check_circle : Icons.cancel_outlined,
                      size: 14,
                      color: has ? scheme.primary : scheme.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      slug,
                      style: textTheme.bodySmall?.copyWith(
                        color: has
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant.withOpacity(0.5),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
