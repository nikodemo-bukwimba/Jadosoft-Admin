// lib/features/officer/presentation/bloc/officer_event.dart
//
// FIX 3: OfficerReassignBranchRequested now includes `fromBranchId`
// so the datasource can remove the existing membership before creating
// the new one in the target branch.

import '../../domain/entities/officer_entity.dart';
import '../../domain/usecases/create_officer_usecase.dart';

abstract class OfficerEvent {}

class OfficerLoadAllRequested extends OfficerEvent {}

class OfficerLoadOneRequested extends OfficerEvent {
  final String userId;
  OfficerLoadOneRequested(this.userId);
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
  final String userId;
  OfficerDeleteRequested(this.userId);
}

class OfficerFormReset extends OfficerEvent {}

class OfficerActivateRequested extends OfficerEvent {
  final String userId;
  OfficerActivateRequested(this.userId);
}

class OfficerSuspendRequested extends OfficerEvent {
  final String userId;
  OfficerSuspendRequested(this.userId);
}

class OfficerDeactivateRequested extends OfficerEvent {
  final String userId;
  OfficerDeactivateRequested(this.userId);
}

/// FIX: Added `fromBranchId` — the officer's current branch that will
/// have its membership removed before the new assignment is created.
class OfficerReassignBranchRequested extends OfficerEvent {
  final String userId;
  final String fromBranchId; // ← was missing; needed by datasource
  final String toBranchId;
  final String orgRoleId;

  OfficerReassignBranchRequested({
    required this.userId,
    required this.fromBranchId,
    required this.toBranchId,
    required this.orgRoleId,
  });
}
