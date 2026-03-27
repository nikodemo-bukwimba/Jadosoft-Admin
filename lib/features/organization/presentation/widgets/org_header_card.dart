import 'package:flutter/material.dart';
import '../../domain/entities/organization_entity.dart';

class OrgHeaderCard extends StatelessWidget {
  final OrganizationEntity org;
  const OrgHeaderCard({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = switch (org.status) { OrgStatus.active => Colors.green, OrgStatus.pending => Colors.orange, OrgStatus.suspended => Colors.red, _ => Colors.grey };
    return Card(margin: const EdgeInsets.all(16), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      CircleAvatar(radius: 24, backgroundColor: scheme.primaryContainer, child: Icon(Icons.business, color: scheme.onPrimaryContainer)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(org.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (org.description != null) Text(org.description!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(org.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor))),
          const SizedBox(width: 8),
          Text(org.type, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ]),
      ])),
    ])));
  }
}
