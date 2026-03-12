import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity_log_bloc.dart';
import '../bloc/activity_log_event.dart';
import '../bloc/activity_log_state.dart';
import '../../domain/usecases/create_activity_log_usecase.dart';

enum ActivityLogFormMode { create, edit }

class ActivityLogFormPage extends StatefulWidget {
  final ActivityLogFormMode mode;
  final String? id;

  const ActivityLogFormPage({
    super.key,
    this.mode = ActivityLogFormMode.create,
    this.id,
  });

  @override
  State<ActivityLogFormPage> createState() => _ActivityLogFormPageState();
}

class _ActivityLogFormPageState extends State<ActivityLogFormPage> {
  final _formKey = GlobalKey<FormState>();



  bool _isSubmitting = false;

  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == ActivityLogFormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Activity Logs' : 'Edit Activity Logs'),
      ),
      body: BlocListener<ActivityLogBloc, ActivityLogState>(
        listener: (context, state) {
          if (state is ActivityLogOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is ActivityLogFailure) {
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
                      : Text(isCreate ? 'Create Activity Logs' : 'Save Changes'),
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

    context.read<ActivityLogBloc>().add(
      ActivityLogCreateRequested(
        CreateActivityLogParams(

        ),
      ),
    );
  }
}
