import 'package:flutter/material.dart';
import '../../domain/entities/officer_entity.dart';
import '../../domain/value_objects/officer_status.dart';
import 'officer_avatar.dart';
import 'officer_status_badge.dart';

class OfficerCardTile extends StatelessWidget {
  final OfficerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const OfficerCardTile({super.key, required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = OfficerStatusX.fromString(item.effectiveStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          OfficerAvatar(name: item.displayName, status: item.effectiveStatus, radius: 26),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.displayName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              OfficerStatusBadge(status: statusEnum, compact: true),
            ]),
            const SizedBox(height: 4),
            Text(item.orgRoleName ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.email_outlined, size: 14, color: scheme.onSurfaceVariant), const SizedBox(width: 4),
              Expanded(child: Text(item.email, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.phone_outlined, size: 14, color: scheme.onSurfaceVariant), const SizedBox(width: 4),
              Text(item.phone ?? '', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ])),
          const SizedBox(width: 4),
          IconButton(icon: Icon(Icons.delete_outline, color: scheme.error, size: 20), tooltip: 'Delete', onPressed: onDelete),
        ]))),
    );
  }
}
