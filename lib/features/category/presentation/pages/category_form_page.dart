import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../../domain/usecases/create_category_usecase.dart';

enum CategoryFormMode { create, edit }

class CategoryFormPage extends StatefulWidget {
  final CategoryFormMode mode;
  final String? id;

  const CategoryFormPage({
    super.key,
    this.mode = CategoryFormMode.create,
    this.id,
  });

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isActiveValue = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == CategoryFormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Product Categories' : 'Edit Product Categories'),
      ),
      body: BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is CategoryFailure) {
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
                    if (v == null || v.trim().isEmpty) return 'Category name is required';
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
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActiveValue,
                  onChanged: (v) => setState(() => _isActiveValue = v),
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
                      : Text(isCreate ? 'Create Product Categories' : 'Save Changes'),
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

    context.read<CategoryBloc>().add(
      CategoryCreateRequested(
        CreateCategoryParams(
        name: _nameController.text,
        description: _descriptionController.text,
        isActive: _isActiveValue,
        ),
      ),
    );
  }
}
