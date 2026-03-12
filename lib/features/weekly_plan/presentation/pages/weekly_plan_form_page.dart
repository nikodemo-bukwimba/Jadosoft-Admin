import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/weekly_plan_form_node.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../../domain/usecases/create_weekly_plan_usecase.dart';

class WeeklyPlanFormPage extends StatefulWidget {
  final WeeklyPlanFormNode mode;
  final String? id;

  const WeeklyPlanFormPage({
    super.key,
    this.mode = WeeklyPlanFormNode.create,
    this.id,
  });

  @override
  State<WeeklyPlanFormPage> createState() => _WeeklyPlanFormPageState();
}

class _WeeklyPlanFormPageState extends State<WeeklyPlanFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _officerIdController = TextEditingController();
  final _weekStartController = TextEditingController();
  final _weekEndController = TextEditingController();
  final _plannedCustomerIdsController = TextEditingController();
  final _plannedActivitiesController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _officerIdController.dispose();
    _weekStartController.dispose();
    _weekEndController.dispose();
    _plannedCustomerIdsController.dispose();
    _plannedActivitiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == WeeklyPlanFormNode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Weekly Plans' : 'Edit Weekly Plans'),
      ),
      body: BlocListener<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (context, state) {
          if (state is WeeklyPlanOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is WeeklyPlanFailure) {
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
                  controller: _officerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Officer Id',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Officer is required';
                    return null;
                  },
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
                      _weekStartController.text = picked
                          .toIso8601String()
                          .split('T')
                          .first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _weekStartController,
                      decoration: const InputDecoration(
                        labelText: 'Week Start',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
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
                      _weekEndController.text = picked
                          .toIso8601String()
                          .split('T')
                          .first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _weekEndController,
                      decoration: const InputDecoration(
                        labelText: 'Week End',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plannedCustomerIdsController,
                  decoration: const InputDecoration(
                    labelText: 'Planned Customer Ids',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plannedActivitiesController,
                  decoration: const InputDecoration(
                    labelText: 'Planned Activities',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
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
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create Weekly Plans' : 'Save Changes'),
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

    context.read<WeeklyPlanBloc>().add(
      WeeklyPlanCreateRequested(
        CreateWeeklyPlanParams(
          officerId: _officerIdController.text,
          weekStart:
              DateTime.tryParse(_weekStartController.text) ?? DateTime.now(),
          weekEnd: DateTime.tryParse(_weekEndController.text) ?? DateTime.now(),
          plannedCustomerIds: _plannedCustomerIdsController.text.trim().isEmpty
              ? null
              : _plannedCustomerIdsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
          plannedActivities: _plannedActivitiesController.text,
          notes: _notesController.text,
        ),
      ),
    );
  }
}
