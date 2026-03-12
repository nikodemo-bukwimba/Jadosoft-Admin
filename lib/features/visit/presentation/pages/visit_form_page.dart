import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/visit_form_node.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../../domain/usecases/create_visit_usecase.dart';

class VisitFormPage extends StatefulWidget {
  final VisitFormNode mode;
  final String? id;

  const VisitFormPage({super.key, this.mode = VisitFormNode.create, this.id});

  @override
  State<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends State<VisitFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _customerIdController = TextEditingController();
  final _officerIdController = TextEditingController();
  final _visitDateController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _gpsLatController = TextEditingController();
  final _gpsLngController = TextEditingController();
  final _promotedProductIdsController = TextEditingController();
  final _discussionSummaryController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerIdController.dispose();
    _officerIdController.dispose();
    _visitDateController.dispose();
    _businessNameController.dispose();
    _ownerPhoneController.dispose();
    _contactPersonPhoneController.dispose();
    _businessPhoneController.dispose();
    _notesController.dispose();
    _gpsLatController.dispose();
    _gpsLngController.dispose();
    _promotedProductIdsController.dispose();
    _discussionSummaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == VisitFormNode.create;

    return Scaffold(
      appBar: AppBar(title: Text(isCreate ? 'New Visits' : 'Edit Visits')),
      body: BlocListener<VisitBloc, VisitState>(
        listener: (context, state) {
          if (state is VisitOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is VisitFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _customerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Customer is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _officerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Officer Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Officer is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _visitDateController.text = picked
                          .toIso8601String()
                          .split('T')
                          .first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _visitDateController,
                      decoration: const InputDecoration(
                        labelText: 'Visit Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Owner Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactPersonPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gpsLatController,
                  decoration: const InputDecoration(
                    labelText: 'Gps Lat',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gpsLngController,
                  decoration: const InputDecoration(
                    labelText: 'Gps Lng',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _promotedProductIdsController,
                  decoration: const InputDecoration(
                    labelText: 'Promoted Product Ids',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discussionSummaryController,
                  decoration: const InputDecoration(
                    labelText: 'Discussion Summary',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Visits' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    context.read<VisitBloc>().add(
      VisitCreateRequested(
        CreateVisitParams(
          customerId: _customerIdController.text,
          officerId: _officerIdController.text,
          visitDate:
              DateTime.tryParse(_visitDateController.text) ?? DateTime.now(),
          businessName: _businessNameController.text,
          ownerPhone: _ownerPhoneController.text,
          contactPersonPhone: _contactPersonPhoneController.text,
          businessPhone: _businessPhoneController.text,
          notes: _notesController.text,
          gpsLat: double.tryParse(_gpsLatController.text) ?? 0.0,
          gpsLng: double.tryParse(_gpsLngController.text) ?? 0.0,
          promotedProductIds: _promotedProductIdsController.text.trim().isEmpty
              ? null
              : _promotedProductIdsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
          discussionSummary: _discussionSummaryController.text,
        ),
      ),
    );
  }
}
