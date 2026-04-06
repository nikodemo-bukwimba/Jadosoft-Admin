import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/mark_order_paid_usecase.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../../../../core/context/org_context.dart';
import '../../../../config/di/injection_container.dart'; // Update this path to where OrgContext is defined

class OrderPaymentCard extends StatelessWidget {
  final OrderEntity order;
  final String currentActorId;
  final String currentActorName;

  const OrderPaymentCard({
    super.key,
    required this.order,
    required this.currentActorId,
    required this.currentActorName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPaid = order.paymentStatus == 'paid';

    final statusColor = isPaid ? Colors.green : Colors.orange;
    final statusLabel = isPaid ? 'Paid' : 'Unpaid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Payment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _row(context, 'Amount', 'TZS ${order.total.toStringAsFixed(0)}'),
            if (order.paymentRef != null && order.paymentRef!.isNotEmpty)
              _row(context, 'Reference', order.paymentRef!),
            if (isPaid && order.paymentVerifiedBy != null)
              _row(
                context,
                'Verified by',
                order.paymentVerifiedBy == sl<OrgContext>().actorId
                    ? (sl<OrgContext>().actorName ?? order.paymentVerifiedBy!)
                    : order.paymentVerifiedBy!,
              ),
            if (isPaid && order.paymentVerifiedAt != null)
              // _row(context, 'Verified at', _fmt(order.paymentVerifiedAt!)),
              Builder(
                builder: (context) {
                  final orgContext = sl<OrgContext>();
                  final verifiedBy =
                      order.paymentVerifiedBy == orgContext.actorId
                      ? (orgContext.actorName ?? order.paymentVerifiedBy!)
                      : order.paymentVerifiedBy!;
                  return _row(context, 'Verified by', verifiedBy);
                },
              ),
            if (!isPaid && order.status != 'cancelled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark as Paid'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                  onPressed: () => _confirmMarkPaid(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmMarkPaid(BuildContext context) async {
    final refController = TextEditingController(text: order.paymentRef ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Order as Paid?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are confirming manual payment of TZS ${order.total.toStringAsFixed(0)}. '
              'This action will be recorded with your name.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: refController,
              decoration: const InputDecoration(
                labelText: 'Payment Reference (optional)',
                hintText: 'e.g. MPESA-2026-XXX or Cash',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<OrderBloc>().add(
        OrderMarkPaidRequested(
          MarkOrderPaidParams(
            orderId: order.id,
            actorId: currentActorId,
            actorName: currentActorName,
            paymentRef: refController.text.trim().isEmpty
                ? null
                : refController.text.trim(),
          ),
        ),
      );
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
