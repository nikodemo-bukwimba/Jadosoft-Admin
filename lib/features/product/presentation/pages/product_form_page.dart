import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/product_form_node.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../../domain/usecases/create_product_usecase.dart';

class ProductFormPage extends StatefulWidget {
  final ProductFormNode mode;
  final String? id;

  const ProductFormPage({
    super.key,
    this.mode = ProductFormNode.create,
    this.id,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryIdController = TextEditingController();
  bool _isAvailableValue = false;
  bool _isFeaturedValue = false;
  bool _isNewValue = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == ProductFormNode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Products' : 'Edit Products'),
      ),
      body: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is ProductFailure) {
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Product name is required';
                    if (v != null && v.trim().length < 2) return 'Name must be at least 2 characters';
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
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Price is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryIdController,
                  decoration: const InputDecoration(
                    labelText: 'Category Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Category is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Available'),
                  value: _isAvailableValue,
                  onChanged: (v) => setState(() => _isAvailableValue = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Featured'),
                  value: _isFeaturedValue,
                  onChanged: (v) => setState(() => _isFeaturedValue = v),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is New'),
                  value: _isNewValue,
                  onChanged: (v) => setState(() => _isNewValue = v),
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
                      : Text(isCreate ? 'Create Products' : 'Save Changes'),
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

    context.read<ProductBloc>().add(
      ProductCreateRequested(
        CreateProductParams(
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          categoryId: _categoryIdController.text,
          isAvailable: _isAvailableValue,
          isFeatured: _isFeaturedValue,
          isNew: _isNewValue,
        ),
      ),
    );
  }
}
