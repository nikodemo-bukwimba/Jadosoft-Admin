import 'package:flutter/material.dart';

import '../../domain/value_objects/product_status.dart';

/// Displays a colored badge for the product status.
///
/// Uses [ProductStatus.color] and [ProductStatus.label] for visual
/// consistency across all product views.
class ProductStatusBadge extends StatelessWidget {
  final ProductStatus status;
  final double fontSize;

  const ProductStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withOpacity(0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: fontSize + 2, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
