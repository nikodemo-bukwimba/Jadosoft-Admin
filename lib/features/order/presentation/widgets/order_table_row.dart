// === FILE: lib/features/order/presentation/widgets/order_table_row.dart
// Admin App — shows customerDisplay instead of raw customerId.

import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_status_badge.dart';
import 'order_confirm_delete_dialog.dart';

class OrderTableRow extends StatelessWidget {
  final OrderEntity item;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OrderTableRow({
    super.key,
    required this.item,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final status = OrderStatusX.fromString(item.status);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
          ),
        ),
        child: Row(
          children: [
            // Order ID
            Expanded(
              flex: 2,
              child: Text(
                '#${item.id.length >= 8 ? item.id.substring(item.id.length - 8).toUpperCase() : item.id.toUpperCase()}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Customer — resolved name
            Expanded(
              flex: 2,
              child: Text(
                item.customerDisplay,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: item.customerName != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                  color: item.customerName != null
                      ? null
                      : scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Placed by
            SizedBox(
              width: 110,
              child: Text(
                item.createdByName ?? '—',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Items
            SizedBox(
              width: 52,
              child: Text(
                '${item.items.length}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            // Total
            SizedBox(
              width: 90,
              child: Text(
                'TZS ${_fmt(item.total)}',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            SizedBox(
              width: 100,
              child: OrderStatusBadge(status: status, compact: true),
            ),
            // Delete
            SizedBox(
              width: 44,
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error, size: 18),
                onPressed: () async {
                  final confirmed = await OrderConfirmDeleteDialog.show(
                    context,
                    orderId: item.id,
                  );
                  if (confirmed) onDelete();
                },
                padding: EdgeInsets.zero,
              ),
            ),
          ],
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
