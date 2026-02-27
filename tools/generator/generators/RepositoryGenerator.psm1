# ============================================================
# RepositoryGenerator.psm1
# Generates:
#   domain/repositories/{feature}_repository.dart   (abstract interface)
#   data/repositories/{feature}_repository_impl.dart (implementation)
# ============================================================

function Invoke-GenerateRepository {
  param([hashtable]$Ctx, [scriptblock]$NewFile)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $maturity = $Ctx.Maturity

  $isRemote = $config.storage.remote -eq $true
  $isLocal = $config.storage.local -eq $true

  $primaryEntityName = $config.entities.PSObject.Properties |
  Where-Object { $_.Value.primary -eq $true } |
  Select-Object -First 1 -ExpandProperty Name
  $primarySnake = ConvertTo-SnakeCase $primaryEntityName

  $isSearchable = $config.entities.$primaryEntityName.api.searchable -eq $true
  $sortables = $config.entities.$primaryEntityName.api.sortable
  if ($null -eq $sortables) { $sortables = @() }

  # ── Transition method signatures ──────────────────────────
  $transitionMethods = ''
  if ($config.stateMachine -and $maturity -ge 2) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('')
    $lines.Add('  // ── State machine transitions ────────────────────────────')
    foreach ($t in $config.stateMachine.transitions) {
      $tName = $t.name
      $lines.Add("  /// Transition: $($t.from -join ' | ') → $($t.to)")
      $lines.Add("  Future<Either<Failure, ${primaryEntityName}Entity>> $tName(String id);")
    }
    $transitionMethods = $lines -join "`n"
  }

  $searchMethod = if ($isSearchable) {
    @"

  /// Server-side full-text search.
  Future<Either<Failure, List<${primaryEntityName}Entity>>> search(
      ${fclass}SearchParams params);
"@ 
  }
  else { '' }

  $sortableComment = if ($sortables.Count -gt 0) {
    "  // Valid sort fields: $(($sortables | ForEach-Object { "'$_'" }) -join ', ')"
  }
  else { '' }

  # ── Repository interface ──────────────────────────────────
  $repoContent = @"
// ${fname}_repository.dart
// Level $maturity — Abstract repository interface.
//
// Design contract:
//   Domain depends on this interface. NEVER on the implementation.
//   No Dio, no Drift, no JSON. Pure domain types only.
//   All query parameters are domain value objects, not raw maps.
//
// Extending:
//   Add domain-specific method signatures below the CRUD surface.
//   Implement them in ${fname}_repository_impl.dart.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${primarySnake}_entity.dart';

abstract class ${fclass}Repository {

  // ── Core CRUD ───────────────────────────────────────────────
  Future<Either<Failure, List<${primaryEntityName}Entity>>> getAll(
      ${fclass}QueryParams params);

  Future<Either<Failure, ${primaryEntityName}Entity>> getById(String id);

  Future<Either<Failure, ${primaryEntityName}Entity>> create(
      ${primaryEntityName}Entity entity);

  Future<Either<Failure, ${primaryEntityName}Entity>> update(
      ${primaryEntityName}Entity entity);

  Future<Either<Failure, void>> delete(String id);
$searchMethod$transitionMethods

  // TODO: Add domain-specific repository methods below
}

// ══════════════════════════════════════════════════════════════
//  DOMAIN QUERY PARAMETER OBJECTS
//  Travel from UseCase → Repository → DataSource
// ══════════════════════════════════════════════════════════════

class ${fclass}QueryParams {
  final ${fclass}FilterParams?     filters;
  final ${fclass}SortParams?       sort;
  final ${fclass}PaginationParams? pagination;

  const ${fclass}QueryParams({
    this.filters,
    this.sort,
    this.pagination,
  });

  static const empty = ${fclass}QueryParams();
}

class ${fclass}FilterParams {
  // TODO: Add one typed field per entry declared in entities.api.filterable
  // Example for filterable: ["status", "ownerId"]:
  //   final String? status;
  //   final String? ownerId;
  //   const ${fclass}FilterParams({this.status, this.ownerId});

  const ${fclass}FilterParams();

  Map<String, dynamic> toQueryMap() {
    // TODO: Return non-null filter values keyed by API param name
    return const {};
  }
}

class ${fclass}SortParams {
$sortableComment
  final String field;
  final bool   descending;

  const ${fclass}SortParams({
    required this.field,
    this.descending = false,
  });

  String get queryValue => descending ? '-`$field' : field;
}

class ${fclass}PaginationParams {
  final int page;
  final int perPage;

  const ${fclass}PaginationParams({
    this.page    = 1,
    this.perPage = 20,
  });
}

$(if ($isSearchable) { @"
class ${fclass}SearchParams {
  final String query;
  final int    page;
  final int    perPage;

  const ${fclass}SearchParams({
    required this.query,
    this.page    = 1,
    this.perPage = 20,
  });
}
"@ })
"@

  & $NewFile (Join-Path $fDir "domain\repositories\${fname}_repository.dart") $repoContent

  # ── Repository implementation ─────────────────────────────
  $strategy = if ($isRemote -and $isLocal) { 'cache-first (local read → remote write-through)' }
  elseif ($isLocal) { 'local only (offline-first)' }
  else { 'remote only' }

  $localImport = if ($isLocal) { "import '../datasources/${fname}_local_datasource.dart';" } else { '' }
  $localField = if ($isLocal) { "  final ${fclass}LocalDataSource  localDataSource;" } else { '' }
  $localCtorParam = if ($isLocal) { "    required this.localDataSource," } else { '' }
  $remoteField = if ($isRemote) { "  final ${fclass}RemoteDataSource remoteDataSource;" } else { '' }
  $remoteCtorParam = if ($isRemote) { "    required this.remoteDataSource," } else { '' }

  $getAllImpl = if ($isRemote -and $isLocal) {
    @"
    try {
      final cached = await localDataSource.getAll();
      if (cached.isNotEmpty) return Right(cached);

      final remote = await remoteDataSource.getAll(params);
      for (final item in remote) { await localDataSource.upsert(item); }
      return Right(remote);
    } on NetworkException {
      final cached = await localDataSource.getAll();
      return Right(cached);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
"@
  }
  elseif ($isLocal) {
    @"
    try {
      return Right(await localDataSource.getAll());
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
"@
  }
  else {
    @"
    try {
      return Right(await remoteDataSource.getAll(params));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
"@
  }

  $transitionImpls = ''
  if ($config.stateMachine -and $maturity -ge 2) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $config.stateMachine.transitions) {
      $tName = $t.name
      $lines.Add('')
      $lines.Add('  @override')
      $lines.Add("  Future<Either<Failure, ${primaryEntityName}Entity>> $tName(String id) async {")
      $lines.Add('    try {')
      if ($isRemote) {
        $lines.Add("      final result = await remoteDataSource.$tName(id);")
      }
      if ($isLocal -and $isRemote) {
        $lines.Add('      await localDataSource.upsert(result);')
      }
      $lines.Add('      return Right(result);')
      $lines.Add('    } on ServerException catch (e) {')
      $lines.Add('      return Left(ServerFailure(e.message));')
      $lines.Add('    } catch (e) {')
      $lines.Add('      return Left(GenericFailure(e.toString()));')
      $lines.Add('    }')
      $lines.Add('  }')
    }
    $transitionImpls = $lines -join "`n"
  }

  $repoImplContent = @"
// ${fname}_repository_impl.dart
// Strategy: $strategy
//
// Responsibility: map datasource exceptions to domain Failures.
// Nothing leaks beyond this boundary.
// No DioException in domain. No SQLite error in domain.

import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/${primarySnake}_entity.dart';
import '../../domain/repositories/${fname}_repository.dart';
$(if ($isRemote) { "import '../datasources/${fname}_remote_datasource.dart';" })
$localImport
import '../models/${primarySnake}_model.dart';

class ${fclass}RepositoryImpl implements ${fclass}Repository {
$remoteField
$localField

  const ${fclass}RepositoryImpl({
$remoteCtorParam$localCtorParam  });

  @override
  Future<Either<Failure, List<${primaryEntityName}Entity>>> getAll(
      ${fclass}QueryParams params) async {
$getAllImpl  }

  @override
  Future<Either<Failure, ${primaryEntityName}Entity>> getById(String id) async {
    try {
$(if ($isLocal) { "      final cached = await localDataSource.getById(id);
      if (cached != null) return Right(cached);" })
$(if ($isRemote) { "      final result = await remoteDataSource.getById(id);" })
$(if ($isLocal -and $isRemote) { "      await localDataSource.upsert(result);" })
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
      final model = ${primaryEntityName}Model.fromEntity(entity);
$(if ($isRemote) { "      final result = await remoteDataSource.create(model.toJson());" })
$(if ($isLocal -and $isRemote) { "      await localDataSource.upsert(result);" })
$(if ($isLocal -and -not $isRemote) { "      await localDataSource.upsert(model);
      final result = model;" })
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
      final model = ${primaryEntityName}Model.fromEntity(entity);
$(if ($isRemote) { "      final result = await remoteDataSource.update(entity.id, model.toJson());" })
$(if ($isLocal -and $isRemote) { "      await localDataSource.upsert(result);" })
$(if ($isLocal -and -not $isRemote) { "      await localDataSource.upsert(model);
      final result = model;" })
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
$(if ($isLocal) { "      await localDataSource.delete(id);" })
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
$transitionImpls}
"@

  & $NewFile (Join-Path $fDir "data\repositories\${fname}_repository_impl.dart") $repoImplContent
}

function ConvertTo-SnakeCase([string]$PascalCase) {
  return ($PascalCase -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
}

Export-ModuleMember -Function Invoke-GenerateRepository
