# ============================================================
# Level3StateMachineGenerator.psm1
# Generates: domain/value_objects, domain/guards, domain/services
#
# PS→Dart SAFETY RULES applied:
#   1. Dart ${expr} interpolation → string concat (PS eats ${} as variable)
#   2. Dart Set literal {a, b} → string concat (PS sees {} as scriptblock)
#   3. Dart $variable? → N/A here, but see PageGenerator
# ============================================================

function Invoke-GenerateStateMachine {
  param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir
  $sm = $Ctx.Config.stateMachine
  $meta = Get-PrimaryEntityMeta -Config $Ctx.Config
  $eSnake = $meta.Snake

  _Gen-StatusEnum      -Ctx $Ctx -NewFile $NewFile -SM $sm
  _Gen-TransitionGuard -Ctx $Ctx -NewFile $NewFile -SM $sm
  _Gen-DomainService   -Ctx $Ctx -NewFile $NewFile -SM $sm -ESnake $eSnake
}

function _Gen-StatusEnum {
  param($Ctx, $NewFile, $SM)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir

  $states = $SM.states
  $initial = $SM.initial
  $transitions = $SM.transitions

  # Enum values
  $enumValues = ($states | ForEach-Object { "  $_," }) -join "`n"

  # ── FIX Bug 2: canTransitionTo map ──
  # PS sees {$targetCsv} as a scriptblock → use string concat for Dart Set literal
  $transMap = [System.Collections.Generic.List[string]]::new()
  foreach ($s in $states) {
    $targets = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $transitions) {
      if ($s -in $t.from) { $targets.Add("${fclass}Status.$($t.to)") }
    }
    $targetCsv = $targets -join ', '
    # String concat keeps PS from parsing the Dart Set braces
    $line = "      ${fclass}Status.${s}: " + "{" + $targetCsv + "},"
    $transMap.Add($line)
  }

  # displayName switch
  $displayCases = ($states | ForEach-Object {
      $label = ConvertTo-HumanLabel $_
      "      ${fclass}Status.${_}  => '$label',"
    }) -join "`n"

  # color switch
  $colorPalette = @('Colors.grey', 'Colors.blue', 'Colors.orange', 'Colors.green', 'Colors.red', 'Colors.purple', 'Colors.teal', 'Colors.amber')
  $colorCases = [System.Collections.Generic.List[string]]::new()
  for ($i = 0; $i -lt $states.Count; $i++) {
    $color = $colorPalette[$i % $colorPalette.Count]
    $colorCases.Add("      ${fclass}Status.$($states[$i]) => $color,")
  }

  # ── Dart ?. on _transitions[this] needs protection too ──
  # Build the canTransitionTo line via concat
  $canTransLine = '      _transitions[this]' + '?.contains(target) ?? false;'

  $content = @"
import 'package:flutter/material.dart';

enum ${fclass}Status {
$enumValues
}

extension ${fclass}StatusX on ${fclass}Status {
  static const Map<${fclass}Status, Set<${fclass}Status>> _transitions = {
$($transMap -join "`n")
  };

  static const ${fclass}Status initial = ${fclass}Status.${initial};

  bool canTransitionTo(${fclass}Status target) =>
$canTransLine

  String get displayName => switch (this) {
$displayCases
  };

  Color get color => switch (this) {
$($colorCases -join "`n")
  };
}
"@
  & $NewFile (Join-Path $fDir "domain\value_objects\${fname}_status.dart") $content
}

function _Gen-TransitionGuard {
  param($Ctx, $NewFile, $SM)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir

  # ── FIX Bug 1: Dart ${current.displayName} interpolation ──
  # PS here-strings interpret ${current} as a PS variable (empty).
  # Build the error-message line entirely via string concat.
  $errMsg = "        'Cannot transition from " + '${current.displayName}' + " to " + '${target.displayName}' + "',"

  $content = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../value_objects/${fname}_status.dart';

class ${fclass}TransitionGuard {
  /// Validates that the transition from [current] to [target] is allowed.
  /// Returns Right(target) if valid, Left(Failure) if not.
  Either<Failure, ${fclass}Status> validate({
    required ${fclass}Status current,
    required ${fclass}Status target,
  }) {
    if (!current.canTransitionTo(target)) {
      return Left(ValidationFailure(
$errMsg
      ));
    }

    // ── HUMAN CUSTOMIZATION ZONE ──────────────────────────
    // Add business rule checks here, e.g.:
    //   if (target == ${fclass}Status.approved && !hasManagerRole) {
    //     return Left(ValidationFailure('Manager approval required'));
    //   }
    // ── END CUSTOMIZATION ZONE ────────────────────────────

    return Right(target);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\guards\${fname}_transition_guard.dart") $content
}

function _Gen-DomainService {
  param($Ctx, $NewFile, $SM, $ESnake)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir
  $meta = Get-PrimaryEntityMeta -Config $Ctx.Config
  $eName = $meta.Name

  $content = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${ESnake}_entity.dart';
import '../guards/${fname}_transition_guard.dart';
import '../repositories/${fname}_repository.dart';
import '../value_objects/${fname}_status.dart';

class ${fclass}DomainService {
  final ${fclass}Repository repository;
  final ${fclass}TransitionGuard guard;

  ${fclass}DomainService({
    required this.repository,
    required this.guard,
  });

  /// Performs a status transition: load, guard, apply, persist.
  Future<Either<Failure, ${eName}Entity>> transition({
    required String id,
    required ${fclass}Status targetStatus,
  }) async {
    // 1. Load
    final loadResult = await repository.getById(id);
    if (loadResult.isLeft()) return loadResult;
    final entity = loadResult.getOrElse(() => throw StateError('unreachable'));

    // 2. Guard
    final guardResult = guard.validate(
      current: entity.status,
      target:  targetStatus,
    );
    if (guardResult.isLeft()) {
      return guardResult.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }
    final validTarget = guardResult.getOrElse(() => throw StateError('unreachable'));

    // 3. Apply + Persist
    final updated = entity.copyWith(status: validTarget);
    return repository.update(updated);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\services\${fname}_domain_service.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateStateMachine'