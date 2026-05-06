import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/weekly_plan_form_node.dart';
import '../bloc/weekly_plan_bloc.dart';
import '../bloc/weekly_plan_event.dart';
import '../bloc/weekly_plan_state.dart';
import '../../domain/usecases/create_weekly_plan_usecase.dart';
import '../../../officer/domain/entities/officer_entity.dart';
import '../../../officer/presentation/bloc/officer_bloc.dart';
import '../../../officer/presentation/bloc/officer_event.dart';
import '../../../officer/presentation/bloc/officer_state.dart';

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
  String? _selectedOfficerId;
  DateTime? _weekStart, _weekEnd;
  final _activitiesCtl = TextEditingController();
  final _notesCtl = TextEditingController();
  bool _isSubmitting = false, _fieldsPopulated = false;
  bool get _isEdit => widget.mode == WeeklyPlanFormNode.edit;

  @override
  void initState() {
    super.initState();
    context.read<OfficerBloc>().add(OfficerLoadAllRequested());
  }

  @override
  void dispose() {
    _activitiesCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  void _populate(WeeklyPlanState s) {
    if (_isEdit && !_fieldsPopulated && s is WeeklyPlanDetailLoaded) {
      _selectedOfficerId = s.item.officerId;
      _weekStart = s.item.weekStart;
      _weekEnd = s.item.weekEnd;
      _activitiesCtl.text = s.item.plannedActivities ?? '';
      _notesCtl.text = s.item.notes ?? '';
      _fieldsPopulated = true;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _weekStart : _weekEnd) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _weekStart = picked;
        } else {
          _weekEnd = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime? d) =>
      d != null ? '${d.day}/${d.month}/${d.year}' : 'Select date';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Plan' : 'New Weekly Plan')),
      body: BlocConsumer<WeeklyPlanBloc, WeeklyPlanState>(
        listener: (c, s) {
          if (s is WeeklyPlanDetailLoaded) setState(() => _populate(s));
          if (s is WeeklyPlanOperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(c).pop(true);
          }
          if (s is WeeklyPlanFailure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (c, weeklyPlanState) {
          if (_isEdit &&
              weeklyPlanState is WeeklyPlanLoading &&
              !_fieldsPopulated) {
            return const Center(child: CircularProgressIndicator());
          }

          return BlocBuilder<OfficerBloc, OfficerState>(
            builder: (_, officerState) {
              final isLoadingOfficers =
                  officerState is OfficerInitial ||
                  officerState is OfficerLoading;

              if (isLoadingOfficers) {
                return const Center(child: CircularProgressIndicator());
              }

              final officers = officerState is OfficerListLoaded
                  ? officerState.items
                        .where((o) => o.effectiveStatus == 'active')
                        .toList()
                  : <OfficerEntity>[];

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide
                        ? MediaQuery.of(context).size.width * 0.1
                        : 16,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Officer
                        DropdownButtonFormField<String>(
                          value: _selectedOfficerId,
                          decoration: const InputDecoration(
                            labelText: 'Officer',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: officers
                              .map(
                                (o) => DropdownMenuItem(
                                  value: o.userId,
                                  child: Text(o.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedOfficerId = v),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Officer is required'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Date range
                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: _dateTile(
                                  context,
                                  'Week Start',
                                  _weekStart,
                                  () => _pickDate(true),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _dateTile(
                                  context,
                                  'Week End',
                                  _weekEnd,
                                  () => _pickDate(false),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _dateTile(
                            context,
                            'Week Start',
                            _weekStart,
                            () => _pickDate(true),
                          ),
                          const SizedBox(height: 16),
                          _dateTile(
                            context,
                            'Week End',
                            _weekEnd,
                            () => _pickDate(false),
                          ),
                        ],
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _activitiesCtl,
                          decoration: const InputDecoration(
                            labelText: 'Planned Activities',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.task_outlined),
                          ),
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesCtl,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 32),

                        FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isEdit ? Icons.save : Icons.calendar_month,
                                ),
                          label: Text(_isEdit ? 'Save Changes' : 'Create Plan'),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _dateTile(
    BuildContext context,
    String label,
    DateTime? value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.date_range),
        ),
        child: Text(
          _fmtDate(value),
          style: value != null
              ? null
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_weekStart == null || _weekEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select week start and end dates')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    if (_isEdit) {
      final s = context.read<WeeklyPlanBloc>().state;
      if (s is WeeklyPlanDetailLoaded) {
        context.read<WeeklyPlanBloc>().add(
          WeeklyPlanUpdateRequested(
            s.item.copyWith(
              officerId: _selectedOfficerId,
              weekStart: _weekStart,
              weekEnd: _weekEnd,
              plannedActivities: _activitiesCtl.text.trim(),
              notes: _notesCtl.text.trim(),
            ),
          ),
        );
      }
    } else {
      context.read<WeeklyPlanBloc>().add(
        WeeklyPlanCreateRequested(
          CreateWeeklyPlanParams(
            officerId: _selectedOfficerId ?? '',
            weekStart: _weekStart!,
            weekEnd: _weekEnd!,
            plannedActivities: _activitiesCtl.text.trim(),
            notes: _notesCtl.text.trim(),
          ),
        ),
      );
    }
  }
}
