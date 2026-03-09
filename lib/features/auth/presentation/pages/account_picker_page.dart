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

class AccountPickerPage extends StatelessWidget {
  final AccountPickerMode mode;
  final List<AccountSession> initialAccounts;
  final String? initialActiveEmail;

  const AccountPickerPage({
    super.key,
    this.mode = AccountPickerMode.picker,
    this.initialAccounts = const [],
    this.initialActiveEmail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<AuthBloc, AuthState>(
      // Only react to meaningful transitions, not same-type re-emissions.
      // Without this, opening the picker while AuthAuthenticated (add mode)
      // triggers context.go(home) on the very next AuthAuthenticated emission.
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRouter.home);
        } else if (state is AuthUnauthenticated) {
          context.go(AppRouter.login);
        }
      },
      builder: (context, state) {
        // Derive live accounts from current BLoC state.
        // Fall back to initialAccounts (read from authBloc.state at route
        // build time) when the BLoC is in a transient state like
        // AuthLoading or AuthSwitching — so the list never disappears
        // during a switch operation.
        List<AccountSession> savedAccounts = initialAccounts;
        String? activeEmail = initialActiveEmail;

        if (state is AuthAuthenticated) {
          savedAccounts = state.savedAccounts;
          activeEmail = state.activeSession.user.email;
        } else if (state is AuthNeedsAccountPicker) {
          savedAccounts = state.savedAccounts;
          activeEmail = null;
        } else if (state is AuthAccountsUpdated) {
          savedAccounts = state.savedAccounts;
          activeEmail = state.activeSession.user.email;
        }
        // AuthLoading / AuthSwitching / AuthFailureState:
        //   keep showing the last known list (initialAccounts / previous state)

        final isLoading = state is AuthLoading || state is AuthSwitching;

        return Scaffold(
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
                      _Header(mode: mode, scheme: scheme, textTheme: textTheme),
                      const SizedBox(height: 32),

                      // ── Account list ──────────────────────────
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
                        _OrDivider(scheme: scheme, textTheme: textTheme),
                        const SizedBox(height: 24),
                      ],

                      // ── Add / sign in ─────────────────────────
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

// ── "or" divider ──────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  final ColorScheme scheme;
  final TextTheme textTheme;
  const _OrDivider({required this.scheme, required this.textTheme});

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
            if (!isActive)
              SizedBox(
                height: 32,
                child: FilledButton.tonal(
                  onPressed: isLoading ? null : onTap,
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
