import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/visit_form_node.dart';
import '../bloc/visit_bloc.dart';
import '../bloc/visit_event.dart';
import '../bloc/visit_state.dart';
import '../../domain/usecases/create_visit_usecase.dart';

/// Visit form page.
///
/// In the admin app, visits are created by marketing officers via the
/// Staff App. This page is kept for router compatibility but shows
/// an informational message for create mode. Edit mode populates
/// from BLoC state for the rare case an admin needs to adjust notes.
class VisitFormPage extends StatefulWidget {
  final VisitFormNode mode;
  final String? id;
  const VisitFormPage({super.key, this.mode = VisitFormNode.create, this.id});
  @override
  State<VisitFormPage> createState() => _VisitFormPageState();
}

class _VisitFormPageState extends State<VisitFormPage> {
  bool get _isEdit => widget.mode == VisitFormNode.edit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Visit' : 'Visits')),
      body: BlocConsumer<VisitBloc, VisitState>(
        listener: (c, s) {
          if (s is VisitOperationSuccess) {
            ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s.message)));
            Navigator.of(c).pop();
          }
          if (s is VisitFailure) {
            ScaffoldMessenger.of(c).showSnackBar(
              SnackBar(content: Text(s.message), backgroundColor: scheme.error),
            );
          }
        },
        builder: (c, s) {
          // For create mode — admin cannot create visits
          if (!_isEdit) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'Visits are created by marketing officers\nusing the Staff App.',
                      style: tt.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As an administrator, you can accept, flag, and\ncomment on visits from the visit detail page.',
                      style: tt.bodyMedium?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Edit mode — show loading or detail
          if (s is VisitLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_off, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'Visit editing is handled through\nthe review and flag workflow.',
                    style: tt.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(c).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}