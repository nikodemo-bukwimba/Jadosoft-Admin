// lib/features/officer/presentation/bloc/officer_event.dart
//
// Added `branchId` to OfficerLoadOneRequested so the datasource
// can call GET /orgs/{branchId}/members/{userId} for branch-only officers.

import '../../domain/entities/officer_entity.dart';
import '../../domain/usecases/create_officer_usecase.dart';

abstract class OfficerEvent {}

class OfficerLoadAllRequested extends OfficerEvent {}

class OfficerLoadOneRequested extends OfficerEvent {
  final String userId;

  /// The officer's actual org/branch id. Null = fall back to root org.
  final String? branchId;
  OfficerLoadOneRequested(this.userId, {this.branchId});
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

class OfficerReassignBranchRequested extends OfficerEvent {
  final String userId;
  final String fromBranchId;
  final String toBranchId;
  final String orgRoleId;

  OfficerReassignBranchRequested({
    required this.userId,
    required this.fromBranchId,
    required this.toBranchId,
    required this.orgRoleId,
  });
}
