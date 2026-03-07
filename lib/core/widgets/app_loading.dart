// app_loading.dart
// ─────────────────────────────────────────────────────────────
// Reusable loading indicators. Material 3. No custom colors.
//
// Variants:
//   AppLoading            — full-screen centered spinner (page-level)
//   AppLoadingOverlay     — transparent scrim + spinner over existing content
//   AppLoadingInline      — small spinner + label for list tiles / cards
//   AppLoadingSliver      — SliverFillRemaining wrapper for CustomScrollView
//
// Usage:
//   // Full-screen
//   if (state is Loading) return const AppLoading();
//
//   // With custom message
//   AppLoading(message: 'Fetching your profile…')
//
//   // Overlay on top of content
//   AppLoadingOverlay(isLoading: state is Loading, child: MyContent())
//
//   // Inside a CustomScrollView
//   if (state is Loading) const AppLoadingSliver()
//
//   // Inline (inside a card / list tile)
//   AppLoadingInline(label: 'Saving…')
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── AppLoading (full-screen) ──────────────────────────────────

/// Full-screen centered loading indicator.
/// Drop-in replacement for a Scaffold body while data is loading.
class AppLoading extends StatelessWidget {
  /// Optional message shown below the spinner.
  final String? message;

  /// Stroke width passed to [CircularProgressIndicator]. Default: 2.5.
  final double strokeWidth;

  /// Size of the spinner container. Default: 48.
  final double size;

  const AppLoading({
    super.key,
    this.message,
    this.strokeWidth = 2.5,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Spinner ───────────────────────────────────────
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              color: scheme.primary,
            ),
          ),

          // ── Optional message ──────────────────────────────
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── AppLoadingOverlay ─────────────────────────────────────────

/// Stacks a semi-transparent scrim + spinner over [child].
/// The child stays mounted (preserves scroll position, state, etc.).
/// Set [isLoading] to toggle the overlay on/off.
class AppLoadingOverlay extends StatelessWidget {
  /// Whether the loading overlay is visible.
  final bool isLoading;

  /// The widget rendered beneath the overlay.
  final Widget child;

  /// Opacity of the scrim layer. Default: 0.45.
  final double scrimOpacity;

  /// Optional message shown below the spinner on the overlay.
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.scrimOpacity = 0.45,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // ── Underlying content ────────────────────────────
        child,

        // ── Overlay (only when loading) ───────────────────
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: scheme.scrim.withOpacity(scrimOpacity),
              child: AppLoading(message: message),
            ),
          ),
      ],
    );
  }
}

// ── AppLoadingInline ──────────────────────────────────────────

/// Compact horizontal spinner + label.
/// Fits naturally inside a [ListTile], [Card], or a [Row].
class AppLoadingInline extends StatelessWidget {
  /// Text displayed to the right of the spinner. Default: 'Loading…'
  final String label;

  /// Diameter of the spinner. Default: 16.
  final double size;

  const AppLoadingInline({super.key, this.label = 'Loading…', this.size = 16});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Spinner ───────────────────────────────────────
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 10),

        // ── Label ─────────────────────────────────────────
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── AppLoadingSliver ──────────────────────────────────────────

/// Sliver version of [AppLoading] for use inside a [CustomScrollView].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppBar(...),
///     if (state is Loading) const AppLoadingSliver(),
///   ],
/// )
/// ```
class AppLoadingSliver extends StatelessWidget {
  final String? message;

  const AppLoadingSliver({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppLoading(message: message),
    );
  }
}
