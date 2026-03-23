import 'package:flutter/material.dart';

import '../../domain/entities/product_entity.dart';
import 'product_status_badge.dart';

/// Builds a [DataRow] for the product table view.
///
/// Displays: name, type, category, price, status, featured, sku.
class ProductTableRow {
  const ProductTableRow._();

  /// Column headers for the product data table.
  static List<DataColumn> columns(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    return [
      DataColumn(label: Text('Name', style: style)),
      DataColumn(label: Text('Type', style: style)),
      DataColumn(label: Text('Category', style: style)),
      DataColumn(label: Text('Price', style: style), numeric: true),
      DataColumn(label: Text('Status', style: style)),
      DataColumn(label: Text('Tags', style: style)),
      DataColumn(label: Text('SKU', style: style)),
    ];
  }

  /// Builds a [DataRow] for the given [product].
  static DataRow row({
    required BuildContext context,
    required ProductEntity product,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodySmall;

    return DataRow(
      onSelectChanged: onTap != null ? (_) => onTap() : null,
      cells: [
        // Name
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    colorScheme.primaryContainer.withOpacity(0.5),
                backgroundImage: product.imageUrl != null
                    ? NetworkImage(product.imageUrl!)
                    : null,
                child: product.imageUrl == null
                    ? Icon(Icons.medication_outlined,
                        size: 12, color: colorScheme.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  product.name,
                  style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Type
        DataCell(Text(
          product.type.label,
          style: bodyStyle,
        )),

        // Category
        DataCell(Text(
          product.categoryName ?? '—',
          style: bodyStyle?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        )),

        // Price
        DataCell(Text(
          product.formattedPrice,
          style: bodyStyle?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        )),

        // Status
        DataCell(ProductStatusBadge(
          status: product.status,
          fontSize: 10,
        )),

        // Tags
        DataCell(
          Wrap(
            spacing: 4,
            children: product.overlayTags.map((tag) {
              return _TableTag(tag: tag);
            }).toList(),
          ),
        ),

        // SKU
        DataCell(Text(
          product.sku ?? '—',
          style: bodyStyle?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            fontFamily: 'monospace',
          ),
        )),
      ],
    );
  }
}

class _TableTag extends StatelessWidget {
  final String tag;

  const _TableTag({required this.tag});

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
