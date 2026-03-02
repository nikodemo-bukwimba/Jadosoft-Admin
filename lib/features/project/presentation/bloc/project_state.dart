import '../../domain/entities/project_entity.dart';

abstract class ProjectState {}

class ProjectInitial extends ProjectState {}
class ProjectLoading extends ProjectState {}

class ProjectListLoaded extends ProjectState {
  final List<ProjectEntity> items;
  ProjectListLoaded(this.items);
}

class ProjectDetailLoaded extends ProjectState {
  final ProjectEntity item;
  ProjectDetailLoaded(this.item);
}

class ProjectOperationSuccess extends ProjectState {
  final String message;
  final ProjectEntity? updatedItem;
  ProjectOperationSuccess(this.message, {this.updatedItem});
}

class ProjectEmpty extends ProjectState {}

class ProjectFailure extends ProjectState {
  final String message;
  ProjectFailure(this.message);
}
