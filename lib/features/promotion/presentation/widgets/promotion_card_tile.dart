import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/value_objects/promotion_status.dart';
import '../../data/datasources/promotion_mock_datasource.dart';
import '../widgets/promotion_status_badge.dart';

class PromotionCardTile extends StatelessWidget {
  final PromotionEntity item;
  const PromotionCardTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = PromotionStatusX.fromString(item.status);
    final isActive = status == PromotionStatus.active;
    final isDraft = status == PromotionStatus.draft;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.green.withOpacity(0.4)
              : theme.colorScheme.outlineVariant,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/promotions/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 20,
                      color: status.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_fmtDate(item.startDate)} – ${_fmtDate(item.endDate)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PromotionStatusBadge(status: status, compact: true),
                ],
              ),
              // Description
              if (item.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // Products
              Wrap(
                spacing: 5,
                runSpacing: 4,
                children: item.productIds.take(3).map((id) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      PromotionMockDataSource.productName(id),
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10),
                    ),
                  );
                }).toList()
                  ..addAll(item.productIds.length > 3
                      ? [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${item.productIds.length - 3} more',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(fontSize: 10),
                            ),
                          )
                        ]
                      : []),
              ),
              const SizedBox(height: 10),
              // Footer
              Row(
                children: [
                  // Channels
                  ..._channelIcons(item.channels, theme),
                  const Spacer(),
                  // Broadcast count (active/ended)
                  if (!isDraft && item is dynamic)
                    _broadcastCount(item, theme),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _channelIcons(List<String> channels, ThemeData theme) {
    return channels.map((c) {
      final icon = c == 'sms'
          ? Icons.sms_outlined
          : c == 'whatsapp'
              ? Icons.chat_outlined
              : Icons.notifications_outlined;
      final color = c == 'sms'
          ? Colors.orange
          : c == 'whatsapp'
              ? const Color(0xFF25D366)
              : Colors.indigo;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Text(
                c == 'sms'
                    ? 'SMS'
                    : c == 'whatsapp'
                        ? 'WhatsApp'
                        : 'In-App',
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _broadcastCount(PromotionEntity item, ThemeData theme) {
    // Access targetCount from PromotionModel if available
    final count = (item as dynamic).targetCount as int? ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_outline,
            size: 13,
            color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$count customers reached',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}