import 'package:flutter/material.dart';
import '../../domain/entities/weekly_plan_entity.dart';
import '../../domain/value_objects/weekly_plan_status.dart';

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _officerLabel(WeeklyPlanEntity item) =>
    (item.officerName != null && item.officerName!.isNotEmpty)
    ? item.officerName!
    : 'Officer ID: ${item.officerId.length > 10 ? item.officerId.substring(0, 10) : item.officerId}...';

class WeeklyPlanCardTile extends StatelessWidget {
  final WeeklyPlanEntity item;
  final VoidCallback onTap;
  const WeeklyPlanCardTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = WeeklyPlanStatusX.fromString(item.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: st.color.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.calendar_month,
                      color: st.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_fmtDate(item.weekStart)} – ${_fmtDate(item.weekEnd)}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        // In WeeklyPlanCardTile, replace the officer name Row:
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 13,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              // ← ADD Expanded
                              child: Text(
                                _officerLabel(item),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis, // ← ADD
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: st.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: st.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      st.displayName,
                      style: TextStyle(
                        color: st.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.items.isNotEmpty ? item.items.length : (item.plannedCustomerIds?.length ?? 0)} visit(s) planned',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (item.plannedActivities != null &&
                  item.plannedActivities!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.plannedActivities!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WeeklyPlanListRow extends StatelessWidget {
  final WeeklyPlanEntity item;
  final VoidCallback onTap;
  const WeeklyPlanListRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = WeeklyPlanStatusX.fromString(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: st.color.withValues(alpha: 0.15),
                child: Icon(Icons.calendar_month, color: st.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmtDate(item.weekStart)} – ${_fmtDate(item.weekEnd)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _officerLabel(item),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  st.displayName,
                  style: TextStyle(
                    color: st.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeeklyPlanTableRow extends StatelessWidget {
  final WeeklyPlanEntity item;
  final bool isLast;
  final VoidCallback onTap;
  const WeeklyPlanTableRow({
    super.key,
    required this.item,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final st = WeeklyPlanStatusX.fromString(item.status);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.3),
                  ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: st.color.withValues(alpha: 0.15),
              child: Icon(Icons.calendar_month, color: st.color, size: 14),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fmtDate(item.weekStart)} – ${_fmtDate(item.weekEnd)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _officerLabel(item),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${item.items.isNotEmpty ? item.items.length : (item.plannedCustomerIds?.length ?? 0)}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  st.displayName,
                  style: TextStyle(
                    color: st.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
