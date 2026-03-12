import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/notification_form_node.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../../domain/usecases/create_notification_usecase.dart';

class NotificationFormPage extends StatefulWidget {
  final NotificationFormNode mode;
  final String? id;

  const NotificationFormPage({
    super.key,
    this.mode = NotificationFormNode.create,
    this.id,
  });

  @override
  State<NotificationFormPage> createState() => _NotificationFormPageState();
}

class _NotificationFormPageState extends State<NotificationFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _recipientIdController = TextEditingController();
  final _recipientTypeController = TextEditingController();
  final _channelController = TextEditingController();
  final _contentController = TextEditingController();
  final _templateIdController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _recipientIdController.dispose();
    _recipientTypeController.dispose();
    _channelController.dispose();
    _contentController.dispose();
    _templateIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == NotificationFormNode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Notifications' : 'Edit Notifications'),
      ),
      body: BlocListener<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is NotificationFailure) {
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
                  controller: _recipientIdController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Recipient is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _recipientTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Type',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Recipient type is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _channelController,
                  decoration: const InputDecoration(
                    labelText: 'Channel',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Channel is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Content is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _templateIdController,
                  decoration: const InputDecoration(
                    labelText: 'Template Id',
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
                      : Text(isCreate ? 'Create Notifications' : 'Save Changes'),
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

    context.read<NotificationBloc>().add(
      NotificationCreateRequested(
        CreateNotificationParams(
          recipientId: _recipientIdController.text,
          recipientType: _recipientTypeController.text,
          channel: _channelController.text,
          content: _contentController.text,
          templateId: _templateIdController.text,
        ),
      ),
    );
  }
}
