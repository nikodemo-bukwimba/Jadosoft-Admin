// app_empty_view.dart
// ─────────────────────────────────────────────────────────────
// Reusable empty-state widgets. Material 3. No custom colors.
//
// Variants:
//   AppEmptyView         — full-screen empty state with icon, title, message
//   AppEmptySliver       — SliverFillRemaining wrapper for CustomScrollView
//
// Usage:
//   // Basic
//   AppEmptyView(
//     title: 'No results found',
//     message: 'Try adjusting your filters.',
//   )
//
//   // With icon and action button
//   AppEmptyView(
//     icon: Icons.inbox_outlined,
//     title: 'Your inbox is empty',
//     message: 'New messages will appear here.',
//     actionLabel: 'Refresh',
//     onAction: () => bloc.add(InboxRefreshRequested()),
//   )
//
//   // Inside a CustomScrollView
//   if (items.isEmpty) AppEmptySliver(title: 'Nothing here yet')
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// ── AppEmptyView ──────────────────────────────────────────────

/// Full-screen centered empty-state illustration.
/// Composable: every field is optional except [title].
class AppEmptyView extends StatelessWidget {
  /// Icon shown above the title. Default: Icons.inbox_outlined.
  final IconData icon;

  /// Short headline (required). E.g. "No results found".
  final String title;

  /// Longer supporting text. Leave null to omit.
  final String? message;

  /// Label for the primary action button. Leave null to omit the button.
  final String? actionLabel;

  /// Callback for the primary action button.
  final VoidCallback? onAction;

  /// Secondary action label (e.g. "Learn more"). Leave null to omit.
  final String? secondaryActionLabel;

  /// Callback for the secondary action.
  final VoidCallback? onSecondaryAction;

  /// Override the icon container size. Default: 72.
  final double iconContainerSize;

  /// Override the icon size inside the container. Default: 36.
  final double iconSize;

  const AppEmptyView({
    super.key,
    this.icon             = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconContainerSize = 72,
    this.iconSize          = 36,
  });

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ────────────────────────────
            Container(
              width:  iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color:        scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size:  iconSize,
                color: scheme.onSurfaceVariant,
              ),
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

            // ── Supporting message ────────────────────────
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

            // ── Primary action ────────────────────────────
            if (actionLabel != null) ...[
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],

            // ── Secondary action ──────────────────────────
            if (secondaryActionLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── AppEmptySliver ────────────────────────────────────────────

/// Sliver version of [AppEmptyView] for use inside a [CustomScrollView].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppBar(...),
///     if (items.isEmpty)
///       AppEmptySliver(
///         title: 'No items yet',
///         message: 'Add your first item to get started.',
///         actionLabel: 'Add Item',
///         onAction: _navigateToCreate,
///       ),
///   ],
/// )
/// ```
class AppEmptySliver extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const AppEmptySliver({
    super.key,
    this.icon         = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AppEmptyView(
        icon:                   icon,
        title:                  title,
        message:                message,
        actionLabel:            actionLabel,
        onAction:               onAction,
        secondaryActionLabel:   secondaryActionLabel,
        onSecondaryAction:      onSecondaryAction,
      ),
    );
  }
}