import '../../domain/entities/project_entity.dart';
import '../../domain/usecases/create_project_usecase.dart';

abstract class ProjectEvent {}

class ProjectLoadAllRequested extends ProjectEvent {}

class ProjectLoadOneRequested extends ProjectEvent {
  final String id;
  ProjectLoadOneRequested(this.id);
}

class ProjectCreateRequested extends ProjectEvent {
  final CreateProjectParams params;
  ProjectCreateRequested(this.params);
}

class ProjectUpdateRequested extends ProjectEvent {
  final ProjectEntity entity;
  ProjectUpdateRequested(this.entity);
}

class ProjectDeleteRequested extends ProjectEvent {
  final String id;
  ProjectDeleteRequested(this.id);
}

class ProjectFormReset extends ProjectEvent {}

class ProjectActivateRequested extends ProjectEvent {
  final String id;
  ProjectActivateRequested(this.id);
}
class ProjectPauseRequested extends ProjectEvent {
  final String id;
  ProjectPauseRequested(this.id);
}
class ProjectResumeRequested extends ProjectEvent {
  final String id;
  ProjectResumeRequested(this.id);
}
class ProjectCompleteRequested extends ProjectEvent {
  final String id;
  ProjectCompleteRequested(this.id);
}
class ProjectArchiveRequested extends ProjectEvent {
  final String id;
  ProjectArchiveRequested(this.id);
}
