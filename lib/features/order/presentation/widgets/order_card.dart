import 'package:flutter/material.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_status_badge.dart';
import 'order_confirm_delete_dialog.dart';

class OrderCard extends StatelessWidget {
  final OrderEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OrderCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.customerId,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(item.total.toString()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OrderStatusBadge(
              status: OrderStatusX.fromString(item.status),
              compact: true,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _confirmDelete(BuildContext context) async {
  final confirmed = await OrderConfirmDeleteDialog.show(
    context,
    orderId: item.id,
  );
  if (confirmed) onDelete();
}
}
