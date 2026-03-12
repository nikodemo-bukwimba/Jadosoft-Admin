import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../../domain/usecases/create_payment_usecase.dart';

enum PaymentFormMode { create, edit }

class PaymentFormPage extends StatefulWidget {
  final PaymentFormMode mode;
  final String? id;

  const PaymentFormPage({
    super.key,
    this.mode = PaymentFormMode.create,
    this.id,
  });

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _orderIdController = TextEditingController();
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController();
  final _providerController = TextEditingController();
  final _transactionRefController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    _customerIdController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _providerController.dispose();
    _transactionRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == PaymentFormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Payments' : 'Edit Payments'),
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is PaymentFailure) {
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
                  controller: _orderIdController,
                  decoration: const InputDecoration(
                    labelText: 'Order Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _providerController,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _transactionRefController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Ref',
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
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Payments' : 'Save Changes'),
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

    context.read<PaymentBloc>().add(
      PaymentCreateRequested(
        CreatePaymentParams(
        orderId: _orderIdController.text,
        customerId: _customerIdController.text,
        amount: double.tryParse(_amountController.text) ?? 0.0,
        currency: _currencyController.text,
        provider: _providerController.text,
        transactionRef: _transactionRefController.text,
        ),
      ),
    );
  }
}
