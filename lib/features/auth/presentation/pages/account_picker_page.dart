// account_picker_page.dart
// ─────────────────────────────────────────────────────────────
// Shown in two scenarios:
//   1. After logging out when other saved accounts still exist
//   2. When user taps "Add account" from profile or home
//
// Mode is passed via route arguments:
//   { 'mode': 'picker' }  → choose existing or add new
//   { 'mode': 'add' }     → same UI but "add new" is more prominent
//
// Actions:
//   - Tap an account tile  → switch to it (AuthSwitchAccountRequested)
//   - "Sign in to another" → LoginPage (addAccount: true)
//   - "Create account"     → RegisterPage
//   - Remove account       → AuthLogoutAccountRequested
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Only navigate if THIS page is the current top route.
          // If the user tapped "Sign in to another account" and /login is
          // now on top of us, isCurrent is false — we stay silent and let
          // LoginPage handle it with pushNamedAndRemoveUntil (full stack clear).
          // If the user switched directly from an account tile in this picker,
          // isCurrent is true and we do the navigation ourselves.
          if (ModalRoute.of(context)?.isCurrent == true) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
          }
        }
      },
      builder: (context, state) {
        // Determine saved accounts — works both during AuthAuthenticated
        // (add-account mode) and after logout (accounts still in storage
        // but state may be AuthUnauthenticated with no active session).
        final savedAccounts = switch (state) {
          AuthAuthenticated s => s.savedAccounts,
          AuthAccountsUpdated s => s.savedAccounts,
          AuthNeedsAccountPicker s => s.savedAccounts, // ← after logout
          _ => <AccountSession>[],
        };

        final isLoading = state is AuthLoading || state is AuthSwitching;

        return Scaffold(
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
                      // ── Header ───────────────────────────────
                      _Header(mode: mode, scheme: scheme, textTheme: textTheme),
                      const SizedBox(height: 32),

                      // ── Saved accounts ────────────────────────
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
                              return _AccountCard(
                                account: account,
                                isLoading: isLoading,
                                onTap: () => context.read<AuthBloc>().add(
                                  AuthSwitchAccountRequested(
                                    account.user.email,
                                  ),
                                ),
                                onRemove: () =>
                                    _confirmRemove(context, account, scheme),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        _Divider(scheme: scheme, textTheme: textTheme),
                        const SizedBox(height: 24),
                      ],

                      // ── Add / login new account ───────────────
                      FilledButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Sign in to another account'),
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pushNamed(
                                '/login',
                                arguments: {'addAccount': true},
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Create new account'),
                        onPressed: isLoading
                            ? null
                            : () =>
                                  Navigator.of(context).pushNamed('/register'),
                      ),

                      // ── Loading indicator ─────────────────────
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
        const SizedBox(height: 20),
        Text(
          isAdd ? 'Add account' : 'Choose account',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAdd
              ? 'Sign in to add another account or create a new one.'
              : 'Continue with a saved account or sign in to another.',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Account card ──────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final AccountSession account;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _AccountCard({
    required this.account,
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
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _initials(user.displayName),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.email,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (user.primaryRole != null)
                      Text(
                        user.primaryRole!.name,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: Icon(
                  Icons.person_remove_outlined,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                tooltip: 'Remove',
                onPressed: isLoading ? null : onRemove,
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
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

// ── Divider with label ────────────────────────────────────────
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
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}
