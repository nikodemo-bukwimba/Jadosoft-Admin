import '../../domain/entities/officer_entity.dart';
import '../../domain/usecases/create_officer_usecase.dart';

abstract class OfficerEvent {}

class OfficerLoadAllRequested extends OfficerEvent {}

class OfficerLoadOneRequested extends OfficerEvent {
  final String id;
  OfficerLoadOneRequested(this.id);
}

class OfficerCreateRequested extends OfficerEvent {
  final CreateOfficerParams params;
  OfficerCreateRequested(this.params);
}

class OfficerUpdateRequested extends OfficerEvent {
  final OfficerEntity entity;
  OfficerUpdateRequested(this.entity);
}

class OfficerDeleteRequested extends OfficerEvent {
  final String id;
  OfficerDeleteRequested(this.id);
}

class OfficerFormReset extends OfficerEvent {}

class OfficerActivateRequested extends OfficerEvent {
  final String id;
  OfficerActivateRequested(this.id);
}
class OfficerSuspendRequested extends OfficerEvent {
  final String id;
  OfficerSuspendRequested(this.id);
}
class OfficerDeactivateRequested extends OfficerEvent {
  final String id;
  OfficerDeactivateRequested(this.id);
}
