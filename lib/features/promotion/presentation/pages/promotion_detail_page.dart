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
//
// UPDATED: Shows discount percentage section when applicable.
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
import 'package:get_it/get_it.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';

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
    final hasDiscount = item.discountPercentage != null;

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

                // ── Discount Banner ───────────────────────────
                if (hasDiscount) ...[
                  _DiscountBanner(percentage: item.discountPercentage!),
                  const SizedBox(height: 12),
                ],

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
                          if (hasDiscount)
                            _InfoBlock(
                              label: 'Discount',
                              value:
                                  '${item.discountPercentage!.toStringAsFixed(item.discountPercentage! % 1 == 0 ? 0 : 1)}% OFF',
                              valueColor: Colors.deepOrange,
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

// ─── Discount Banner ───────────────────────────────────────────────────────

class _DiscountBanner extends StatelessWidget {
  final double percentage;
  const _DiscountBanner({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = percentage % 1 == 0
        ? '${percentage.toInt()}%'
        : '${percentage.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: Colors.deepOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discount Campaign — $label OFF',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.deepOrange.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Applied to all selected products. '
                  'Per-variant overrides can be configured via the Override API.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.deepOrange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                    'Sent on ${_fmtDate(sentAt)}',
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

// ─── Info Block ────────────────────────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoBlock({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─── Product Row ───────────────────────────────────────────────────────────

class _ProductRow extends StatefulWidget {
  final String productId;
  const _ProductRow({required this.productId});

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  String? name;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = GetIt.instance<ProductRemoteDataSource>();
      final product = await ds.getById(widget.productId);

      if (mounted) {
        setState(() {
          name = product.name;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          name = widget.productId;
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loading ? 'Loading...' : (name ?? widget.productId),
              style: theme.textTheme.bodySmall,
            ),
          ),
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
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.2)),
              ),
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

// ─── Action Buttons ────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final PromotionEntity item;
  final PromotionStatus status;

  const _ActionButtons({required this.item, required this.status});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PromotionBloc>();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (status == PromotionStatus.draft)
          FilledButton.icon(
            onPressed: () => _confirmAction(
              context,
              title: 'Publish Promotion?',
              body:
                  'This will broadcast to all eligible customers via selected channels. This cannot be undone.',
              confirmLabel: 'Publish',
              onConfirm: () => bloc.add(PromotionActivateRequested(item.id)),
            ),
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Publish'),
          ),
        if (status == PromotionStatus.active)
          OutlinedButton.icon(
            onPressed: () => _confirmAction(
              context,
              title: 'End Campaign?',
              body:
                  'The campaign will be marked as ended. No further broadcasts will be sent.',
              confirmLabel: 'End Campaign',
              onConfirm: () => bloc.add(PromotionEndRequested(item.id)),
            ),
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('End Campaign'),
          ),
        if (status == PromotionStatus.draft || status == PromotionStatus.active)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              ),
            ),
            onPressed: () => _confirmAction(
              context,
              title: 'Cancel Promotion?',
              body: 'The campaign will be cancelled. This cannot be undone.',
              confirmLabel: 'Cancel Campaign',
              onConfirm: () => bloc.add(PromotionCancelRequested(item.id)),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('Cancel'),
          ),
      ],
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onConfirm();
    }
  }
}
