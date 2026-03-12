import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/daily_report_form_node.dart';
import '../bloc/daily_report_bloc.dart';
import '../bloc/daily_report_event.dart';
import '../bloc/daily_report_state.dart';
import '../../domain/usecases/create_daily_report_usecase.dart';

class DailyReportFormPage extends StatefulWidget {
  final DailyReportFormNode mode;
  final String? id;

  const DailyReportFormPage({
    super.key,
    this.mode = DailyReportFormNode.create,
    this.id,
  });

  @override
  State<DailyReportFormPage> createState() => _DailyReportFormPageState();
}

class _DailyReportFormPageState extends State<DailyReportFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _officerIdController = TextEditingController();
  final _reportDateController = TextEditingController();
  final _keyOutcomesController = TextEditingController();
  final _challengesFacedController = TextEditingController();
  final _nextDayPlanController = TextEditingController();
  final _customBodyController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _officerIdController.dispose();
    _reportDateController.dispose();
    _keyOutcomesController.dispose();
    _challengesFacedController.dispose();
    _nextDayPlanController.dispose();
    _customBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == DailyReportFormNode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New Daily Reports' : 'Edit Daily Reports'),
      ),
      body: BlocListener<DailyReportBloc, DailyReportState>(
        listener: (context, state) {
          if (state is DailyReportOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is DailyReportFailure) {
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
                    if (v == null || v.trim().isEmpty) return 'Officer is required';
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
                      _reportDateController.text =
                          picked.toIso8601String().split('T').first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _reportDateController,
                      decoration: const InputDecoration(
                        labelText: 'Report Date',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _keyOutcomesController,
                  decoration: const InputDecoration(
                    labelText: 'Key Outcomes',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _challengesFacedController,
                  decoration: const InputDecoration(
                    labelText: 'Challenges Faced',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nextDayPlanController,
                  decoration: const InputDecoration(
                    labelText: 'Next Day Plan',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,

                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customBodyController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Body',
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
                      : Text(isCreate ? 'Create Daily Reports' : 'Save Changes'),
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

    context.read<DailyReportBloc>().add(
      DailyReportCreateRequested(
        CreateDailyReportParams(
          officerId: _officerIdController.text,
          reportDate: DateTime.tryParse(_reportDateController.text) ?? DateTime.now(),
          keyOutcomes: _keyOutcomesController.text,
          challengesFaced: _challengesFacedController.text,
          nextDayPlan: _nextDayPlanController.text,
          customBody: _customBodyController.text,
        ),
      ),
    );
  }
}
