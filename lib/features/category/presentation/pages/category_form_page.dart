// category_form_page.dart
// Form with validation, loading state, and error handling.

import 'package:fca/features/category/domain/usecases/create_isActive_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/category_bloc.dart';

enum FormMode { create, edit }

class CategoryFormPage extends StatefulWidget {
  final FormMode mode;
  final String? id;

  const CategoryFormPage({super.key, this.mode = FormMode.create, this.id});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();

  // ── Field controllers ──────────────────────────────────────
  final _nameController = TextEditingController();
  bool _isActiveValue = false;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == FormMode.create;

    return Scaffold(
      appBar: AppBar(title: Text(isCreate ? 'New Category' : 'Edit Category')),
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
                // ── Form fields ──────────────────────────────
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Name is required';
                    if (v != null && v.length < 2) return 'Name too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActiveValue,
                  onChanged: (v) => setState(() => _isActiveValue = v),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 24),

                // ── Submit button ────────────────────────────
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Category' : 'Save Changes'),
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

    // TODO: Map controller values to CreateCategoryParams fields
    context.read<CategoryBloc>().add(
      CategoryCreateRequested(
        CreateCategoryParams(
          // TODO: pass controller values here
          name: _nameController.text,
          isActive: _isActiveValue,
        ),
      ),
    );
  }
}
