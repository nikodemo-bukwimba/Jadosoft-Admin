// visit_form_page.dart
// Form with validation, loading state, and error handling.

import 'package:fca/features/visit/domain/usecases/create_isActive_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/visit_bloc.dart';
 

enum FormModee { create, edit }

class VisitFormPage extends StatefulWidget {
  final FormModee mode;
  final String?  id;

  const VisitFormPage({
    super.key,
    this.mode = FormModee.create,
    this.id,
  });

  @override
  State<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends State<VisitFormPage> {
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
    final isCreate = widget.mode == FormModee.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Visit' : 'Edit Visit'),
      ),
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
                content:         Text(state.message),
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
              if (v == null || v.trim().isEmpty) return 'Name is required';
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
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Visit' : 'Save Changes'),
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

    // TODO: Map controller values to CreateVisitParams fields
    context.read<VisitBloc>().add(
      VisitCreateRequested(
        CreateVisitParams(
          // TODO: pass controller values here
          name: _nameController.text,
          isActive: _isActiveValue,
        ),
      ),
    );
  }
}
