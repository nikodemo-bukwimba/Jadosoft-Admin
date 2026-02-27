# ============================================================
# WorkflowGenerator.psm1
# Generates Level 3 additions:
#   domain/events/{feature}_domain_events.dart
#   domain/workflows/{feature}_workflow.dart
# ============================================================

function Invoke-GenerateWorkflow {
  param([hashtable]$Ctx, [scriptblock]$NewFile)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $maturity = $Ctx.Maturity

  $primaryEntityName = $config.entities.PSObject.Properties |
  Where-Object { $_.Value.primary -eq $true } |
  Select-Object -First 1 -ExpandProperty Name
  $primarySnake = ConvertTo-SnakeCase $primaryEntityName

  # ── Domain events ─────────────────────────────────────────
  # Build event classes from workflow.events config
  $eventClasses = [System.Collections.Generic.List[string]]::new()

  if ($config.workflow -and $config.workflow.events) {
    foreach ($evt in $config.workflow.events) {
      $eName = $evt.name
      $fields = if ($evt.fields) { $evt.fields } else { @('entityId') }

      $fieldDecls = ($fields | ForEach-Object {
          "  final String $_;"
        }) -join "`n"

      $ctorParams = ($fields | ForEach-Object {
          "    required this.$_,"
        }) -join "`n"

      $eventClasses.Add(@"

/// Emitted when: $(if ($null -ne $evt.trigger) { $evt.trigger } else { $eName })
class $eName extends ${fclass}DomainEvent {
$fieldDecls

  const $eName({
$ctorParams    required super.occurredAt,
  });
}
"@)
    }
  }
  else {
    # Default events if none declared
    $eventClasses.Add(@"

/// Emitted when the workflow completes successfully.
/// TODO: Replace with domain-meaningful events.
class ${fclass}WorkflowCompletedEvent extends ${fclass}DomainEvent {
  const ${fclass}WorkflowCompletedEvent({
    required super.entityId,
    required super.occurredAt,
  });
}

/// Emitted when the workflow is cancelled at any step.
class ${fclass}WorkflowCancelledEvent extends ${fclass}DomainEvent {
  final String reason;
  const ${fclass}WorkflowCancelledEvent({
    required super.entityId,
    required super.occurredAt,
    required this.reason,
  });
}
"@)
  }

  $eventsContent = @"
// ${fname}_domain_events.dart
// Level 3 — Domain events emitted after workflow completion or key transitions.
//
// Design intent:
//   Other features subscribe to these events WITHOUT importing this feature's
//   internals. Events are the public broadcast channel of a feature.
//
// TODO: Replace placeholder events with events meaningful to your domain.
// TODO: Register subscribers in injection_container.dart where needed.

abstract class ${fclass}DomainEvent {
  final String   entityId;
  final DateTime occurredAt;

  const ${fclass}DomainEvent({
    required this.entityId,
    required this.occurredAt,
  });
}
$($eventClasses -join "`n")
"@

  & $NewFile (Join-Path $fDir "domain\events\${fname}_domain_events.dart") $eventsContent

  # ── Workflow step executor ────────────────────────────────
  # Build step list from workflow.steps config or use defaults
  $steps = if ($config.workflow -and $config.workflow.steps) {
    $config.workflow.steps
  }
  else {
    @(
      [PSCustomObject]@{ name = 'validatePreconditions'; label = 'Validate'; description = 'Check all pre-conditions before proceeding'; canFail = $true; rollback = $false },
      [PSCustomObject]@{ name = 'executeCoreOperation'; label = 'Execute'; description = 'Core domain operation'; canFail = $false; rollback = $true },
      [PSCustomObject]@{ name = 'executePostProcessing'; label = 'Finalise'; description = 'Side effects, notifications, ledger entries'; canFail = $true; rollback = $false }
    )
  }

  # Build step execution calls
  $stepCalls = [System.Collections.Generic.List[string]]::new()
  foreach ($step in $steps) {
    $sName = $step.name
    $sLabel = if ($null -ne $step.label) { $step.label }   else { $sName }
    $sDesc = if ($null -ne $step.description) { $step.description } else { $sName }
    $canFail = if ($null -ne $step.canFail) { $step.canFail }  else { $true }
    $rollback = if ($null -ne $step.rollback) { $step.rollback } else { $false }

    $failureType = if ($canFail) { 'WorkflowStepFailure' } else { 'GenericFailure' }

    $stepCalls.Add(@"
    // ── Step: $sLabel ─────────────────────────────────────────
    // $sDesc
    final ${sName}Error = await _${sName}(entityId);
    if (${sName}Error != null) {
      return Left(${failureType}('[$sLabel] `$${sName}Error'));
    }
"@)
  }

  # Build step method stubs
  $stepMethods = [System.Collections.Generic.List[string]]::new()
  foreach ($step in $steps) {
    $sName = $step.name
    $sDesc = if ($null -ne $step.description) { $step.description } else { $sName }
    $canFail = if ($null -ne $step.canFail) { $step.canFail } else { $true }
    $rollback = if ($null -ne $step.rollback) { $step.rollback } else { $false }

    $rollbackNote = if ($rollback) {
      "`n  /// NOTE: This step supports rollback. Implement _rollback${sName} if a later step fails."
    }
    else { '' }

    $stepMethods.Add(@"
  /// $sDesc
  /// Return null to continue. Return an error message string to halt the workflow.
  // TODO: Implement this step with your actual domain logic.
  //       This is a HUMAN CUSTOMIZATION ZONE — implement your domain logic here.$rollbackNote
  Future<String?> _${sName}(String entityId) async {
    // Example:
    // final entity = await _repository.getById(entityId);
    // if (entity.isLeft()) return 'Could not load entity';
    // final e = entity.getOrElse(() => throw Exception());
    // if (e.someField == null) return 'Cannot proceed without someField';
    return null; // null = step passed, workflow continues
  }
"@)

    if ($rollback) {
      $stepMethods.Add(@"
  /// Rollback for: $sDesc
  /// Called if a later step fails. Undo what _${sName} did.
  // TODO: Implement rollback logic
  Future<void> _rollback${sName}(String entityId) async {
    // TODO: undo the effect of _${sName}
  }
"@)
    }
  }

  # Completion event emit
  $completionEvent = if ($config.workflow -and $config.workflow.events -and $config.workflow.events.Count -gt 0) {
    $firstEvt = $config.workflow.events[0].name
    @"
    _onEvent?.call($firstEvt(
      entityId:   entityId,
      occurredAt: DateTime.now(),
    ));
"@
  }
  else {
    @"
    _onEvent?.call(${fclass}WorkflowCompletedEvent(
      entityId:   entityId,
      occurredAt: DateTime.now(),
    ));
"@
  }

  $workflowContent = @"
// ${fname}_workflow.dart
// Level 3 — Ordered step executor with domain event emission.
//
// Responsibilities:
//   - Execute steps in declared order
//   - Halt at first failure with a clear error message
//   - Emit domain events on completion for other features to react
//   - Support rollback on steps that declare rollback: true
//
// What belongs here:
//   - Orchestration: calling multiple repositories in sequence
//   - Side effects: sending notifications, writing audit logs, updating ledgers
//   - Coordination: ensuring multiple domain changes happen atomically
//
// What does NOT belong here:
//   - Single-entity validation (that belongs in use cases)
//   - State machine transitions (that belongs in ${fclass}DomainService)
//   - HTTP calls (that belongs in the remote datasource)
//
// HUMAN CUSTOMIZATION ZONE: implement the _step() methods below.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../events/${fname}_domain_events.dart';
import '../repositories/${fname}_repository.dart';

typedef WorkflowEventCallback = void Function(${fclass}DomainEvent event);

class ${fclass}Workflow {
  final ${fclass}Repository    _repository;
  WorkflowEventCallback?       _onEvent;

  ${fclass}Workflow({required ${fclass}Repository repository})
      : _repository = repository;

  /// Register a listener to receive domain events after successful execution.
  /// Inject this in the BLoC or use case that triggers the workflow.
  void setEventCallback(WorkflowEventCallback callback) {
    _onEvent = callback;
  }

  // ═══════════════════════════════════════════════════════════════
  //  ENTRY POINT
  // ═══════════════════════════════════════════════════════════════

  /// Execute the full workflow for [entityId].
  /// Steps run in order. First failure halts all subsequent steps.
  Future<Either<Failure, void>> execute(String entityId) async {

$($stepCalls -join "`n")
    // ── Emit completion event ─────────────────────────────────
$completionEvent
    return const Right(null);
  }

  // ═══════════════════════════════════════════════════════════════
  //  STEP IMPLEMENTATIONS — HUMAN CUSTOMIZATION ZONE
  // ═══════════════════════════════════════════════════════════════

$($stepMethods -join "`n")
}

// ── Workflow-specific failures ────────────────────────────────────
/// A named step failed. Message includes the step label.
class WorkflowStepFailure extends Failure {
  const WorkflowStepFailure(super.message);
}
"@

  & $NewFile (Join-Path $fDir "domain\workflows\${fname}_workflow.dart") $workflowContent
}

# ── Helper ────────────────────────────────────────────────────
function ConvertTo-SnakeCase([string]$PascalCase) {
  return ($PascalCase -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
}

Export-ModuleMember -Function Invoke-GenerateWorkflow
