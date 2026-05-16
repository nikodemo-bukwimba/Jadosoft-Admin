import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable product image widget.
/// Handles network URLs (https://), local file paths, loading, error, placeholder.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  bool get _isLocalFile {
    if (imageUrl == null) return false;
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return false;
    }
    // On mobile, paths from image_picker are absolute. Avoid existsSync() on
    // non-absolute strings (e.g. relative paths, Android content:// URIs)
    // which can return false even for valid files or throw on some platforms.
    if (imageUrl!.startsWith('/') || imageUrl!.startsWith('file://')) {
      return true; // treat as local file; Image.file handles errors via errorBuilder
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder(scheme);
    }

    // Local file path (from image picker)
    if (_isLocalFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(imageUrl!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _placeholder(scheme),
        ),
      );
    }

    // Network URL
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _loading(scheme, progress);
        },
        errorBuilder: (_, __, ___) => _placeholder(scheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.medication_outlined,
          color: scheme.primary.withValues(alpha: 0.5),
          size: (height ?? 48) * 0.4,
        ),
      ),
    );
  }

  Widget _loading(ColorScheme scheme, ImageChunkEvent progress) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
          ),
        ),
      ),
    );
  }
}
