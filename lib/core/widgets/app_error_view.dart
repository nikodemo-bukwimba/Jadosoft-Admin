// app_error_view.dart
// ─────────────────────────────────────────────────────────────
// Reusable error-state widgets. Material 3. No custom colors.
//
// Variants:
//   AppErrorView         — full-screen error with optional retry button
//   AppErrorSliver       — SliverFillRemaining wrapper for CustomScrollView
//   AppErrorBanner       — compact inline banner (inside a Card or list)
//
// Factory constructors for common scenarios:
//   AppErrorView.network(onRetry: ...)   — no internet / timeout
//   AppErrorView.notFound(onRetry: ...)  — 404 / resource missing
//   AppErrorView.unauthorized()          — session expired / 401
//   AppErrorView.generic(message, ...)   — fallback for unknown errors
//
// Usage:
//   // From a BLoC state
//   if (state is SomeError)
//     AppErrorView.network(onRetry: () => bloc.add(RetryRequested()))
//
//   // With a custom message
//   AppErrorView(
//     message: state.message,
//     onRetry: () => bloc.add(RetryRequested()),
//   )
//
//   // Inline banner inside a card
//   AppErrorBanner(message: 'Failed to save. Please try again.')
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── AppErrorView ──────────────────────────────────────────────

/// Full-screen centered error state.
/// All fields are optional — sensible defaults are applied.
class AppErrorView extends StatelessWidget {
  /// Icon displayed in the container. Default: Icons.error_outline_rounded.
  final IconData icon;

  /// Short headline. Default: 'Something went wrong'.
  final String title;

  /// Supporting detail text. Leave null to omit.
  final String? message;

  /// Label for the retry button. Leave null to hide it.
  final String? retryLabel;

  /// Callback wired to the retry button.
  final VoidCallback? onRetry;

  /// Secondary action label (e.g. 'Go back'). Leave null to omit.
  final String? secondaryLabel;

  /// Callback for the secondary action.
  final VoidCallback? onSecondary;

  /// When true, uses [ColorScheme.errorContainer] for the icon background.
  /// Set false for softer tones (e.g. empty-search vs real errors).
  final bool useErrorColor;

  const AppErrorView({
    super.key,
    this.icon = Icons.error_outline_rounded,
    this.title = 'Something went wrong',
    this.message,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
    this.useErrorColor = true,
  });

  // ── Factory: network error ────────────────────────────────

  /// Pre-configured for connection / timeout failures.
  factory AppErrorView.network({VoidCallback? onRetry}) {
    return AppErrorView(
      icon: Icons.wifi_off_rounded,
      title: 'No connection',
      message: 'Check your internet connection and try again.',
      retryLabel: 'Retry',
      onRetry: onRetry,
    );
  }

  // ── Factory: resource not found ───────────────────────────

  /// Pre-configured for 404 / missing resource responses.
  factory AppErrorView.notFound({VoidCallback? onRetry}) {
    return AppErrorView(
      icon: Icons.search_off_rounded,
      title: 'Not found',
      message: 'The resource you requested could not be located.',
      retryLabel: onRetry != null ? 'Try again' : null,
      onRetry: onRetry,
      useErrorColor: false,
    );
  }

  // ── Factory: unauthorized ─────────────────────────────────

  /// Pre-configured for 401 / session-expired scenarios.
  /// Typically pair with a navigation callback to push the login page.
  factory AppErrorView.unauthorized({VoidCallback? onSignIn}) {
    return AppErrorView(
      icon: Icons.lock_outline_rounded,
      title: 'Session expired',
      message: 'Please sign in again to continue.',
      retryLabel: 'Sign in',
      onRetry: onSignIn,
      useErrorColor: false,
    );
  }

  // ── Factory: generic fallback ─────────────────────────────

  /// Convenience constructor for any Failure.message string.
  factory AppErrorView.generic(String message, {VoidCallback? onRetry}) {
    return AppErrorView(
      message: message,
      retryLabel: onRetry != null ? 'Try again' : null,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ── Icon container colors ─────────────────────────────
    final containerColor = useErrorColor
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final iconColor = useErrorColor
        ? scheme.onErrorContainer
        : scheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 24),

            // ── Title ─────────────────────────────────────
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Message ───────────────────────────────────
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // ── Retry button ──────────────────────────────
            if (retryLabel != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel!),
              ),
            ],

            // ── Secondary action ──────────────────────────
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── AppErrorSliver ────────────────────────────────────────────

/// Sliver version of [AppErrorView] for use inside a [CustomScrollView].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppBar(...),
///     if (state is SomeError)
///       AppErrorSliver.network(
///         onRetry: () => bloc.add(RetryRequested()),
///       ),
///   ],
/// )
/// ```
class AppErrorSliver extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool useErrorColor;

  const AppErrorSliver({
    super.key,
    this.icon = Icons.error_outline_rounded,
    this.title = 'Something went wrong',
    this.message,
    this.retryLabel = 'Try again',
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
    this.useErrorColor = true,
  });

  // ── Named constructors (mirrors AppErrorView factories) ───

  factory AppErrorSliver.network({VoidCallback? onRetry}) => AppErrorSliver(
    icon: Icons.wifi_off_rounded,
    title: 'No connection',
    message: 'Check your internet connection and try again.',
    retryLabel: 'Retry',
    onRetry: onRetry,
  );

  factory AppErrorSliver.notFound({VoidCallback? onRetry}) => AppErrorSliver(
    icon: Icons.search_off_rounded,
    title: 'Not found',
    message: 'The resource you requested could not be located.',
    retryLabel: onRetry != null ? 'Try again' : null,
    onRetry: onRetry,
    useErrorColor: false,
  );

  factory AppErrorSliver.generic(String message, {VoidCallback? onRetry}) =>
      AppErrorSliver(
        message: message,
        retryLabel: onRetry != null ? 'Try again' : null,
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppErrorView(
        icon: icon,
        title: title,
        message: message,
        retryLabel: retryLabel,
        onRetry: onRetry,
        secondaryLabel: secondaryLabel,
        onSecondary: onSecondary,
        useErrorColor: useErrorColor,
      ),
    );
  }
}

// ── AppErrorBanner ────────────────────────────────────────────

/// Compact inline error banner.
/// Use inside a Card, a form section, or at the top of a page body.
/// Dismissible when [onDismiss] is provided.
///
/// ```dart
/// if (state is AuthFailureState)
///   AppErrorBanner(
///     message: state.message,
///     onDismiss: () => bloc.add(AuthErrorDismissed()),
///   )
/// ```
class AppErrorBanner extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// When provided, shows an ✕ icon button to dismiss the banner.
  final VoidCallback? onDismiss;

  /// Optional leading icon override. Default: Icons.warning_amber_rounded.
  final IconData icon;

  const AppErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.warning_amber_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ──────────────────────────────────────
          Icon(icon, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 10),

          // ── Message ───────────────────────────────────
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),

          // ── Dismiss button ────────────────────────────
          if (onDismiss != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: scheme.onErrorContainer.withAlpha(179), // 0.7 * 255
              ),
            ),
          ],
        ],
      ),
    );
  }
}
