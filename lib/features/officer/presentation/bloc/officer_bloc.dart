// lib/features/officer/presentation/bloc/officer_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/officer_domain_service.dart';
import '../../domain/usecases/create_officer_usecase.dart';
import '../../domain/usecases/delete_officer_usecase.dart';
import '../../domain/usecases/get_officer_usecase.dart';
import '../../domain/usecases/get_all_officer_usecase.dart';
import '../../domain/usecases/update_officer_usecase.dart';
import '../../domain/value_objects/officer_status.dart';
import 'officer_event.dart';
import 'officer_state.dart';

class OfficerBloc extends Bloc<OfficerEvent, OfficerState> {
  final GetAllOfficerUseCase getAllUseCase;
  final GetOfficerUseCase getUseCase;
  final CreateOfficerUseCase createUseCase;
  final UpdateOfficerUseCase updateUseCase;
  final DeleteOfficerUseCase deleteUseCase;
  final OfficerDomainService domainService;

  OfficerBloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(OfficerInitial()) {
    on<OfficerLoadAllRequested>(_onLoadAll);
    on<OfficerLoadOneRequested>(_onLoadOne);
    on<OfficerCreateRequested>(_onCreate);
    on<OfficerUpdateRequested>(_onUpdate);
    on<OfficerDeleteRequested>(_onDelete);
    on<OfficerFormReset>((_, emit) => emit(OfficerInitial()));
    on<OfficerActivateRequested>(_onActivate);
    on<OfficerSuspendRequested>(_onSuspend);
    on<OfficerDeactivateRequested>(_onDeactivate);
    on<OfficerReassignBranchRequested>(_onReassignBranch);
  }

  Future<void> _onLoadAll(
    OfficerLoadAllRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final result = await getAllUseCase(NoParams());
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (p) => p.items.isEmpty
          ? emit(OfficerEmpty())
          : emit(OfficerListLoaded(p.items)),
    );
  }

  // FIX 1: forward branchId so getById uses the correct org URL.
  Future<void> _onLoadOne(
    OfficerLoadOneRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final result = await getUseCase(
      GetOfficerParams(userId: event.userId, branchId: event.branchId),
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (item) => emit(OfficerDetailLoaded(item)),
    );
  }

  // Problem #2 fix: CreateOfficerParams now carries fullName + password.
  // The usecase calls repository.create() → POST /orgs/{rootOrgId}/officers
  // which creates a fully active User account the officer can log in with.
  Future<void> _onCreate(
    OfficerCreateRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (officer) => emit(
        OfficerOperationSuccess(
          'Officer "${officer.displayName}" created. They can log in immediately.',
          updatedItem: officer,
        ),
      ),
    );
  }

  Future<void> _onUpdate(
    OfficerUpdateRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final result = await updateUseCase(
      UpdateOfficerParams(entity: event.entity),
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (_) => emit(OfficerOperationSuccess('Officer updated successfully')),
    );
  }

  Future<void> _onDelete(
    OfficerDeleteRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final result = await deleteUseCase(
      DeleteOfficerParams(userId: event.userId),
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (_) => emit(OfficerOperationSuccess('Officer removed successfully')),
    );
  }

  // FIX 1: Load the officer first (with branchId) so domainService.transition
  // can use the correct org URL for activate/suspend PATCH calls.
  Future<void> _onActivate(
    OfficerActivateRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final loaded = await getUseCase(GetOfficerParams(userId: event.userId));
    if (loaded.isLeft()) {
      loaded.fold((f) => emit(OfficerFailure(f.message)), (_) {});
      return;
    }
    final branchId = loaded.getOrElse(() => throw StateError('')).branchId;
    final result = await domainService.transition(
      userId: event.userId,
      targetStatus: OfficerStatus.active,
      branchId: branchId,
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (e) => emit(OfficerOperationSuccess('Activated', updatedItem: e)),
    );
  }

  Future<void> _onSuspend(
    OfficerSuspendRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final loaded = await getUseCase(GetOfficerParams(userId: event.userId));
    if (loaded.isLeft()) {
      loaded.fold((f) => emit(OfficerFailure(f.message)), (_) {});
      return;
    }
    final branchId = loaded.getOrElse(() => throw StateError('')).branchId;
    final result = await domainService.transition(
      userId: event.userId,
      targetStatus: OfficerStatus.suspended,
      branchId: branchId,
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (e) => emit(OfficerOperationSuccess('Suspended', updatedItem: e)),
    );
  }

  Future<void> _onDeactivate(
    OfficerDeactivateRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final loaded = await getUseCase(GetOfficerParams(userId: event.userId));
    if (loaded.isLeft()) {
      loaded.fold((f) => emit(OfficerFailure(f.message)), (_) {});
      return;
    }
    final branchId = loaded.getOrElse(() => throw StateError('')).branchId;
    final result = await domainService.transition(
      userId: event.userId,
      targetStatus: OfficerStatus.deactivated,
      branchId: branchId,
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (e) => emit(OfficerOperationSuccess('Deactivated', updatedItem: e)),
    );
  }

  // Problem #3 fix: calls the dedicated transfer endpoint via domainService
  // which never deletes the root org membership anchor.
  Future<void> _onReassignBranch(
    OfficerReassignBranchRequested event,
    Emitter<OfficerState> emit,
  ) async {
    emit(OfficerLoading());
    final result = await domainService.reassignBranch(
      userId: event.userId,
      fromBranchId: event.fromBranchId,
      toBranchId: event.toBranchId,
      orgRoleId: event.orgRoleId,
    );
    result.fold(
      (f) => emit(OfficerFailure(f.message)),
      (_) =>
          emit(OfficerOperationSuccess('Officer transferred to new branch.')),
    );
  }
}
