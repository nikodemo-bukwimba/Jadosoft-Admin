// === FILE: lib/features/order/presentation/widgets/order_card_tile.dart
// Admin App — shows resolved customer name (customerDisplay) instead of raw ID.
// All other content preserved exactly.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/value_objects/order_status.dart';
import 'order_status_badge.dart';
import 'order_confirm_delete_dialog.dart';

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
    final hasPlacedBy =
        item.createdByName != null && item.createdByName!.isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _copyId(context, item.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: status.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order #${item.id.length >= 8 ? item.id.substring(item.id.length - 8).toUpperCase() : item.id.toUpperCase()}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Copy icon
                            GestureDetector(
                              onTap: () => _copyId(context, item.id),
                              child: Icon(
                                Icons.copy_outlined,
                                size: 12,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          item.createdAt.toIso8601String().split('T').first,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OrderStatusBadge(status: status, compact: true),
                ],
              ),
              const SizedBox(height: 10),

              // ── Items count + total ──────────────────────
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.items.length} item${item.items.length != 1 ? 's' : ''}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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

              // ── Payment ref ──────────────────────────────
              if (item.paymentRef != null && item.paymentRef!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 13,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.paymentRef!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.tertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Placed by ────────────────────────────────
              if (hasPlacedBy) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 13,
                      color: scheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'By ${item.createdByName!}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

              // ── Footer: customer name (resolved) + delete ──
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      // customerDisplay returns resolved name or raw ID
                      item.customerDisplay,
                      style: textTheme.bodySmall?.copyWith(
                        color: item.customerName != null
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                        fontWeight: item.customerName != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: scheme.error,
                      size: 18,
                    ),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirmed = await OrderConfirmDeleteDialog.show(
                        context,
                        orderId: item.id,
                      );
                      if (confirmed) onDelete();
                    },
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

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
