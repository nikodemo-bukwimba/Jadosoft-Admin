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
  bool _isActiveValue = true; // default active for new categories

  bool _isSubmitting = false;
  bool _fieldsPopulated = false;

  bool get _isEdit => widget.mode == CategoryFormMode.edit;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Pre-populate fields when BLoC loads the existing entity (edit mode).
  void _populateFields(CategoryState state) {
    if (_isEdit && !_fieldsPopulated && state is CategoryDetailLoaded) {
      _nameController.text = state.item.name;
      _descriptionController.text = state.item.description ?? '';
      _isActiveValue = state.item.isActive;
      _fieldsPopulated = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Category' : 'New Category'),
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          // Pre-populate on detail load (edit mode)
          if (state is CategoryDetailLoaded) {
            setState(() => _populateFields(state));
          }
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
        builder: (context, state) {
          // Show loader while fetching existing data in edit mode
          if (_isEdit && state is CategoryLoading && !_fieldsPopulated) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Painkillers & Analgesics',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Category name is required';
                      if (v.trim().length < 2) return 'Name must be at least 2 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Brief description of this category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: Text(
                      _isActiveValue
                          ? 'Category is visible to users'
                          : 'Category is hidden from users',
                    ),
                    value: _isActiveValue,
                    onChanged: (v) => setState(() => _isActiveValue = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isEdit ? Icons.save : Icons.add),
                    label: Text(_isEdit ? 'Save Changes' : 'Create Category'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    if (_isEdit) {
      // Edit mode — get the loaded entity and update it
      final currentState = context.read<CategoryBloc>().state;
      if (currentState is CategoryDetailLoaded) {
        context.read<CategoryBloc>().add(
          CategoryUpdateRequested(
            currentState.item.copyWith(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              isActive: _isActiveValue,
            ),
          ),
        );
      }
    } else {
      // Create mode
      context.read<CategoryBloc>().add(
        CategoryCreateRequested(
          CreateCategoryParams(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            isActive: _isActiveValue,
          ),
        ),
      );
    }
  }
}