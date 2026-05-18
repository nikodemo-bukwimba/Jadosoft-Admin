// lib/features/inventory/presentation/widgets/inventory_warehouse_card.dart

import 'package:flutter/material.dart';
import '../../domain/entities/inventory_entity.dart';

class InventoryWarehouseCard extends StatelessWidget {
  final WarehouseEntity warehouse;

  const InventoryWarehouseCard({super.key, required this.warehouse});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _typeIcon(),
            color: scheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        title: Text(
          warehouse.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          warehouse.type[0].toUpperCase() + warehouse.type.substring(1),
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: warehouse.isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            warehouse.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              color: warehouse.isActive
                  ? Colors.green.shade700
                  : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon() {
    return switch (warehouse.type) {
      'cold' => Icons.ac_unit_rounded,
      'bonded' => Icons.lock_outlined,
      'virtual' => Icons.cloud_outlined,
      _ => Icons.warehouse_outlined,
    };
  }
}