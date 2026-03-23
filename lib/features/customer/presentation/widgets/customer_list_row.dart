import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerListRow extends StatelessWidget {
  final CustomerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const CustomerListRow({super.key, required this.item, required this.onTap, required this.onDelete});

  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.only(bottom: 2), child: Material(color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
            child: Icon(item.isB2B ? Icons.store : Icons.person, color: scheme.primary, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${item.customerType.toUpperCase()} · ${item.phone ?? ""}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (item.hasGps) Icon(Icons.gps_fixed, size: 16, color: scheme.primary.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          SizedBox(width: 36, child: IconButton(icon: Icon(Icons.delete_outline, color: scheme.error, size: 18),
            onPressed: onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints())),
        ])))));
  }
}
