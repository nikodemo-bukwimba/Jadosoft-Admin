// lib/features/product/presentation/widgets/branch_price_section.dart
//
// Widget to embed in ProductDetailPage when the viewing org is a branch.
// Shows the current branch override (or root price) and a button to manage it.
 
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
 
import '../../../../core/context/org_context.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/branch_variant_price_entity.dart';
import '../pages/branch_price_page.dart';
 
/// Renders a branch-price management card inside ProductDetailPage.
///
/// Only shown when:
///   1. The viewing org is a BRANCH (not root).
///   2. The product has a variantId.
///
/// Usage in ProductDetailPage — add after _InfoCard:
///
/// ```dart
/// if (_orgContext.isBranch && item.variantId != null)
///   _BranchPriceSection(item: item, formatPrice: widget.formatPrice),
/// ```
class BranchPriceSection extends StatelessWidget {
  final ProductEntity item;
  final String Function(double) formatPrice;
 
  const BranchPriceSection({
    super.key,
    required this.item,
    required this.formatPrice,
  });
 
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasBranchPrice = item.hasBranchPrice;
 
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasBranchPrice
              ? scheme.primary.withOpacity(0.4)
              : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Branch Price',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openBranchPricePage(context),
                  icon: Icon(
                    hasBranchPrice ? Icons.edit_outlined : Icons.add,
                    size: 16,
                  ),
                  label: Text(hasBranchPrice ? 'Edit' : 'Set Price'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
 
            // Price comparison row
            Row(
              children: [
                // Root base
                _PriceChip(
                  label: 'Root Base',
                  value: formatPrice(item.price),
                  color: scheme.surfaceContainerHighest,
                  textColor: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                // Branch price
                _PriceChip(
                  label: 'This Branch',
                  value: hasBranchPrice
                      ? formatPrice(item.branchPrice!)
                      : 'Same as root',
                  color: hasBranchPrice
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHighest,
                  textColor: hasBranchPrice
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ],
            ),
 
            // Markup info
            if (hasBranchPrice && item.branchPrice != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final markup = item.price > 0
                    ? ((item.branchPrice! - item.price) / item.price) * 100
                    : 0.0;
                return Text(
                  '+${markup.toStringAsFixed(1)}% above root price '
                  '(covers transport & regional costs)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                );
              }),
            ],
 
            if (!hasBranchPrice) ...[
              const SizedBox(height: 8),
              Text(
                'No branch override — customers in this branch see the root base price.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
 
  void _openBranchPricePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BranchPricePage(product: item),
      ),
    );
  }
}
 
class _PriceChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
 
  const _PriceChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}