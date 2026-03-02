# ============================================================
# Level5CubitGenerator.psm1
# Generates:
#   presentation/cubit/{fname}_cubit.dart
#   presentation/cubit/{fname}_state.dart
# ============================================================

function Invoke-GenerateIntegrationCubit {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    _Gen-State -Ctx $Ctx -NewFile $NewFile
    _Gen-Cubit -Ctx $Ctx -NewFile $NewFile
}

function _Gen-State {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $intg   = $Ctx.Config.integration
    $ops    = @($intg.operations)

    # Build per-operation status fields
    $statusFields = [System.Collections.Generic.List[string]]::new()
    $ctorParams   = [System.Collections.Generic.List[string]]::new()
    $copyParams   = [System.Collections.Generic.List[string]]::new()
    $copyBody     = [System.Collections.Generic.List[string]]::new()
    $propsList    = [System.Collections.Generic.List[string]]::new()

    # Global fields
    $statusFields.Add("  final bool isLoading;")
    $statusFields.Add("  final String? errorMessage;")
    $statusFields.Add("  final DateTime? lastSyncAt;")
    $ctorParams.Add("    this.isLoading = false,")
    $ctorParams.Add("    this.errorMessage,")
    $ctorParams.Add("    this.lastSyncAt,")
    $copyParams.Add("    bool? isLoading,")
    $copyParams.Add("    String? errorMessage,")
    $copyParams.Add("    DateTime? lastSyncAt,")
    $copyBody.Add("      isLoading: isLoading ?? this.isLoading,")
    $copyBody.Add("      errorMessage: errorMessage ?? this.errorMessage,")
    $copyBody.Add("      lastSyncAt: lastSyncAt ?? this.lastSyncAt,")
    $propsList.Add("isLoading")
    $propsList.Add("errorMessage")
    $propsList.Add("lastSyncAt")

    foreach ($op in $ops) {
        $opName = $op.name
        $opClass = ConvertTo-PascalCase $opName

        # Each operation tracks: result (dynamic), loading, error
        $statusFields.Add("  final bool is${opClass}Loading;")
        $statusFields.Add("  final String? ${opName}Error;")
        $ctorParams.Add("    this.is${opClass}Loading = false,")
        $ctorParams.Add("    this.${opName}Error,")
        $copyParams.Add("    bool? is${opClass}Loading,")
        $copyParams.Add("    String? ${opName}Error,")
        $copyBody.Add("      is${opClass}Loading: is${opClass}Loading ?? this.is${opClass}Loading,")
        $copyBody.Add("      ${opName}Error: ${opName}Error ?? this.${opName}Error,")
        $propsList.Add("is${opClass}Loading")
        $propsList.Add("${opName}Error")

        # If GET operation has response, track last result
        if ($op.method.ToUpper() -eq 'GET' -and $op.responseFields) {
            $opSnake = ConvertTo-SnakeCase $opName
            $statusFields.Add("  final ${opClass}Response? ${opName}Result;")
            $ctorParams.Add("    this.${opName}Result,")
            $copyParams.Add("    ${opClass}Response? ${opName}Result,")
            $copyBody.Add("      ${opName}Result: ${opName}Result ?? this.${opName}Result,")
            $propsList.Add("${opName}Result")
        }
    }

    # Build response imports for GET operations
    $responseImports = [System.Collections.Generic.List[string]]::new()
    foreach ($op in $ops) {
        if ($op.method.ToUpper() -eq 'GET' -and $op.responseFields) {
            $opSnake = ConvertTo-SnakeCase $op.name
            $responseImports.Add("import '../../domain/models/${opSnake}_response.dart';")
        }
    }
    $responseImportStr = if ($responseImports.Count -gt 0) { ($responseImports | Select-Object -Unique) -join "`n" } else { '' }

    $content = @"
import 'package:equatable/equatable.dart';
$responseImportStr

class ${fclass}State extends Equatable {
$($statusFields -join "`n")

  const ${fclass}State({
$($ctorParams -join "`n")
  });

  ${fclass}State copyWith({
$($copyParams -join "`n")
  }) {
    return ${fclass}State(
$($copyBody -join "`n")
    );
  }

  @override
  List<Object?> get props => [$($propsList -join ', ')];
}
"@
    & $NewFile (Join-Path $fDir "presentation\cubit\${fname}_state.dart") $content
}

function _Gen-Cubit {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $intg   = $Ctx.Config.integration
    $ops    = @($intg.operations)

    # Build operation methods
    $opMethods = [System.Collections.Generic.List[string]]::new()
    $opImports = [System.Collections.Generic.List[string]]::new()

    foreach ($op in $ops) {
        $opName  = $op.name
        $opClass = ConvertTo-PascalCase $opName
        $opSnake = ConvertTo-SnakeCase $opName
        $method  = $op.method.ToUpper()

        if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) {
            $opImports.Add("import '../../domain/models/${opSnake}_request.dart';")
        }

        # Build method signature params
        $hasPathParam = $op.path -match '\{(\w+)\}'
        $paramName = if ($hasPathParam) { $Matches[1] } else { $null }

        $mParams = [System.Collections.Generic.List[string]]::new()
        if ($paramName) { $mParams.Add("String $paramName") }
        if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) { $mParams.Add("${opClass}Request request") }
        $mParamStr = $mParams -join ', '

        # Build service call args
        $callArgs = [System.Collections.Generic.List[string]]::new()
        if ($paramName) { $callArgs.Add($paramName) }
        if ($method -in @('POST', 'PUT', 'PATCH') -and $op.requestFields) { $callArgs.Add('request') }
        $callStr = $callArgs -join ', '

        # Build success state update
        $successUpdate = if ($method -eq 'GET' -and $op.responseFields) {
            "emit(state.copyWith(is${opClass}Loading: false, ${opName}Result: result, lastSyncAt: DateTime.now()));"
        } else {
            "emit(state.copyWith(is${opClass}Loading: false, lastSyncAt: DateTime.now()));"
        }

        $opMethods.Add(@"
  Future<void> $opName($mParamStr) async {
    emit(state.copyWith(is${opClass}Loading: true, ${opName}Error: null));
    final result = await _service.$opName($callStr);
    result.fold(
      (failure) => emit(state.copyWith(is${opClass}Loading: false, ${opName}Error: failure.toString())),
      (result) {
        $successUpdate
      },
    );
  }
"@)
    }

    $uniqueImports = $opImports | Select-Object -Unique

    $content = @"
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/services/${fname}_service.dart';
import '${fname}_state.dart';
$($uniqueImports -join "`n")

class ${fclass}Cubit extends Cubit<${fclass}State> {
  final ${fclass}Service _service;

  ${fclass}Cubit({required ${fclass}Service service})
      : _service = service,
        super(const ${fclass}State());

$($opMethods -join "`n")
}
"@
    & $NewFile (Join-Path $fDir "presentation\cubit\${fname}_cubit.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateIntegrationCubit'
