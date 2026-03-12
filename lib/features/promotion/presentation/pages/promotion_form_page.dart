import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/promotion_form_node.dart';
import '../bloc/promotion_bloc.dart';
import '../bloc/promotion_event.dart';
import '../bloc/promotion_state.dart';
import '../../domain/usecases/create_promotion_usecase.dart';

class PromotionFormPage extends StatefulWidget {
  final PromotionFormNode mode;
  final String? id;

  const PromotionFormPage({
    super.key,
    this.mode = PromotionFormNode.create,
    this.id,
  });

  @override
  State<PromotionFormPage> createState() => _PromotionFormPageState();
}

class _PromotionFormPageState extends State<PromotionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productIdsController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _channelsController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _productIdsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _channelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == PromotionFormNode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Promotions' : 'Edit Promotions'),
      ),
      body: BlocListener<PromotionBloc, PromotionState>(
        listener: (context, state) {
          if (state is PromotionOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is PromotionFailure) {
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Promotion title is required';
                    }
                    if (v.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _productIdsController,
                  decoration: const InputDecoration(
                    labelText: 'Product Ids',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'At least one product is required';
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
                      _startDateController.text = picked
                          .toIso8601String()
                          .split('T')
                          .first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
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
                      _endDateController.text = picked
                          .toIso8601String()
                          .split('T')
                          .first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _channelsController,
                  decoration: const InputDecoration(
                    labelText: 'Channels',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'At least one channel is required';
                    return null;
                  },
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
                      : Text(isCreate ? 'Create Promotions' : 'Save Changes'),
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

    context.read<PromotionBloc>().add(
      PromotionCreateRequested(
        CreatePromotionParams(
          title: _titleController.text,
          description: _descriptionController.text,
          productIds: _productIdsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          startDate:
              DateTime.tryParse(_startDateController.text) ?? DateTime.now(),
          endDate: DateTime.tryParse(_endDateController.text) ?? DateTime.now(),
          channels: _channelsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        ),
      ),
    );
  }
}
