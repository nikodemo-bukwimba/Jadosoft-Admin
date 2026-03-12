import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/conversation_bloc.dart';
import '../bloc/conversation_event.dart';
import '../bloc/conversation_state.dart';
import '../../domain/usecases/create_conversation_usecase.dart';

enum ConversationFormMode { create, edit }

class ConversationFormPage extends StatefulWidget {
  final ConversationFormMode mode;
  final String? id;

  const ConversationFormPage({
    super.key,
    this.mode = ConversationFormMode.create,
    this.id,
  });

  @override
  State<ConversationFormPage> createState() => _ConversationFormPageState();
}

class _ConversationFormPageState extends State<ConversationFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _participantIdsController = TextEditingController();
  final _participantRolesController = TextEditingController();
  final _lastMessageController = TextEditingController();
  final _lastMessageAtController = TextEditingController();
  final _unreadCountController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _participantIdsController.dispose();
    _participantRolesController.dispose();
    _lastMessageController.dispose();
    _lastMessageAtController.dispose();
    _unreadCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == ConversationFormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Conversations' : 'Edit Conversations'),
      ),
      body: BlocListener<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is ConversationFailure) {
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
                  controller: _participantIdsController,
                  decoration: const InputDecoration(
                    labelText: 'Participant Ids',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _participantRolesController,
                  decoration: const InputDecoration(
                    labelText: 'Participant Roles',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastMessageController,
                  decoration: const InputDecoration(
                    labelText: 'Last Message',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
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
                      _lastMessageAtController.text = picked
                          .toIso8601String()
                          .split('T')
                          .first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _lastMessageAtController,
                      decoration: const InputDecoration(
                        labelText: 'Last Message At',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unreadCountController,
                  decoration: const InputDecoration(
                    labelText: 'Unread Count',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
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
                      : Text(
                          isCreate ? 'Create Conversations' : 'Save Changes',
                        ),
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

    context.read<ConversationBloc>().add(
      ConversationCreateRequested(
        CreateConversationParams(
          participantIds: _participantIdsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          participantRoles: _participantRolesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          lastMessage: _lastMessageController.text,
          lastMessageAt:
              DateTime.tryParse(_lastMessageAtController.text) ??
              DateTime.now(),
          unreadCount: int.tryParse(_unreadCountController.text) ?? 0,
        ),
      ),
    );
  }
}
