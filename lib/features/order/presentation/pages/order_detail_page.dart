// === FILE: lib/features/order/presentation/pages/order_detail_page.dart
// Admin App — shows resolved customer name + copyable order/customer IDs.
// All other logic (status transitions, payment card, action bar) preserved.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../widgets/order_payment_card.dart';
import '../../../../core/context/org_context.dart';
import '../../../../config/di/injection_container.dart';
import '../bloc/order_state.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
            final reloadId = state.updatedItem?.id;
            if (reloadId != null) {
              context.read<OrderBloc>().add(OrderLoadOneRequested(reloadId));
            } else {
              final current = context.read<OrderBloc>().state;
              if (current is OrderDetailLoaded) {
                context
                    .read<OrderBloc>()
                    .add(OrderLoadOneRequested(current.item.id));
              }
            }
          }
          if (state is OrderFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderLoading || state is OrderInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrderFailure) {
            return Center(child: Text(state.message));
          }
          if (state is OrderDetailLoaded) {
            return _OrderBody(item: state.item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  final OrderEntity item;
  const _OrderBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusEnum = OrderStatusX.fromString(item.status);
    final hasPayment = item.paymentRef != null && item.paymentRef!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner (order ID copyable) ─────────────
          _StatusBanner(status: statusEnum, item: item),
          const SizedBox(height: 16),

          // ── Payment verified banner ────────────────────────
          if (hasPayment && statusEnum != OrderStatus.draft) ...[
            _PaymentVerifiedBanner(
              paymentRef: item.paymentRef!,
              orderId: item.id,
            ),
            const SizedBox(height: 16),
          ],

          // ── Action buttons ─────────────────────────────────
          _ActionBar(item: item, status: statusEnum),

          if (statusEnum != OrderStatus.delivered &&
              statusEnum != OrderStatus.cancelled)
            const SizedBox(height: 16),

          // ── Order Summary ──────────────────────────────────
          _SectionCard(
            title: 'Order Summary',
            icon: Icons.receipt_long_outlined,
            children: [
              // Customer — resolved name + copyable ID
              _CustomerField(item: item),
              _Field('Total', 'TZS ${item.total.toStringAsFixed(2)}'),
              _Field('Payment Ref', item.paymentRef ?? '—'),
              _Field('Status', statusEnum.displayName),
              _Field(
                'Created',
                item.createdAt.toIso8601String().split('T').first,
              ),
              if (item.createdByName != null && item.createdByName!.isNotEmpty)
                _Field('Placed by', item.createdByName!),
            ],
          ),
          const SizedBox(height: 16),

          // ── Order Items ────────────────────────────────────
          _ItemsCard(items: item.items),
          const SizedBox(height: 16),

          OrderPaymentCard(
            order: item,
            currentActorId:
                sl<OrgContext>().actorId ?? sl<OrgContext>().effectiveOrgId,
            currentActorName:
                sl<OrgContext>().actorName ??
                sl<OrgContext>().rootOrgName ??
                'Admin',
          ),
          const SizedBox(height: 80),

          if (hasPayment)
            OutlinedButton.icon(
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('View Payment Record'),
              onPressed: () => context.push(AppRouter.paymentList),
            ),
        ],
      ),
    );
  }
}

// ── Customer field — name + copyable ID ─────────────────────────────────────

class _CustomerField extends StatelessWidget {
  final OrderEntity item;
  const _CustomerField({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasName =
        item.customerName != null && item.customerName!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              'Customer',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resolved name (bold) or raw ID
                Text(
                  item.customerDisplay,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            hasName ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
                // Raw customer ID — always shown, tappable to copy
                GestureDetector(
                  onTap: () => _copy(context, item.customerId, 'Customer ID'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.customerId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                            ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.copy_outlined,
                        size: 11,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Status banner — order ID copyable ───────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final OrderStatus status;
  final OrderEntity item;
  const _StatusBanner({required this.status, required this.item});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(status), color: status.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Short display ID — tap to copy full ULID
                GestureDetector(
                  onTap: () => _copyId(context, item.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order #${item.id.length >= 8 ? item.id.substring(item.id.length - 8).toUpperCase() : item.id.toUpperCase()}',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Copy full order ID',
                        child: Icon(
                          Icons.copy_outlined,
                          size: 14,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Full ULID — also tappable to copy
                GestureDetector(
                  onTap: () => _copyId(context, item.id),
                  child: Text(
                    item.id,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  status.displayName,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          OrderStatusBadge(status: status),
        ],
      ),
    );
  }

  void _copyId(BuildContext context, String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID copied: $id'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _statusIcon(OrderStatus s) => switch (s) {
        OrderStatus.draft => Icons.edit_note_outlined,
        OrderStatus.confirmed => Icons.check_circle_outline,
        OrderStatus.shipped => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.done_all_outlined,
        OrderStatus.cancelled => Icons.cancel_outlined,
      };
}

// ── Payment verified banner (unchanged) ─────────────────────────────────────

class _PaymentVerifiedBanner extends StatelessWidget {
  final String paymentRef;
  final String orderId;
  const _PaymentVerifiedBanner({
    required this.paymentRef,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Verified — Auto Confirmed',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ref: $paymentRef',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payment was confirmed automatically by the mobile money gateway. '
                  'Funds are in the business account. '
                  'You can proceed directly to shipping.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: Colors.green.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action bar (unchanged) ───────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final OrderEntity item;
  final OrderStatus status;
  const _ActionBar({required this.item, required this.status});

  bool get _hasPayment =>
      item.paymentRef != null && item.paymentRef!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrderBloc>();
    final actions = <Widget>[];

    if (status == OrderStatus.draft) {
      if (_hasPayment) {
        actions.add(_ActionButton(
          label: 'Mark Shipped',
          icon: Icons.local_shipping_outlined,
          color: Colors.orange,
          onTap: () => bloc.add(OrderShipRequested(item.id)),
        ));
      } else {
        actions.add(_ActionButton(
          label: 'Confirm Order',
          icon: Icons.check_circle_outline,
          color: Colors.blue,
          onTap: () => _confirmManual(context, bloc),
        ));
      }
      actions.add(_ActionButton(
        label: 'Cancel',
        icon: Icons.cancel_outlined,
        color: Colors.red,
        onTap: () => _cancel(context, bloc),
      ));
    }

    if (status == OrderStatus.confirmed) {
      actions.add(_ActionButton(
        label: 'Mark Shipped',
        icon: Icons.local_shipping_outlined,
        color: Colors.orange,
        onTap: () => bloc.add(OrderShipRequested(item.id)),
      ));
      actions.add(_ActionButton(
        label: 'Cancel',
        icon: Icons.cancel_outlined,
        color: Colors.red,
        onTap: () => _cancel(context, bloc),
      ));
    }

    if (status == OrderStatus.shipped) {
      actions.add(_ActionButton(
        label: 'Mark Delivered',
        icon: Icons.done_all_outlined,
        color: Colors.green,
        onTap: () => bloc.add(OrderDeliverRequested(item.id)),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: actions);
  }

  void _confirmManual(BuildContext context, OrderBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Manual Order'),
        content: const Text(
          'This order has no payment reference. '
          'Confirm only if payment has been received by other means (e.g. cash).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              bloc.add(OrderConfirmRequested(item.id));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _cancel(BuildContext context, OrderBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('This will cancel the order. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              bloc.add(OrderCancelRequested(item.id));
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onTap,
    );
  }
}

// ── Items card (unchanged) ───────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ItemsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    double grandTotal = 0;
    for (final item in items) {
      grandTotal += (item['subtotal'] as num?)?.toDouble() ?? 0;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text('Order Items',
                    style:
                        textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('${items.length} item${items.length != 1 ? 's' : ''}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text('Product',
                          style: textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600))),
                  SizedBox(
                      width: 40,
                      child: Text('Qty',
                          style: textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600))),
                  SizedBox(
                      width: 70,
                      child: Text('Unit',
                          style: textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600))),
                  SizedBox(
                      width: 80,
                      child: Text('Subtotal',
                          textAlign: TextAlign.end,
                          style: textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['name']?.toString() ??
                            item['productId']?.toString() ??
                            '—',
                        style: textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                        width: 40,
                        child: Text(item['qty']?.toString() ?? '—',
                            style: textTheme.bodySmall)),
                    SizedBox(
                      width: 70,
                      child: Text(
                        item['unitPrice'] != null
                            ? _fmt((item['unitPrice'] as num).toDouble())
                            : '—',
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        item['subtotal'] != null
                            ? _fmt((item['subtotal'] as num).toDouble())
                            : '—',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Total:',
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text(
                  'TZS ${grandTotal.toStringAsFixed(2)}',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0);
}

// ── Helpers (unchanged) ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
              child: Text(value,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}