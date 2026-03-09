// account_picker_page.dart
// ─────────────────────────────────────────────────────────────
// Shown in two scenarios:
//   1. After logging out when other saved accounts still exist
//      (AuthNeedsAccountPicker → GoRouter redirect → /account-picker)
//   2. When user taps "Add account" from profile or home
//      (context.push(AppRouter.accountPicker, extra: {'mode': 'add'}))
//
// Navigation:
//   Switch account success  → BlocListener sees AuthAuthenticated → go /home
//   "Sign in to another"    → context.push(AppRouter.login, extra: addAccount:true)
//   "Create account"        → context.push(AppRouter.register, extra: addAccount:true)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/account_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

enum AccountPickerMode { picker, add }

class AccountPickerPage extends StatelessWidget {
  final AccountPickerMode mode;

  const AccountPickerPage({super.key, this.mode = AccountPickerMode.picker});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      // ── Navigate away when a switch completes ─────────────────────────────
      // The global redirect (app_router.dart) no longer bounces authenticated
      // users away from /account-picker, so the PAGE is responsible for
      // navigating to /home after a successful account switch.
      listenWhen: (previous, current) =>
          // Only react to a meaningful state change — ignore initial build.
          previous != current,
      listener: (context, state) {
        switch (state) {
          case AuthAuthenticated():
            // Switch succeeded (or add-account login succeeded if user ended
            // up here). Go home and clear the navigation stack.
            context.go(AppRouter.home);
          case AuthUnauthenticated():
            // Every account was removed — go to login.
            context.go(AppRouter.login);
          default:
            break;
        }
      },
      builder: (context, state) {
        // ── Derive live data from the current BLoC state ─────────────────────
        // This is the critical fix: read savedAccounts directly from the
        // current state so the list is never stale.
        final savedAccounts = switch (state) {
          AuthAuthenticated s => s.savedAccounts,
          AuthAccountsUpdated s => s.savedAccounts,
          AuthNeedsAccountPicker s => s.savedAccounts,
          _ => <AccountSession>[],
        };

        // The currently active account (null when unauthenticated / needs-picker).
        final activeEmail = switch (state) {
          AuthAuthenticated s => s.activeSession.user.email,
          _ => null,
        };

        final isLoading = state is AuthLoading || state is AuthSwitching;

        return Scaffold(
          // Show a back button only when the user deliberately pushed here
          // (add-account mode) — not when redirected here after logout.
          appBar: mode == AccountPickerMode.add
              ? AppBar(leading: const BackButton())
              : null,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ─────────────────────────────────
                      _Header(mode: mode, scheme: scheme, textTheme: textTheme),
                      const SizedBox(height: 32),

                      // ── Saved accounts list ────────────────────
                      if (savedAccounts.isNotEmpty) ...[
                        Text(
                          'Saved accounts',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: savedAccounts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final account = savedAccounts[index];
                              final isActive =
                                  account.user.email == activeEmail;
                              return _AccountCard(
                                account: account,
                                isActive: isActive,
                                isLoading: isLoading,
                                onTap: isActive || isLoading
                                    ? null
                                    : () => context.read<AuthBloc>().add(
                                        AuthSwitchAccountRequested(
                                          account.user.email,
                                        ),
                                      ),
                                onRemove: isLoading
                                    ? null
                                    : () => _confirmRemove(
                                        context,
                                        account,
                                        scheme,
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _Divider(scheme: scheme, textTheme: textTheme),
                        const SizedBox(height: 24),
                      ],

                      // ── Add / login new account ────────────────
                      // Always pass addAccount:true so LoginPage / RegisterPage
                      // show the correct AppBar and navigate back properly.
                      FilledButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Sign in to another account'),
                        onPressed: isLoading
                            ? null
                            : () => context.push(
                                AppRouter.login,
                                extra: {'addAccount': true},
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Create new account'),
                        onPressed: isLoading
                            ? null
                            : () => context.push(
                                AppRouter.register,
                                extra: {'addAccount': true},
                              ),
                      ),

                      // ── Loading indicator ──────────────────────
                      if (isLoading) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ],
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

  Future<void> _confirmRemove(
    BuildContext context,
    AccountSession account,
    ColorScheme scheme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove account?'),
        content: Text(
          'Remove ${account.user.email} from this device?\n'
          'You can always sign back in later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(
        AuthLogoutAccountRequested(account.user.email),
      );
    }
  }
}

// ── Header ────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AccountPickerMode mode;
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _Header({
    required this.mode,
    required this.scheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isAdd = mode == AccountPickerMode.add;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isAdd ? Icons.person_add_outlined : Icons.switch_account_outlined,
            size: 28,
            color: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isAdd ? 'Add account' : 'Choose account',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAdd
              ? 'Sign in to add another account'
              : 'Select an account to continue',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Divider ───────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;

  const _Divider({required this.scheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: scheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}

// ── Account card ──────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final AccountSession account;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _AccountCard({
    required this.account,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = account.user;

    return Card(
      elevation: 0,
      color: isActive
          ? scheme.primaryContainer.withOpacity(0.4)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: scheme.primary.withOpacity(0.4))
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: isActive
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          child: Text(
            _initials(user.displayName),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isActive
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
        title: Text(
          user.displayName,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: textTheme.bodySmall),
            if (user.primaryRole != null)
              Text(
                user.primaryRole!.name,
                style: textTheme.labelSmall?.copyWith(color: scheme.primary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
            if (!isActive && onTap != null)
              SizedBox(
                height: 32,
                child: FilledButton.tonal(
                  onPressed: isLoading ? null : onTap,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Switch'),
                ),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Remove',
              onPressed: isLoading ? null : onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
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
