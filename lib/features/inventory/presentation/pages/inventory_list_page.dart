// lib/features/inventory/presentation/pages/inventory_list_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/app_router.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/context/org_context.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../widgets/inventory_batch_card.dart';
import '../widgets/inventory_section_header.dart';
import '../../domain/entities/inventory_entity.dart';

class InventoryListPage extends StatelessWidget {
  const InventoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final orgId = sl<OrgContext>().effectiveOrgId;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          backgroundColor: scheme.surface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Stock & Warehouses',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(AppRouter.inventoryReceiveStock);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Receive Stock'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
          bottom: TabBar(
            labelColor: scheme.primary,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: scheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                text: 'Stock Batches',
                icon: Icon(Icons.inventory_2_outlined, size: 18),
              ),
              Tab(
                text: 'Warehouses',
                icon: Icon(Icons.warehouse_outlined, size: 18),
              ),
            ],
          ),
        ),
        body: BlocConsumer<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryLoaded && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!), // fix: was state.message
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state is InventoryLoaded && state.createdWarehouse != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Warehouse "${state.createdWarehouse!.name}" created.', // fix: was state.warehouse
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              context.read<InventoryBloc>().add(
                InventoryWarehousesLoadRequested(orgId),
              );
            }
          },
          builder: (context, state) {
            return TabBarView(
              children: [
                _buildBatchesTab(context, state, orgId),
                _buildWarehousesTab(context, state, orgId),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Batches tab ───────────────────────────────────────────

  Widget _buildBatchesTab(
    BuildContext context,
    InventoryState state,
    String orgId,
  ) {
    if (state is InventoryLoaded && state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is InventoryLoaded) {
      if (state.batches.isEmpty) {
        return _buildEmptyBatches(context);
      }
      return _buildBatchList(context, state.batches);
    }
    return _buildEmptyBatches(context);
  }

  Widget _buildBatchList(
    BuildContext context,
    List<InventoryBatchEntity> batches,
  ) {
    final expired = batches.where((b) => b.isExpired).toList();
    final nearExpiry = batches
        .where((b) => !b.isExpired && b.isNearExpiry)
        .toList();
    final active = batches
        .where((b) => b.isActive && !b.isExpired && !b.isNearExpiry)
        .toList();
    final depleted = batches
        .where((b) => b.isDepleted && !b.isExpired)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (expired.isNotEmpty) ...[
          InventorySectionHeader(
            label: 'Expired (${expired.length})',
            color: Colors.red.shade700,
          ),
          ...expired.map((b) => InventoryBatchCard(batch: b)),
          const SizedBox(height: 8),
        ],
        if (nearExpiry.isNotEmpty) ...[
          InventorySectionHeader(
            label: 'Near Expiry (${nearExpiry.length})',
            color: Colors.orange.shade700,
          ),
          ...nearExpiry.map((b) => InventoryBatchCard(batch: b)),
          const SizedBox(height: 8),
        ],
        if (active.isNotEmpty) ...[
          InventorySectionHeader(
            label: 'Active (${active.length})',
            color: Colors.green.shade700,
          ),
          ...active.map((b) => InventoryBatchCard(batch: b)),
          const SizedBox(height: 8),
        ],
        if (depleted.isNotEmpty) ...[
          InventorySectionHeader(
            label: 'Depleted (${depleted.length})',
            color: Colors.grey.shade600,
          ),
          ...depleted.map((b) => InventoryBatchCard(batch: b)),
        ],
      ],
    );
  }

  Widget _buildEmptyBatches(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No stock batches yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Receive Stock" to add your first batch.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ── Warehouses tab ────────────────────────────────────────

  Widget _buildWarehousesTab(
    BuildContext context,
    InventoryState state,
    String orgId,
  ) {
    // fix: removed duplicate ternary; InventoryLoading doesn't exist — use loading flag
    final warehouses = state is InventoryLoaded
        ? state.warehouses
        : <WarehouseEntity>[];

    if (state is InventoryLoaded && state.loading && warehouses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildWarehouseList(context, warehouses, orgId);
  }

  Widget _buildWarehouseList(
    BuildContext context,
    List<WarehouseEntity> warehouses,
    String orgId,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push(AppRouter.inventoryWarehouseCreate),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Warehouse'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        if (warehouses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No warehouses yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...warehouses.map((w) => _buildWarehouseCard(context, w, scheme)),
      ],
    );
  }

  Widget _buildWarehouseCard(
    BuildContext context,
    WarehouseEntity w,
    ColorScheme scheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _warehouseIcon(w.type),
            color: scheme.onPrimaryContainer,
            size: 22,
          ),
        ),
        title: Text(
          w.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          w.type[0].toUpperCase() + w.type.substring(1),
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: w.isActive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            w.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              color: w.isActive ? Colors.green.shade700 : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  IconData _warehouseIcon(String type) {
    return switch (type) {
      'cold' => Icons.ac_unit_rounded,
      'bonded' => Icons.lock_outlined,
      'virtual' => Icons.cloud_outlined,
      _ => Icons.warehouse_outlined,
    };
  }
}
