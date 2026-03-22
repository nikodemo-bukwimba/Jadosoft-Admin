import '../../domain/entities/officer_entity.dart';
import '../../domain/usecases/create_officer_usecase.dart';

abstract class OfficerEvent {}
class OfficerLoadAllRequested extends OfficerEvent {}
class OfficerLoadOneRequested extends OfficerEvent { final String userId; OfficerLoadOneRequested(this.userId); }
class OfficerCreateRequested extends OfficerEvent { final CreateOfficerParams params; OfficerCreateRequested(this.params); }
class OfficerUpdateRequested extends OfficerEvent { final OfficerEntity entity; OfficerUpdateRequested(this.entity); }
class OfficerDeleteRequested extends OfficerEvent { final String userId; OfficerDeleteRequested(this.userId); }
class OfficerFormReset extends OfficerEvent {}
class OfficerActivateRequested extends OfficerEvent { final String userId; OfficerActivateRequested(this.userId); }
class OfficerSuspendRequested extends OfficerEvent { final String userId; OfficerSuspendRequested(this.userId); }
class OfficerDeactivateRequested extends OfficerEvent { final String userId; OfficerDeactivateRequested(this.userId); }
class OfficerReassignBranchRequested extends OfficerEvent {
  final String userId; final String toBranchId; final String orgRoleId;
  OfficerReassignBranchRequested({required this.userId, required this.toBranchId, required this.orgRoleId});
}
