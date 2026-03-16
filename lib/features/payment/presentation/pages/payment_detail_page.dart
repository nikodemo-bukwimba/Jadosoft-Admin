import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../domain/entities/payment_entity.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_state.dart';

class PaymentDetailPage extends StatelessWidget {
  const PaymentDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Detail')),
      body: BlocBuilder<PaymentBloc, PaymentState>(
        builder: (context, state) {
          if (state is PaymentLoading || state is PaymentInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PaymentFailure) {
            return Center(child: Text(state.message));
          }
          if (state is PaymentDetailLoaded) {
            return _PaymentBody(item: state.item);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _PaymentBody extends StatelessWidget {
  final PaymentEntity item;
  const _PaymentBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor(item.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_providerIcon(item.provider),
                      color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.transactionRef ?? 'No reference',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        item.provider,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: item.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Auto-confirm explanation (for confirmed payments) ──
          if (item.status == 'confirmed') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_outlined,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Automatically Verified',
                          style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This payment was confirmed directly by ${item.provider}. '
                          'The funds are in the business account. '
                          'The order was automatically confirmed when payment was received.',
                          style: textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Failure reason ──────────────────────────────────
          if (item.status == 'failed' &&
              item.failureReason != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: scheme.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      color: scheme.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Failed',
                          style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.error),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.failureReason!,
                          style: textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The customer needs to retry payment before this order can proceed.',
                          style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Payment details ─────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_outlined,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 8),
                      Text('Payment Details',
                          style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Field('Payment ID', item.id),
                  _Field('Order', '#${item.orderId.split('-').last.toUpperCase()}'),
                  _Field('Customer', item.customerId),
                  _Field('Amount',
                      'TZS ${item.amount.toStringAsFixed(2)} ${item.currency}'),
                  _Field('Provider', item.provider),
                  _Field('Reference', item.transactionRef ?? '—'),
                  _Field('Status', _statusLabel(item.status)),
                  _Field(
                      'Initiated',
                      item.initiatedAt
                          .toIso8601String()
                          .replaceFirst('T', ' ')
                          .substring(0, 16)),
                  if (item.confirmedAt != null)
                    _Field(
                        'Confirmed',
                        item.confirmedAt!
                            .toIso8601String()
                            .replaceFirst('T', ' ')
                            .substring(0, 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── View linked order ───────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text(
                'View Order #${item.orderId.split('-').last.toUpperCase()}'),
            onPressed: () =>
                context.push(AppRouter.orderDetailPath(item.orderId)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'confirmed' => Colors.green,
        'pending' => Colors.orange,
        'failed' => Colors.red,
        _ => Colors.grey,
      };

  String _statusLabel(String s) => switch (s) {
        'confirmed' => 'Confirmed',
        'pending' => 'Pending',
        'failed' => 'Failed',
        _ => s,
      };

  IconData _providerIcon(String p) {
    final lower = p.toLowerCase();
    if (lower.contains('mpesa') || lower.contains('m-pesa')) {
      return Icons.phone_android_outlined;
    }
    if (lower.contains('airtel')) return Icons.sim_card_outlined;
    return Icons.payments_outlined;
  }
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
              child:
                  Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;
  const _StatusBadge({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' => Colors.green,
      'pending' => Colors.orange,
      'failed' => Colors.red,
      _ => Colors.grey,
    };
    final label = switch (status) {
      'confirmed' => 'Confirmed',
      'pending' => 'Pending',
      'failed' => 'Failed',
      _ => status,
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w600)),
    );
  }
}