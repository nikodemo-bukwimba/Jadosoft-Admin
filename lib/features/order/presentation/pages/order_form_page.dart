import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/form_mode.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../domain/usecases/create_order_usecase.dart';

class OrderFormPage extends StatefulWidget {
  final FormMode mode;
  final String? id;

  const OrderFormPage({
    super.key,
    this.mode = FormMode.create,
    this.id,
  });

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _orderNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isUrgentValue = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _orderNumberController.dispose();
    _customerNameController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == FormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Order' : 'Edit Order'),
      ),
      body: BlocListener<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state is OrderOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is OrderFailure) {
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
                  controller: _orderNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Order Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Order number is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Customer name is required';
                    if (v != null && v.trim().length < 2) return 'Customer name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Total Amount is required';
                    return null;
                  },
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
                SwitchListTile(
                  title: const Text('Is Urgent'),
                  value: _isUrgentValue,
                  onChanged: (v) => setState(() => _isUrgentValue = v),
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
                      : Text(isCreate ? 'Create Order' : 'Save Changes'),
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

    context.read<OrderBloc>().add(
      OrderCreateRequested(
        CreateOrderParams(
          orderNumber: _orderNumberController.text,
          customerName: _customerNameController.text,
          totalAmount: double.tryParse(_totalAmountController.text) ?? 0.0,
          notes: _notesController.text,
          isUrgent: _isUrgentValue,
        ),
      ),
    );
  }
}
