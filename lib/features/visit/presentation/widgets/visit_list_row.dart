import 'package:flutter/material.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/value_objects/visit_status.dart';

class VisitListRow extends StatelessWidget {
  final VisitEntity item;
  final VoidCallback onTap;
  const VisitListRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: st.color.withValues(alpha: 0.15),
              child: Icon(Icons.location_on, color: st.color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.businessName ?? 'Unknown', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(item.visitDate.toIso8601String().split('T').first,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: st.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(st.displayName, style: TextStyle(color: st.color, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }
}

class VisitTableRow extends StatelessWidget {
  final VisitEntity item;
  final bool isLast;
  final VoidCallback onTap;
  const VisitTableRow({super.key, required this.item, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = VisitStatusX.fromString(item.status);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: isLast ? BorderSide.none : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)))),
        child: Row(children: [
          CircleAvatar(radius: 14, backgroundColor: st.color.withValues(alpha: 0.15),
            child: Icon(Icons.location_on, color: st.color, size: 14)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(item.businessName ?? 'Unknown', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(item.visitDate.toIso8601String().split('T').first, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: st.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(st.displayName, style: TextStyle(color: st.color, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          )),
        ]),
      ),
    );
  }
}