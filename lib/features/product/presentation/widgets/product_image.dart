// lib/features/product/presentation/widgets/product_image.dart

import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable product image widget.
/// Handles network URLs (https://), local file paths on all platforms
/// (Unix /path, Windows C:\path), loading states, errors, and placeholder.
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

  /// Returns true when imageUrl is a local file path rather than a network URL.
  ///
  /// Covers:
  ///   • Unix / macOS / Linux absolute paths  → start with /
  ///   • file:// URIs                          → start with file://
  ///   • Windows absolute paths               → start with a drive letter (C:\, D:/, etc.)
  ///   • Windows UNC paths                    → start with \\
  ///
  /// Anything starting with http:// or https:// is treated as a network URL.
  bool get _isLocalFile {
    if (imageUrl == null || imageUrl!.isEmpty) return false;
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return false;
    }
    // Unix / Linux / macOS absolute path
    if (imageUrl!.startsWith('/')) return true;
    // file:// URI
    if (imageUrl!.startsWith('file://')) return true;
    // Windows drive letter: C:\ or C:/
    if (imageUrl!.length >= 3 &&
        imageUrl![1] == ':' &&
        (imageUrl![2] == '\\' || imageUrl![2] == '/')) {
      return true;
    }
    // Windows UNC path: \\server\share
    if (imageUrl!.startsWith('\\\\')) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder(scheme);
    }

    // ── Local file path (image_picker on mobile, file_picker on desktop) ──
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

    // ── Network URL ──────────────────────────────────────────────────────────
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
