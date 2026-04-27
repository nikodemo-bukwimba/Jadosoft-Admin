// pending_activation_page.dart
//
// Self-contained: invitation acceptance is done through a local async call
// to OrganizationRepository (injected via sl<>), so this page has zero
// dependency on OrganizationBloc, which is not provided at this route.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/injection_container.dart'; // adjust path to your sl export
import '../../../organization/domain/repositories/organization_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class PendingActivationPage extends StatelessWidget {
  const PendingActivationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon ─────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 40,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Headline ──────────────────────────────────────
                  Text(
                    'Account Pending Activation',
                    textAlign: TextAlign.center,
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your account has been created but has not been '
                    'assigned a role yet.\n\n'
                    'Ask your administrator to invite you, or enter '
                    'an invitation token if you already received one.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 28),

                  // ── Accept Invitation ─────────────────────────────
                  FilledButton.icon(
                    onPressed: () => _showAcceptDialog(context),
                    icon: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: const Text('Enter Invitation Token'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Check again ───────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<AuthBloc>()
                        .add(AuthSessionRefreshRequested()),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Check Again'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Sign out ──────────────────────────────────────
                  TextButton.icon(
                    onPressed: () =>
                        context.read<AuthBloc>().add(AuthLogoutRequested()),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAcceptDialog(BuildContext context) {
    // Capture AuthBloc BEFORE opening the dialog — the dialog's BuildContext
    // is detached from the page's provider tree.
    final authBloc = context.read<AuthBloc>();
    showDialog<void>(
      context: context,
      builder: (_) => _AcceptInvitationDialog(authBloc: authBloc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Self-contained dialog — manages its own loading / error state locally.
// Calls sl<OrganizationRepository>() directly so OrganizationBloc is
// never needed and the ProviderNotFoundException cannot occur.
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
      final repo = sl<OrganizationRepository>();
      final result = await repo.acceptInvitation(token);

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _loading = false;
            _error = failure.message;
          });
        },
        (membership) {
          final orgName =
              membership['organization']?['name'] as String? ?? 'Organization';

          Navigator.of(context).pop();

          // Trigger a session refresh so the router re-evaluates org context
          // and navigates the user away from this page automatically.
          widget.authBloc.add(AuthSessionRefreshRequested());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have joined $orgName successfully!'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    } catch (e) {
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
          // Info banner
          Container(
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
                    'Enter the invitation token from your email to join '
                    'an organization.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Token field — errorText wires validation inline
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