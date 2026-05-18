// promotion_form_page.dart
// Products are fetched from the real Nexora Commerce Products endpoint:
//   GET /api/v1/commerce/orgs/{orgId}/products?per_page=200&status=active
// No hardcoded product map. Products load on page init via _loadProducts().
//
// UPDATED: Added discount_percentage field (optional).
//   null  → normal product campaign
//   0-100 → discount campaign (percentage)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../product/data/datasources/product_remote_datasource.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/usecases/create_promotion_usecase.dart';
import '../../../../core/widgets/searchable_picker_sheet.dart';
import '../bloc/promotion_bloc.dart';
import '../bloc/promotion_event.dart';
import '../bloc/promotion_state.dart';
import '../enums/promotion_form_node.dart';

class PromotionFormPage extends StatefulWidget {
  final PromotionFormNode mode;
  final String? id;

  const PromotionFormPage({super.key, required this.mode, this.id});

  @override
  State<PromotionFormPage> createState() => _PromotionFormPageState();
}

class _PromotionFormPageState extends State<PromotionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final List<String> _selectedProducts = [];
  final List<String> _selectedChannels = ['sms', 'whatsapp'];
  bool _hasDiscount = false;

  bool _populated = false;
  PromotionEntity? _originalEntity;

  // ── Product catalogue (loaded from API) ───────────────────
  Map<String, String> _productMap = {};
  bool _productsLoading = true;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _loadProducts();

    if (widget.mode == PromotionFormNode.edit) {
      final currentState = context.read<PromotionBloc>().state;
      if (currentState is PromotionDetailLoaded) {
        _populate(currentState.item);
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _productsLoading = true;
      _productsError = null;
    });

    try {
      final productDs = GetIt.instance<ProductRemoteDataSource>();
      final products = await productDs.getAll();

      final map = <String, String>{
        for (final p in products)
          if (p.id.isNotEmpty) p.id: p.name,
      };

      if (mounted) {
        setState(() {
          _productMap = map;
          _productsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _productsLoading = false;
          _productsError = 'Failed to load products. Tap to retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  void _populate(PromotionEntity item) {
    if (_populated) return;
    _populated = true;
    _originalEntity = item;
    _titleCtrl.text = item.title;
    _descCtrl.text = item.description ?? '';
    _startDate = item.startDate;
    _endDate = item.endDate;
    _selectedProducts
      ..clear()
      ..addAll(item.productIds);
    _selectedChannels
      ..clear()
      ..addAll(item.channels);

    if (item.discountPercentage != null) {
      _hasDiscount = true;
      _discountCtrl.text = item.discountPercentage!.toStringAsFixed(
        item.discountPercentage! % 1 == 0 ? 0 : 2,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.mode == PromotionFormNode.edit;
    final isWide = MediaQuery.of(context).size.width > 768;

    return BlocConsumer<PromotionBloc, PromotionState>(
      listenWhen: (_, state) =>
          state is PromotionOperationSuccess || state is PromotionFailure,

      listener: (context, state) {
        if (state is PromotionOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );

          context.go('/promotions');
        }

        if (state is PromotionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },

      builder: (context, state) {
        if (isEdit && state is PromotionDetailLoaded) {
          _populate(state.item);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Promotion' : 'New Promotion'),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Promotion Details ─────────────────────
                      _SectionCard(
                        title: 'Promotion Details',
                        icon: Icons.campaign_outlined,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Title *',
                                hintText: 'e.g. October Antibiotics Campaign',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                if (v.trim().length < 3) {
                                  return 'At least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText:
                                    'Optional — describe the promotion goal and target audience',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Discount / Campaign Type ──────────────
                      _SectionCard(
                        title: 'Campaign Type',
                        icon: Icons.local_offer_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toggle between product campaign and discount campaign
                            Row(
                              children: [
                                Expanded(
                                  child: _CampaignTypeButton(
                                    label: 'Product Campaign',
                                    subtitle:
                                        'Announce new or featured products',
                                    icon: Icons.medication_outlined,
                                    selected: !_hasDiscount,
                                    onTap: () => setState(() {
                                      _hasDiscount = false;
                                      _discountCtrl.clear();
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CampaignTypeButton(
                                    label: 'Discount Campaign',
                                    subtitle: 'Offer a percentage discount',
                                    icon: Icons.percent_outlined,
                                    selected: _hasDiscount,
                                    onTap: () =>
                                        setState(() => _hasDiscount = true),
                                  ),
                                ),
                              ],
                            ),
                            if (_hasDiscount) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _discountCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d{0,3}(\.\d{0,2})?'),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Discount Percentage *',
                                  hintText: 'e.g. 15',
                                  border: const OutlineInputBorder(),
                                  suffixText: '%',
                                  suffixStyle: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  helperText:
                                      'Applied to all selected products. '
                                      'Variant-level overrides can be set after publishing.',
                                ),
                                validator: (v) {
                                  if (!_hasDiscount) return null;
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Discount percentage is required';
                                  }
                                  final parsed = double.tryParse(v.trim());
                                  if (parsed == null) {
                                    return 'Enter a valid number';
                                  }
                                  if (parsed < 0 || parsed > 100) {
                                    return 'Must be between 0 and 100';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Date Range ────────────────────────────
                      _SectionCard(
                        title: 'Date Range',
                        icon: Icons.date_range_outlined,
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _DateField(
                                      label: 'Start Date',
                                      value: _startDate,
                                      onChanged: (d) =>
                                          setState(() => _startDate = d),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _DateField(
                                      label: 'End Date',
                                      value: _endDate,
                                      firstDate: _startDate,
                                      onChanged: (d) =>
                                          setState(() => _endDate = d),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _DateField(
                                    label: 'Start Date',
                                    value: _startDate,
                                    onChanged: (d) =>
                                        setState(() => _startDate = d),
                                  ),
                                  const SizedBox(height: 12),
                                  _DateField(
                                    label: 'End Date',
                                    value: _endDate,
                                    firstDate: _startDate,
                                    onChanged: (d) =>
                                        setState(() => _endDate = d),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),

                      // ── Broadcast Channels ────────────────────
                      _SectionCard(
                        title: 'Broadcast Channels',
                        icon: Icons.cell_tower_outlined,
                        child: Column(
                          children: [
                            _ChannelToggle(
                              channel: 'sms',
                              label: 'SMS',
                              subtitle: 'Vodacom / Airtel / Yas gateway',
                              icon: Icons.sms_outlined,
                              color: Colors.orange,
                              selected: _selectedChannels.contains('sms'),
                              onToggle: (v) => setState(() {
                                if (v) {
                                  _selectedChannels.add('sms');
                                } else {
                                  _selectedChannels.remove('sms');
                                }
                              }),
                            ),
                            const SizedBox(height: 8),
                            _ChannelToggle(
                              channel: 'whatsapp',
                              label: 'WhatsApp',
                              subtitle: 'WhatsApp Business API',
                              icon: Icons.chat_outlined,
                              color: const Color(0xFF25D366),
                              selected: _selectedChannels.contains('whatsapp'),
                              onToggle: (v) => setState(() {
                                if (v) {
                                  _selectedChannels.add('whatsapp');
                                } else {
                                  _selectedChannels.remove('whatsapp');
                                }
                              }),
                            ),
                            if (_selectedChannels.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Select at least one channel',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Products ──────────────────────────────
                      _SectionCard(
                        title:
                            'Products to Promote (${_selectedProducts.length} selected)',
                        icon: Icons.medication_outlined,
                        child: _productsLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Loading products…',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _productsError != null
                            ? _ProductsErrorState(
                                message: _productsError!,
                                onRetry: _loadProducts,
                              )
                            : _ProductPickerField(
                                selectedProducts: _selectedProducts,
                                productMap: _productMap,
                                onChanged: (selected) => setState(() {
                                  _selectedProducts.clear();
                                  _selectedProducts.addAll(selected);
                                }),
                              ),
                      ),
                      if (_selectedProducts.isEmpty &&
                          !_productsLoading &&
                          _productsError == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Select at least one product',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // ── Submit ────────────────────────────────
                      BlocBuilder<PromotionBloc, PromotionState>(
                        buildWhen: (_, state) =>
                            state is PromotionLoading ||
                            state is PromotionFailure ||
                            state is PromotionOperationSuccess,
                        builder: (context, state) {
                          final isSubmitting = state is PromotionSubmitting;
                          return SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: isSubmitting ? null : _submit,
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isEdit
                                          ? 'Save Changes'
                                          : 'Create Promotion',
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (_selectedProducts.isEmpty || _selectedChannels.isEmpty) {
      setState(() {});
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<PromotionBloc>();
    final isEdit = widget.mode == PromotionFormNode.edit;

    // Resolve discount percentage
    double? discountPercentage;
    if (_hasDiscount && _discountCtrl.text.trim().isNotEmpty) {
      discountPercentage = double.tryParse(_discountCtrl.text.trim());
    }

    if (isEdit) {
      if (_originalEntity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save. Please go back and try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final updated = _originalEntity!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        productIds: List<String>.from(_selectedProducts),
        startDate: _startDate,
        endDate: _endDate,
        channels: List<String>.from(_selectedChannels),
        discountPercentage: discountPercentage,
        clearDiscount: !_hasDiscount,
      );
      bloc.add(PromotionUpdateRequested(updated));
    } else {
      bloc.add(
        PromotionCreateRequested(
          CreatePromotionParams(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            productIds: List<String>.from(_selectedProducts),
            startDate: _startDate,
            endDate: _endDate,
            channels: List<String>.from(_selectedChannels),
            discountPercentage: discountPercentage,
          ),
        ),
      );
    }
  }
}

// ─── Campaign Type Button ──────────────────────────────────────────────────

class _CampaignTypeButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CampaignTypeButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.colorScheme.primary : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const Spacer(),
                if (selected) Icon(Icons.check_circle, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? color : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Picker Field ──────────────────────────────────────────────────

class _ProductPickerField extends StatelessWidget {
  final List<String> selectedProducts;
  final Map<String, String> productMap;
  final ValueChanged<List<String>> onChanged;

  const _ProductPickerField({
    required this.selectedProducts,
    required this.productMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedProducts.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: selectedProducts
                .map(
                  (id) => Chip(
                    label: Text(
                      productMap[id] ?? id,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      final updated = List<String>.from(selectedProducts)
                        ..remove(id);
                      onChanged(updated);
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: productMap.isEmpty
              ? null
              : () async {
                  final result = await showSearchableMultiPicker<String>(
                    context: context,
                    title: 'Select Products',
                    hint: 'Search products…',
                    items: productMap.entries
                        .map(
                          (e) =>
                              (value: e.key, label: e.value, subtitle: e.key),
                        )
                        .toList(),
                    selected: selectedProducts.toSet(),
                  );
                  if (result != null) onChanged(result.toList());
                },
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            productMap.isEmpty ? 'No products available' : 'Select Products',
          ),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }
}

// ─── Products Error/Retry State ────────────────────────────────────────────

class _ProductsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ProductsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─── Date Field ────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    this.firstDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const months = [
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

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: firstDate ?? DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          '${months[value.month - 1]} ${value.day}, ${value.year}',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

// ─── Channel Toggle ────────────────────────────────────────────────────────

class _ChannelToggle extends StatelessWidget {
  final String channel;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _ChannelToggle({
    required this.channel,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? color.withOpacity(0.4)
              : Colors.grey.withOpacity(0.3),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: SwitchListTile(
        value: selected,
        onChanged: onToggle,
        secondary: Icon(icon, color: selected ? color : Colors.grey),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? color : null,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        activeColor: color,
        dense: true,
      ),
    );
  }
}

// ─── Section Card ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}
