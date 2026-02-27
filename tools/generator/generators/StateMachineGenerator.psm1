# ============================================================
# StateMachineGenerator.psm1
# Generates Level 2 additions:
#   domain/value_objects/{feature}_status.dart
#   domain/guards/{feature}_transition_guard.dart
#   domain/services/{feature}_domain_service.dart
#   presentation/widgets/{feature}_status_badge.dart
#   presentation/widgets/{feature}_transition_button.dart
# ============================================================

function Invoke-GenerateStateMachine {
  param([hashtable]$Ctx, [scriptblock]$NewFile)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $sm = $config.stateMachine

  $primaryEntityName = $config.entities.PSObject.Properties |
  Where-Object { $_.Value.primary -eq $true } |
  Select-Object -First 1 -ExpandProperty Name
  $primarySnake = ConvertTo-SnakeCase $primaryEntityName

  # ── Status enum ───────────────────────────────────────────
  $stateNames = @($sm.states | ForEach-Object { $_.name })

  # Generate canTransitionTo map
  $allowedMap = [System.Collections.Generic.List[string]]::new()
  foreach ($state in $sm.states) {
    $outgoing = @($sm.transitions |
      Where-Object { $_.from -contains $state.name } |
      ForEach-Object { "${fclass}Status.$($_.to)" })

    $listVal = if ($outgoing.Count -gt 0) { "[" + ($outgoing -join ', ') + "]" } else { "[]" }
    $allowedMap.Add("      ${fclass}Status.$($state.name): $listVal,")
  }

  # Generate displayName switch
  $displayMap = ($sm.states | ForEach-Object {
      $label = if ($_.label) { $_.label } else { $_.name }
      "      ${fclass}Status.$($_.name) => '$label',"
    }) -join "`n"

  # Generate color switch
  $colorMap = ($sm.states | ForEach-Object {
      $color = switch ($_.color) {
        'grey' { 'Colors.grey' }
        'blue' { 'Colors.blue' }
        'green' { 'Colors.green' }
        'red' { 'Colors.red' }
        'orange' { 'Colors.orange' }
        'purple' { 'Colors.purple' }
        default { 'Colors.grey' }
      }
      "      ${fclass}Status.$($_.name) => $color,"
    }) -join "`n"

  # Enum values
  $enumValues = ($sm.states | ForEach-Object { "  $($_.name)," }) -join "`n"

  $statusContent = @"
// ${fname}_status.dart
// Level 2 — Generated from stateMachine.states in feature.config.json.
// Regenerate by running the generator with a new config. Do NOT edit manually.

import 'package:flutter/material.dart';

enum ${fclass}Status {
$enumValues

  bool canTransitionTo(${fclass}Status next) {
    const allowed = <${fclass}Status, List<${fclass}Status>>{
$($allowedMap -join "`n")
    };
    return allowed[this]?.contains(next) ?? false;
  }

  List<${fclass}Status> get allowedTransitions {
    const allowed = <${fclass}Status, List<${fclass}Status>>{
$($allowedMap -join "`n")
    };
    return allowed[this] ?? const [];
  }

  String get displayName => switch (this) {
$displayMap
  };

  Color get color => switch (this) {
$colorMap
  };

  Color get onColor => Colors.white;

  bool get isTerminal => allowedTransitions.isEmpty;
}
"@
  & $NewFile (Join-Path $fDir "domain\value_objects\${fname}_status.dart") $statusContent

  # ── Transition guard ──────────────────────────────────────
  $guardContent = @"
// ${fname}_transition_guard.dart
// Level 2 — HUMAN CUSTOMIZATION ZONE.
// This file is generated ONCE and never overwritten.
// Implement your domain invariants here.
//
// Contract:
//   - Return null  → transition is ALLOWED
//   - Return string → transition is BLOCKED (message shown to user)
//
// Examples of what belongs here:
//   - "Cannot complete a project with unresolved milestones"
//   - "Cannot activate without at least one team member"
//   - "Cannot cancel after completion"

import '../entities/${primarySnake}_entity.dart';
import '../value_objects/${fname}_status.dart';

class ${fclass}TransitionGuard {
  const ${fclass}TransitionGuard();

  /// Validates whether the given entity can transition to [targetStatus].
  /// Returns null if allowed. Returns an error message if blocked.
  String? canTransition({
    required ${primaryEntityName}Entity entity,
    required ${fclass}Status            targetStatus,
  }) {
    // ── Structural check (always runs) ────────────────────────
    if (!entity.status.canTransitionTo(targetStatus)) {
      return 'Cannot transition from `${entity.status.displayName}` '
             'to `${targetStatus.displayName}`';
    }

    // ── Domain invariants ─────────────────────────────────────
    // TODO: Implement your business rules below.
    //
    // Template:
    // if (targetStatus == ${fclass}Status.someState) {
    //   if (someConditionNotMet) {
    //     return 'Human-readable explanation of why this is blocked';
    //   }
    // }

    return null; // null = transition allowed
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\guards\${fname}_transition_guard.dart") $guardContent

  # ── Domain service ────────────────────────────────────────
  $serviceContent = @"
// ${fname}_domain_service.dart
// Level 2 — Transition executor.
// Loads entity → runs guard → applies transition → persists.
// Usecases delegate here. Usecases never duplicate this logic.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${primarySnake}_entity.dart';
import '../value_objects/${fname}_status.dart';
import '../guards/${fname}_transition_guard.dart';
import '../repositories/${fname}_repository.dart';

class ${fclass}DomainService {
  final ${fclass}Repository      _repository;
  final ${fclass}TransitionGuard _guard;

  const ${fclass}DomainService({
    required ${fclass}Repository      repository,
    required ${fclass}TransitionGuard guard,
  })  : _repository = repository,
        _guard      = guard;

  /// Execute a transition. Full contract:
  /// 1. Load current entity
  /// 2. Run structural + domain guard
  /// 3. Apply transition (update status + updatedAt)
  /// 4. Persist via repository
  Future<Either<Failure, ${primaryEntityName}Entity>> transition({
    required String          id,
    required ${fclass}Status targetStatus,
  }) async {
    // ── Step 1: Load ─────────────────────────────────────────
    final loadResult = await _repository.getById(id);
    if (loadResult.isLeft()) return loadResult;

    final entity = loadResult.getOrElse(() => throw Exception('unreachable'));

    // ── Step 2: Guard ─────────────────────────────────────────
    final guardMessage = _guard.canTransition(
      entity:       entity,
      targetStatus: targetStatus,
    );
    if (guardMessage != null) {
      return Left(ValidationFailure(guardMessage));
    }

    // ── Step 3: Apply ─────────────────────────────────────────
    final updated = entity.copyWith(
      status:    targetStatus,
      updatedAt: DateTime.now(),
    );

    // ── Step 4: Persist ───────────────────────────────────────
    return _repository.update(updated);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\services\${fname}_domain_service.dart") $serviceContent

  # ── Status badge widget ───────────────────────────────────
  $badgeContent = @"
// ${fname}_status_badge.dart
// Renders a colored chip for the current entity status.
// Color and label are driven by ${fclass}Status.color and .displayName.

import 'package:flutter/material.dart';
import '../../domain/value_objects/${fname}_status.dart';

class ${fclass}StatusBadge extends StatelessWidget {
  final ${fclass}Status status;
  final bool            compact;

  const ${fclass}StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical:   compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color:        status.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: status.color.withOpacity(0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color:      status.color,
          fontSize:   compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_status_badge.dart") $badgeContent
}

Export-ModuleMember -Function Invoke-GenerateStateMachine
