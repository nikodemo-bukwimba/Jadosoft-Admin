import 'package:flutter/material.dart';

enum ProjectStatus {
  planning,
  active,
  onHold,
  completed,
  archived,
}

extension ProjectStatusX on ProjectStatus {
  static const Map<ProjectStatus, Set<ProjectStatus>> _transitions = {
      ProjectStatus.planning: {ProjectStatus.active},
      ProjectStatus.active: {ProjectStatus.onHold, ProjectStatus.completed},
      ProjectStatus.onHold: {ProjectStatus.active, ProjectStatus.archived},
      ProjectStatus.completed: {ProjectStatus.archived},
      ProjectStatus.archived: {},
  };

  static const ProjectStatus initial = ProjectStatus.planning;

  bool canTransitionTo(ProjectStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
      ProjectStatus.planning  => 'Planning',
      ProjectStatus.active  => 'Active',
      ProjectStatus.onHold  => 'On Hold',
      ProjectStatus.completed  => 'Completed',
      ProjectStatus.archived  => 'Archived',
  };

  Color get color => switch (this) {
      ProjectStatus.planning => Colors.grey,
      ProjectStatus.active => Colors.blue,
      ProjectStatus.onHold => Colors.orange,
      ProjectStatus.completed => Colors.green,
      ProjectStatus.archived => Colors.red,
  };
}
