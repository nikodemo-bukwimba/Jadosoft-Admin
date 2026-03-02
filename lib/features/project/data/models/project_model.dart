import '../../domain/entities/project_entity.dart';
import '../../domain/value_objects/project_status.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.name,
    required super.description,
    required super.budget,
    required super.isPublic,
    required super.startDate,
    required super.createdAt,
    super.status = ProjectStatusX.initial,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      budget: (json['budget'] as num?)?.toDouble(),
      isPublic: json['is_public'] as bool? ?? false,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'planning'),
        orElse: () => ProjectStatusX.initial,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'name': name,
      'description': description,
      'budget': budget,
      'is_public': isPublic,
      'start_date': startDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
  };

  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      budget: entity.budget,
      isPublic: entity.isPublic,
      startDate: entity.startDate,
      createdAt: entity.createdAt,
      status: entity.status,
    );
  }
}
