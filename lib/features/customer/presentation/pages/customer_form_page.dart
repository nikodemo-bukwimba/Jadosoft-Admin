import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../bloc/customer_state.dart';
import '../../domain/usecases/create_customer_usecase.dart';

enum CustomerFormMode { create, edit }

class CustomerFormPage extends StatefulWidget {
  final CustomerFormMode mode;
  final String? id;

  const CustomerFormPage({
    super.key,
    this.mode = CustomerFormMode.create,
    this.id,
  });

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _businessNameController = TextEditingController();
  final _fullOfficeNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _officialPhoneController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPersonPhoneController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _gpsLatController = TextEditingController();
  final _gpsLngController = TextEditingController();
  final _assignedOfficerIdController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullOfficeNameController.dispose();
    _ownerNameController.dispose();
    _officialPhoneController.dispose();
    _contactPersonController.dispose();
    _contactPersonPhoneController.dispose();
    _officeAddressController.dispose();
    _gpsLatController.dispose();
    _gpsLngController.dispose();
    _assignedOfficerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == CustomerFormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Customers' : 'Edit Customers'),
      ),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is CustomerFailure) {
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
                  controller: _businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Business name is required';
                    if (v != null && v.trim().length < 2) return 'Business name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullOfficeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Office Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Owner Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Owner name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _officialPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Official Phone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Official phone is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person',
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
                  controller: _officeAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Office Address',
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _gpsLngController,
                  decoration: const InputDecoration(
                    labelText: 'Gps Lng',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignedOfficerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Officer Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Assigned officer is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Customers' : 'Save Changes'),
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

    context.read<CustomerBloc>().add(
      CustomerCreateRequested(
        CreateCustomerParams(
        businessName: _businessNameController.text,
        fullOfficeName: _fullOfficeNameController.text,
        ownerName: _ownerNameController.text,
        officialPhone: _officialPhoneController.text,
        contactPerson: _contactPersonController.text,
        contactPersonPhone: _contactPersonPhoneController.text,
        officeAddress: _officeAddressController.text,
        gpsLat: double.tryParse(_gpsLatController.text) ?? 0.0,
        gpsLng: double.tryParse(_gpsLngController.text) ?? 0.0,
        assignedOfficerId: _assignedOfficerIdController.text,
        ),
      ),
    );
  }
}
