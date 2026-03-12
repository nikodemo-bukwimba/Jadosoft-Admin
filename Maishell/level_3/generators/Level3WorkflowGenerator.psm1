# ============================================================
# Level3WorkflowGenerator.psm1
# Generates: domain/events, domain/workflow
# ============================================================

function Invoke-GenerateWorkflow {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $wf     = $Ctx.Config.workflow
    $meta   = Get-PrimaryEntityMeta -Config $Ctx.Config
    $eSnake = $meta.Snake
    $eName  = $meta.Name

    _Gen-DomainEvents      -Ctx $Ctx -NewFile $NewFile -WF $wf -EName $eName -ESnake $eSnake
    _Gen-WorkflowExecutor  -Ctx $Ctx -NewFile $NewFile -WF $wf -EName $eName -ESnake $eSnake
}

function _Gen-DomainEvents {
    param($Ctx, $NewFile, $WF, $EName, $ESnake)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $steps = @()
    if ($WF -and $WF.steps) { $steps = @($WF.steps) }

    # Event classes from workflow steps
    $eventClasses = [System.Collections.Generic.List[string]]::new()
    foreach ($step in $steps) {
        $stepClass = ConvertTo-PascalCase $step.name
        $label     = if ($step.label) { $step.label } else { ConvertTo-HumanLabel $step.name }
        $eventClasses.Add(@"

class ${fclass}${stepClass}Event extends ${fclass}DomainEvent {
  ${fclass}${stepClass}Event({
    required super.entityId,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => '$($step.name)';
}
"@)
    }

    # Standard lifecycle events (always generated)
    $content = @"
import '../entities/${ESnake}_entity.dart';

/// Base class for all $fclass domain events.
abstract class ${fclass}DomainEvent {
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime occurredAt;

  ${fclass}DomainEvent({
    required this.entityId,
    this.payload,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();

  String get name;

  Map<String, dynamic> toMap() => {
    'event':      name,
    'entityId':   entityId,
    'occurredAt': occurredAt.toIso8601String(),
    if (payload != null) 'payload': payload,
  };
}

class ${fclass}CreatedEvent extends ${fclass}DomainEvent {
  ${fclass}CreatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => '${fname}.created';
}

class ${fclass}UpdatedEvent extends ${fclass}DomainEvent {
  ${fclass}UpdatedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => '${fname}.updated';
}

class ${fclass}StatusChangedEvent extends ${fclass}DomainEvent {
  final String fromStatus;
  final String toStatus;

  ${fclass}StatusChangedEvent({
    required super.entityId,
    required this.fromStatus,
    required this.toStatus,
    super.payload,
    super.occurredAt,
  });

  @override
  String get name => '${fname}.status_changed';

  @override
  Map<String, dynamic> toMap() => {
    ...super.toMap(),
    'fromStatus': fromStatus,
    'toStatus':   toStatus,
  };
}

class ${fclass}DeletedEvent extends ${fclass}DomainEvent {
  ${fclass}DeletedEvent({required super.entityId, super.payload, super.occurredAt});

  @override
  String get name => '${fname}.deleted';
}
$($eventClasses -join "`n")
"@
    & $NewFile (Join-Path $fDir "domain\events\${fname}_domain_events.dart") $content
}

function _Gen-WorkflowExecutor {
    param($Ctx, $NewFile, $WF, $EName, $ESnake)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $steps = @()
    if ($WF -and $WF.steps) { $steps = @($WF.steps) }

    # Step method declarations
    $stepMethods = [System.Collections.Generic.List[string]]::new()
    $stepCalls   = [System.Collections.Generic.List[string]]::new()
    $rollbackMethods = [System.Collections.Generic.List[string]]::new()

    foreach ($step in $steps) {
        $methodName = $step.name
        $label      = if ($step.label) { $step.label } else { ConvertTo-HumanLabel $step.name }

        $stepMethods.Add(@"
  /// Step: $label
  Future<Either<Failure, ${EName}Entity>> _$methodName(${EName}Entity entity) async {
    // -- HUMAN CUSTOMIZATION ZONE --
    // Implement: $label
    // Return Right(entity) on success, Left(Failure) on failure.
    // -- END CUSTOMIZATION ZONE --
    return Right(entity);
  }
"@)

        $stepCalls.Add(@"
    // Step: $label
    result = await _$methodName(current);
    if (result.isLeft()) {
      await _rollback(entity, completedSteps);
      return result;
    }
    current = result.getOrElse(() => current);
    completedSteps.add('$methodName');
"@)

        $rollbackMethods.Add("      case '$methodName': break; // TODO: rollback $label")
    }

    $content = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${ESnake}_entity.dart';
import '../events/${fname}_domain_events.dart';

class ${fclass}WorkflowExecutor {
  final List<${fclass}DomainEvent> _emittedEvents = [];

  List<${fclass}DomainEvent> get emittedEvents => List.unmodifiable(_emittedEvents);

  void clearEvents() => _emittedEvents.clear();

  /// Executes the full workflow for the given entity.
  /// Steps run in order; on failure, completed steps are rolled back.
  Future<Either<Failure, ${EName}Entity>> execute(${EName}Entity entity) async {
    _emittedEvents.clear();
    final completedSteps = <String>[];
    var current = entity;
    Either<Failure, ${EName}Entity> result;

$($stepCalls -join "`n")

    return Right(current);
  }

$($stepMethods -join "`n")

  Future<void> _rollback(${EName}Entity entity, List<String> completedSteps) async {
    for (final step in completedSteps.reversed) {
      switch (step) {
$($rollbackMethods -join "`n")
      }
    }
  }

  void _emit(${fclass}DomainEvent event) => _emittedEvents.add(event);
}
"@
    & $NewFile (Join-Path $fDir "domain\workflow\${fname}_workflow_executor.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateWorkflow'

