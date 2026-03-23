import 'package:flutter/material.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerTableRow extends StatelessWidget {
  final CustomerEntity item;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const CustomerTableRow({super.key, required this.item, required this.isLast, required this.onTap, required this.onDelete});

  @override Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)))),
      child: Row(children: [
        CircleAvatar(radius: 16, backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
          child: Icon(item.isB2B ? Icons.store : Icons.person, color: scheme.primary, size: 16)),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: Text(item.name, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text('${item.customerType.toUpperCase()}${item.category != null ? " · ${item.category}" : ""}',
          style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(item.phone ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
        SizedBox(width: 40, child: IconButton(icon: Icon(Icons.delete_outline, color: scheme.error, size: 18), onPressed: onDelete, padding: EdgeInsets.zero)),
      ])));
  }
}
