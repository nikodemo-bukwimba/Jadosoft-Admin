// visit_event.dart
// All events dispatched to VisitBloc.

part of 'visit_bloc.dart';

abstract class VisitEvent {}

// ── CRUD events ───────────────────────────────────────────────
class VisitLoadAllRequested extends VisitEvent {
  final VisitFilterParams?     filters;
  final VisitSortParams?       sort;
  final VisitPaginationParams? pagination;

  VisitLoadAllRequested({this.filters, this.sort, this.pagination});
}

class VisitLoadOneRequested extends VisitEvent {
  final String id;
  VisitLoadOneRequested(this.id);
}

class VisitCreateRequested extends VisitEvent {
  final CreateVisitParams params;
  VisitCreateRequested(this.params);
}

class VisitUpdateRequested extends VisitEvent {
  final CategoryEntity entity;
  VisitUpdateRequested(this.entity);
}

class VisitDeleteRequested extends VisitEvent {
  final String id;
  VisitDeleteRequested(this.id);
}

class VisitSearchChanged extends VisitEvent {
  final String query;
  VisitSearchChanged(this.query);
}

class VisitFormReset extends VisitEvent {}

