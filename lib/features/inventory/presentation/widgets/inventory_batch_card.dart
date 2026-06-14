// lib/features/inventory/presentation/widgets/inventory_batch_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/inventory_entity.dart';

class InventoryBatchCard extends StatelessWidget {
  final InventoryBatchEntity batch;

  const InventoryBatchCard({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM yyyy');

    final statusColor = _statusColor();
    final statusLabel = _statusLabel();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: batch.isExpired
              ? Colors.red.shade200
              : batch.isNearExpiry
              ? Colors.orange.shade200
              : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, statusColor, statusLabel),
            const SizedBox(height: 12),
            _buildStockRow(context),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _buildMetaRow(context, fmt, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Color statusColor,
    String statusLabel,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product name (primary) ──
              Text(
                batch.productName ?? 'Unknown Product',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (batch.variantName != null &&
                  batch.variantName!.isNotEmpty &&
                  batch.variantName != batch.productName) ...[
                const SizedBox(height: 2),
                Text(
                  batch.variantName!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2),
              // ── Batch / SKU (secondary) ──
              if (batch.batchNumber != null)
                Text(
                  'Batch #${batch.batchNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (batch.sku != null)
                Text(
                  'SKU: ${batch.sku}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              if (batch.batchNumber == null && batch.sku == null)
                Text(
                  'Batch ID: ...${batch.id.substring(batch.id.length - 8)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusChip(statusColor, statusLabel),
      ],
    );
  }

  Widget _buildStatusChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStockRow(BuildContext context) {
    return Row(
      children: [
        _InventoryStatItem(
          label: 'Available',
          value: batch.availableQuantity.toString(),
          color: Colors.green.shade700,
        ),
        const SizedBox(width: 20),
        _InventoryStatItem(
          label: 'Reserved',
          value: batch.quantityReserved.toString(),
          color: Colors.orange.shade700,
        ),
        const SizedBox(width: 20),
        _InventoryStatItem(
          label: 'Received',
          value: batch.quantityReceived.toString(),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildMetaRow(
    BuildContext context,
    DateFormat fmt,
    ColorScheme scheme,
  ) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _InventoryMetaChip(
          icon: Icons.warehouse_outlined,
          label: batch.warehouseName.isNotEmpty
              ? batch.warehouseName
              : 'Warehouse',
        ),
        if (batch.expiresAt != null)
          _InventoryMetaChip(
            icon: Icons.schedule_rounded,
            label: 'Exp: ${fmt.format(batch.expiresAt!)}',
            color: batch.isExpired
                ? Colors.red.shade700
                : batch.isNearExpiry
                ? Colors.orange.shade700
                : null,
          ),
        if (batch.unitCost != null)
          _InventoryMetaChip(
            icon: Icons.attach_money_rounded,
            label:
                '${batch.currency} ${batch.unitCost!.toStringAsFixed(0)}/unit',
          ),
      ],
    );
  }

  Color _statusColor() {
    if (batch.isExpired) return Colors.red.shade700;
    if (batch.isNearExpiry) return Colors.orange.shade700;
    if (batch.isDepleted) return Colors.grey;
    return Colors.green.shade700;
  }

  String _statusLabel() {
    if (batch.isExpired) return 'Expired';
    if (batch.isNearExpiry) return 'Near Expiry';
    if (batch.isDepleted) return 'Depleted';
    return 'Active';
  }
}

class _InventoryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InventoryStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InventoryMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InventoryMetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}
