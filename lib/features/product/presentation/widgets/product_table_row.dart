import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/value_objects/product_status.dart';
import 'product_image.dart';
import 'product_status_badge.dart';

/// Details view row — table-style with aligned columns.
class ProductTableRow extends StatelessWidget {
  final ProductEntity item;
  final String Function(double) formatPrice;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductTableRow({
    super.key,
    required this.item,
    required this.formatPrice,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = ProductStatusX.fromString(item.status);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            // Image
            ProductImage(
              imageUrl: item.imageUrl,
              width: 36,
              height: 36,
              borderRadius: 6,
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      item.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.isNew) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Price
            Expanded(
              flex: 2,
              child: Text(
                formatPrice(item.price),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: ProductStatusBadge(status: statusEnum, compact: true),
            ),
            // Delete
            SizedBox(
              width: 48,
              child: IconButton(
                icon:
                    Icon(Icons.delete_outline, color: scheme.error, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}