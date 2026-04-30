// lib/features/organization/presentation/pages/invitations_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/org_invitation_entity.dart';
import '../bloc/organization_bloc.dart';
import '../bloc/organization_event.dart';
import '../bloc/organization_state.dart';

class InvitationsTab extends StatefulWidget {
  const InvitationsTab({super.key});

  @override
  State<InvitationsTab> createState() => _InvitationsTabState();
}

class _InvitationsTabState extends State<InvitationsTab> {
  String _statusFilter = 'pending';

  static const _statusOptions = [
    ('pending',   'Pending'),
    ('accepted',  'Accepted'),
    ('expired',   'Expired'),
    ('cancelled', 'Cancelled'),
    ('all',       'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganizationBloc, OrganizationState>(
      listener: (context, state) {
        if (state is OrganizationOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (state is OrganizationFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Column(
        children: [
          // ── Status filter bar ────────────────────────────────
          _StatusFilterBar(
            selected: _statusFilter,
            options: _statusOptions,
            onChanged: (v) {
              setState(() => _statusFilter = v);
              context.read<OrganizationBloc>().add(
                InvitationsLoadRequested(status: v),
              );
            },
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<OrganizationBloc, OrganizationState>(
              buildWhen: (_, s) =>
                  s is InvitationsLoaded || s is OrganizationLoading,
              builder: (context, state) {
                if (state is OrganizationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is InvitationsLoaded) {
                  if (state.invitations.isEmpty) {
                    return _EmptyState(status: _statusFilter);
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<OrganizationBloc>().add(
                          InvitationsLoadRequested(status: _statusFilter),
                        ),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: state.invitations.length,
                      itemBuilder: (_, i) => _InvitationCard(
                        invitation: state.invitations[i],
                        onCancel: state.invitations[i].isPending
                            ? () => _confirmCancel(context, state.invitations[i])
                            : null,
                      ),
                    ),
                  );
                }
                // Initial state — trigger load
                return Center(
                  child: FilledButton.icon(
                    onPressed: () => context.read<OrganizationBloc>().add(
                      InvitationsLoadRequested(status: _statusFilter),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Load Invitations'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, OrgInvitationEntity inv) {
    final bloc = context.read<OrganizationBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text('Cancel invitation for ${inv.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(InvitationCancelRequested(inv.id));
            },
            child: const Text('Cancel Invitation'),
          ),
        ],
      ),
    );
  }
}

// ── Status filter chip bar ─────────────────────────────────────────
class _StatusFilterBar extends StatelessWidget {
  final String selected;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  const _StatusFilterBar({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      color: scheme.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: options.length,
        itemBuilder: (_, i) {
          final (value, label) = options[i];
          final isSelected = value == selected;
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(value),
            selectedColor: scheme.primaryContainer,
            checkmarkColor: scheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}

// ── Individual invitation card ─────────────────────────────────────
class _InvitationCard extends StatelessWidget {
  final OrgInvitationEntity invitation;
  final VoidCallback? onCancel;

  const _InvitationCard({required this.invitation, this.onCancel});

  Color _statusColor(BuildContext context) => switch (invitation.status) {
    InvitationStatus.pending   => Colors.blue,
    InvitationStatus.accepted  => Colors.green,
    InvitationStatus.expired   => Colors.orange,
    InvitationStatus.cancelled => Colors.grey,
  };

  String _statusLabel() => switch (invitation.status) {
    InvitationStatus.pending   => 'Pending',
    InvitationStatus.accepted  => 'Accepted',
    InvitationStatus.expired   => 'Expired',
    InvitationStatus.cancelled => 'Cancelled',
  };

  String get _whatsAppMessage =>
      'You have been invited to join *${invitation.orgName}* on Barick Pharma.\n\n'
      'To accept your invitation:\n'
      '1. Open the *Barick Officer* app\n'
      '2. Register or log in with this email: *${invitation.email}*\n'
      '3. On the pending activation screen, tap *Enter Invitation Token*\n'
      '4. Paste this token:\n\n'
      '${invitation.token}\n\n'
      'The invitation expires on ${_formatDate(invitation.expiresAt)}.';

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  Future<void> _copyToken(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invitation.token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final uri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(_whatsAppMessage)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not installed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color  = _statusColor(context);
    final isPending = invitation.isPending;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPending
              ? color.withOpacity(0.3)
              : scheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${invitation.orgName}  ·  ${invitation.roleName}  ·  Level ${invitation.level}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            // ── Expiry ──────────────────────────────────────
            if (isPending) ...[
              const SizedBox(height: 6),
              Text(
                invitation.isExpired
                    ? '⚠ Expired ${_formatDate(invitation.expiresAt)}'
                    : 'Expires ${_formatDate(invitation.expiresAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: invitation.isExpired ? Colors.orange : scheme.onSurfaceVariant,
                ),
              ),
            ],

            // ── Token box (only for pending) ─────────────────
            if (isPending && invitation.token.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  invitation.token,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Action row ────────────────────────────────
              Row(
                children: [
                  // Copy token
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToken(context),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy Token'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // WhatsApp share
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareWhatsApp(context),
                      icon: const Icon(Icons.share, size: 14),
                      label: const Text('WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined),
                      color: scheme.error,
                      tooltip: 'Cancel invitation',
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.errorContainer.withOpacity(0.2),
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String status;
  const _EmptyState({required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'accepted' ? Icons.check_circle_outline : Icons.mail_outline,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            status == 'pending'
                ? 'No pending invitations'
                : 'No $status invitations',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}