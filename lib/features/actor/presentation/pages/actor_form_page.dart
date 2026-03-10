// actor_form_page.dart
// ─────────────────────────────────────────────────────────────
// Phase 2: Properly handles create + edit modes.
//   - Edit mode pre-populates fields from loaded state
//   - Status uses dropdown (pending/active/suspended/inactive)
//   - Uses ActorFormMode enum from core/enums (shared across features)
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/form_mode.dart';
import '../../domain/usecases/create_actor_usecase.dart';
import '../bloc/actor_bloc.dart';
import '../bloc/actor_event.dart';
import '../bloc/actor_state.dart';

class ActorFormPage extends StatefulWidget {
  final ActorFormMode mode;
  final String? id;

  const ActorFormPage({super.key, this.mode = ActorFormMode.create, this.id});

  @override
  State<ActorFormPage> createState() => _ActorFormPageState();
}

class _ActorFormPageState extends State<ActorFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  String _selectedStatus = 'pending';
  bool _isSubmitting = false;
  bool _didPopulateForEdit = false;

  static const _statuses = ['pending', 'active', 'suspended', 'inactive'];

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == ActorFormMode.create;

    return Scaffold(
      appBar: AppBar(title: Text(isCreate ? 'New Actor' : 'Edit Actor')),
      body: BlocConsumer<ActorBloc, ActorState>(
        listener: (context, state) {
          // ── Success → pop back ──────────────────────────
          if (state is ActorOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          // ── Failure → show error ────────────────────────
          if (state is ActorFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          // ── Detail loaded → populate form for edit mode ─
          if (!_didPopulateForEdit &&
              widget.mode == ActorFormMode.edit &&
              state is ActorDetailLoaded) {
            _displayNameController.text = state.item.displayName;
            _selectedStatus = state.item.status;
            _didPopulateForEdit = true;
            setState(() {});
          }
        },
        builder: (context, state) {
          // Show loading while fetching data for edit mode
          if (widget.mode == ActorFormMode.edit &&
              !_didPopulateForEdit &&
              state is ActorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Display Name ──────────────────────────
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Display name is required';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Status dropdown ───────────────────────
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedStatus = v);
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Status is required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Submit button ─────────────────────────
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isCreate ? 'Create Actor' : 'Save Changes'),
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

    final bloc = context.read<ActorBloc>();

    if (widget.mode == ActorFormMode.create) {
      bloc.add(
        ActorCreateRequested(
          CreateActorParams(
            displayName: _displayNameController.text.trim(),
            status: _selectedStatus,
          ),
        ),
      );
    } else {
      // Edit mode — get current entity from state and apply changes
      final state = bloc.state;
      if (state is ActorDetailLoaded) {
        final updated = state.item.copyWith(
          displayName: _displayNameController.text.trim(),
          status: _selectedStatus,
        );
        bloc.add(ActorUpdateRequested(updated));
      }
    }
  }
}
