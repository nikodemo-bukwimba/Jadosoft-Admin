import 'package:flutter/material.dart';

import '../../domain/entities/product_entity.dart';
import 'product_status_badge.dart';

/// Compact single-line row for [ProductViewMode.list].
///
/// Shows small avatar, name, price, category, and status in a dense row.
class ProductListRow extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;

  const ProductListRow({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Small avatar
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  colorScheme.primaryContainer.withOpacity(0.5),
              backgroundImage: product.imageUrl != null
                  ? NetworkImage(product.imageUrl!)
                  : null,
              child: product.imageUrl == null
                  ? Icon(
                      Icons.medication_outlined,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.categoryName != null)
                    Text(
                      product.categoryName!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
            ),

            // Overlay tags
            if (product.overlayTags.isNotEmpty) ...[
              const SizedBox(width: 8),
              ...product.overlayTags.take(2).map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _MiniTag(tag: tag),
                );
              }),
            ],

            const SizedBox(width: 8),

            // Price
            SizedBox(
              width: 100,
              child: Text(
                product.formattedPrice,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.end,
              ),
            ),
            const SizedBox(width: 12),

            // Status
            ProductStatusBadge(
              status: product.status,
              fontSize: 10,
            ),

            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String tag;

  const _MiniTag({required this.tag});

  Color get _color {
    switch (tag) {
      case 'NEW':
        return Colors.green;
      case 'FEATURED':
        return Colors.amber.shade700;
      case 'UNAVAILABLE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
