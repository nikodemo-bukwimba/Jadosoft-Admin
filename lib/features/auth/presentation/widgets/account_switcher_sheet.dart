// account_switcher_sheet.dart
// Fix: FilledButton.tonal in ListTile trailing wrapped in SizedBox
// to prevent BoxConstraints infinite width error.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/account_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AccountSwitcherSheet extends StatelessWidget {
  final AccountSession activeSession;
  final List<AccountSession> savedAccounts;

  const AccountSwitcherSheet({
    super.key,
    required this.activeSession,
    required this.savedAccounts,
  });

  static Future<void> show(
    BuildContext context, {
    required AccountSession activeSession,
    required List<AccountSession> savedAccounts,
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
        child: AccountSwitcherSheet(
          activeSession: activeSession,
          savedAccounts: savedAccounts,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          Navigator.of(context).pop();
        }
      },
      child: DraggableScrollableSheet(
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
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(
                        context,
                      ).pushNamed('/login', arguments: {'addAccount': true});
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Account list ─────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: savedAccounts.length,
                itemBuilder: (context, index) {
                  final account = savedAccounts[index];
                  final isActive =
                      account.user.email == activeSession.user.email;

                  return _AccountTile(
                    account: account,
                    isActive: isActive,
                    onSwitch: isActive
                        ? null
                        : () => context.read<AuthBloc>().add(
                            AuthSwitchAccountRequested(account.user.email),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
  final VoidCallback? onSwitch;
  final VoidCallback onRemove;

  const _AccountTile({
    required this.account,
    required this.isActive,
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
      // ── FIX: constrain trailing Row so buttons don't get infinite width ──
      trailing: isActive
          ? Icon(Icons.check_circle, color: scheme.primary)
          : Row(
              mainAxisSize: MainAxisSize.min, // critical — shrink to content
              children: [
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, size: 20),
                  tooltip: 'Remove account',
                  onPressed: onRemove,
                ),
                // FIX: SizedBox gives the button a finite width
                SizedBox(
                  width: 80,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(80, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onSwitch,
                    child: const Text('Switch'),
                  ),
                ),
              ],
            ),
      onTap: onSwitch,
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
