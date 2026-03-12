import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/order_form_node.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../../domain/usecases/create_order_usecase.dart';

class OrderFormPage extends StatefulWidget {
  final OrderFormNode mode;
  final String? id;

  const OrderFormPage({super.key, this.mode = OrderFormNode.create, this.id});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _customerIdController = TextEditingController();
  final _itemsController = TextEditingController();
  final _totalController = TextEditingController();
  final _paymentRefController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerIdController.dispose();
    _itemsController.dispose();
    _totalController.dispose();
    _paymentRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == OrderFormNode.create;

    return Scaffold(
      appBar: AppBar(title: Text(isCreate ? 'New Orders' : 'Edit Orders')),
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
                  controller: _itemsController,
                  decoration: const InputDecoration(
                    labelText: 'Items',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'At least one item is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _totalController,
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Total is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paymentRefController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Ref',
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
                      : Text(isCreate ? 'Create Orders' : 'Save Changes'),
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
          customerId: _customerIdController.text,
          items: [
            {'description': _itemsController.text},
          ],
          total: double.tryParse(_totalController.text) ?? 0.0,
          paymentRef: _paymentRefController.text,
        ),
      ),
    );
  }
}
