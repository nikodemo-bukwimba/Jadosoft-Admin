import 'package:flutter/material.dart';
import '../../domain/entities/officer_entity.dart';
import '../../domain/value_objects/officer_status.dart';
import 'officer_avatar.dart';
import 'officer_status_badge.dart';

/// Details view row — table-style with aligned columns.
class OfficerTableRow extends StatelessWidget {
  final OfficerEntity item;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OfficerTableRow({
    super.key,
    required this.item,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = OfficerStatusX.fromString(item.status);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: Row(
          children: [
            OfficerAvatar(name: item.name, status: item.status, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                item.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.role,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.phone,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: OfficerStatusBadge(status: statusEnum, compact: true),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error, size: 18),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}