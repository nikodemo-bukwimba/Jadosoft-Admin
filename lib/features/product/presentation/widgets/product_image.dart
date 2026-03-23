import 'package:flutter/material.dart';

import '../../domain/entities/product_entity.dart';

/// Displays a product image with optional overlay tags.
///
/// Shows NEW, FEATURED, and UNAVAILABLE overlay badges on top of the
/// image. Falls back to a placeholder icon when no image is available.
class ProductImage extends StatelessWidget {
  final ProductEntity product;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool showOverlayTags;

  const ProductImage({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.showOverlayTags = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tags = product.overlayTags;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image or placeholder
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              Image.network(
                product.imageUrl!,
                fit: fit,
                errorBuilder: (_, __, ___) => _Placeholder(
                  colorScheme: colorScheme,
                ),
              )
            else
              _Placeholder(colorScheme: colorScheme),

            // Overlay tags
            if (showOverlayTags && tags.isNotEmpty)
              Positioned(
                top: 6,
                left: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tags.map((tag) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _OverlayTag(tag: tag),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _Placeholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Center(
        child: Icon(
          Icons.medication_outlined,
          size: 40,
          color: colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _OverlayTag extends StatelessWidget {
  final String tag;

  const _OverlayTag({required this.tag});

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
