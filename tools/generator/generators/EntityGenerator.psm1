# ============================================================
# EntityGenerator.psm1 + RepositoryGenerator.psm1
# Generates: domain/entities/, domain/repositories/
# ============================================================

function Invoke-GenerateDomain {
  param(
    [hashtable]$Ctx,
    [scriptblock]$NewFile
  )

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $maturity = $Ctx.Maturity

  foreach ($eName in $config.entities.PSObject.Properties.Name) {
    $entity = $config.entities.$eName
    $eSnake = ConvertTo-SnakeCase $eName   # ProjectMember → project_member
    $isPrimary = $entity.primary -eq $true

    # ── Entity file ───────────────────────────────────────
    $fieldDecls = Get-EntityFields       -Fields $entity.fields
    $ctorParams = Get-ConstructorParams  -Fields $entity.fields
    $copyWithParams = Get-CopyWithParams     -Fields $entity.fields
    $copyWithBody = Get-CopyWithBody       -Fields $entity.fields -ClassName $eName

    # Relationship fields on entity
    $relImports = ''
    $relFields = ''
    if ($entity.relationships) {
      $relLines = [System.Collections.Generic.List[string]]::new()
      $importLines = [System.Collections.Generic.List[string]]::new()

      foreach ($rName in $entity.relationships.PSObject.Properties.Name) {
        $rel = $entity.relationships.$rName
        if ($rel.type -eq 'hasMany') {
          $childSnake = ConvertTo-SnakeCase $rel.entity
          $importLines.Add("import '${childSnake}_entity.dart';")
          $relLines.Add("  final List<$($rel.entity)Entity> $rName;")
        }
        elseif ($rel.type -eq 'hasOne') {
          $childSnake = ConvertTo-SnakeCase $rel.entity
          $importLines.Add("import '${childSnake}_entity.dart';")
          $relLines.Add("  final $($rel.entity)Entity? $rName;")
        }
        # belongsTo: only store the ID field (already in fields), no entity ref
      }
      $relImports = ($importLines | Select-Object -Unique) -join "`n"
      $relFields = ($relLines -join "`n")
    }

    # Relationship constructor params
    $relCtorParams = ''
    if ($entity.relationships) {
      $lines = [System.Collections.Generic.List[string]]::new()
      foreach ($rName in $entity.relationships.PSObject.Properties.Name) {
        $rel = $entity.relationships.$rName
        if ($rel.type -eq 'hasMany') {
          $lines.Add("    this.$rName = const [],")
        }
        elseif ($rel.type -eq 'hasOne') {
          $lines.Add("    this.$rName,")
        }
      }
      $relCtorParams = $lines -join "`n"
    }

    $entityContent = @"
// ${eSnake}_entity.dart
// Level $maturity — Pure Dart domain entity.
// Zero Flutter imports. Zero network imports.
// Replace placeholder fields with your actual domain fields.
$(if ($relImports) { "`n$relImports" })
class ${eName}Entity {
$fieldDecls
$(if ($relFields) { "$relFields`n" })
  const ${eName}Entity({
$ctorParams
$relCtorParams  });

  ${eName}Entity copyWith({
$copyWithParams  }) {
    return ${eName}Entity(
$copyWithBody    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${eName}Entity && runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '${eName}Entity(id: `$id)';
}
"@

    & $NewFile (Join-Path $fDir "domain\entities\${eSnake}_entity.dart") $entityContent
  }

  # ── Repository interface (primary entity only) ────────────
  $primaryEntityName = $config.entities.PSObject.Properties |
  Where-Object { $_.Value.primary -eq $true } |
  Select-Object -First 1 -ExpandProperty Name

  $primarySnake = ConvertTo-SnakeCase $primaryEntityName

  # Build transition methods for the interface if stateMachine
  $transitionMethods = ''
  if ($config.stateMachine -and $maturity -ge 2) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $config.stateMachine.transitions) {
      $tName = $t.name
      $lines.Add("  Future<Either<Failure, ${primaryEntityName}Entity>> $tName(String id);")
    }
    $transitionMethods = "`n  // State machine transitions`n" + ($lines -join "`n")
  }

  $repoContent = @"
// ${fname}_repository.dart
// Level $maturity — Abstract repository interface.
// Domain depends on this contract. Never on the implementation.
// Add domain-specific methods below the generated CRUD surface.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${primarySnake}_entity.dart';

abstract class ${fclass}Repository {
  // ── CRUD ───────────────────────────────────────────────────
  Future<Either<Failure, List<${primaryEntityName}Entity>>> getAll({
    ${fclass}FilterParams?  filters,
    ${fclass}SortParams?    sort,
    ${fclass}PaginationParams? pagination,
  });

  Future<Either<Failure, ${primaryEntityName}Entity>> getById(String id);

  Future<Either<Failure, ${primaryEntityName}Entity>> create(
      ${primaryEntityName}Entity entity);

  Future<Either<Failure, ${primaryEntityName}Entity>> update(
      ${primaryEntityName}Entity entity);

  Future<Either<Failure, void>> delete(String id);
$transitionMethods
  // TODO: Add domain-specific repository methods here
}

// ── Query parameter objects ───────────────────────────────────
class ${fclass}FilterParams {
  // TODO: Add filterable fields from config
  const ${fclass}FilterParams();
}

class ${fclass}SortParams {
  final String  field;
  final bool    descending;
  const ${fclass}SortParams({
    required this.field,
    this.descending = false,
  });
}

class ${fclass}PaginationParams {
  final int page;
  final int perPage;
  const ${fclass}PaginationParams({
    this.page    = 1,
    this.perPage = 20,
  });
}
"@

  & $NewFile (Join-Path $fDir "domain\repositories\${fname}_repository.dart") $repoContent

  # ── Use cases ─────────────────────────────────────────────
  Invoke-GenerateUseCases -Ctx $Ctx -NewFile $NewFile `
    -PrimaryEntityName $primaryEntityName `
    -PrimarySnake $primarySnake
}

function Invoke-GenerateUseCases {
  param(
    [hashtable]$Ctx,
    [scriptblock]$NewFile,
    [string]$PrimaryEntityName,
    [string]$PrimarySnake
  )

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $maturity = $Ctx.Maturity

  $entity = $config.entities.$PrimaryEntityName
  $validationGate = Get-ValidationGate -Fields $entity.fields -ParamsVar 'p'

  # ── GetAll ────────────────────────────────────────────────
  $getAllContent = @"
// get_all_${fname}_usecase.dart
// Fetches all records with optional filters, sort, and pagination.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${PrimarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class GetAll${fclass}UseCase
    implements UseCase<List<${PrimaryEntityName}Entity>, GetAll${fclass}Params> {

  final ${fclass}Repository repository;
  GetAll${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, List<${PrimaryEntityName}Entity>>> call(
      GetAll${fclass}Params p) =>
      repository.getAll(
        filters:    p.filters,
        sort:       p.sort,
        pagination: p.pagination,
      );
}

class GetAll${fclass}Params {
  final ${fclass}FilterParams?     filters;
  final ${fclass}SortParams?       sort;
  final ${fclass}PaginationParams? pagination;

  const GetAll${fclass}Params({
    this.filters,
    this.sort,
    this.pagination,
  });
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\get_all_${fname}_usecase.dart") $getAllContent

  # ── GetById ───────────────────────────────────────────────
  $getContent = @"
// get_${fname}_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${PrimarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Get${fclass}UseCase
    implements UseCase<${PrimaryEntityName}Entity, Get${fclass}Params> {

  final ${fclass}Repository repository;
  Get${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${PrimaryEntityName}Entity>> call(
      Get${fclass}Params p) =>
      repository.getById(p.id);
}

class Get${fclass}Params {
  final String id;
  const Get${fclass}Params({required this.id});
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\get_${fname}_usecase.dart") $getContent

  # ── Create ────────────────────────────────────────────────
  # Build params class from non-readonly fields
  $writableFields = $entity.fields.PSObject.Properties |
  Where-Object { $_.Value.readonly -ne $true }

  $paramFields = ($writableFields | ForEach-Object {
      $f = $_.Value
      $dartType = Get-DartType -ConfigType $f.type -Nullable ($f.nullable -eq $true)
      $req = if ($f.nullable -eq $true) { '' } else { 'required ' }
      "  final $dartType $($_.Name);"
    }) -join "`n"

  $paramCtor = ($writableFields | ForEach-Object {
      $f = $_.Value
      $req = if ($f.nullable -eq $true) { '' } else { 'required ' }
      "    ${req}this.$($_.Name),"
    }) -join "`n"

  $entityBuild = ($entity.fields.PSObject.Properties | ForEach-Object {
      $fName = $_.Name
      $f = $_.Value
      if ($f.primary -eq $true) {
        "      ${fName}: '',"  # Server assigns
      }
      elseif ($f.readonly -eq $true -and $f.type -like '*DateTime*') {
        "      ${fName}: DateTime.now(),"
      }
      elseif ($f.readonly -eq $true) {
        "      ${fName}: '',"
      }
      else {
        "      ${fName}: p.${fName},"
      }
    }) -join "`n"

  $createContent = @"
// create_${fname}_usecase.dart
// Security gate: ALL validation runs here before touching the repository.
// Never bypass this use case to call the repository directly.
// TODO: Replace placeholder validation with your actual domain rules.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${PrimarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Create${fclass}Params {
$paramFields

  const Create${fclass}Params({
$paramCtor  });
}

class Create${fclass}UseCase
    implements UseCase<${PrimaryEntityName}Entity, Create${fclass}Params> {

  final ${fclass}Repository repository;
  Create${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${PrimaryEntityName}Entity>> call(
      Create${fclass}Params p) async {

    // ── Validation gate ──────────────────────────────────────
$validationGate

    // ── Build entity ─────────────────────────────────────────
    return repository.create(
      ${PrimaryEntityName}Entity(
$entityBuild      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\create_${fname}_usecase.dart") $createContent

  # ── Update ────────────────────────────────────────────────
  $updateContent = @"
// update_${fname}_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${PrimarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Update${fclass}Params {
  final ${PrimaryEntityName}Entity entity;
  const Update${fclass}Params({required this.entity});
}

class Update${fclass}UseCase
    implements UseCase<${PrimaryEntityName}Entity, Update${fclass}Params> {

  final ${fclass}Repository repository;
  Update${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${PrimaryEntityName}Entity>> call(
      Update${fclass}Params p) async {

    // ── Validation gate ──────────────────────────────────────
    // TODO: Add update-specific validation rules
    if (p.entity.id.isEmpty) {
      return const Left(ValidationFailure('Cannot update entity without an id'));
    }

    return repository.update(p.entity);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\update_${fname}_usecase.dart") $updateContent

  # ── Delete ────────────────────────────────────────────────
  $deleteContent = @"
// delete_${fname}_usecase.dart
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
  Future<Either<Failure, void>> call(Delete${fclass}Params p) async {
    if (p.id.isEmpty) {
      return const Left(ValidationFailure('id is required for deletion'));
    }
    return repository.delete(p.id);
  }
}
"@
  & $NewFile (Join-Path $fDir "domain\usecases\delete_${fname}_usecase.dart") $deleteContent

  # ── Transition use cases (Level 2+) ───────────────────────
  if ($config.stateMachine -and $maturity -ge 2) {
    $smEntity = $config.stateMachine.entity
    $smSnake = ConvertTo-SnakeCase $smEntity

    foreach ($t in $config.stateMachine.transitions) {
      $tCamel = $t.name
      $tPascal = $tCamel.Substring(0, 1).ToUpper() + $tCamel.Substring(1)
      $tSnake = ConvertTo-SnakeCase $tCamel
      $perm = if ($t.permission) { $t.permission } else { '' }
      $permCheck = if ($perm) {
        "    // Permission: $perm (checked in UI via PermissionGuard)"
      }
      else { '' }

      $transitionContent = @"
// ${tSnake}_${fname}_usecase.dart
// Transition: $tCamel
// From: $($t.from -join ', ') → To: $($t.to)
// Guard logic lives in: domain/guards/${fname}_transition_guard.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${PrimarySnake}_entity.dart';
import '../repositories/${fname}_repository.dart';
import '../services/${fname}_domain_service.dart';

class ${tPascal}${fclass}Params {
  final String id;
  const ${tPascal}${fclass}Params({required this.id});
}

class ${tPascal}${fclass}UseCase
    implements UseCase<${PrimaryEntityName}Entity, ${tPascal}${fclass}Params> {

  final ${fclass}DomainService domainService;
  ${tPascal}${fclass}UseCase(this.domainService);

  @override
  Future<Either<Failure, ${PrimaryEntityName}Entity>> call(
      ${tPascal}${fclass}Params p) async {
$permCheck
    return domainService.transition(
      id:           p.id,
      targetStatus: ${fclass}Status.$($t.to),
    );
  }
}
"@
      & $NewFile (Join-Path $fDir "domain\usecases\${tSnake}_${fname}_usecase.dart") $transitionContent
    }
  }
}

# ── Data layer ───────────────────────────────────────────────
function Invoke-GenerateData {
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

  # ── Models ────────────────────────────────────────────────
  foreach ($eName in $config.entities.PSObject.Properties.Name) {
    $entity = $config.entities.$eName
    $eSnake = ConvertTo-SnakeCase $eName

    $fromJsonFields = Get-FromJsonFields -Fields $entity.fields
    $toJsonFields = Get-ToJsonFields   -Fields $entity.fields

    # Nested relationship deserialization
    $relFromJson = ''
    $relToJson = ''
    if ($entity.relationships) {
      $fromLines = [System.Collections.Generic.List[string]]::new()
      $toLines = [System.Collections.Generic.List[string]]::new()

      foreach ($rName in $entity.relationships.PSObject.Properties.Name) {
        $rel = $entity.relationships.$rName
        if ($rel.type -eq 'hasMany') {
          $childSnake = ConvertTo-SnakeCase $rel.entity
          $fromLines.Add("      ${rName}: (json['$rName'] as List<dynamic>?)")
          $fromLines.Add("          ?.map((e) => $($rel.entity)Model.fromJson(e as Map<String, dynamic>))")
          $fromLines.Add("          .toList() ?? const [],")
          $toLines.Add("      '$rName': $rName.map((e) => (e as $($rel.entity)Model).toJson()).toList(),")
        }
      }
      $relFromJson = if ($fromLines.Count -gt 0) { "`n      // Nested relationships`n" + ($fromLines -join "`n") } else { '' }
      $relToJson = if ($toLines.Count -gt 0) { "`n      // Nested relationships`n" + ($toLines -join "`n") } else { '' }
    }

    $modelContent = @"
// ${eSnake}_model.dart
// Extends the domain entity with JSON serialization.
// TODO: Update fromJson/toJson field names to match your actual API response.

import '../../domain/entities/${eSnake}_entity.dart';

class ${eName}Model extends ${eName}Entity {
  const ${eName}Model({
    required super.id,
$(($entity.fields.PSObject.Properties | Where-Object { $_.Name -ne 'id' } | ForEach-Object {
    $f   = $_.Value
    $req = if ($f.nullable -eq $true) { '' } else { 'required ' }
    "    ${req}super.$($_.Name),"
}) -join "`n")
  });

  factory ${eName}Model.fromJson(Map<String, dynamic> json) {
    return ${eName}Model(
$fromJsonFields$relFromJson    );
  }

  Map<String, dynamic> toJson() => {
$toJsonFields$relToJson  };

  factory ${eName}Model.fromEntity(${eName}Entity entity) {
    return ${eName}Model(
$(($entity.fields.PSObject.Properties | ForEach-Object {
    "      $($_.Name): entity.$($_.Name),"
}) -join "`n")    );
  }
}
"@
    & $NewFile (Join-Path $fDir "data\models\${eSnake}_model.dart") $modelContent
  }

  # ── Remote datasource ─────────────────────────────────────
  if ($config.storage.remote -eq $true) {
    $api = $primaryEntity.api
    $endpoint = if ($api.endpoint) { $api.endpoint } else { "/$fname`s" }
    $includes = if ($api?.includes) { ($api.includes -join ',') } else { '' }
    $withParam = if ($includes) { ", queryParameters: {'with': '$includes'}" } else { '' }
    $pagParam = if ($api?.paginatable) {
      ", queryParameters: {...(p.pagination != null ? {'page': p.pagination!.page, 'per_page': p.pagination!.perPage} : {})}"
    }
    else { $withParam }

    $transitionDsOps = ''
    if ($config.stateMachine -and $maturity -ge 2) {
      $lines = [System.Collections.Generic.List[string]]::new()
      foreach ($t in $config.stateMachine.transitions) {
        $tName = $t.name
        $tSnake = ConvertTo-SnakeCase $tName
        $lines.Add("  Future<${primaryEntityName}Model> $tName(String id);")
      }
      $transitionDsOps = "`n  // State machine transitions`n" + ($lines -join "`n")
    }

    $transitionImpls = ''
    if ($config.stateMachine -and $maturity -ge 2) {
      $lines = [System.Collections.Generic.List[string]]::new()
      foreach ($t in $config.stateMachine.transitions) {
        $tName = $t.name
        $tSnake = ConvertTo-SnakeCase $tName
        $lines.Add("")
        $lines.Add("  @override")
        $lines.Add("  Future<${primaryEntityName}Model> $tName(String id) async {")
        $lines.Add("    try {")
        $lines.Add("      final response = await dio.patch('$endpoint/`$id/$tSnake');")
        $lines.Add("      return ${primaryEntityName}Model.fromJson(response.data as Map<String, dynamic>);")
        $lines.Add("    } on DioException catch (e) {")
        $lines.Add("      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);")
        $lines.Add("    }")
        $lines.Add("  }")
      }
      $transitionImpls = $lines -join "`n"
    }

    $remoteDsContent = @"
// ${fname}_remote_datasource.dart
// All HTTP calls go through the shared Dio instance from core/network/.
// TODO: Update endpoint paths to match your actual API routes.

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/${primarySnake}_model.dart';
import '../../domain/repositories/${fname}_repository.dart';

abstract class ${fclass}RemoteDataSource {
  Future<List<${primaryEntityName}Model>> getAll(${fclass}FilterParams params);
  Future<${primaryEntityName}Model>       getById(String id);
  Future<${primaryEntityName}Model>       create(Map<String, dynamic> data);
  Future<${primaryEntityName}Model>       update(String id, Map<String, dynamic> data);
  Future<void>                           delete(String id);
$transitionDsOps}

class ${fclass}RemoteDataSourceImpl implements ${fclass}RemoteDataSource {
  final Dio dio;
  ${fclass}RemoteDataSourceImpl(this.dio);

  @override
  Future<List<${primaryEntityName}Model>> getAll(${fclass}FilterParams params) async {
    try {
      final response = await dio.get('$endpoint'$pagParam);
      final data = response.data as List;
      return data.map((e) =>
          ${primaryEntityName}Model.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<${primaryEntityName}Model> getById(String id) async {
    try {
      final response = await dio.get('$endpoint/`$id'$withParam);
      return ${primaryEntityName}Model.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<${primaryEntityName}Model> create(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('$endpoint', data: data);
      return ${primaryEntityName}Model.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<${primaryEntityName}Model> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('$endpoint/`$id', data: data);
      return ${primaryEntityName}Model.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await dio.delete('$endpoint/`$id');
    } on DioException catch (e) {
      throw ServerException(_extractMessage(e), statusCode: e.response?.statusCode);
    }
  }
$transitionImpls
  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return e.message ?? 'An error occurred. Please try again.';
  }
}
"@
    & $NewFile (Join-Path $fDir "data\datasources\${fname}_remote_datasource.dart") $remoteDsContent
  }

  # ── Local datasource (Drift) ──────────────────────────────
  if ($config.storage.local -eq $true) {
    $table = if ($primaryEntity.table) { $primaryEntity.table } else { "${fname}s" }

    $driftCols = ($entity.fields.PSObject.Properties | ForEach-Object {
        $fName = $_.Name
        $f = $_.Value
        $driftType = switch -Wildcard ($f.type) {
          'int' { 'IntColumn' }
          'double' { 'RealColumn' }
          'bool' { 'BoolColumn' }
          'DateTime' { 'DateTimeColumn' }
          default { 'TextColumn' }
        }
        "  ${driftType} get $fName => $driftType()($(if ($f.nullable -eq $true) { '.nullable()' } else { '' }))();"
      }) -join "`n"

    $localDsContent = @"
// ${fname}_local_datasource.dart
// Drift (SQLite) local storage.
// TODO: Ensure ${fclass}Table is added to AppDatabase in core/database/app_database.dart

import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../models/${primarySnake}_model.dart';

part '${fname}_local_datasource.g.dart';

// ── Drift table definition ─────────────────────────────────
class ${fclass}Table extends Table {
  @override
  String get tableName => '$table';

$driftCols}

// ── Datasource interface + implementation ──────────────────
abstract class ${fclass}LocalDataSource {
  Future<List<${primaryEntityName}Model>> getAll();
  Future<${primaryEntityName}Model?>      getById(String id);
  Future<void>                           upsert(${primaryEntityName}Model model);
  Future<void>                           delete(String id);
  Future<void>                           clear();
}

class ${fclass}LocalDataSourceImpl implements ${fclass}LocalDataSource {
  final AppDatabase db;
  ${fclass}LocalDataSourceImpl(this.db);

  @override
  Future<List<${primaryEntityName}Model>> getAll() async {
    // TODO: Replace with generated Drift query
    final rows = await db.select(db.${fclass}Table).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<${primaryEntityName}Model?> getById(String id) async {
    final row = await (db.select(db.${fclass}Table)
        ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toModel(row) : null;
  }

  @override
  Future<void> upsert(${primaryEntityName}Model model) async {
    await db.into(db.${fclass}Table).insertOnConflictUpdate(
      ${fclass}TableCompanion.insert(
        // TODO: map model fields to Drift companion
        id: model.id,
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await (db.delete(db.${fclass}Table)
        ..where((t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> clear() async {
    await db.delete(db.${fclass}Table).go();
  }

  ${primaryEntityName}Model _toModel(dynamic row) {
    // TODO: Map Drift row to model fields
    return ${primaryEntityName}Model(
      id: row.id,
$(($entity.fields.PSObject.Properties | Where-Object { $_.Name -ne 'id' } | ForEach-Object {
    $f   = $_.Value
    "      $($_.Name): row.$($_.Name),"
}) -join "`n")    );
  }
}
"@
    & $NewFile (Join-Path $fDir "data\datasources\${fname}_local_datasource.dart") $localDsContent
  }

  # ── Repository implementation ─────────────────────────────
  $isRemote = $config.storage.remote -eq $true
  $isLocal = $config.storage.local -eq $true
  $cacheFirst = $isRemote -and $isLocal

  $localDsImport = if ($isLocal) {
    "import '../datasources/${fname}_local_datasource.dart';"
  }
  else { '' }

  $localDsParam = if ($isLocal) { "`n    this.localDataSource," } else { '' }
  $localDsField = if ($isLocal) {
    "`n  final ${fclass}LocalDataSource? localDataSource;"
  }
  else { '' }

  $localCtor = if ($isLocal) {
    "`n    ${fclass}LocalDataSource? localDataSource,"
  }
  else { '' }

  $getAllImpl = if ($cacheFirst) {
    @"

    try {
      // Cache-first: return local if available
      final cached = await localDataSource?.getAll();
      if (cached != null && cached.isNotEmpty) {
        return Right(cached);
      }
      final remote = await remoteDataSource.getAll(p.filters ?? const ${fclass}FilterParams());
      for (final item in remote) { await localDataSource?.upsert(item); }
      return Right(remote);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      // Fallback to local on network error
      final cached = await localDataSource?.getAll();
      if (cached != null) return Right(cached);
      return const Left(NetworkFailure('No internet connection and no cached data'));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
"@
  }
  else {
    @"

    try {
      final result = await remoteDataSource.getAll(p.filters ?? const ${fclass}FilterParams());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
"@
  }

  $transitionImpls2 = ''
  if ($config.stateMachine -and $maturity -ge 2) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $config.stateMachine.transitions) {
      $tName = $t.name
      $lines.Add("")
      $lines.Add("  @override")
      $lines.Add("  Future<Either<Failure, ${primaryEntityName}Entity>> $tName(String id) async {")
      $lines.Add("    try {")
      $lines.Add("      final result = await remoteDataSource.$tName(id);")
      if ($isLocal) {
        $lines.Add("      await localDataSource?.upsert(result);")
      }
      $lines.Add("      return Right(result);")
      $lines.Add("    } on ServerException catch (e) {")
      $lines.Add("      return Left(ServerFailure(e.message));")
      $lines.Add("    } catch (e) {")
      $lines.Add("      return Left(GenericFailure(e.toString()));")
      $lines.Add("    }")
      $lines.Add("  }")
    }
    $transitionImpls2 = $lines -join "`n"
  }

  $repoImplContent = @"
// ${fname}_repository_impl.dart
// Maps datasource exceptions to domain Failures.
// Nothing leaks beyond this boundary — no DioException, no SQLite error.
// Strategy: $(if ($cacheFirst) { 'cache-first (local → remote fallback)' } elseif ($isLocal) { 'local only' } else { 'remote only' })

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/${primarySnake}_entity.dart';
import '../../domain/repositories/${fname}_repository.dart';
$(if ($isRemote) { "import '../datasources/${fname}_remote_datasource.dart';" })
$localDsImport
import '../models/${primarySnake}_model.dart';

class ${fclass}RepositoryImpl implements ${fclass}Repository {
$(if ($isRemote) { "  final ${fclass}RemoteDataSource remoteDataSource;" })
$localDsField

  ${fclass}RepositoryImpl({
$(if ($isRemote) { "    required this.remoteDataSource," })
$localDsParam  });

  @override
  Future<Either<Failure, List<${primaryEntityName}Entity>>> getAll({
    ${fclass}FilterParams?     filters,
    ${fclass}SortParams?       sort,
    ${fclass}PaginationParams? pagination,
  }) async {
    final p = GetAll${fclass}Params(filters: filters, sort: sort, pagination: pagination);
    $getAllImpl  }

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> getById(String id) async {
    try {
$(if ($isLocal) { "      final cached = await localDataSource?.getById(id);" })
$(if ($isLocal) { "      if (cached != null) return Right(cached);" })
$(if ($isRemote) { "      final result = await remoteDataSource.getById(id);" })
$(if ($isLocal -and $isRemote) { "      await localDataSource?.upsert(result);" })
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> create(
      ${primaryEntityName}Entity entity) async {
    try {
      final model  = ${primaryEntityName}Model.fromEntity(entity);
$(if ($isRemote) { "      final result = await remoteDataSource.create(model.toJson());" })
$(if ($isLocal -and $isRemote) { "      await localDataSource?.upsert(result);" })
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> update(
      ${primaryEntityName}Entity entity) async {
    try {
      final model  = ${primaryEntityName}Model.fromEntity(entity);
$(if ($isRemote) { "      final result = await remoteDataSource.update(entity.id, model.toJson());" })
$(if ($isLocal -and $isRemote) { "      await localDataSource?.upsert(result);" })
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
$(if ($isRemote) { "      await remoteDataSource.delete(id);" })
$(if ($isLocal) { "      await localDataSource?.delete(id);" })
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
$transitionImpls2}
"@
  & $NewFile (Join-Path $fDir "data\repositories\${fname}_repository_impl.dart") $repoImplContent
}

# ── Helper ────────────────────────────────────────────────────
function ConvertTo-SnakeCase([string]$PascalCase) {
  return ($PascalCase -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
}

Export-ModuleMember -Function @(
  'Invoke-GenerateDomain',
  'Invoke-GenerateData',
  'ConvertTo-SnakeCase'
)
