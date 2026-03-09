// account_switcher_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/account_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AccountSwitcherSheet {
  const AccountSwitcherSheet._();

  static Future<void> show(BuildContext context) {
    // Capture the router BEFORE the modal opens so that we can push to it
    // from inside the sheet (the modal has its own Navigator scope).
    final router = GoRouter.of(context);
    final authBloc = context.read<AuthBloc>();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: authBloc,
        child: _AccountSwitcherSheetBody(router: router),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal body — receives the pre-captured router so it can navigate without
// depending on the modal's Navigator scope.
// ─────────────────────────────────────────────────────────────────────────────
class _AccountSwitcherSheetBody extends StatelessWidget {
  final GoRouter router;
  const _AccountSwitcherSheetBody({required this.router});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        // Close the sheet on any auth-transition that means the user's
        // context has changed.
        switch (state) {
          case AuthAuthenticated():
          case AuthAccountsUpdated():
          case AuthNeedsAccountPicker():
          case AuthUnauthenticated():
            if (context.mounted) Navigator.of(context).pop();
          default:
            break;
        }
      },
      builder: (context, state) {
        // ── Read LIVE data from the BLoC ─────────────────────────────────────
        // This is the core fix: instead of relying on the constructor-param
        // snapshot (which was captured when the sheet opened and never updated),
        // we read directly from the current BLoC state.
        final liveAccounts = switch (state) {
          AuthAuthenticated s => s.savedAccounts,
          AuthAccountsUpdated s => s.savedAccounts,
          _ => <AccountSession>[],
        };

        final activeEmail = switch (state) {
          AuthAuthenticated s => s.activeSession.user.email,
          _ => null,
        };

        final isLoading = state is AuthLoading || state is AuthSwitching;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) => Column(
            children: [
              // ── Handle ────────────────────────────────────────
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

              // ── Header ────────────────────────────────────────
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
                              // Pop the sheet first (uses the modal Navigator —
                              // this is correct). Then push the login route
                              // using the pre-captured GoRouter reference.
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

              // ── Account list ──────────────────────────────────
              Expanded(
                child: liveAccounts.isEmpty
                    ? Center(
                        child: Text(
                          'No saved accounts',
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: liveAccounts.length,
                        itemBuilder: (context, index) {
                          final account = liveAccounts[index];
                          final isActive = account.user.email == activeEmail;

                          return _AccountTile(
                            account: account,
                            isActive: isActive,
                            isLoading: isLoading,
                            onSwitch: isActive || isLoading
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    AuthSwitchAccountRequested(
                                      account.user.email,
                                    ),
                                  ),
                            onRemove: isLoading
                                ? null
                                : () => _confirmRemove(context, account),
                          );
                        },
                      ),
              ),

              // ── Sign out current ──────────────────────────────
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
  final VoidCallback? onRemove;

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
          if (!isActive)
            SizedBox(
              height: 32,
              child: FilledButton.tonal(
                onPressed: isLoading ? null : onSwitch,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Switch'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Remove',
            onPressed: isLoading ? null : onRemove,
            visualDensity: VisualDensity.compact,
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
