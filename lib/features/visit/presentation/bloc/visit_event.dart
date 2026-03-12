import '../../domain/entities/visit_entity.dart';
import '../../domain/usecases/create_visit_usecase.dart';

abstract class VisitEvent {}

class VisitLoadAllRequested extends VisitEvent {}

class VisitLoadOneRequested extends VisitEvent {
  final String id;
  VisitLoadOneRequested(this.id);
}

class VisitCreateRequested extends VisitEvent {
  final CreateVisitParams params;
  VisitCreateRequested(this.params);
}

class VisitUpdateRequested extends VisitEvent {
  final VisitEntity entity;
  VisitUpdateRequested(this.entity);
}

class VisitDeleteRequested extends VisitEvent {
  final String id;
  VisitDeleteRequested(this.id);
}

class VisitFormReset extends VisitEvent {}

class VisitReviewRequested extends VisitEvent {
  final String id;
  VisitReviewRequested(this.id);
}
class VisitFlagRequested extends VisitEvent {
  final String id;
  VisitFlagRequested(this.id);
}
class VisitUnflagRequested extends VisitEvent {
  final String id;
  VisitUnflagRequested(this.id);
}
