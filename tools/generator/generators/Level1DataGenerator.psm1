# ============================================================
# Level1DataGenerator.psm1
# Repo interface + model + datasource + repo impl
# Unified to guarantee signature consistency.
# ============================================================

function Invoke-GenerateData {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $config = $Ctx.Config
    $meta   = Get-PrimaryEntityMeta -Config $config
    $eName  = $meta.Name
    $eSnake = $meta.Snake
    $endpoint = $meta.Endpoint
    $isRemote = $config.storage.remote -eq $true
    $isLocal  = ($null -ne $config.storage.local) -and ($config.storage.local -eq $true)

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

    # ── Model ─────────────────────────────────────────────
    $fromJsonFields = ($meta.Fields | ForEach-Object {
        $parseExpr = Get-JsonParseExpr -ConfigType $_.Type -JsonKey $_.SnakeCase -Nullable $_.IsNullable
        "      $($_.Name): $parseExpr,"
    }) -join "`n"

    $toJsonFields = ($meta.Fields | ForEach-Object {
        $writeExpr = Get-JsonWriteExpr -ConfigType $_.Type -FieldName $_.Name -Nullable $_.IsNullable
        "      '$($_.SnakeCase)': $writeExpr,"
    }) -join "`n"

    $superParams = ($meta.Fields | ForEach-Object {
        "    required super.$($_.Name),"
    }) -join "`n"

    $modelContent = @"
import '../../domain/entities/${eSnake}_entity.dart';

class ${eName}Model extends ${eName}Entity {
  const ${eName}Model({
$superParams
  });

  factory ${eName}Model.fromJson(Map<String, dynamic> json) {
    return ${eName}Model(
$fromJsonFields
    );
  }

  Map<String, dynamic> toJson() => {
$toJsonFields
  };

  factory ${eName}Model.fromEntity(${eName}Entity entity) {
    return ${eName}Model(
$( ($meta.Fields | ForEach-Object { "      $($_.Name): entity.$($_.Name)," }) -join "`n" )
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "data\models\${eSnake}_model.dart") $modelContent

    # ── Remote datasource ─────────────────────────────────
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

    # ── Repository implementation ─────────────────────────
    $dsImports = ''
    $dsFields  = ''
    $dsCtorParams = ''
    $dsCtorInit   = ''

    if ($isRemote) {
        $dsImports += "import '../datasources/${fname}_remote_datasource.dart';`n"
        $dsFields  += "  final ${fclass}RemoteDataSource _remoteDataSource;`n"
        $dsCtorParams += "    required ${fclass}RemoteDataSource remoteDataSource,`n"
        $dsCtorInit   += "        _remoteDataSource = remoteDataSource"
    }
    if ($isLocal) {
        $dsImports += "import '../datasources/${fname}_local_datasource.dart';`n"
        $dsFields  += "  final ${fclass}LocalDataSource _localDataSource;`n"
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
