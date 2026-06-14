// ─── Admin Inventory Card ─────────────────────────────────────────────────────
// Reads live stock from GetVariantStockUseCase.
// Falls back to product metadata when variantId is null.
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/context/org_context.dart';
import '../../domain/entities/product_entity.dart';
import '../../../inventory/domain/entities/inventory_entity.dart';
import '../../../inventory/domain/usecases/get_variant_stock_usecase.dart';

class AdminInventoryCard extends StatefulWidget {
  final ProductEntity item;
  final ColorScheme scheme;

  const AdminInventoryCard({required this.item, required this.scheme});

  @override
  State<AdminInventoryCard> createState() => AdminInventoryCardState();
}

class AdminInventoryCardState extends State<AdminInventoryCard> {
  VariantStockEntity? _stock;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final variantId = widget.item.variantId;
    if (variantId == null || variantId.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orgId = GetIt.instance<OrgContext>().requireRootOrgId();
      final useCase = GetIt.instance<GetVariantStockUseCase>();
      final result = await useCase(
        GetVariantStockParams(orgId: orgId, variantId: variantId),
      );
      result.fold(
        (f) {
          if (mounted)
            setState(() {
              _loading = false;
              _error = f.message;
            });
        },
        (stock) {
          if (mounted)
            setState(() {
              _loading = false;
              _stock = stock;
            });
        },
      );
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    final item = widget.item;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Stock Availability',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (item.variantId != null)
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _load,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const Divider(height: 24),

            if (item.variantId == null || item.variantId!.isEmpty)
              _staticFallback(context, item, scheme)
            else if (_loading && _stock == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _stock == null) ...[
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: scheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Could not load live stock.',
                      style: TextStyle(fontSize: 12, color: scheme.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _staticFallback(context, item, scheme),
            ] else if (_stock != null)
              _liveStock(context, _stock!, scheme),
          ],
        ),
      ),
    );
  }

  Widget _staticFallback(
    BuildContext context,
    ProductEntity item,
    ColorScheme scheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(context, 'Batch No.', item.batchNumber ?? '—', scheme),
        _row(context, 'Pack Size', item.packSize ?? '—', scheme),
        _row(
          context,
          'Available Qty',
          item.quantityAvailable?.toString() ?? '—',
          scheme,
        ),
        if (item.expiryDate != null)
          _row(context, 'Expiry Date', _fmt(item.expiryDate!), scheme),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live stock tracking will appear once this product is stocked in a warehouse.',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _liveStock(
    BuildContext context,
    VariantStockEntity stock,
    ColorScheme scheme,
  ) {
    final batches = stock.batches;
    final active = batches
        .where(
          (b) => b.isActive && !b.isExpired && !b.isNearExpiry && !b.isDepleted,
        )
        .toList();
    final nearExpiry = batches
        .where((b) => b.isNearExpiry && !b.isExpired)
        .toList();
    final expired = batches.where((b) => b.isExpired).toList();
    final depleted = batches
        .where((b) => b.isDepleted && !b.isExpired)
        .toList();

    final isLow = stock.totalStock > 0 && stock.totalStock <= 10;
    final isDepleted = stock.totalStock <= 0;
    final stockColor = isDepleted
        ? scheme.error
        : isLow
        ? Colors.orange.shade700
        : Colors.green.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: stockColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: stockColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isDepleted
                    ? Icons.remove_shopping_cart_outlined
                    : Icons.inventory_2_outlined,
                color: stockColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Available Stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: stockColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${stock.totalStock} units',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDepleted)
                _badge(
                  'OUT OF STOCK',
                  scheme.errorContainer,
                  scheme.onErrorContainer,
                )
              else if (isLow)
                _badge(
                  'LOW STOCK',
                  Colors.orange.withValues(alpha: 0.15),
                  Colors.orange.shade800,
                ),
            ],
          ),
        ),
        if (batches.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (expired.isNotEmpty) ...[
            _groupLabel('Expired (${expired.length})', Colors.red.shade700),
            ...expired.map((b) => _batchRow(context, b, scheme)),
            const SizedBox(height: 10),
          ],
          if (nearExpiry.isNotEmpty) ...[
            _groupLabel(
              'Near Expiry (${nearExpiry.length})',
              Colors.orange.shade700,
            ),
            ...nearExpiry.map((b) => _batchRow(context, b, scheme)),
            const SizedBox(height: 10),
          ],
          if (active.isNotEmpty) ...[
            _groupLabel('Active (${active.length})', Colors.green.shade700),
            ...active.map((b) => _batchRow(context, b, scheme)),
          ],
          if (depleted.isNotEmpty) ...[
            const SizedBox(height: 10),
            _groupLabel('Depleted (${depleted.length})', Colors.grey.shade600),
            ...depleted.map((b) => _batchRow(context, b, scheme)),
          ],
        ],
      ],
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
    ),
  );

  Widget _groupLabel(String label, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );

  Widget _batchRow(
    BuildContext context,
    InventoryBatchEntity batch,
    ColorScheme scheme,
  ) {
    final statusColor = batch.isExpired
        ? Colors.red.shade700
        : batch.isNearExpiry
        ? Colors.orange.shade700
        : batch.isDepleted
        ? Colors.grey.shade600
        : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  batch.batchNumber != null
                      ? 'Batch: ${batch.batchNumber}'
                      : 'Batch: ${batch.id.substring(0, 8)}…',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${batch.quantityAvailable} units',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (batch.warehouseName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.warehouse_outlined,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  batch.warehouseName,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
          if (batch.expiresAt != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 12,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${_fmt(batch.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: batch.isExpired
                        ? Colors.red.shade700
                        : batch.isNearExpiry
                        ? Colors.orange.shade700
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value,
    ColorScheme scheme,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
