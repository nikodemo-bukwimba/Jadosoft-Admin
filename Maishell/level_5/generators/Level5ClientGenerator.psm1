# ============================================================
# Level5ClientGenerator.psm1
# Generates:
#   data/client/{fname}_client.dart            (HTTP client + retry)
#   domain/models/{op_name}_request.dart       (per operation)
#   domain/models/{op_name}_response.dart      (per operation)
#   domain/services/{fname}_service.dart       (orchestration)
#   domain/models/{wh_name}_webhook_payload.dart (per webhook)
#   domain/services/{fname}_webhook_handler.dart (webhook processor)
# ============================================================

function Invoke-GenerateIntegrationClient {
  param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir
  $config = $Ctx.Config
  $intg = $config.integration

  _Gen-Client         -Ctx $Ctx -NewFile $NewFile -Intg $intg
  _Gen-OperationDTOs  -Ctx $Ctx -NewFile $NewFile -Intg $intg
  _Gen-Service        -Ctx $Ctx -NewFile $NewFile -Intg $intg
  if ($intg.webhooks -and $intg.webhooks.Count -gt 0) {
    _Gen-WebhookPayloads -Ctx $Ctx -NewFile $NewFile -Intg $intg
    _Gen-WebhookHandler  -Ctx $Ctx -NewFile $NewFile -Intg $intg
  }
}

function _Gen-Client {
  param($Ctx, $NewFile, $Intg)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir

  $baseUrl = $Intg.baseUrl
  $auth = if ($Intg.auth) { $Intg.auth } else { 'none' }
  $maxRetries = if ($Intg.retryPolicy -and $Intg.retryPolicy.maxAttempts) { $Intg.retryPolicy.maxAttempts } else { 3 }
  $backoffMs = if ($Intg.retryPolicy -and $Intg.retryPolicy.backoffMs) { $Intg.retryPolicy.backoffMs } else { 1000 }
  $timeoutSec = if ($Intg.timeout) { $Intg.timeout } else { 30 }

  # Build auth header setup
  $authSetup = switch ($auth) {
    'bearer' {
      @"
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer ' + token;
  }
"@
    }
    'apiKey' {
      @"
  void setApiKey(String key) {
    _dio.options.headers['X-Api-Key'] = key;
  }
"@
    }
    default { '' }
  }

  # Build operation methods
  $ops = @($Intg.operations)
  $opMethods = [System.Collections.Generic.List[string]]::new()
  $opImports = [System.Collections.Generic.List[string]]::new()

  foreach ($op in $ops) {
    $opName = $op.name
    $opClass = ConvertTo-PascalCase $opName
    $opSnake = ConvertTo-SnakeCase $opName
    $method = $op.method.ToUpper()
    $path = $op.path

    if ($method -ne 'DELETE' -and $op.responseFields) {
      $opImports.Add("import '../../domain/models/${opSnake}_response.dart';")
    }
    if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) {
      $opImports.Add("import '../../domain/models/${opSnake}_request.dart';")
    }

    $methodBody = switch ($method) {
      'GET' {
        # Check if path has {id} parameter
        $hasPathParam = $path -match '\{(\w+)\}'
        if ($hasPathParam) {
          $paramName = $Matches[1]
          # Build path via concat to protect Dart ${} from PS
          $dartPath = "'" + $path.Replace("{$paramName}", "' + $paramName + '") + "'"
          # Clean up trailing empty string concat if path ends with param
          $dartPath = $dartPath.Replace(" + ''", "")
          @"
  Future<${opClass}Response> $opName(String $paramName) async {
    final response = await _requestWithRetry(
      () => _dio.get($dartPath),
    );
    return ${opClass}Response.fromJson(response.data as Map<String, dynamic>);
  }
"@
        }
        else {
          @"
  Future<${opClass}Response> $opName() async {
    final response = await _requestWithRetry(
      () => _dio.get('$path'),
    );
    return ${opClass}Response.fromJson(response.data as Map<String, dynamic>);
  }
"@
        }
      }
      'POST' {
        @"
  Future<${opClass}Response> $opName(${opClass}Request request) async {
    final response = await _requestWithRetry(
      () => _dio.post('$path', data: request.toJson()),
    );
    return ${opClass}Response.fromJson(response.data as Map<String, dynamic>);
  }
"@
      }
      'PUT' {
        $hasPathParam = $path -match '\{(\w+)\}'
        if ($hasPathParam) {
          $paramName = $Matches[1]
          $dartPath = "'" + $path.Replace("{$paramName}", "' + $paramName + '") + "'"
          $dartPath = $dartPath.Replace(" + ''", "")
          @"
  Future<${opClass}Response> $opName(String $paramName, ${opClass}Request request) async {
    final response = await _requestWithRetry(
      () => _dio.put($dartPath, data: request.toJson()),
    );
    return ${opClass}Response.fromJson(response.data as Map<String, dynamic>);
  }
"@
        }
        else {
          @"
  Future<${opClass}Response> $opName(${opClass}Request request) async {
    final response = await _requestWithRetry(
      () => _dio.put('$path', data: request.toJson()),
    );
    return ${opClass}Response.fromJson(response.data as Map<String, dynamic>);
  }
"@
        }
      }
      'DELETE' {
        $hasPathParam = $path -match '\{(\w+)\}'
        if ($hasPathParam) {
          $paramName = $Matches[1]
          $dartPath = "'" + $path.Replace("{$paramName}", "' + $paramName + '") + "'"
          $dartPath = $dartPath.Replace(" + ''", "")
          @"
  Future<void> $opName(String $paramName) async {
    await _requestWithRetry(
      () => _dio.delete($dartPath),
    );
  }
"@
        }
        else {
          @"
  Future<void> $opName() async {
    await _requestWithRetry(
      () => _dio.delete('$path'),
    );
  }
"@
        }
      }
      default {
        @"
  // TODO: implement $method $path
"@
      }
    }
    $opMethods.Add($methodBody)
  }

  $uniqueImports = $opImports | Select-Object -Unique

  $content = @"
import 'package:dio/dio.dart';
$($uniqueImports -join "`n")

class ${fclass}Client {
  final Dio _dio;
  static const int _maxRetries = $maxRetries;
  static const int _backoffMs = $backoffMs;

  ${fclass}Client({required Dio dio}) : _dio = dio {
    _dio.options.baseUrl = '$baseUrl';
    _dio.options.connectTimeout = const Duration(seconds: $timeoutSec);
    _dio.options.receiveTimeout = const Duration(seconds: $timeoutSec);
  }

$authSetup

  /// Executes [request] with exponential backoff retry on transient failures.
  Future<Response> _requestWithRetry(
    Future<Response> Function() request,
  ) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await request();
      } on DioException catch (e) {
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError ||
            (e.response != null && e.response!.statusCode != null && e.response!.statusCode! >= 500);

        if (!isRetryable || attempt >= _maxRetries) rethrow;

        final delay = _backoffMs * (1 << (attempt - 1));
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

$($opMethods -join "`n")
}
"@
  & $NewFile (Join-Path $fDir "data\client\${fname}_client.dart") $content
}

function _Gen-OperationDTOs {
  param($Ctx, $NewFile, $Intg)
  $fname = $Ctx.Tokens.FNAME
  $fDir = $Ctx.FeatureDir
  $ops = @($Intg.operations)

  foreach ($op in $ops) {
    $opName = $op.name
    $opClass = ConvertTo-PascalCase $opName
    $opSnake = ConvertTo-SnakeCase $opName
    $method = $op.method.ToUpper()

    # Request DTO (only for POST/PUT/PATCH)
    if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) {
      $reqFields = @($op.requestFields)
      $fieldDecls = [System.Collections.Generic.List[string]]::new()
      $ctorParams = [System.Collections.Generic.List[string]]::new()
      $toJsonLines = [System.Collections.Generic.List[string]]::new()

      foreach ($f in $reqFields) {
        $dartType = $f.type
        $nullable = if ($f.nullable) { $f.nullable } else { $false }
        if ($nullable) { $dartType = $dartType + '?' }
        $fieldDecls.Add("  final $dartType $($f.name);")
        $req = if ($nullable) { '' } else { 'required ' }
        $ctorParams.Add("    ${req}this.$($f.name),")
        $snakeKey = ConvertTo-SnakeCase $f.name
        $toJsonLines.Add("      '$snakeKey': $($f.name),")
      }

      $reqContent = @"
class ${opClass}Request {
$($fieldDecls -join "`n")

  const ${opClass}Request({
$($ctorParams -join "`n")
  });

  Map<String, dynamic> toJson() => {
$($toJsonLines -join "`n")
  };
}
"@
      & $NewFile (Join-Path $fDir "domain\models\${opSnake}_request.dart") $reqContent
    }

    # Response DTO
    if ($op.responseFields) {
      $respFields = @($op.responseFields)
      $fieldDecls = [System.Collections.Generic.List[string]]::new()
      $ctorParams = [System.Collections.Generic.List[string]]::new()
      $fromJsonLines = [System.Collections.Generic.List[string]]::new()

      foreach ($f in $respFields) {
        $dartType = $f.type
        $nullable = if ($f.nullable) { $f.nullable } else { $false }
        if ($nullable) { $dartType = $dartType + '?' }
        $fieldDecls.Add("  final $dartType $($f.name);")
        $req = if ($nullable) { '' } else { 'required ' }
        $ctorParams.Add("    ${req}this.$($f.name),")
        $snakeKey = ConvertTo-SnakeCase $f.name
        $castExpr = _Get-JsonCast -DartType $f.type -Key $snakeKey -Nullable $nullable
        $fromJsonLines.Add("      $($f.name): $castExpr,")
      }

      $respContent = @"
class ${opClass}Response {
$($fieldDecls -join "`n")

  const ${opClass}Response({
$($ctorParams -join "`n")
  });

  factory ${opClass}Response.fromJson(Map<String, dynamic> json) {
    return ${opClass}Response(
$($fromJsonLines -join "`n")
    );
  }
}
"@
      & $NewFile (Join-Path $fDir "domain\models\${opSnake}_response.dart") $respContent
    }
  }
}

function _Get-JsonCast {
  param([string]$DartType, [string]$Key, [bool]$Nullable)
  switch ($DartType) {
    'String' { if ($Nullable) { "json['$Key'] as String?" } else { "json['$Key'] as String" } }
    'int' { if ($Nullable) { "json['$Key'] as int?" } else { "json['$Key'] as int" } }
    'double' { if ($Nullable) { "(json['$Key'] as num?)?.toDouble()" } else { "(json['$Key'] as num).toDouble()" } }
    'bool' { if ($Nullable) { "json['$Key'] as bool?" } else { "json['$Key'] as bool" } }
    'DateTime' { if ($Nullable) { "json['$Key'] != null ? DateTime.parse(json['$Key'] as String) : null" } else { "DateTime.parse(json['$Key'] as String)" } }
    default { "json['$Key']" }
  }
}

function _Gen-Service {
  param($Ctx, $NewFile, $Intg)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir
  $ops = @($Intg.operations)

  $opImports = [System.Collections.Generic.List[string]]::new()
  $opMethods = [System.Collections.Generic.List[string]]::new()

  foreach ($op in $ops) {
    $opName = $op.name
    $opClass = ConvertTo-PascalCase $opName
    $opSnake = ConvertTo-SnakeCase $opName
    $method = $op.method.ToUpper()

    if ($op.responseFields) {
      $opImports.Add("import '../models/${opSnake}_response.dart';")
    }
    if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) {
      $opImports.Add("import '../models/${opSnake}_request.dart';")
    }

    # Build service method that wraps client call in try/catch -> Either
    $hasPathParam = $op.path -match '\{(\w+)\}'
    $paramName = if ($hasPathParam) { $Matches[1] } else { $null }

    $retType = if ($method -eq 'DELETE') { 'void' } else { "${opClass}Response" }

    $callArgs = [System.Collections.Generic.List[string]]::new()
    if ($paramName) { $callArgs.Add($paramName) }
    if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) { $callArgs.Add('request') }
    $callStr = $callArgs -join ', '

    $params = [System.Collections.Generic.List[string]]::new()
    if ($paramName) { $params.Add("String $paramName") }
    if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) { $params.Add("${opClass}Request request") }
    $paramStr = $params -join ', '

    # Build return line via concat for Dart ${} safety
    $returnLine = if ($method -eq 'DELETE') {
      "      await _client.$opName($callStr);" + "`n" + "      return const Right(null);"
    }
    else {
      "      final result = await _client.$opName($callStr);" + "`n" + "      return Right(result);"
    }

    # Build catch msg via concat
    $catchMsg = "e.response" + "?.data" + "?.toString() ?? e.message ?? 'Unknown error'"

    $opMethods.Add(@"
  Future<Either<Failure, $retType>> $opName($paramStr) async {
    try {
$returnLine
    } on DioException catch (e) {
      return Left(ServerFailure($catchMsg));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
"@)
  }

  $uniqueImports = $opImports | Select-Object -Unique

  $content = @"
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../data/client/${fname}_client.dart';
$($uniqueImports -join "`n")

class ${fclass}Service {
  final ${fclass}Client _client;

  ${fclass}Service({required ${fclass}Client client}) : _client = client;

$($opMethods -join "`n")
}
"@
  & $NewFile (Join-Path $fDir "domain\services\${fname}_service.dart") $content
}

function _Gen-WebhookPayloads {
  param($Ctx, $NewFile, $Intg)
  $fname = $Ctx.Tokens.FNAME
  $fDir = $Ctx.FeatureDir
  $whs = @($Intg.webhooks)

  foreach ($wh in $whs) {
    $whName = $wh.name
    $whClass = ConvertTo-PascalCase $whName
    $whSnake = ConvertTo-SnakeCase $whName

    $fieldDecls = [System.Collections.Generic.List[string]]::new()
    $ctorParams = [System.Collections.Generic.List[string]]::new()
    $fromJsonLines = [System.Collections.Generic.List[string]]::new()

    $fieldDecls.Add("  final String event;")
    $ctorParams.Add("    required this.event,")
    $fromJsonLines.Add("      event: json['event'] as String,")

    if ($wh.fields) {
      foreach ($f in $wh.fields) {
        $dartType = $f.type
        $nullable = if ($f.nullable) { $f.nullable } else { $false }
        if ($nullable) { $dartType = $dartType + '?' }
        $fieldDecls.Add("  final $dartType $($f.name);")
        $req = if ($nullable) { '' } else { 'required ' }
        $ctorParams.Add("    ${req}this.$($f.name),")
        $snakeKey = ConvertTo-SnakeCase $f.name
        $castExpr = _Get-JsonCast -DartType $f.type -Key $snakeKey -Nullable $nullable
        $fromJsonLines.Add("      $($f.name): $castExpr,")
      }
    }

    $content = @"
class ${whClass}WebhookPayload {
$($fieldDecls -join "`n")

  const ${whClass}WebhookPayload({
$($ctorParams -join "`n")
  });

  factory ${whClass}WebhookPayload.fromJson(Map<String, dynamic> json) {
    return ${whClass}WebhookPayload(
$($fromJsonLines -join "`n")
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "domain\models\${whSnake}_webhook_payload.dart") $content
  }
}

function _Gen-WebhookHandler {
  param($Ctx, $NewFile, $Intg)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir
  $whs = @($Intg.webhooks)

  $whImports = [System.Collections.Generic.List[string]]::new()
  $whCases = [System.Collections.Generic.List[string]]::new()

  foreach ($wh in $whs) {
    $whName = $wh.name
    $whClass = ConvertTo-PascalCase $whName
    $whSnake = ConvertTo-SnakeCase $whName
    $event = $wh.event

    $whImports.Add("import '../models/${whSnake}_webhook_payload.dart';")
    $whCases.Add(@"
      case '$event':
        final payload = ${whClass}WebhookPayload.fromJson(data);
        await _handle${whClass}(payload);
        break;
"@)
  }

  $whHandlers = [System.Collections.Generic.List[string]]::new()
  foreach ($wh in $whs) {
    $whClass = ConvertTo-PascalCase $wh.name
    $whSnake = ConvertTo-SnakeCase $wh.name
    $whHandlers.Add(@"
  Future<void> _handle${whClass}(${whClass}WebhookPayload payload) async {
    // TODO: implement handler for $($wh.event)
  }
"@)
  }

  $content = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
$($whImports -join "`n")

class ${fclass}WebhookHandler {
  ${fclass}WebhookHandler();

  /// Routes incoming webhook to the appropriate handler by event type.
  Future<Either<Failure, void>> handle(Map<String, dynamic> data) async {
    try {
      final event = data['event'] as String?;
      if (event == null) {
        return Left(ValidationFailure('Missing event field in webhook payload'));
      }

      switch (event) {
$($whCases -join "`n")
        default:
          return Left(ValidationFailure('Unknown webhook event: ' + event));
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

$($whHandlers -join "`n")
}
"@
  & $NewFile (Join-Path $fDir "domain\services\${fname}_webhook_handler.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateIntegrationClient'