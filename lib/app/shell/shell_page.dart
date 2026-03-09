// shell_page.dart
// ─────────────────────────────────────────────────────────────
// Authenticated app scaffold — wraps AdaptiveNavShell.
//
// MIGRATION: Replaced IndexedStack + NavigationBar/Drawer approach
// with AdaptiveNavShell from customnav/. GoRouter's ShellRoute now
// owns which page is active; this widget only provides the chrome.
//
// Responsibilities (and only these):
//   - Wrap AdaptiveNavShell with RBAC-aware nav items
//   - Supply AppBar actions (account switcher)
//   - Supply rail footer (logout)
//   - Re-render nav items when auth state / account changes
//
// What does NOT belong here:
//   - Which nav items exist  → shell_nav_items.dart
//   - Page content           → individual feature pages
//   - Auth redirect logic    → app_router.dart (_redirect)
//   - Permission definitions → core/rbac/rbac_extensions.dart
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../customnav/navigation.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/widgets/account_switcher_sheet.dart';
import 'shell_nav_items.dart';

class ShellPage extends StatelessWidget {
  /// The currently active page widget provided by GoRouter's ShellRoute.
  final Widget child;

  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // Only rebuild when auth type changes or the active account switches.
      // Prevents unnecessary AdaptiveNavShell rebuilds on unrelated state.
      buildWhen: (prev, curr) =>
          prev.runtimeType != curr.runtimeType ||
          (curr is AuthAuthenticated &&
              prev is AuthAuthenticated &&
              curr.activeSession.user.email != prev.activeSession.user.email),
      builder: (context, state) {
        final navItems = state is AuthAuthenticated
            ? ShellNavItems.buildNavItems(auth: state)
            : const <NavItem>[];

        return AdaptiveNavShell(
          router: GoRouter.of(context),
          items: navItems,
          showBackButton: true,
          logo: const _ShellLogo(),
          appBarActions: _appBarActions(context, state),
          railFooter: _RailFooter(state: state),
          child: child,
        );
      },
    );
  }

  // ── AppBar actions ────────────────────────────────────────
  List<Widget> _appBarActions(BuildContext context, AuthState state) {
    if (state is! AuthAuthenticated) return const [];
    return [_AccountAvatarButton(auth: state), const SizedBox(width: 8)];
  }
}

// ── Shell logo ────────────────────────────────────────────────

class _ShellLogo extends StatelessWidget {
  const _ShellLogo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FCA',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Account avatar button ─────────────────────────────────────
// Tapping opens the AccountSwitcherSheet bottom sheet.

class _AccountAvatarButton extends StatelessWidget {
  final AuthAuthenticated auth;
  const _AccountAvatarButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = auth.activeSession.user;
    final hasMultiple = auth.savedAccounts.length > 1;

    return GestureDetector(
      // ✅ FIX: AccountSwitcherSheet.show now takes only context.
      // It reads live savedAccounts and activeSession from the BLoC itself
      // so the sheet is never stale.
      onTap: () => AccountSwitcherSheet.show(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Avatar ──────────────────────────────────────
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

          // ── Multi-account badge ──────────────────────────
          if (hasMultiple)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
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

// ── Rail footer ───────────────────────────────────────────────
// Pinned at the bottom of the nav rail / drawer.

class _RailFooter extends StatelessWidget {
  final AuthState state;
  const _RailFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state is! AuthAuthenticated) return const SizedBox.shrink();

    final auth = state as AuthAuthenticated;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = auth.activeSession.user;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: scheme.outlineVariant, height: 1),
        const SizedBox(height: 4),

        // ── User info row ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _initials(user.displayName),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.email,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Logout button ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.logout, size: 16, color: scheme.error),
              label: Text(
                'Sign out',
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.error.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthLogoutRequested()),
            ),
          ),
        ),
      ],
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
