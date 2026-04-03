import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/datasources/promotion_mock_datasource.dart';
import '../../domain/entities/promotion_entity.dart';
import '../../domain/usecases/create_promotion_usecase.dart';
import '../../domain/usecases/update_promotion_usecase.dart';
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

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  final List<String> _selectedProducts = [];
  final List<String> _selectedChannels = ['sms', 'whatsapp'];

  bool _populated = false;

  // All available products from mock
  static const Map<String, String> _allProducts = {
    'prod-001': 'Amoxicillin 500mg Capsules',
    'prod-002': 'Artemether/Lumefantrine 20/120mg',
    'prod-003': 'Ibuprofen 400mg Tablets',
    'prod-004': 'Vitamin C 1000mg Effervescent',
    'prod-005': 'Multivitamin & Minerals Complex',
    'prod-006': 'Metronidazole 400mg Tablets',
    'prod-007': 'Oral Rehydration Salts (ORS)',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _populate(PromotionEntity item) {
    if (_populated) return;
    _populated = true;
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.mode == PromotionFormNode.edit;
    final isWide = MediaQuery.of(context).size.width > 768;

    return BlocConsumer<PromotionBloc, PromotionState>(
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
        // Pre-populate for edit mode
        if (isEdit && state is PromotionDetailLoaded) {
          _populate(state.item);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? 'Edit Promotion' : 'New Promotion'),
            centerTitle: false,
          ),
          body: state is PromotionLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
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
                            // ── Basic Info ─────────────────────
                            _SectionCard(
                              title: 'Promotion Details',
                              icon: Icons.campaign_outlined,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _titleCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Title *',
                                      hintText:
                                          'e.g. October Antibiotics Campaign',
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

                            // ── Date Range ─────────────────────
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

                            // ── Channels ───────────────────────
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
                                    selected: _selectedChannels.contains(
                                      'whatsapp',
                                    ),
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

                            // ── Products ───────────────────────
                            _SectionCard(
                              title:
                                  'Products to Promote (${_selectedProducts.length} selected)',
                              icon: Icons.medication_outlined,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedProducts.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: _selectedProducts
                                          .map(
                                            (id) => Chip(
                                              label: Text(
                                                _allProducts[id] ?? id,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              onDeleted: () => setState(
                                                () => _selectedProducts.remove(
                                                  id,
                                                ),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final result =
                                          await showSearchableMultiPicker<
                                            String
                                          >(
                                            context: context,
                                            title: 'Select Products',
                                            hint: 'Search products...',
                                            items: _allProducts.entries
                                                .map(
                                                  (e) => (
                                                    value: e.key,
                                                    label: e.value,
                                                    subtitle: e.key,
                                                  ),
                                                )
                                                .toList(),
                                            selected: _selectedProducts.toSet(),
                                          );
                                      if (result != null)
                                        setState(() {
                                          _selectedProducts.clear();
                                          _selectedProducts.addAll(result);
                                        });
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Select Products'),
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedProducts.isEmpty)
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

                            // ── Submit ─────────────────────────
                            SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: _submit,
                                child: Text(
                                  isEdit ? 'Save Changes' : 'Create Promotion',
                                ),
                              ),
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
    // Validate manually for non-form fields
    if (_selectedProducts.isEmpty || _selectedChannels.isEmpty) {
      setState(() {}); // trigger rebuild to show error messages
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final bloc = context.read<PromotionBloc>();
    final isEdit = widget.mode == PromotionFormNode.edit;

    if (isEdit) {
      // Need the current entity from state
      final state = bloc.state;
      if (state is PromotionDetailLoaded) {
        final updated = state.item.copyWith(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          productIds: List<String>.from(_selectedProducts),
          startDate: _startDate,
          endDate: _endDate,
          channels: List<String>.from(_selectedChannels),
        );
        bloc.add(PromotionUpdateRequested(updated));
      }
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
          ),
        ),
      );
    }
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
