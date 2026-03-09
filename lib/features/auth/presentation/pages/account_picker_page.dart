// account_picker_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/account_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

enum AccountPickerMode { picker, add }

class AccountPickerPage extends StatefulWidget {
  final AccountPickerMode mode;
  const AccountPickerPage({super.key, this.mode = AccountPickerMode.picker});

  @override
  State<AccountPickerPage> createState() => _AccountPickerPageState();
}

class _AccountPickerPageState extends State<AccountPickerPage> {
  // ── Cache last known non-empty accounts list ───────────────
  // BLoC transitions through AuthSwitching/AuthLoading which carry no
  // accounts. Without caching, the list disappears mid-transition and
  // if a switch fails the page is stuck showing nothing.
  List<AccountSession> _cachedAccounts = [];

  List<AccountSession> _accountsFromState(AuthState state) {
    final accounts = switch (state) {
      AuthAuthenticated s => s.savedAccounts,
      AuthAccountsUpdated s => s.savedAccounts,
      AuthNeedsAccountPicker s => s.savedAccounts,
      _ => null,
    };
    if (accounts != null && accounts.isNotEmpty) {
      _cachedAccounts = accounts;
    }
    return _cachedAccounts;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      // ── Show error snackbar on failure ─────────────────────
      // Without this, a failed switch emits AuthFailureState and the
      // BlocBuilder rebuilds with _cachedAccounts (list stays visible)
      // but the user sees zero feedback about what went wrong.
      listener: (context, state) {
        if (state is AuthFailureState) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
        }
      },
      builder: (context, state) {
        final savedAccounts = _accountsFromState(state);
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
                      _Header(
                        mode: widget.mode,
                        scheme: scheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: 32),

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
