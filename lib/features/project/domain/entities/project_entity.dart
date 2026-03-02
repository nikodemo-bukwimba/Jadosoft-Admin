import 'package:equatable/equatable.dart';
import '../value_objects/project_status.dart';

class ProjectEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double? budget;
  final bool isPublic;
  final DateTime? startDate;
  final DateTime createdAt;
  final ProjectStatus status;

  const ProjectEntity({
    required this.id,
    required this.name,
    this.description,
    this.budget,
    required this.isPublic,
    this.startDate,
    required this.createdAt,
    this.status = ProjectStatusX.initial,
  });

  ProjectEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? budget,
    bool? isPublic,
    DateTime? startDate,
    DateTime? createdAt,
    ProjectStatus? status,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      isPublic: isPublic ?? this.isPublic,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, name, description, budget, isPublic, startDate, createdAt, status];
}
