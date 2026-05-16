// lib/features/inventory/presentation/pages/inventory_form_page.dart
//
// CHANGE: InventoryFormPage now accepts an optional productId via GoRouter
// `extra` so that navigating from the product detail page pre-selects the
// correct product in the receive-stock form.
//
// Usage from product detail:
//   context.push(AppRouter.inventoryReceiveStock, extra: {'productId': item.id});
//
// Everything else is unchanged from the original.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/di/injection_container.dart';
import '../../../../core/context/org_context.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../bloc/inventory_state.dart';
import '../enums/inventory_form_node.dart';
import '../../domain/entities/inventory_entity.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/bloc/product_state.dart';

class InventoryFormPage extends StatefulWidget {
  final InventoryFormNode mode;

  /// Optional: pre-select a product in receive-stock mode.
  /// Passed via GoRouter extra: {'productId': '...'}.
  final String? preselectedProductId;

  const InventoryFormPage({
    super.key,
    required this.mode,
    this.preselectedProductId,
  });

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();

  // ── Receive stock fields ─────────────────────────────────
  String? _warehouseId;
  String? _productId;
  String? _variantId;
  String? _variantName;
  final _quantityCtrl = TextEditingController();
  final _unitCostCtrl = TextEditingController();
  final _batchNumberCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  DateTime? _expiresAt;
  DateTime? _bestBeforeAt;
  bool _variantTouched = false;

  // ── Create warehouse fields ──────────────────────────────
  final _warehouseNameCtrl = TextEditingController();
  String _warehouseType = 'standard';

  final List<WarehouseEntity> _warehouses = [];

  static const _warehouseTypes = ['standard', 'cold', 'bonded', 'virtual'];

  bool get _isReceiveMode => widget.mode == InventoryFormNode.receiveStock;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _unitCostCtrl.dispose();
    _batchNumberCtrl.dispose();
    _skuCtrl.dispose();
    _warehouseNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgId = sl<OrgContext>().requireRootOrgId();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<InventoryBloc>()),
        if (_isReceiveMode)
          BlocProvider(
            create: (_) => sl<ProductBloc>()..add(ProductLoadAllRequested()),
          ),
      ],
      child: BlocListener<InventoryBloc, InventoryState>(
        listener: (ctx, state) {
          if (state is! InventoryLoaded) return;

          if (state.warehouses.isNotEmpty &&
              _warehouses.length != state.warehouses.length) {
            setState(() {
              _warehouses
                ..clear()
                ..addAll(state.warehouses);
            });
          }

          if (state.receivedBatch != null && state.successMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Stock received successfully.'),
                backgroundColor: Colors.green,
              ),
            );
            ctx.pop();
          }

          if (state.createdWarehouse != null && state.successMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  'Warehouse "${state.createdWarehouse!.name}" created.',
                ),
                backgroundColor: Colors.green,
              ),
            );
            ctx.pop();
          }

          if (state.errorMessage != null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: Text(
              _isReceiveMode ? 'Receive Stock' : 'Add Warehouse',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: _isReceiveMode
                  ? _buildReceiveStockFields(context, orgId)
                  : _buildWarehouseFields(context, orgId),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(context, orgId),
        ),
      ),
    );
  }

  // ── Receive Stock Form ────────────────────────────────────

  List<Widget> _buildReceiveStockFields(BuildContext context, String orgId) {
    return [
      _buildSectionLabel(context, '1. Select Warehouse'),
      const SizedBox(height: 8),
      _buildWarehouseDropdown(context),
      const SizedBox(height: 24),
      _buildSectionLabel(context, '2. Select Product & Variant'),
      const SizedBox(height: 8),
      _buildProductVariantPicker(context),
      if (_variantTouched && _variantId == null)
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            'Please select a product',
            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
          ),
        ),
      const SizedBox(height: 24),
      _buildSectionLabel(context, '3. Batch Details'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: _buildBatchNumberField()),
          const SizedBox(width: 12),
          Expanded(child: _buildSkuField()),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(child: _buildQuantityField()),
          const SizedBox(width: 12),
          Expanded(child: _buildUnitCostField()),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _buildDateField(
              context,
              'Expiry Date',
              Icons.event_outlined,
              _expiresAt,
              (d) => setState(() => _expiresAt = d),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateField(
              context,
              'Best Before',
              Icons.event_available_outlined,
              _bestBeforeAt,
              (d) => setState(() => _bestBeforeAt = d),
            ),
          ),
        ],
      ),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildWarehouseDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _warehouseId,
      decoration: const InputDecoration(
        labelText: 'Warehouse *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse_outlined),
      ),
      hint: const Text('Select warehouse'),
      items: _warehouses
          .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
          .toList(),
      onChanged: (v) => setState(() => _warehouseId = v),
      validator: (v) => v == null ? 'Please select a warehouse' : null,
    );
  }

  Widget _buildProductVariantPicker(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (ctx, state) {
        if (state is ProductLoading) {
          return const LinearProgressIndicator();
        }

        if (state is ProductListLoaded) {
          final active = state.items
              .where((p) => p.status == 'active')
              .toList();

          // Auto-select preselectedProductId on first load
          if (widget.preselectedProductId != null &&
              _productId == null &&
              _variantId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final match = active
                  .where((p) => p.id == widget.preselectedProductId)
                  .firstOrNull;
              if (match != null && mounted) {
                setState(() {
                  _productId = match.id;
                  _variantId = match.variantId;
                  _variantName = match.name;
                  _variantTouched = true;
                });
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _productId,
                decoration: const InputDecoration(
                  labelText: 'Product *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                hint: const Text('Select product'),
                items: active
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p.id,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _variantTouched = true;
                    _productId = v;
                    _variantId = null;
                    _variantName = null;

                    if (v != null) {
                      final p = active.firstWhere((p) => p.id == v);
                      if (p.variantId != null) {
                        _variantId = p.variantId;
                        _variantName = p.name;
                      }
                    }
                  });
                },
              ),
              if (_productId != null && _variantId != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Variant: $_variantName',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }

        if (state is ProductFailure) {
          return Text(state.message);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBatchNumberField() {
    return TextFormField(
      controller: _batchNumberCtrl,
      decoration: const InputDecoration(
        labelText: 'Batch Number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.tag_rounded),
      ),
    );
  }

  Widget _buildSkuField() {
    return TextFormField(
      controller: _skuCtrl,
      decoration: const InputDecoration(
        labelText: 'SKU',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.qr_code_rounded),
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Quantity *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers_rounded),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if ((int.tryParse(v) ?? 0) < 1) return 'Must be ≥ 1';
        return null;
      },
    );
  }

  Widget _buildUnitCostField() {
    return TextFormField(
      controller: _unitCostCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Unit Cost (TZS)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.attach_money_rounded),
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    IconData icon,
    DateTime? value,
    ValueChanged<DateTime?> onPicked,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 365)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
        );
        onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value == null
                    ? label
                    : '${value.day}/${value.month}/${value.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: value == null
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create Warehouse Form ─────────────────────────────────

  List<Widget> _buildWarehouseFields(BuildContext context, String orgId) {
    return [
      _buildSectionLabel(context, 'Warehouse Details'),
      const SizedBox(height: 16),
      TextFormField(
        controller: _warehouseNameCtrl,
        decoration: const InputDecoration(
          labelText: 'Warehouse Name *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.warehouse_outlined),
        ),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Name is required' : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _warehouseType,
        decoration: const InputDecoration(
          labelText: 'Type',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.category_outlined),
        ),
        items: _warehouseTypes
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(t[0].toUpperCase() + t.substring(1)),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _warehouseType = v ?? 'standard'),
      ),
      const SizedBox(height: 40),
    ];
  }

  // ── Shared ────────────────────────────────────────────────

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, String orgId) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: BlocBuilder<InventoryBloc, InventoryState>(
          builder: (ctx, state) {
            final loading = state is InventoryLoaded && state.loading;
            return FilledButton(
              onPressed: loading ? null : () => _submit(ctx, orgId),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isReceiveMode ? 'Receive Stock' : 'Create Warehouse'),
            );
          },
        ),
      ),
    );
  }

  void _submit(BuildContext context, String orgId) {
    if (_isReceiveMode) {
      setState(() => _variantTouched = true);
      if (_warehouseId == null || _variantId == null) return;
      if (!_formKey.currentState!.validate()) return;

      context.read<InventoryBloc>().add(
        InventoryReceiveStockRequested(
          warehouseId: _warehouseId!,
          productId: _productId!,
          variantId: _variantId!,
          orgId: orgId,
          quantity: int.parse(_quantityCtrl.text.trim()),
          unitCost: _unitCostCtrl.text.isNotEmpty
              ? double.tryParse(_unitCostCtrl.text.trim())
              : null,
          currency: 'TZS',
          batchNumber: _batchNumberCtrl.text.isNotEmpty
              ? _batchNumberCtrl.text.trim()
              : null,
          sku: _skuCtrl.text.isNotEmpty ? _skuCtrl.text.trim() : null,
          expiresAt: _expiresAt,
          bestBeforeAt: _bestBeforeAt,
        ),
      );
    } else {
      if (!_formKey.currentState!.validate()) return;
      context.read<InventoryBloc>().add(
        InventoryWarehouseCreateRequested(
          orgId,
          _warehouseNameCtrl.text.trim(),
          _warehouseType,
        ),
      );
    }
  }
}
