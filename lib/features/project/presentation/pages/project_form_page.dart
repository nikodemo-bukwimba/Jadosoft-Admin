import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/form_mode.dart';
import '../bloc/project_bloc.dart';
import '../bloc/project_event.dart';
import '../bloc/project_state.dart';
import '../../domain/usecases/create_project_usecase.dart';

class ProjectFormPage extends StatefulWidget {
  final FormMode mode;
  final String? id;

  const ProjectFormPage({
    super.key,
    this.mode = FormMode.create,
    this.id,
  });

  @override
  State<ProjectFormPage> createState() => _ProjectFormPageState();
}

class _ProjectFormPageState extends State<ProjectFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isPublicValue = false;
  final _startDateController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == FormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Project' : 'Edit Project'),
      ),
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ProjectOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is ProjectFailure) {
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
                    if (v == null || v.trim().isEmpty) return 'Project name is required';
                    if (v != null && v.trim().length < 3) return 'Name must be at least 3 characters';
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
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),

                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Public'),
                  value: _isPublicValue,
                  onChanged: (v) => setState(() => _isPublicValue = v),
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
                      _startDateController.text =
                          picked.toIso8601String().split('T').first;
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
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Project' : 'Save Changes'),
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

    context.read<ProjectBloc>().add(
      ProjectCreateRequested(
        CreateProjectParams(
          name: _nameController.text,
          description: _descriptionController.text,
          budget: double.tryParse(_budgetController.text) ?? 0.0,
          isPublic: _isPublicValue,
          startDate: DateTime.tryParse(_startDateController.text) ?? DateTime.now(),
        ),
      ),
    );
  }
}
