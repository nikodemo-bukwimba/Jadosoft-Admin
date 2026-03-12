import 'package:flutter/material.dart';

class SmsGatewayOperationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isLoading;
  final String? error;
  final VoidCallback? onExecute;
  final IconData icon;

  const SmsGatewayOperationCard({
    super.key,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    this.error,
    this.onExecute,
    this.icon = Icons.sync,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: error != null
                        ? scheme.errorContainer
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    error != null ? Icons.error_outline : icon,
                    color: error != null ? scheme.error : scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else if (onExecute != null)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Execute',
                    onPressed: onExecute,
                  ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
