# ============================================================
# Level3BlocGenerator.psm1 -- BLoC with CRUD + transitions
# ============================================================

function Invoke-GenerateBloc {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $sm     = $Ctx.Config.stateMachine
    $meta   = Get-PrimaryEntityMeta -Config $Ctx.Config
    $eName  = $meta.Name
    $eSnake = $meta.Snake

    $transitions = @($sm.transitions)

    # -- Events --
    $transEventClasses = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $transitions) {
        $tClass = ConvertTo-PascalCase $t.name
        $transEventClasses.Add(@"

class ${fclass}${tClass}Requested extends ${fclass}Event {
  final String id;
  ${fclass}${tClass}Requested(this.id);
}
"@)
    }

    $eventContent = @"
import '../../domain/entities/${eSnake}_entity.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';

abstract class ${fclass}Event {}

class ${fclass}LoadAllRequested extends ${fclass}Event {}

class ${fclass}LoadOneRequested extends ${fclass}Event {
  final String id;
  ${fclass}LoadOneRequested(this.id);
}

class ${fclass}CreateRequested extends ${fclass}Event {
  final Create${fclass}Params params;
  ${fclass}CreateRequested(this.params);
}

class ${fclass}UpdateRequested extends ${fclass}Event {
  final ${eName}Entity entity;
  ${fclass}UpdateRequested(this.entity);
}

class ${fclass}DeleteRequested extends ${fclass}Event {
  final String id;
  ${fclass}DeleteRequested(this.id);
}

class ${fclass}FormReset extends ${fclass}Event {}
$($transEventClasses -join '')
"@
    & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_event.dart") $eventContent

    # -- States --
    $stateContent = @"
import '../../domain/entities/${eSnake}_entity.dart';

abstract class ${fclass}State {}

class ${fclass}Initial extends ${fclass}State {}
class ${fclass}Loading extends ${fclass}State {}

class ${fclass}ListLoaded extends ${fclass}State {
  final List<${eName}Entity> items;
  ${fclass}ListLoaded(this.items);
}

class ${fclass}DetailLoaded extends ${fclass}State {
  final ${eName}Entity item;
  ${fclass}DetailLoaded(this.item);
}

class ${fclass}OperationSuccess extends ${fclass}State {
  final String message;
  final ${eName}Entity? updatedItem;
  ${fclass}OperationSuccess(this.message, {this.updatedItem});
}

class ${fclass}Empty extends ${fclass}State {}

class ${fclass}Failure extends ${fclass}State {
  final String message;
  ${fclass}Failure(this.message);
}
"@
    & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_state.dart") $stateContent

    # -- BLoC --
    # Transition handler registrations
    $transOnLines = [System.Collections.Generic.List[string]]::new()
    $transHandlers = [System.Collections.Generic.List[string]]::new()

    foreach ($t in $transitions) {
        $tClass  = ConvertTo-PascalCase $t.name
        $tLabel  = if ($t.label) { $t.label } else { ConvertTo-HumanLabel $t.name }
        $tTarget = $t.to

        $transOnLines.Add("    on<${fclass}${tClass}Requested>(_on${tClass});")

        $transHandlers.Add(@"

  Future<void> _on${tClass}(
      ${fclass}${tClass}Requested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await domainService.transition(
      id: event.id,
      targetStatus: ${fclass}Status.${tTarget},
    );
    result.fold(
      (f) => emit(${fclass}Failure(f.message)),
      (entity) => emit(${fclass}OperationSuccess(
        '${tLabel} successful',
        updatedItem: entity,
      )),
    );
  }
"@)
    }

    $blocContent = @"
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/services/${fname}_domain_service.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';
import '../../domain/usecases/delete_${fname}_usecase.dart';
import '../../domain/usecases/get_${fname}_usecase.dart';
import '../../domain/usecases/get_all_${fname}_usecase.dart';
import '../../domain/usecases/update_${fname}_usecase.dart';
import '../../domain/value_objects/${fname}_status.dart';
import '${fname}_event.dart';
import '${fname}_state.dart';

class ${fclass}Bloc extends Bloc<${fclass}Event, ${fclass}State> {
  final GetAll${fclass}UseCase  getAllUseCase;
  final Get${fclass}UseCase     getUseCase;
  final Create${fclass}UseCase  createUseCase;
  final Update${fclass}UseCase  updateUseCase;
  final Delete${fclass}UseCase  deleteUseCase;
  final ${fclass}DomainService  domainService;

  ${fclass}Bloc({
    required this.getAllUseCase,
    required this.getUseCase,
    required this.createUseCase,
    required this.updateUseCase,
    required this.deleteUseCase,
    required this.domainService,
  }) : super(${fclass}Initial()) {
    on<${fclass}LoadAllRequested>(_onLoadAll);
    on<${fclass}LoadOneRequested>(_onLoadOne);
    on<${fclass}CreateRequested>(_onCreate);
    on<${fclass}UpdateRequested>(_onUpdate);
    on<${fclass}DeleteRequested>(_onDelete);
    on<${fclass}FormReset>((_, emit) => emit(${fclass}Initial()));
$($transOnLines -join "`n")
  }

  Future<void> _onLoadAll(
      ${fclass}LoadAllRequested event, Emitter<${fclass}State> emit) async {
    emit(${fclass}Loading());
    final result = await getAllUseCase(NoParams());
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
      (_) => emit(${fclass}OperationSuccess('${fclass} updated successfully')),
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
$($transHandlers -join '')
}
"@
    & $NewFile (Join-Path $fDir "presentation\bloc\${fname}_bloc.dart") $blocContent
}

Export-ModuleMember -Function 'Invoke-GenerateBloc'

