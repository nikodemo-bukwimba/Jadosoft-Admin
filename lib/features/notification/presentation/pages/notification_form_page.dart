// notification_form_page.dart
// ─────────────────────────────────────────────────────────────
// DEPRECATED — NotificationFormPage has no backend to talk to.
//
// The backend NotificationController exposes only:
//   GET  /notifications          (list)
//   GET  /notifications/{id}     (show)
//   POST /notifications/{id}/retry
//
// Notifications are created exclusively by the Laravel queue job
// SendProductUpdateToCustomer when a promotion is published.
// There is no admin-facing create / update / delete endpoint.
//
// This page now renders a clear informational screen so that
// any route that accidentally navigates here does not crash,
// and the developer knows to remove the route registration.
//
// ACTION: Remove the promotionCreate / notificationCreate routes
// from your router, and remove this file once confirmed.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../enums/notification_form_node.dart';

class NotificationFormPage extends StatelessWidget {
  // Parameters kept so existing router references compile cleanly.
  final NotificationFormNode mode;
  final String? id;

  const NotificationFormPage({
    super.key,
    this.mode = NotificationFormNode.create,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Available')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Notifications cannot be created manually.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Deliveries are generated automatically when a promotion '
                'is published. Use the Delivery Center to view and retry '
                'failed deliveries.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}