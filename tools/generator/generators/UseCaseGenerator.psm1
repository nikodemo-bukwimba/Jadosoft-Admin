# ============================================================
# UseCaseGenerator.psm1
# Generates: domain/usecases/
#
#   get_all_{feature}_usecase.dart
#   get_{feature}_usecase.dart
#   create_{feature}_usecase.dart
#   update_{feature}_usecase.dart
#   delete_{feature}_usecase.dart
#   search_{feature}_usecase.dart         (if api.searchable: true)
#   {transition}_{feature}_usecase.dart   (one per stateMachine.transitions, Level 2+)
# ============================================================

function Invoke-GenerateUseCases {
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
  $primaryEntity = $config.entities.$primaryEntityName
  $primarySnake = ConvertTo-SnakeCase $primaryEntityName

  # ── GetAll ────────────────────────────────────────────────
  $getAllContent = @"
// get_all_${fname}_usecase.dart
// Fetches a list of records with optional filtering, sorting, pagination.
// Add domain-level list validation here if needed (e.g. date range guards).

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${primarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class GetAll${fclass}UseCase
    implements UseCase<List<${primaryEntityName}Entity>, ${fclass}QueryParams> {

  final ${fclass}Repository repository;
  GetAll${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, List<${primaryEntityName}Entity>>> call(
      ${fclass}QueryParams params) =>
      repository.getAll(params);
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\get_all_${fname}_usecase.dart") $getAllContent

  # ── GetById ───────────────────────────────────────────────
  $getContent = @"
// get_${fname}_usecase.dart
// Fetches a single record by ID.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${primarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Get${fclass}Params {
  final String id;
  const Get${fclass}Params({required this.id});
}

class Get${fclass}UseCase
    implements UseCase<${primaryEntityName}Entity, Get${fclass}Params> {

  final ${fclass}Repository repository;
  Get${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> call(
      Get${fclass}Params params) {
    if (params.id.isEmpty) {
      return Future.value(const Left(ValidationFailure('ID is required')));
    }
    return repository.getById(params.id);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\get_${fname}_usecase.dart") $getContent

  # ── Create ────────────────────────────────────────────────
  # Build params from writable fields only
  $writableFields = @($primaryEntity.fields.PSObject.Properties |
    Where-Object { $_.Value.readonly -ne $true -and $_.Value.primary -ne $true })

  $paramFieldDecls = ($writableFields | ForEach-Object {
      $f = $_.Value
      $dartType = Get-DartType -ConfigType $f.type -Nullable ($f.nullable -eq $true)
      $req = if ($f.nullable -eq $true) { '' } else { 'required ' }
      "  final $dartType $($_.Name);"
    }) -join "`n"

  $paramCtorArgs = ($writableFields | ForEach-Object {
      $f = $_.Value
      $req = if ($f.nullable -eq $true) { '' } else { 'required ' }
      "    ${req}this.$($_.Name),"
    }) -join "`n"

  $validationGate = Get-ValidationGate -Fields $primaryEntity.fields -ParamsVar 'params'

  $entityConstruction = ($primaryEntity.fields.PSObject.Properties | ForEach-Object {
      $fName = $_.Name
      $f = $_.Value
      if ($f.primary -eq $true) {
        "      ${fName}: '',"                         # server assigns
      }
      elseif ($f.readonly -eq $true -and $f.type -like '*DateTime*') {
        "      ${fName}: DateTime.now(),"
      }
      elseif ($f.readonly -eq $true) {
        "      ${fName}: '',"
      }
      else {
        "      ${fName}: params.$fName,"
      }
    }) -join "`n"

  $createContent = @"
// create_${fname}_usecase.dart
//
// The validation gate — ALL domain validation runs here.
// Never bypass this use case to call the repository directly.
//
// HUMAN CUSTOMIZATION ZONE:
//   Replace the generated validation with your actual domain rules.
//   Add cross-field validation here (e.g. endDate must be after startDate).
//   Domain invariants that span multiple fields belong here, not in the guard.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${primarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Create${fclass}Params {
$paramFieldDecls

  const Create${fclass}Params({
$paramCtorArgs  });
}

class Create${fclass}UseCase
    implements UseCase<${primaryEntityName}Entity, Create${fclass}Params> {

  final ${fclass}Repository repository;
  Create${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> call(
      Create${fclass}Params params) async {

    // ════════════════════════════════════════
    //  VALIDATION GATE — generated from config
    //  TODO: Replace with your domain rules
    // ════════════════════════════════════════
$validationGate

    // ── Build and persist ────────────────────────────────────
    return repository.create(
      ${primaryEntityName}Entity(
$entityConstruction      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\create_${fname}_usecase.dart") $createContent

  # ── Update ────────────────────────────────────────────────
  $updateContent = @"
// update_${fname}_usecase.dart
// Validates the entity before updating.
// TODO: Add update-specific validation rules (e.g. cannot rename if published).

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${primarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Update${fclass}Params {
  final ${primaryEntityName}Entity entity;
  const Update${fclass}Params({required this.entity});
}

class Update${fclass}UseCase
    implements UseCase<${primaryEntityName}Entity, Update${fclass}Params> {

  final ${fclass}Repository repository;
  Update${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> call(
      Update${fclass}Params params) async {

    if (params.entity.id.isEmpty) {
      return const Left(ValidationFailure('Cannot update: entity ID is missing'));
    }

    // TODO: Add domain-specific update validation here

    return repository.update(params.entity);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\update_${fname}_usecase.dart") $updateContent

  # ── Delete ────────────────────────────────────────────────
  # Check for cascade relationships
  $cascadeRels = @($primaryEntity.relationships.PSObject.Properties |
    Where-Object { $_.Value.type -eq 'hasMany' -and $_.Value.cascade -eq $true })

  $cascadeNote = if ($cascadeRels.Count -gt 0) {
    "// Cascade deletes: $($cascadeRels | ForEach-Object { $_.Name } | Join-String -Separator ', ')"
  }
  else { '' }

  $deleteContent = @"
// delete_${fname}_usecase.dart
$cascadeNote
// TODO: Add pre-delete validation (e.g. cannot delete an active record).

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/${fname}_repository.dart';

class Delete${fclass}Params {
  final String id;
  const Delete${fclass}Params({required this.id});
}

class Delete${fclass}UseCase
    implements UseCase<void, Delete${fclass}Params> {

  final ${fclass}Repository repository;
  Delete${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Delete${fclass}Params params) async {
    if (params.id.isEmpty) {
      return const Left(ValidationFailure('Cannot delete: ID is required'));
    }

    // TODO: Add pre-delete domain checks here
    // Example: cannot delete if entity is in 'active' status

    return repository.delete(params.id);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\delete_${fname}_usecase.dart") $deleteContent

  # ── Search (optional) ─────────────────────────────────────
  if ($primaryEntity.api -and $primaryEntity.api.searchable -eq $true) {
    $searchContent = @"
// search_${fname}_usecase.dart
// Server-side search. Only generated when api.searchable: true.
// TODO: Add minimum query length validation if needed.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${primarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Search${fclass}UseCase
    implements UseCase<List<${primaryEntityName}Entity>, ${fclass}SearchParams> {

  final ${fclass}Repository repository;
  Search${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, List<${primaryEntityName}Entity>>> call(
      ${fclass}SearchParams params) async {

    if (params.query.trim().length < 2) {
      return const Left(ValidationFailure('Search query must be at least 2 characters'));
    }

    return repository.search(params);
  }
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\search_${fname}_usecase.dart") $searchContent
  }

  # ── Transition use cases (Level 2+) ───────────────────────
  if ($config.stateMachine -and $maturity -ge 2) {
    foreach ($t in $config.stateMachine.transitions) {
      $tName = $t.name
      $tPascal = $tName.Substring(0, 1).ToUpper() + $tName.Substring(1)
      $tSnake = ConvertTo-SnakeCase $tName
      $perm = if ($t.permission -eq $null) { '' } else { $t.permission }
      $fromStr = $t.from -join ', '
      $toStr = $t.to

      $permComment = if ($perm) {
        "// Required permission: $perm (enforced in UI via PermissionGuard — not here)"
      }
      else { '' }

      $transitionContent = @"
// ${tSnake}_${fname}_usecase.dart
// Transition: $fromStr → $toStr
//
// This use case delegates entirely to ${fclass}DomainService.transition().
// The domain service loads the entity, runs the transition guard,
// applies the status change, and persists via the repository.
//
// HUMAN CUSTOMIZATION:
//   Put domain invariants in: domain/guards/${fname}_transition_guard.dart
//   Not here. Not in the BLoC. In the guard.
$permComment

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${primarySnake}_entity.dart';
import '../services/${fname}_domain_service.dart';
import '../value_objects/${fname}_status.dart';

class ${tPascal}${fclass}Params {
  final String id;
  const ${tPascal}${fclass}Params({required this.id});
}

class ${tPascal}${fclass}UseCase
    implements UseCase<${primaryEntityName}Entity, ${tPascal}${fclass}Params> {

  final ${fclass}DomainService domainService;
  ${tPascal}${fclass}UseCase(this.domainService);

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> call(
      ${tPascal}${fclass}Params params) {

    if (params.id.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Cannot transition: entity ID is missing')),
      );
    }

    return domainService.transition(
      id:           params.id,
      targetStatus: ${fclass}Status.$toStr,
    );
  }
}
"@
      & $NewFile (Join-Path $fDir "domain\usecases\${tSnake}_${fname}_usecase.dart") $transitionContent
    }
  }
}

function ConvertTo-SnakeCase([string]$PascalCase) {
  return ($PascalCase -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
}

Export-ModuleMember -Function Invoke-GenerateUseCases
