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
            Expanded(
              flex: 2,
              child: Text(
                '#${item.id.split('-').last.toUpperCase()}',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.customerId,
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '${item.items.length} item${item.items.length != 1 ? 's' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
              ),
            ),
            SizedBox(
              width: 80,
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
            SizedBox(
              width: 80,
              child: OrderStatusBadge(status: status, compact: true),
            ),
            SizedBox(
              width: 36,
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
