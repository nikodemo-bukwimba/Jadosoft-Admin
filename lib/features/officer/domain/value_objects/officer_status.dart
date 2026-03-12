import 'package:flutter/material.dart';

enum OfficerStatus {
  active,
  suspended,
  deactivated,
}

extension OfficerStatusX on OfficerStatus {
  static const Map<OfficerStatus, Set<OfficerStatus>> _transitions = {
    OfficerStatus.active:      {OfficerStatus.suspended, OfficerStatus.deactivated},
    OfficerStatus.suspended:   {OfficerStatus.active, OfficerStatus.deactivated},
    OfficerStatus.deactivated: {},
  };

  static const OfficerStatus initial = OfficerStatus.active;

  bool canTransitionTo(OfficerStatus target) =>
      _transitions[this]?.contains(target) ?? false;

  String get displayName => switch (this) {
    OfficerStatus.active      => 'Active',
    OfficerStatus.suspended   => 'Suspended',
    OfficerStatus.deactivated => 'Deactivated',
  };

  Color get color => switch (this) {
    OfficerStatus.active      => Colors.green,
    OfficerStatus.suspended   => Colors.orange,
    OfficerStatus.deactivated => Colors.grey,
  };

  static OfficerStatus fromString(String? value) =>
      OfficerStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => OfficerStatus.active,
      );
}