// home_page.dart
// ─────────────────────────────────────────────────────────────
// Placeholder home page shown after login.
// Replace body content with your actual home feature widget,
// or generate a Level 4 feature and swap HomeTab() in
// shell_nav_items.dart.
//
// Navigation:
//   Logout / unauthenticated → GoRouter redirect handles it
//   "Add another account"    → context.push(AppRouter.login)
//                              (addAccount handled by LoginPage itself)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/account_switcher_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Guard: GoRouter redirect handles unauthenticated navigation.
        // Only render when authenticated.
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = state.activeSession;
        final user = session.user;
        final accounts = state.savedAccounts;
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            actions: [
              // ── Account avatar / switcher ───────────────
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => AccountSwitcherSheet.show(
                    context,
                    activeSession: session,
                    savedAccounts: accounts,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          _initials(user.displayName),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (accounts.length > 1)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${accounts.length}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Welcome card ─────────────────────
                      Card(
                        color: scheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: scheme.primary.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  _initials(user.displayName),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome, ${user.displayName}',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onPrimaryContainer,
                                      ),
                                    ),
                                    Text(
                                      user.email,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: scheme.onPrimaryContainer
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    if (user.primaryRole != null) ...[
                                      const SizedBox(height: 4),
                                      _RoleBadge(
                                        label: user.primaryRole!.name,
                                        scheme: scheme,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Session info ─────────────────────
                      Text('Session Info', style: textTheme.titleSmall),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.verified_outlined,
                        label: 'Email verified',
                        value: user.isActive ? 'Yes' : 'No',
                        scheme: scheme,
                      ),
                      _InfoRow(
                        icon: Icons.card_membership_outlined,
                        label: 'Subscription',
                        value: user.subscriptionStatus,
                        scheme: scheme,
                      ),
                      _InfoRow(
                        icon: Icons.shield_outlined,
                        label: 'Permissions',
                        value: '${session.permissions.length} granted',
                        scheme: scheme,
                      ),

                      const SizedBox(height: 24),

                      // ── Saved accounts summary ────────────
                      if (accounts.length > 1) ...[
                        Text('Signed-in accounts', style: textTheme.titleSmall),
                        const SizedBox(height: 12),
                        ...accounts.map((acc) {
                          final isActive = acc.user.email == user.email;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: isActive
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHighest,
                              child: Text(
                                _initials(acc.user.displayName),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            title: Text(acc.user.displayName),
                            subtitle: Text(acc.user.email),
                            trailing: isActive
                                ? Chip(
                                    label: const Text('Active'),
                                    padding: EdgeInsets.zero,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSecondaryContainer,
                                    ),
                                    backgroundColor: scheme.secondaryContainer,
                                  )
                                : TextButton(
                                    onPressed: () =>
                                        context.read<AuthBloc>().add(
                                          AuthSwitchAccountRequested(
                                            acc.user.email,
                                          ),
                                        ),
                                    child: const Text('Switch'),
                                  ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 16),

                      // ── Add account ───────────────────────
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Add another account'),
                        onPressed: () => context.push(AppRouter.login),
                      ),

                      const SizedBox(height: 12),

                      // ── Logout ────────────────────────────
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Sign out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5),
                          ),
                        ),
                        onPressed: () =>
                            context.read<AuthBloc>().add(AuthLogoutRequested()),
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ── Small widgets ─────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _RoleBadge({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 24),
          Text(value, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
