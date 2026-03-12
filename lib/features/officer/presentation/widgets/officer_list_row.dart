import 'package:flutter/material.dart';
import '../../domain/entities/officer_entity.dart';
import '../../domain/value_objects/officer_status.dart';
import 'officer_avatar.dart';
import 'officer_status_badge.dart';

/// List view row — compact with small avatar.
class OfficerListRow extends StatelessWidget {
  final OfficerEntity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OfficerListRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusEnum = OfficerStatusX.fromString(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                OfficerAvatar(name: item.name, status: item.status, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.role,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                OfficerStatusBadge(status: statusEnum, compact: true),
                const SizedBox(width: 4),
                SizedBox(
                  width: 36,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: scheme.error, size: 18),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}