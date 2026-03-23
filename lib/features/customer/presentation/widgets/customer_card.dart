import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const CustomerCard({super.key, required this.item, required this.onTap, required this.onDelete});

  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(onTap: onTap,
      title: Text(item.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('${item.customerType.toUpperCase()} ${item.category != null ? "· ${item.category}" : ""} · ${item.phone ?? ""}'),
      trailing: IconButton(icon: Icon(Icons.delete_outline, color: scheme.error), tooltip: 'Delete',
        onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: const Text('Delete?'), content: Text('Remove "${item.name}"?'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(style: FilledButton.styleFrom(backgroundColor: scheme.error), onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))]));
          if (ok == true) onDelete();
        })));
  }
}
