// account_switcher_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/app_router.dart';
import '../../domain/entities/account_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AccountSwitcherSheet extends StatefulWidget {
  /// Snapshot of the active session at the time the sheet opened.
  /// Used only as a fallback until the first BlocBuilder rebuild.
  final AccountSession activeSession;

  const AccountSwitcherSheet({super.key, required this.activeSession});

  static Future<void> show(
    BuildContext context, {
    required AccountSession activeSession,
    required List<AccountSession> savedAccounts, // kept for API compat
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: AccountSwitcherSheet(activeSession: activeSession),
      ),
    );
  }

  @override
  State<AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<AccountSwitcherSheet> {
  // ── Cache last known non-empty accounts list ───────────────
  // BLoC emits AuthSwitching (no accounts) between states. Without
  // caching the list goes blank mid-transition. If the switch FAILS,
  // AuthFailureState is emitted (also no accounts); without caching the
  // list disappears permanently and the user has no way to retry.
  List<AccountSession> _cachedAccounts = [];
  late AccountSession _cachedActive;

  @override
  void initState() {
    super.initState();
    _cachedActive = widget.activeSession;
  }

  /// Returns the best available list and updates the cache when richer
  /// data arrives.
  List<AccountSession> _liveAccounts(AuthState state) {
    switch (state) {
      case AuthAuthenticated():
        _cachedActive = state.activeSession;
        _cachedAccounts = state.savedAccounts;
      case AuthAccountsUpdated():
        _cachedActive = state.activeSession;
        _cachedAccounts = state.savedAccounts;
      default:
        break;
    }
    return _cachedAccounts;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        switch (state) {
          // ── Close sheet on clean transitions ────────────────
          case AuthAuthenticated():
          case AuthAccountsUpdated():
          case AuthNeedsAccountPicker():
          case AuthUnauthenticated():
            if (context.mounted) Navigator.of(context).pop();

          // ── Show error but KEEP sheet open so user can retry ─
          // Previously AuthFailureState was unhandled — switch silently
          // did nothing and the user had no idea why.
          case AuthFailureState():
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

          default:
            break;
        }
      },
      builder: (context, state) {
        final accounts = _liveAccounts(state);
        final isLoading = state is AuthLoading || state is AuthSwitching;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              // ── Handle ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text('Accounts', style: textTheme.titleLarge),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add account'),
                      onPressed: isLoading
                          ? null
                          : () {
                              final router = GoRouter.of(context);
                              Navigator.of(context).pop();
                              router.push(
                                AppRouter.login,
                                extra: {'addAccount': true},
                              );
                            },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Account list (live + cached) ─────────────────
              Expanded(
                child: accounts.isEmpty && !isLoading
                    ? Center(
                        child: Text(
                          'No saved accounts',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : accounts.isEmpty && isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          final isActive =
                              account.user.email == _cachedActive.user.email;

                          return _AccountTile(
                            account: account,
                            isActive: isActive,
                            isLoading: isLoading,
                            onSwitch: isActive
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    AuthSwitchAccountRequested(
                                      account.user.email,
                                    ),
                                  ),
                            onRemove: () => _confirmRemove(context, account),
                          );
                        },
                      ),
              ),

              // ── Logout current ───────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign out of this account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withOpacity(0.5)),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                          },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AccountSession account,
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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

// ── Single account tile ───────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final AccountSession account;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onSwitch;
  final VoidCallback onRemove;

  const _AccountTile({
    required this.account,
    required this.isActive,
    required this.isLoading,
    required this.onSwitch,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = account.user;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: isActive
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        child: Text(
          _initials(user.displayName),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isActive
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(
        user.displayName,
        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        user.email,
        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
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
          : SizedBox(
              width: 80,
              child: FilledButton.tonal(
                // Disable only during loading so user cannot double-tap.
                onPressed: isLoading ? null : onSwitch,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Switch'),
              ),
            ),
      onLongPress: isLoading ? null : onRemove,
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
