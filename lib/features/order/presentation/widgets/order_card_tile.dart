import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_status_badge.dart';

class OrderCardTile extends StatelessWidget {
  final OrderEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OrderCardTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = OrderStatusX.fromString(item.status);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.receipt_long_outlined,
                        color: status.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${item.id.split('-').last.toUpperCase()}',
                          style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.createdAt.toIso8601String().split('T').first,
                          style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusBadge(status: status, compact: true),
                ],
              ),
              const SizedBox(height: 12),
              // Items count + total
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${item.items.length} item${item.items.length != 1 ? 's' : ''}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    'TZS ${_fmt(item.total)}',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              if (item.paymentRef != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.payment_outlined,
                        size: 13, color: scheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      item.paymentRef!,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.tertiary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 13, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Customer: ${item.customerId}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: scheme.error, size: 18),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}