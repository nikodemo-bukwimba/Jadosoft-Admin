// lib/features/product/presentation/pages/branch_price_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/context/org_context.dart';
import '../../domain/entities/branch_variant_price_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/branch_pricing_bloc.dart';

// ── Entry-point page ──────────────────────────────────────────────────────────

class BranchPricePage extends StatelessWidget {
  final ProductEntity? product;

  const BranchPricePage({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final orgContext = GetIt.instance<OrgContext>();
        final bloc = BranchPricingBloc(repository: GetIt.instance());
        bloc.add(BranchPricingLoadRequested(orgContext.effectiveOrgId));
        return bloc;
      },
      child: _BranchPriceView(product: product),
    );
  }
}

// ── Main view ─────────────────────────────────────────────────────────────────

class _BranchPriceView extends StatefulWidget {
  final ProductEntity? product;

  const _BranchPriceView({this.product});

  @override
  State<_BranchPriceView> createState() => _BranchPriceViewState();
}

class _BranchPriceViewState extends State<_BranchPriceView> {
  bool _sheetOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_sheetOpened && widget.product != null) {
      _sheetOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openSetSheet(context, product: widget.product);
      });
    }
  }

  String _formatPrice(double v) =>
      'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branch Prices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Set price for a variant',
            onPressed: () => _openSetSheet(context),
          ),
        ],
      ),
      body: BlocConsumer<BranchPricingBloc, BranchPricingState>(
        listener: (context, state) {
          if (state is BranchPricingOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            if (state.updatedOverrides == null) {
              final orgContext = GetIt.instance<OrgContext>();
              context.read<BranchPricingBloc>().add(
                BranchPricingLoadRequested(orgContext.effectiveOrgId),
              );
            }
          }
          if (state is BranchPricingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BranchPricingLoading || state is BranchPricingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          List<BranchVariantPriceEntity> overrides = [];
          if (state is BranchPricingLoaded) overrides = state.overrides;
          if (state is BranchPricingOperationSuccess &&
              state.updatedOverrides != null) {
            overrides = state.updatedOverrides!;
          }

          if (overrides.isEmpty) {
            return _EmptyState(onAdd: () => _openSetSheet(context));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: overrides.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _OverrideTile(
              priceOverride: overrides[i],                          // ← fixed
              formatPrice: _formatPrice,
              onEdit: () => _openSetSheet(context, priceOverride: overrides[i]), // ← fixed
              onRemove: () => _confirmRemove(context, overrides[i]),
            ),
          );
        },
      ),
    );
  }

  void _openSetSheet(
    BuildContext context, {
    BranchVariantPriceEntity? priceOverride,   // ← renamed from 'override'
    ProductEntity? product,
  }) {
    final orgContext = GetIt.instance<OrgContext>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<BranchPricingBloc>(),
        child: _SetBranchPriceSheet(
          orgId: orgContext.effectiveOrgId,
          existingOverride: priceOverride,       // ← fixed
          product: product,
        ),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    BranchVariantPriceEntity priceOverride,    // ← renamed from 'override'
  ) async {
    final label =
        priceOverride.productName ?? priceOverride.variantName ?? 'this variant';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Branch Price?'),
        content: Text(
          'Remove the branch price for "$label"? '
          'It will revert to the root base price.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final orgContext = GetIt.instance<OrgContext>();
      context.read<BranchPricingBloc>().add(
        BranchPricingRemoveRequested(
          orgId: orgContext.effectiveOrgId,
          variantId: priceOverride.variantId,   // ← fixed
        ),
      );
    }
  }
}

// ── Override tile ─────────────────────────────────────────────────────────────

class _OverrideTile extends StatelessWidget {
  final BranchVariantPriceEntity priceOverride;
  final String Function(double) formatPrice;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _OverrideTile({
    required this.priceOverride,
    required this.formatPrice,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final markup = priceOverride.markupPercentage;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.price_change_outlined,
                color: scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceOverride.productName ??
                        priceOverride.variantName ??
                        'Variant ${priceOverride.variantId.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatPrice(priceOverride.price),            // ← fixed
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (priceOverride.variantBasePrice != null) ...[  // ← fixed
                        const SizedBox(width: 6),
                        Text(
                          formatPrice(priceOverride.variantBasePrice!), // ← fixed
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      if (markup != null && markup > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '+${markup.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'remove') onRemove();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit price')),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Remove override',
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Set price bottom sheet ────────────────────────────────────────────────────

class _SetBranchPriceSheet extends StatefulWidget {
  final String orgId;
  final BranchVariantPriceEntity? existingOverride;
  final ProductEntity? product;

  const _SetBranchPriceSheet({
    required this.orgId,
    this.existingOverride,
    this.product,
  });

  @override
  State<_SetBranchPriceSheet> createState() => _SetBranchPriceSheetState();
}

class _SetBranchPriceSheetState extends State<_SetBranchPriceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  bool _saving = false;

  String get _variantId =>
      widget.existingOverride?.variantId ?? widget.product?.variantId ?? '';

  double get _rootBasePrice =>
      widget.existingOverride?.variantBasePrice ?? widget.product?.price ?? 0;

  String get _productLabel =>
      widget.existingOverride?.productName ??
      widget.existingOverride?.variantName ??
      widget.product?.name ??
      'Product';

  @override
  void initState() {
    super.initState();
    if (widget.existingOverride != null) {
      _priceCtrl.text = widget.existingOverride!.price.toStringAsFixed(0);
    } else if (widget.product != null) {
      final current = widget.product!.branchPrice ?? widget.product!.price;
      _priceCtrl.text = current.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  String _formatPrice(double v) =>
      'TZS ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No variant ID available.')),
      );
      return;
    }

    setState(() => _saving = true);

    final price = double.parse(_priceCtrl.text.replaceAll(',', ''));
    context.read<BranchPricingBloc>().add(
      BranchPricingSetRequested(
        orgId: widget.orgId,
        variantId: _variantId,
        price: price,
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.existingOverride != null
                  ? 'Edit Branch Price'
                  : 'Set Branch Price',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _productLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            if (_rootBasePrice > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Root base price: ${_formatPrice(_rootBasePrice)}. '
                        'Branch price must be equal or higher.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Branch Price (TZS)',
                prefixText: 'TZS ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Price is required.';
                final parsed = double.tryParse(v.replaceAll(',', ''));
                if (parsed == null || parsed <= 0) return 'Enter a valid price.';
                if (_rootBasePrice > 0 && parsed < _rootBasePrice) {
                  return 'Cannot be lower than root base price '
                      '(${_rootBasePrice.toStringAsFixed(0)}).';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.price_change_outlined,
              size: 64,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4), // ← fixed
            ),
            const SizedBox(height: 16),
            Text(
              'No Branch Prices Set',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set branch-specific prices for products to reflect '
              'transport costs or regional adjustments.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Set Branch Price'),
            ),
          ],
        ),
      ),
    );
  }
}