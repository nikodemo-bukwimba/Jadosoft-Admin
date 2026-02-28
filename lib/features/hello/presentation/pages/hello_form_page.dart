import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/hello_bloc.dart';
import '../bloc/hello_event.dart';
import '../bloc/hello_state.dart';
import '../../domain/usecases/create_hello_usecase.dart';

enum HelloFormMode { create, edit }

class HelloFormPage extends StatefulWidget {
  final HelloFormMode mode;
  final String? id;

  const HelloFormPage({
    super.key,
    this.mode = HelloFormMode.create,
    this.id,
  });

  @override
  State<HelloFormPage> createState() => _HelloFormPageState();
}

class _HelloFormPageState extends State<HelloFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == HelloFormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Hello' : 'Edit Hello'),
      ),
      body: BlocListener<HelloBloc, HelloState>(
        listener: (context, state) {
          if (state is HelloOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is HelloFailure) {
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

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Hello' : 'Save Changes'),
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

    context.read<HelloBloc>().add(
      HelloCreateRequested(
        CreateHelloParams(
        name: _nameController.text,
        ),
      ),
    );
  }
}
