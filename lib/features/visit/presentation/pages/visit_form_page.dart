import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/visit_form_node.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../../domain/usecases/create_visit_usecase.dart';
import '../../../officer/data/datasources/officer_mock_datasource.dart';
import '../../../officer/domain/entities/officer_entity.dart';
import '../../../customer/data/datasources/customer_mock_datasource.dart';
import '../../../customer/domain/entities/customer_entity.dart';

class VisitFormPage extends StatefulWidget {
  final VisitFormNode mode;
  final String? id;
  const VisitFormPage({super.key, this.mode = VisitFormNode.create, this.id});
  @override
  State<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends State<VisitFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedOfficerId, _selectedCustomerId;
  final _notesCtl = TextEditingController();
  final _summaryCtl = TextEditingController();
  bool _isSubmitting = false, _fieldsPopulated = false;
  bool get _isEdit => widget.mode == VisitFormNode.edit;

  List<OfficerEntity> _officers = [];
  List<CustomerEntity> _customers = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final o = await OfficerMockDataSource().getAll();
      final c = await CustomerMockDataSource().getAll();
      if (mounted) setState(() { _officers = o; _customers = c; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  void dispose() { _notesCtl.dispose(); _summaryCtl.dispose(); super.dispose(); }

  void _populate(VisitState s) {
    if (_isEdit && !_fieldsPopulated && s is VisitDetailLoaded) {
      _selectedOfficerId = s.item.officerId;
      _selectedCustomerId = s.item.customerId;
      _notesCtl.text = s.item.notes ?? '';
      _summaryCtl.text = s.item.discussionSummary ?? '';
      _fieldsPopulated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Visit' : 'Log Visit')),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (c, s) {
          if (s is VisitDetailLoaded) setState(() => _populate(s));
          if (s is VisitOperationSuccess) { setState(() => _isSubmitting = false); Navigator.of(c).pop(true); }
          if (s is VisitFailure) { setState(() => _isSubmitting = false); ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.message), backgroundColor: scheme.error)); }
        },
        builder: (c, s) {
          if (_isEdit && s is VisitLoading && !_fieldsPopulated) return const Center(child: CircularProgressIndicator());
          if (_loading) return const Center(child: CircularProgressIndicator());

          return Form(key: _formKey, child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? MediaQuery.of(context).size.width * 0.1 : 16, vertical: 16),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (isWide) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _officerDropdown()), const SizedBox(width: 16), Expanded(child: _customerDropdown()),
              ]) else ...[_officerDropdown(), const SizedBox(height: 16), _customerDropdown()],
              const SizedBox(height: 16),
              TextFormField(controller: _summaryCtl, decoration: const InputDecoration(labelText: 'Discussion Summary', border: OutlineInputBorder(), prefixIcon: Icon(Icons.summarize_outlined)), maxLines: 3, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 16),
              TextFormField(controller: _notesCtl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes_outlined)), maxLines: 3, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 32),
              FilledButton.icon(onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_isEdit ? Icons.save : Icons.add),
                label: Text(_isEdit ? 'Save Changes' : 'Log Visit')),
              const SizedBox(height: 32),
            ]))));
        },
      ),
    );
  }

  Widget _officerDropdown() => DropdownButtonFormField<String>(
    value: _selectedOfficerId,
    decoration: const InputDecoration(labelText: 'Officer', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge_outlined)),
    items: _officers.where((o) => o.status == 'active').map((o) => DropdownMenuItem(value: o.id, child: Text(o.name))).toList(),
    onChanged: (v) => setState(() => _selectedOfficerId = v),
    validator: (v) => v == null || v.isEmpty ? 'Officer is required' : null,
  );

  Widget _customerDropdown() => DropdownButtonFormField<String>(
    value: _selectedCustomerId,
    decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store_outlined)),
    items: _customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.businessName))).toList(),
    onChanged: (v) => setState(() => _selectedCustomerId = v),
    validator: (v) => v == null || v.isEmpty ? 'Customer is required' : null,
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    if (_isEdit) {
      final s = context.read<VisitBloc>().state;
      if (s is VisitDetailLoaded) context.read<VisitBloc>().add(VisitUpdateRequested(s.item.copyWith(
        officerId: _selectedOfficerId, customerId: _selectedCustomerId, notes: _notesCtl.text.trim(), discussionSummary: _summaryCtl.text.trim())));
    } else {
      context.read<VisitBloc>().add(VisitCreateRequested(CreateVisitParams(
        officerId: _selectedOfficerId ?? '', customerId: _selectedCustomerId ?? '', visitDate: DateTime.now(),
        notes: _notesCtl.text.trim(), discussionSummary: _summaryCtl.text.trim())));
    }
  }
}