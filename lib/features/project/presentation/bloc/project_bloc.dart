import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/project_domain_service.dart';
import '../../domain/usecases/create_project_usecase.dart';
import '../../domain/usecases/delete_project_usecase.dart';
import '../../domain/usecases/get_project_usecase.dart';
import '../../domain/usecases/get_all_project_usecase.dart';
import '../../domain/usecases/update_project_usecase.dart';
import '../../domain/value_objects/project_status.dart';
import 'project_event.dart';
import 'project_state.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final GetAllProjectUseCase  getAllUseCase;
  final GetProjectUseCase     getUseCase;
  final CreateProjectUseCase  createUseCase;
  final UpdateProjectUseCase  updateUseCase;
  final DeleteProjectUseCase  deleteUseCase;
  final ProjectDomainService  domainService;

  ProjectBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(ProjectInitial()) {
    on<ProjectLoadAllRequested>(_onLoadAll);
    on<ProjectLoadOneRequested>(_onLoadOne);
    on<ProjectCreateRequested>(_onCreate);
    on<ProjectUpdateRequested>(_onUpdate);
    on<ProjectDeleteRequested>(_onDelete);
    on<ProjectFormReset>((_, emit) => emit(ProjectInitial()));
    on<ProjectActivateRequested>(_onActivate);
    on<ProjectPauseRequested>(_onPause);
    on<ProjectResumeRequested>(_onResume);
    on<ProjectCompleteRequested>(_onComplete);
    on<ProjectArchiveRequested>(_onArchive);
  }

  Future<void> _onLoadAll(
      ProjectLoadAllRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (items) => items.isEmpty
          ? emit(ProjectEmpty())
          : emit(ProjectListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      ProjectLoadOneRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await getUseCase(GetProjectParams(id: event.id));
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (item) => emit(ProjectDetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      ProjectCreateRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (_) => emit(ProjectOperationSuccess('Project created successfully')),
    );
  }

  Future<void> _onUpdate(
      ProjectUpdateRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await updateUseCase(UpdateProjectParams(entity: event.entity));
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (_) => emit(ProjectOperationSuccess('Project updated successfully')),
    );
  }

  Future<void> _onDelete(
      ProjectDeleteRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await deleteUseCase(DeleteProjectParams(id: event.id));
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (_) => emit(ProjectOperationSuccess('Project deleted successfully')),
    );
  }

  Future<void> _onActivate(
      ProjectActivateRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProjectStatus.active,
    );
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (entity) => emit(ProjectOperationSuccess(
        'Start Project successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onPause(
      ProjectPauseRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProjectStatus.onHold,
    );
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (entity) => emit(ProjectOperationSuccess(
        'Put On Hold successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onResume(
      ProjectResumeRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProjectStatus.active,
    );
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (entity) => emit(ProjectOperationSuccess(
        'Resume successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onComplete(
      ProjectCompleteRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProjectStatus.completed,
    );
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (entity) => emit(ProjectOperationSuccess(
        'Mark Complete successful',
        updatedItem: entity,
      )),
    );
  }
  Future<void> _onArchive(
      ProjectArchiveRequested event, Emitter<ProjectState> emit) async {
    emit(ProjectLoading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ProjectStatus.archived,
    );
    result.fold(
      (f) => emit(ProjectFailure(f.message)),
      (entity) => emit(ProjectOperationSuccess(
        'Archive successful',
        updatedItem: entity,
      )),
    );
  }
}
