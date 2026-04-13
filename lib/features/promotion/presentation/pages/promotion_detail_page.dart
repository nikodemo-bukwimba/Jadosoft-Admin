// promotion_detail_page.dart
// ─────────────────────────────────────────────────────────────
// Admin App — Promotion detail with state transition actions.
//
// FIX (Issue 3): After End/Cancel transitions, Nexora maps
// the status back to 'sent'/'failed' → 'active'/'cancelled'.
// Re-fetching from API after these transitions would overwrite
// the local terminal status. Instead, we apply the returned
// entity directly via PromotionStatusOverridden so the UI
// reflects the correct state without a network round-trip.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/promotion_model.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/value_objects/promotion_status.dart';
import '../bloc/promotion_bloc.dart';
import '../bloc/promotion_event.dart';
import '../bloc/promotion_state.dart';
import '../widgets/promotion_status_badge.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PromotionBloc, PromotionState>(
      listener: (context, state) {
        if (state is PromotionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // FIX: Apply the updated entity directly to state.
          // Do NOT call LoadOne — it re-fetches from Nexora which maps
          // 'sent' → 'active', discarding the local 'ended' status.
          if (state.updatedItem != null) {
            context.read<PromotionBloc>().add(
              PromotionStatusOverridden(state.updatedItem!),
            );
          }
        }
        if (state is PromotionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PromotionLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Promotion')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is PromotionDetailLoaded) {
          return _DetailView(item: state.item);
        }
        if (state is PromotionFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Promotion')),
            body: Center(child: Text(state.message)),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Promotion')),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// ─── Detail View ───────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  final PromotionEntity item;
  const _DetailView({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = PromotionStatusX.fromString(item.status);
    final isWide = MediaQuery.of(context).size.width > 768;
    final model = item is PromotionModel ? item as PromotionModel : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        centerTitle: false,
        actions: [
          if (status == PromotionStatus.draft)
            IconButton(
              onPressed: () => context.go('/promotions/${item.id}/edit'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
          PromotionStatusBadge(status: status),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 48 : 16,
          vertical: 16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Broadcast Summary Banner (active/ended) ──
                if (model != null && model.targetCount > 0)
                  _BroadcastBanner(model: model),
                if (model != null && model.targetCount > 0)
                  const SizedBox(height: 12),

                // ── Overview ─────────────────────────────────
                _SectionCard(
                  title: 'Overview',
                  icon: Icons.campaign_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 32,
                        runSpacing: 12,
                        children: [
                          _InfoBlock(
                            label: 'Start Date',
                            value: _fmtDate(item.startDate),
                          ),
                          _InfoBlock(
                            label: 'End Date',
                            value: _fmtDate(item.endDate),
                          ),
                          _InfoBlock(
                            label: 'Duration',
                            value:
                                '${item.endDate.difference(item.startDate).inDays} days',
                          ),
                          _InfoBlock(
                            label: 'Created',
                            value: _fmtDate(item.createdAt),
                          ),
                        ],
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          item.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Channels ──────────────────────────────────
                _SectionCard(
                  title: 'Broadcast Channels',
                  icon: Icons.cell_tower_outlined,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: item.channels.map((c) {
                      final color = c == 'sms'
                          ? Colors.orange
                          : c == 'whatsapp'
                          ? const Color(0xFF25D366)
                          : Colors.indigo;
                      final icon = c == 'sms'
                          ? Icons.sms_outlined
                          : c == 'whatsapp'
                          ? Icons.chat_outlined
                          : Icons.notifications_outlined;
                      final label = c == 'sms'
                          ? 'SMS'
                          : c == 'whatsapp'
                          ? 'WhatsApp Business API'
                          : 'In-App';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 16, color: color),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Products ──────────────────────────────────
                _SectionCard(
                  title: 'Promoted Products (${item.productIds.length})',
                  icon: Icons.medication_outlined,
                  child: Column(
                    children: item.productIds
                        .map((id) => _ProductRow(productId: id))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Action Buttons ────────────────────────────
                _ActionButtons(item: item, status: status),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ─── Broadcast Banner ──────────────────────────────────────────────────────

class _BroadcastBanner extends StatelessWidget {
  final PromotionModel model;
  const _BroadcastBanner({required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentAt = model.broadcastSentAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast Sent to ${model.targetCount} Customers',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sentAt != null)
                  Text(
                    'Dispatched via ${model.channels.map((c) => c == 'sms'
                        ? 'SMS'
                        : c == 'whatsapp'
                        ? 'WhatsApp'
                        : 'In-App').join(' & ')} on ${_fmtDateTime(sentAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDateTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year} at $h:$min';
  }
}

// ─── Action Buttons ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final PromotionEntity item;
  final PromotionStatus status;
  const _ActionButtons({required this.item, required this.status});

  @override
  Widget build(BuildContext context) {
    final canActivate = status == PromotionStatus.draft;
    final canEnd = status == PromotionStatus.active;
    final canCancel =
        status == PromotionStatus.draft || status == PromotionStatus.active;

    if (!canActivate && !canEnd && !canCancel) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (canActivate)
                  FilledButton.icon(
                    onPressed: () => _confirmActivate(context),
                    icon: const Icon(Icons.rocket_launch_outlined),
                    label: const Text('Activate & Broadcast'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                if (canEnd)
                  FilledButton.icon(
                    onPressed: () => _confirmEnd(context),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('End Promotion'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmActivate(BuildContext context) {
    final bloc = context.read<PromotionBloc>();
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('Activate & Broadcast'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activating this promotion will immediately:'),
            const SizedBox(height: 12),
            _bulletPoint(
              'Send SMS to all registered customers via Vodacom/Airtel gateway',
              Icons.sms_outlined,
              Colors.orange,
            ),
            const SizedBox(height: 6),
            _bulletPoint(
              'Send WhatsApp messages via WhatsApp Business API',
              Icons.chat_outlined,
              const Color(0xFF25D366),
            ),
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone. The broadcast will go out immediately.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Activate & Broadcast'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        bloc.add(PromotionActivateRequested(item.id));
      }
    });
  }

  void _confirmEnd(BuildContext context) {
    final bloc = context.read<PromotionBloc>();
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.stop_circle_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('End Promotion'),
          ],
        ),
        content: const Text(
          'This will mark the promotion as ended. No further broadcasts will be sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End Promotion'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        bloc.add(PromotionEndRequested(item.id));
      }
    });
  }

  void _confirmCancel(BuildContext context) {
    final bloc = context.read<PromotionBloc>();
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Promotion'),
          ],
        ),
        content: const Text(
          'This will cancel the promotion. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Promotion'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        bloc.add(PromotionCancelRequested(item.id));
      }
    });
  }

  Widget _bulletPoint(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

// ─── Product Row ───────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final String productId;
  const _ProductRow({required this.productId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.medication_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(productId, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? accentColor;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoBlock({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(value ?? '—', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
