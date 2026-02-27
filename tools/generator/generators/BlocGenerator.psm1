# ============================================================
# BlocGenerator.psm1
# Generates: presentation/bloc/
# ============================================================

function Invoke-GenerateBloc {
    param([hashtable]$Ctx, [scriptblock]$NewFile)

    $config   = $Ctx.Config
    $tokens   = $Ctx.Tokens
    $fDir     = $Ctx.FeatureDir
    $fname    = $tokens.FNAME
    $fclass   = $tokens.FCLASS
    $maturity = $Ctx.Maturity

    $primaryEntityName = $config.entities.PSObject.Properties |
        Where-Object { $_.Value.primary -eq $true } |
        Select-Object -First 1 -ExpandProperty Name
    $primarySnake = ConvertTo-SnakeCase $primaryEntityName

    # ── Events ───────────────────────────────────────────────
    $transitionEvents = ''
    if ($config.stateMachine -and $maturity -ge 2) {
        $lines = [System.Collections.Generic.List[string]]::new()
        $lines.Add('')
        $lines.Add('// State machine transition events')
        foreach ($t in $config.stateMachine.transitions) {
            $tPascal = $t.name.Substring(0,1).ToUpper() + $t.name.Substring(1)
            $lines.Add("class ${fclass}${tPascal}Requested extends ${fclass}Event {")
            $lines.Add("  final String id;")
            $lines.Add("  ${fclass}${tPascal}Requested(this.id);")
            $lines.Add("}")
        }
        $transitionEvents = $lines -join "`n"
    }

    $eventContent = @"
// ${fname}_event.dart
// All events dispatched to ${fclass}Bloc.
// UI dispatches events. Never calls use cases directly.

part of '${fname}_bloc.dart';

abstract class ${fclass}Event {}

// ── CRUD events ───────────────────────────────────────────────
class ${fclass}LoadAllRequested  extends ${fclass}Event {
  final ${fclass}FilterParams?     filters;
  final ${fclass}SortParams?       sort;
  final ${fclass}PaginationParams? pagination;

  ${fclass}LoadAllRequested({this.filters, this.sort, this.pagination});
}

class ${fclass}LoadOneRequested  extends ${fclass}Event {
  final String id;
  ${fclass}LoadOneRequested(this.id);
}

class ${fclass}CreateRequested   extends ${fclass}Event {
  final Create${fclass}Params params;
  ${fclass}CreateRequested(this.params);
}

class ${fclass}UpdateRequested   extends ${fclass}Event {
  final ${primaryEntityName}Entity entity;
  ${fclass}UpdateRequested(this.entity);
}

class ${fclass}DeleteRequested   extends ${fclass}Event {
  final String id;
  ${fclass}DeleteRequested(this.id);
}

class ${fclass}SearchChanged     extends ${fclass}Event {
  final String query;
  ${fclass}SearchChanged(this.query);
}

class ${fclass}FormReset         extends ${fclass}Event {}
$transitionEvents
"@
    & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_event.dart") $eventContent

    # ── State ─────────────────────────────────────────────────
    $stateContent = @"
// ${fname}_state.dart
// All states emitted by ${fclass}Bloc.
// UI reacts to these states exclusively.

part of '${fname}_bloc.dart';

abstract class ${fclass}State {}

class ${fclass}Initial           extends ${fclass}State {}
class ${fclass}Loading           extends ${fclass}State {}
class ${fclass}Empty             extends ${fclass}State {}

class ${fclass}ListLoaded        extends ${fclass}State {
  final List<${primaryEntityName}Entity> items;
  final int?                            totalCount;

  ${fclass}ListLoaded(this.items, {this.totalCount});
}

class ${fclass}DetailLoaded      extends ${fclass}State {
  final ${primaryEntityName}Entity item;
  ${fclass}DetailLoaded(this.item);
}

class ${fclass}OperationSuccess  extends ${fclass}State {
  final String              message;
  final ${primaryEntityName}Entity? updatedItem;

  ${fclass}OperationSuccess(this.message, {this.updatedItem});
}

class ${fclass}Failure           extends ${fclass}State {
  final String message;
  ${fclass}Failure(this.message);
}
"@
    & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_state.dart") $stateContent

    # ── BLoC ─────────────────────────────────────────────────
    $transitionUseCaseImports = ''
    $transitionUseCaseFields  = ''
    $transitionUseCaseCtor    = ''
    $transitionHandlerReg     = ''
    $transitionHandlers       = ''

    if ($config.stateMachine -and $maturity -ge 2) {
        $importLines  = [System.Collections.Generic.List[string]]::new()
        $fieldLines   = [System.Collections.Generic.List[string]]::new()
        $ctorLines    = [System.Collections.Generic.List[string]]::new()
        $regLines     = [System.Collections.Generic.List[string]]::new()
        $handlerLines = [System.Collections.Generic.List[string]]::new()

        foreach ($t in $config.stateMachine.transitions) {
            $tName   = $t.name
            $tPascal = $tName.Substring(0,1).ToUpper() + $tName.Substring(1)
            $tSnake  = ConvertTo-SnakeCase $tName

            $importLines.Add("import '../../domain/usecases/${tSnake}_${fname}_usecase.dart';")
            $fieldLines.Add("  final ${tPascal}${fclass}UseCase  ${tName}UseCase;")
            $ctorLines.Add("    required this.${tName}UseCase,")
            $regLines.Add("    on<${fclass}${tPascal}Requested>(_on${tPascal});")

            $handlerLines.Add("")
            $handlerLines.Add("  Future<void> _on${tPascal}(")
            $handlerLines.Add("      ${fclass}${tPascal}Requested event, Emitter<${fclass}State> emit) async {")
            $handlerLines.Add("    emit(${fclass}Loading());")
            $handlerLines.Add("    final result = await ${tName}UseCase(${tPascal}${fclass}Params(id: event.id));")
            $handlerLines.Add("    result.fold(")
            $handlerLines.Add("      (f) => emit(${fclass}Failure(f.message)),")
            $handlerLines.Add("      (item) => emit(${fclass}OperationSuccess('${fclass} status updated', updatedItem: item)),")
            $handlerLines.Add("    );")
            $handlerLines.Add("  }")
        }

        $transitionUseCaseImports = ($importLines -join "`n")
        $transitionUseCaseFields  = ($fieldLines -join "`n")
        $transitionUseCaseCtor    = ($ctorLines -join "`n")
        $transitionHandlerReg     = ($regLines -join "`n")
        $transitionHandlers       = ($handlerLines -join "`n")
    }

    $blocContent = @"
// ${fname}_bloc.dart
// Orchestrates CRUD and state machine transitions.
// No business logic here. No repository calls. No datasource calls.
// This is a pure dispatcher — events in, states out.

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/${primarySnake}_entity.dart';
import '../../domain/repositories/${fname}_repository.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';
import '../../domain/usecases/delete_${fname}_usecase.dart';
import '../../domain/usecases/get_${fname}_usecase.dart';
import '../../domain/usecases/get_all_${fname}_usecase.dart';
import '../../domain/usecases/update_${fname}_usecase.dart';
$transitionUseCaseImports

part '${fname}_event.dart';
part '${fname}_state.dart';

class ${fclass}Bloc extends Bloc<${fclass}Event, ${fclass}State> {
  final GetAll${fclass}UseCase  getAllUseCase;
  final Get${fclass}UseCase     getUseCase;
  final Create${fclass}UseCase  createUseCase;
  final Update${fclass}UseCase  updateUseCase;
  final Delete${fclass}UseCase  deleteUseCase;
$transitionUseCaseFields

  ${fclass}Bloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
$transitionUseCaseCtor  }) : super(${fclass}Initial()) {
    on<${fclass}LoadAllRequested>(_onLoadAll);
    on<${fclass}LoadOneRequested>(_onLoadOne);
    on<${fclass}CreateRequested>(_onCreate);
    on<${fclass}UpdateRequested>(_onUpdate);
    on<${fclass}DeleteRequested>(_onDelete);
    on<${fclass}SearchChanged>(_onSearch);
    on<${fclass}FormReset>((_, emit) => emit(${fclass}Initial()));
$transitionHandlerReg  }

  Future<void> _onLoadAll(
      ${fclass}LoadAllRequested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await getAllUseCase(GetAll${fclass}Params(
      filters:    event.filters,
      sort:       event.sort,
      pagination: event.pagination,
    ));
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (items) => items.isEmpty
          ? emit(${fclass}Empty())
          : emit(${fclass}ListLoaded(items)),
    );
  }

  Future<void> _onLoadOne(
      ${fclass}LoadOneRequested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await getUseCase(Get${fclass}Params(id: event.id));
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (item) => emit(${fclass}DetailLoaded(item)),
    );
  }

  Future<void> _onCreate(
      ${fclass}CreateRequested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await createUseCase(event.params);
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (_) => emit(${fclass}OperationSuccess('${fclass} created successfully')),
    );
  }

  Future<void> _onUpdate(
      ${fclass}UpdateRequested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await updateUseCase(Update${fclass}Params(entity: event.entity));
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (item) => emit(${fclass}OperationSuccess('${fclass} updated successfully', updatedItem: item)),
    );
  }

  Future<void> _onDelete(
      ${fclass}DeleteRequested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await deleteUseCase(Delete${fclass}Params(id: event.id));
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (_) => emit(${fclass}OperationSuccess('${fclass} deleted successfully')),
    );
  }

  Future<void> _onSearch(
      ${fclass}SearchChanged event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    // TODO: Implement search — use SearchUseCase if api.searchable: true
    final result = await getAllUseCase(const GetAll${fclass}Params());
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (items) {
        final filtered = items.where((item) =>
          item.toString().toLowerCase().contains(event.query.toLowerCase())
        ).toList();
        filtered.isEmpty
          ? emit(${fclass}Empty())
          : emit(${fclass}ListLoaded(filtered));
      },
    );
  }
$transitionHandlers}
"@
    & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_bloc.dart") $blocContent

    # ── Form Cubit (for inline child management) ──────────────
    $hasInline = $false
    $primaryEntity = $config.entities.$primaryEntityName
    if ($null -ne $primaryEntity.ui -and $null -ne $primaryEntity.ui.form -and $null -ne $primaryEntity.ui.form.inline) {
        $hasInline = $primaryEntity.ui.form.inline.Count -gt 0
    }

    if ($hasInline) {
        $formCubitContent = @"
// ${fname}_form_cubit.dart
// Manages form state including pending inline child additions/removals.
// On submit, all changes are applied atomically.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/${primarySnake}_entity.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';
import '../../domain/usecases/update_${fname}_usecase.dart';

part '${fname}_form_state.dart';

enum FormMode { create, edit }

class ${fclass}FormCubit extends Cubit<${fclass}FormState> {
  final Create${fclass}UseCase createUseCase;
  final Update${fclass}UseCase updateUseCase;

  ${fclass}FormCubit({
    required this.createUseCase,
    required this.updateUseCase,
  }) : super(${fclass}FormState.initial());

  void init({${primaryEntityName}Entity? existing}) {
    emit(${fclass}FormState.initial(entity: existing));
  }

  // TODO: Add methods for each inline relationship declared in ui.form.inline
  // Example pattern for inline children:
  // void addPendingMember(ProjectMemberEntity member) {
  //   emit(state.copyWith(pendingMembers: [...state.pendingMembers, member]));
  // }
  // void removeMember(String id) {
  //   emit(state.copyWith(removedMemberIds: [...state.removedMemberIds, id]));
  // }

  Future<void> submit(Create${fclass}Params params) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final result = state.entity == null
      ? await createUseCase(params)
      : await updateUseCase(Update${fclass}Params(entity: state.entity!));

    result.fold(
      (f) => emit(state.copyWith(isSubmitting: false, errorMessage: f.message)),
      (_) => emit(state.copyWith(isSubmitting: false, isSuccess: true)),
    );
  }
}
"@
        & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_form_cubit.dart") $formCubitContent

        $formStateContent = @"
// ${fname}_form_state.dart
part of '${fname}_form_cubit.dart';

class ${fclass}FormState extends Equatable {
  final ${primaryEntityName}Entity? entity;        // null = create mode
  final bool                       isSubmitting;
  final bool                       isSuccess;
  final String?                    errorMessage;

  // TODO: Add fields for each inline relationship
  // final List<ProjectMemberEntity> pendingMembers;
  // final List<String>              removedMemberIds;

  const ${fclass}FormState({
    this.entity,
    this.isSubmitting = false,
    this.isSuccess    = false,
    this.errorMessage,
  });

  factory ${fclass}FormState.initial({${primaryEntityName}Entity? entity}) {
    return ${fclass}FormState(entity: entity);
  }

  ${fclass}FormState copyWith({
    ${primaryEntityName}Entity? entity,
    bool?                      isSubmitting,
    bool?                      isSuccess,
    String?                    errorMessage,
  }) {
    return ${fclass}FormState(
      entity:       entity       ?? this.entity,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess:    isSuccess    ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [entity, isSubmitting, isSuccess, errorMessage];
}
"@
        & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_form_state.dart") $formStateContent
    }
}

Export-ModuleMember -Function Invoke-GenerateBloc
