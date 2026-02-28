# ============================================================
# Level3DataGenerator.psm1 — Data layer with status awareness
# Extends Level 1: model handles status ↔ string conversion
# ============================================================

function Invoke-GenerateData {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $config = $Ctx.Config
    $sm     = $config.stateMachine
    $meta   = Get-PrimaryEntityMeta -Config $config
    $eName  = $meta.Name
    $eSnake = $meta.Snake
    $endpoint  = $meta.Endpoint
    $isRemote  = $config.storage.remote -eq $true
    $isLocal   = ($null -ne $config.storage.local) -and ($config.storage.local -eq $true)

    $statusField = $sm.field
    $statusType  = "${fclass}Status"

    # ── Repository interface ──────────────────────────────
    $repoContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/${eSnake}_entity.dart';

abstract class ${fclass}Repository {
  Future<Either<Failure, List<${eName}Entity>>> getAll();
  Future<Either<Failure, ${eName}Entity>>       getById(String id);
  Future<Either<Failure, ${eName}Entity>>       create(${eName}Entity entity);
  Future<Either<Failure, ${eName}Entity>>       update(${eName}Entity entity);
  Future<Either<Failure, void>>                 delete(String id);
}
"@
    & $NewFile (Join-Path $fDir "domain\repositories\${fname}_repository.dart") $repoContent

    # ── Model (with status serialization) ─────────────────
    # Determine if status field exists in config fields
    $hasStatusInConfig = ($meta.Fields | Where-Object { $_.Name -eq $statusField }).Count -gt 0

    $fromJsonFields = [System.Collections.Generic.List[string]]::new()
    $toJsonFields   = [System.Collections.Generic.List[string]]::new()
    $superParams    = [System.Collections.Generic.List[string]]::new()

    foreach ($f in $meta.Fields) {
        if ($f.Name -eq $statusField) {
            $fromJsonFields.Add("      $($f.Name): ${statusType}.values.firstWhere(")
            $fromJsonFields.Add("        (e) => e.name == (json['$($f.SnakeCase)'] as String? ?? '${($sm.initial)}'),")
            $fromJsonFields.Add("        orElse: () => ${statusType}X.initial,")
            $fromJsonFields.Add("      ),")
            $toJsonFields.Add("      '$($f.SnakeCase)': $($f.Name).name,")
        } else {
            $parseExpr = Get-JsonParseExpr -ConfigType $f.Type -JsonKey $f.SnakeCase -Nullable $f.IsNullable
            $fromJsonFields.Add("      $($f.Name): $parseExpr,")
            $writeExpr = Get-JsonWriteExpr -ConfigType $f.Type -FieldName $f.Name -Nullable $f.IsNullable
            $toJsonFields.Add("      '$($f.SnakeCase)': $writeExpr,")
        }
        $superParams.Add("    required super.$($f.Name),")
    }

    # Inject status if not in config fields
    if (-not $hasStatusInConfig) {
        $fromJsonFields.Add("      $statusField: ${statusType}.values.firstWhere(")
        $fromJsonFields.Add("        (e) => e.name == (json['$statusField'] as String? ?? '${($sm.initial)}'),")
        $fromJsonFields.Add("        orElse: () => ${statusType}X.initial,")
        $fromJsonFields.Add("      ),")
        $toJsonFields.Add("      '$statusField': $statusField.name,")
        $superParams.Add("    super.$statusField = ${statusType}X.initial,")
    }

    $modelContent = @"
import '../../domain/entities/${eSnake}_entity.dart';
import '../../domain/value_objects/${fname}_status.dart';

class ${eName}Model extends ${eName}Entity {
  const ${eName}Model({
$($superParams -join "`n")
  });

  factory ${eName}Model.fromJson(Map<String, dynamic> json) {
    return ${eName}Model(
$($fromJsonFields -join "`n")
    );
  }

  Map<String, dynamic> toJson() => {
$($toJsonFields -join "`n")
  };

  factory ${eName}Model.fromEntity(${eName}Entity entity) {
    return ${eName}Model(
$( ($meta.Fields | ForEach-Object { "      $($_.Name): entity.$($_.Name)," }) -join "`n" )
$(if (-not $hasStatusInConfig) { "      $statusField`: entity.$statusField," })
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "data\models\${eSnake}_model.dart") $modelContent

    # ── Remote datasource (same as Level 1) ───────────────
    if ($isRemote) {
        $dsContent = @"
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/${eSnake}_model.dart';

abstract class ${fclass}RemoteDataSource {
  Future<List<${eName}Model>> getAll();
  Future<${eName}Model>       getById(String id);
  Future<${eName}Model>       create(Map<String, dynamic> data);
  Future<${eName}Model>       update(String id, Map<String, dynamic> data);
  Future<void>                delete(String id);
}

class ${fclass}RemoteDataSourceImpl implements ${fclass}RemoteDataSource {
  final Dio _dio;
  ${fclass}RemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<${eName}Model>> getAll() async {
    try {
      final response = await _dio.get('$endpoint');
      final data = response.data as List;
      return data
          .map((e) => ${eName}Model.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<${eName}Model> getById(String id) async {
    try {
      final response = await _dio.get('$endpoint/`$id');
      return ${eName}Model.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<${eName}Model> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('$endpoint', data: data);
      return ${eName}Model.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<${eName}Model> update(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('$endpoint/`$id', data: data);
      return ${eName}Model.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('$endpoint/`$id');
    } on DioException catch (e) {
      throw ServerException(_msg(e), statusCode: e.response?.statusCode);
    }
  }

  String _msg(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }
    return 'An error occurred. Please try again.';
  }
}
"@
        & $NewFile (Join-Path $fDir "data\datasources\${fname}_remote_datasource.dart") $dsContent
    }

    # ── Repository implementation (same structure as Level 1) ──
    $dsImports    = ''
    $dsFields     = ''
    $dsCtorParams = ''
    $dsCtorInit   = ''

    if ($isRemote) {
        $dsImports    += "import '../datasources/${fname}_remote_datasource.dart';`n"
        $dsFields     += "  final ${fclass}RemoteDataSource _remoteDataSource;`n"
        $dsCtorParams += "    required ${fclass}RemoteDataSource remoteDataSource,`n"
        $dsCtorInit   += "        _remoteDataSource = remoteDataSource"
    }
    if ($isLocal) {
        $dsImports    += "import '../datasources/${fname}_local_datasource.dart';`n"
        $dsFields     += "  final ${fclass}LocalDataSource _localDataSource;`n"
        $dsCtorParams += "    required ${fclass}LocalDataSource localDataSource,`n"
        if ($isRemote) { $dsCtorInit += ",`n        _localDataSource = localDataSource" }
        else           { $dsCtorInit += "        _localDataSource = localDataSource" }
    }

    $dataSourceCall = if ($isRemote) { '_remoteDataSource' } else { '_localDataSource' }

    $implContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/${eSnake}_entity.dart';
import '../../domain/repositories/${fname}_repository.dart';
import '../models/${eSnake}_model.dart';
${dsImports}
class ${fclass}RepositoryImpl implements ${fclass}Repository {
${dsFields}
  ${fclass}RepositoryImpl({
${dsCtorParams}  })  : ${dsCtorInit};

  @override
  Future<Either<Failure, List<${eName}Entity>>> getAll() async {
    try {
      final result = await ${dataSourceCall}.getAll();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${eName}Entity>> getById(String id) async {
    try {
      final result = await ${dataSourceCall}.getById(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${eName}Entity>> create(${eName}Entity entity) async {
    try {
      final model = ${eName}Model.fromEntity(entity);
      final result = await ${dataSourceCall}.create(model.toJson());
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ${eName}Entity>> update(${eName}Entity entity) async {
    try {
      final model = ${eName}Model.fromEntity(entity);
      final result = await ${dataSourceCall}.update(entity.id, model.toJson());
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
      await ${dataSourceCall}.delete(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GenericFailure(e.toString()));
    }
  }
}
"@
    & $NewFile (Join-Path $fDir "data\repositories\${fname}_repository_impl.dart") $implContent
}

Export-ModuleMember -Function 'Invoke-GenerateData'
