// promotion_tiles.dart
// Removed all references to PromotionMockDataSource.productName().
// Product IDs are displayed as-is until the Product feature (Seq 7)
// provides a name cache/repository.
//
// UPDATED: List row and table row now show discount percentage when set.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/value_objects/promotion_status.dart';
import '../widgets/promotion_status_badge.dart';

// ─── List Row ──────────────────────────────────────────────────────────────

class PromotionListRow extends StatelessWidget {
  final PromotionEntity item;
  const PromotionListRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = PromotionStatusX.fromString(item.status);
    final hasDiscount = item.discountPercentage != null;

    return InkWell(
      onTap: () => context.go('/promotions/${item.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasDiscount
                    ? Icons.local_offer_outlined
                    : Icons.campaign_outlined,
                size: 18,
                color: status.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${item.productIds.length} products · '
                        '${_fmtDate(item.startDate)} – ${_fmtDate(item.endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        _InlineDiscountBadge(
                          percentage: item.discountPercentage!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PromotionStatusBadge(status: status, compact: true),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

// ─── Table Row ─────────────────────────────────────────────────────────────

class PromotionTableRow extends StatelessWidget {
  final PromotionEntity? item;
  const PromotionTableRow({super.key, this.item});
  const PromotionTableRow.header({super.key}) : item = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (item == null) return _buildHeader(theme);
    return _buildRow(context, theme);
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _hcell('Title', flex: 3, theme: theme),
          _hcell('Products', flex: 2, theme: theme),
          _hcell('Discount', flex: 1, theme: theme),
          _hcell('Channels', flex: 2, theme: theme),
          _hcell('Date Range', flex: 2, theme: theme),
          _hcell('Status', flex: 1, theme: theme),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, ThemeData theme) {
    final e = item!;
    final status = PromotionStatusX.fromString(e.status);

    final productDisplay = e.productIds.isEmpty
        ? '—'
        : e.productIds.take(2).join(', ') +
              (e.productIds.length > 2 ? ' +${e.productIds.length - 2}' : '');

    final discountDisplay = e.discountPercentage != null
        ? '${e.discountPercentage!.toStringAsFixed(e.discountPercentage! % 1 == 0 ? 0 : 1)}%'
        : '—';

    return InkWell(
      onTap: () => context.go('/promotions/${e.id}'),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                e.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                productDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: e.discountPercentage != null
                  ? Text(
                      discountDisplay,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Text(
                      '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                e.channels
                    .map(
                      (c) => c == 'sms'
                          ? 'SMS'
                          : c == 'whatsapp'
                          ? 'WhatsApp'
                          : 'In-App',
                    )
                    .join(', '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${_fmtDate(e.startDate)} – ${_fmtDate(e.endDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: PromotionStatusBadge(status: status, compact: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hcell(String text, {required int flex, required ThemeData theme}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
          fontSize: 10,
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

// ─── Inline Discount Badge ─────────────────────────────────────────────────

class _InlineDiscountBadge extends StatelessWidget {
  final double percentage;
  const _InlineDiscountBadge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final label = percentage % 1 == 0
        ? '${percentage.toInt()}%'
        : '${percentage.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepOrange.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          color: Colors.deepOrange,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
