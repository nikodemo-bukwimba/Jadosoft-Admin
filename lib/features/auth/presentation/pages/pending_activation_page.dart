// pending_activation_page.dart
//
// State-aware page covering two distinct situations:
//
//   State A — NO ORG
//     User registered but has no org membership yet.
//     Options: Enter invitation token  |  Create a new organization
//
//   State B — ORG PENDING APPROVAL
//     User already created an org but it hasn't been approved yet.
//     Shows progress info and a "Check Again" refresh.
//
// Both states are determined from OrgContext at build time.
// The page is self-contained: all async calls go through sl<> directly,
// with no dependency on OrganizationBloc.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/context/org_context.dart';
import '../../../organization/domain/repositories/organization_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../bloc/auth_state.dart';

class PendingActivationPage extends StatefulWidget {
  const PendingActivationPage({super.key});

  @override
  State<PendingActivationPage> createState() => _PendingActivationPageState();
}

class _PendingActivationPageState extends State<PendingActivationPage> {
  // After a successful org creation in this session we flip this flag
  // so the UI shows the "awaiting approval" state immediately —
  // without needing a full session refresh.
  bool _justCreatedOrg = false;

  // AFTER
  @override
  Widget build(BuildContext context) {
    final orgContext = sl<OrgContext>();
    final isPending = _justCreatedOrg || orgContext.isOrgPendingApproval;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go(AppRouter.login);
        } else if (state is AuthNeedsAccountPicker) {
          context.go(AppRouter.accountPicker);
        } else if (state is AuthAuthenticated) {
          context.go(
            AppRouter.home,
          ); // ← this fires after session refresh succeeds
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: isPending
                    ? _OrgPendingApprovalBody(
                        orgName: orgContext.rootOrgName,
                        onCheckAgain: _checkAgain,
                        onLogout: _logout,
                      )
                    : _NoOrgBody(
                        onEnterToken: () => _showAcceptDialog(context),
                        onCreateOrg: () => _showCreateOrgDialog(context),
                        onCheckAgain: _checkAgain,
                        onLogout: _logout,
                      ),
              ),
            ),
          ),
        ),
      ),
    ); // closes BlocListener
  }

  // ── Actions ───────────────────────────────────────────────

  void _checkAgain(BuildContext context) {
    context.read<AuthBloc>().add(AuthSessionRefreshRequested());
  }

  void _logout(BuildContext context) {
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  void _showAcceptDialog(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => _AcceptInvitationDialog(authBloc: authBloc),
    );
  }

  void _showCreateOrgDialog(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateOrgDialog(authBloc: authBloc),
    ).then((created) {
      if (created == true && mounted) {
        setState(() => _justCreatedOrg = true);
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State A — User has no org membership
// ─────────────────────────────────────────────────────────────────────────────

class _NoOrgBody extends StatelessWidget {
  final VoidCallback onEnterToken;
  final VoidCallback onCreateOrg;
  final void Function(BuildContext) onCheckAgain;
  final void Function(BuildContext) onLogout;

  const _NoOrgBody({
    required this.onEnterToken,
    required this.onCreateOrg,
    required this.onCheckAgain,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Icon ───────────────────────────────────────────
        _StatusIcon(
          icon: Icons.hourglass_top_rounded,
          color: scheme.secondaryContainer,
          iconColor: scheme.onSecondaryContainer,
        ),
        const SizedBox(height: 32),

        // ── Headline ───────────────────────────────────────
        Text(
          'Account Pending Activation',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Your account has been created. Ask your manager to send '
          'you an invitation, then enter the token below to gain access.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // ── Divider with label ─────────────────────────────
        _SectionDivider(label: 'Join an existing organization'),
        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: onEnterToken,
          icon: const Icon(Icons.vpn_key_outlined, size: 18),
          label: const Text('Enter Invitation Token'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Divider with label ─────────────────────────────
        _SectionDivider(label: 'Or create your own'),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: onCreateOrg,
          icon: const Icon(Icons.add_business_outlined, size: 18),
          label: const Text('Create Organization'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
        const SizedBox(height: 24),

        // ── Check / Logout ─────────────────────────────────
        Builder(
          builder: (ctx) => OutlinedButton.icon(
            onPressed: () => onCheckAgain(ctx),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Check Again'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (ctx) => TextButton.icon(
            onPressed: () => onLogout(ctx),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State B — Org exists but is pending admin approval
// ─────────────────────────────────────────────────────────────────────────────

class _OrgPendingApprovalBody extends StatelessWidget {
  final String? orgName;
  final void Function(BuildContext) onCheckAgain;
  final void Function(BuildContext) onLogout;

  const _OrgPendingApprovalBody({
    this.orgName,
    required this.onCheckAgain,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Icon ───────────────────────────────────────────
        _StatusIcon(
          icon: Icons.domain_verification_outlined,
          color: scheme.tertiaryContainer,
          iconColor: scheme.onTertiaryContainer,
        ),
        const SizedBox(height: 32),

        // ── Headline ───────────────────────────────────────
        Text(
          'Organization Awaiting Approval',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        if (orgName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  orgName!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Text(
          'Your organization has been submitted and is waiting for platform '
          'admin review.\n\n'
          'You will gain full access once it is approved. '
          'This usually takes less than 24 hours.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),

        // ── What happens next info card ────────────────────
        _InfoCard(
          items: const [
            _InfoItem(
              icon: Icons.admin_panel_settings_outlined,
              text: 'A platform admin reviews your organization details',
            ),
            _InfoItem(
              icon: Icons.mark_email_read_outlined,
              text: 'You\'ll receive a notification when approved',
            ),
            _InfoItem(
              icon: Icons.rocket_launch_outlined,
              text: 'Your full dashboard unlocks upon approval',
            ),
          ],
        ),
        const SizedBox(height: 28),

        // ── Check Again ────────────────────────────────────
        Builder(
          builder: (ctx) => FilledButton.icon(
            onPressed: () => onCheckAgain(ctx),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Check Approval Status'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (ctx) => TextButton.icon(
            onPressed: () => onLogout(ctx),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: Accept Invitation Token (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class _AcceptInvitationDialog extends StatefulWidget {
  final AuthBloc authBloc;
  const _AcceptInvitationDialog({required this.authBloc});

  @override
  State<_AcceptInvitationDialog> createState() =>
      _AcceptInvitationDialogState();
}

class _AcceptInvitationDialogState extends State<_AcceptInvitationDialog> {
  final _tokenCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _tokenCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please enter an invitation token.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await sl<OrganizationRepository>().acceptInvitation(token);
      if (!mounted) return;
      result.fold(
        (failure) => setState(() {
          _loading = false;
          _error = failure.message;
        }),
        (membership) {
          Navigator.of(context).pop();
          // Wait one frame so BlocListener on PendingActivationPage
          // is mounted before the state change fires.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.authBloc.add(AuthSessionRefreshRequested());
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unexpected error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.group_add_outlined),
          SizedBox(width: 10),
          Text('Accept Invitation'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlueInfoBanner(
            text:
                'Enter the invitation token from your email to join '
                'an organization.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenCtrl,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: 'Invitation Token *',
              hintText: 'Paste your token here',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            maxLines: 2,
            minLines: 1,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('Accept'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: Create Organization  ← NEW
// ─────────────────────────────────────────────────────────────────────────────

class _CreateOrgDialog extends StatefulWidget {
  final AuthBloc authBloc;
  const _CreateOrgDialog({required this.authBloc});

  @override
  State<_CreateOrgDialog> createState() => _CreateOrgDialogState();
}

class _CreateOrgDialogState extends State<_CreateOrgDialog> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _serverError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _serverError = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final repo = sl<OrganizationRepository>();
      final result = await repo.createOrg({'name': _nameCtrl.text.trim()});

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _loading = false;
            _serverError = failure.message;
          });
          // Re-validate to show server error under the field
          _formKey.currentState?.validate();
        },
        (org) {
          Navigator.of(context).pop(true); // true = org was created
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _serverError = 'Unexpected error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.add_business_outlined),
          SizedBox(width: 10),
          Expanded(child: Text('Create Organization')),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BlueInfoBanner(
              text:
                  'After creation your organization will be reviewed by '
                  'a platform admin before becoming active.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Organization Name *',
                hintText: 'e.g. Barick Pharma Ltd',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Name must be at least 2 characters.';
                }
                if (_serverError != null) return _serverError;
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _submit,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_business_outlined),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;

  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 40, color: iconColor),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _BlueInfoBanner extends StatelessWidget {
  final String text;
  const _BlueInfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 18, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});
}
