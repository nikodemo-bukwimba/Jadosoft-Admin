# ============================================================
# Level4ProjectionGenerator.psm1
# Generates:
#   domain/projections/{fname}_projection.dart
#   domain/providers/{source}_data_provider.dart  (per source)
#   data/providers/{source}_data_provider_impl.dart (per source)
#   domain/usecases/get_{fname}_usecase.dart
# ============================================================

function Invoke-GenerateProjection {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir = $Ctx.FeatureDir
    $config = $Ctx.Config

    _Gen-ProjectionClass -Ctx $Ctx -NewFile $NewFile
    _Gen-Providers        -Ctx $Ctx -NewFile $NewFile
    _Gen-UseCase          -Ctx $Ctx -NewFile $NewFile
}

function _Gen-ProjectionClass {
    param($Ctx, $NewFile)
    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir = $Ctx.FeatureDir
    $config = $Ctx.Config

    $metrics = @($config.projection.metrics)

    $fieldDecls = [System.Collections.Generic.List[string]]::new()
    $ctorParams = [System.Collections.Generic.List[string]]::new()
    $propsList = [System.Collections.Generic.List[string]]::new()

    foreach ($m in $metrics) {
        $dartType = $m.type
        $fieldDecls.Add("  final $dartType $($m.name);")
        $ctorParams.Add("    required this.$($m.name),")
        $propsList.Add($m.name)
    }

    # Add timestamp
    $fieldDecls.Add("  final DateTime generatedAt;")
    $ctorParams.Add("    required this.generatedAt,")
    $propsList.Add("generatedAt")

    $propsJoin = $propsList -join ', '

    # -- Build source entity imports (not fname!) --
    $sourceEntityImports = [System.Collections.Generic.List[string]]::new()
    $sources = $config.sources.PSObject.Properties
    foreach ($srcProp in $sources) {
        $src = $srcProp.Value
        $srcFeat = $src.feature
        $srcEntitySnake = ConvertTo-SnakeCase $src.entity
        $sourceEntityImports.Add("import '../../../${srcFeat}/domain/entities/${srcEntitySnake}_entity.dart';")
    }
    $uniqueSourceImports = $sourceEntityImports | Select-Object -Unique

    $content = @"
import 'package:equatable/equatable.dart';
$($uniqueSourceImports -join "`n")

class ${fclass}Projection extends Equatable {
$($fieldDecls -join "`n")

  const ${fclass}Projection({
$($ctorParams -join "`n")
  });

  @override
  List<Object?> get props => [$propsJoin];
}
"@
    & $NewFile (Join-Path $fDir "domain\projections\${fname}_projection.dart") $content
}

function _Gen-Providers {
    param($Ctx, $NewFile)
    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir = $Ctx.FeatureDir
    $config = $Ctx.Config

    $sources = $config.sources.PSObject.Properties

    foreach ($srcProp in $sources) {
        $srcKey = $srcProp.Name
        $src = $srcProp.Value
        $srcEntity = $src.entity
        $srcFeat = $src.feature
        $srcSnake = ConvertTo-SnakeCase $srcKey
        $srcClass = ConvertTo-PascalCase $srcKey

        $srcEntitySnake = ConvertTo-SnakeCase $srcEntity

        # Abstract provider
        $abstractContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/${srcFeat}/domain/entities/${srcEntitySnake}_entity.dart';

/// Provider interface to access ${srcEntity} data from ${srcFeat} feature.
abstract class ${srcClass}DataProvider {
  Future<Either<Failure, List<${srcEntity}Entity>>> getAll();
}
"@
        & $NewFile (Join-Path $fDir "domain\providers\${srcSnake}_data_provider.dart") $abstractContent

        # Concrete impl
        $implContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/${srcFeat}/domain/entities/${srcEntitySnake}_entity.dart';
import '../../../../features/${srcFeat}/domain/repositories/${srcFeat}_repository.dart';
import '../../domain/providers/${srcSnake}_data_provider.dart';

class ${srcClass}DataProviderImpl implements ${srcClass}DataProvider {
  final ${srcClass}Repository _repository;

  ${srcClass}DataProviderImpl({required ${srcClass}Repository repository})
      : _repository = repository;

  @override
  Future<Either<Failure, List<${srcEntity}Entity>>> getAll() =>
      _repository.getAll();
}
"@
        & $NewFile (Join-Path $fDir "data\providers\${srcSnake}_data_provider_impl.dart") $implContent
    }
}

function _Gen-UseCase {
    param($Ctx, $NewFile)
    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir = $Ctx.FeatureDir
    $config = $Ctx.Config

    $sources = $config.sources.PSObject.Properties
    $metrics = @($config.projection.metrics)

    # Build provider fields + constructor params
    $providerFields = [System.Collections.Generic.List[string]]::new()
    $ctorParams = [System.Collections.Generic.List[string]]::new()
    $providerImports = [System.Collections.Generic.List[string]]::new()
    $sourceImports = [System.Collections.Generic.List[string]]::new()

    foreach ($srcProp in $sources) {
        $srcKey = $srcProp.Name
        $src = $srcProp.Value
        $srcSnake = ConvertTo-SnakeCase $srcKey
        $srcClass = ConvertTo-PascalCase $srcKey
        $srcEntitySnake = ConvertTo-SnakeCase $src.entity

        $fieldName = "_" + $srcKey + "Provider"
        $providerFields.Add("  final ${srcClass}DataProvider $fieldName;")
        $ctorParams.Add("    required ${srcClass}DataProvider " + $srcKey + "Provider,")
        $providerImports.Add("import '../providers/${srcSnake}_data_provider.dart';")
        #$sourceImports.Add("import '../../../../features/$($src.feature)/domain/entities/${srcEntitySnake}_entity.dart';")
        $sourceImports.Add("import '../../../$($src.feature)/domain/entities/${srcEntitySnake}_entity.dart';")
    }

    # Build load steps + metric computations
    $loadSteps = [System.Collections.Generic.List[string]]::new()
    $computeLines = [System.Collections.Generic.List[string]]::new()

    # Track which sources we've loaded
    $loadedSources = @{}

    foreach ($m in $metrics) {
        $srcKey = $m.source
        if (-not $loadedSources.ContainsKey($srcKey)) {
            $loadedSources[$srcKey] = $true
            $varName = "${srcKey}List"
            $fieldName = "_${srcKey}Provider"
            $loadSteps.Add(@"
    final ${srcKey}Result = await ${fieldName}.getAll();
    if (${srcKey}Result.isLeft()) {
      return ${srcKey}Result.fold((f) => Left(f), (_) => throw StateError('unreachable'));
    }
    final $varName = ${srcKey}Result.getOrElse(() => throw StateError('unreachable'));
"@)
        }
    }

    foreach ($m in $metrics) {
        $srcVar = "$($m.source)List"
        $name = $m.name
        $op = $m.operation

        switch ($op) {
            'count' {
                $computeLines.Add("    final $name = ${srcVar}.length;")
            }
            'sum' {
                $field = $m.field
                $computeLines.Add("    final $name = ${srcVar}.fold<double>(0.0, (s, e) => s + (e.${field} ?? 0.0));")
            }
            'sumNonNull' {
                $field = $m.field
                $computeLines.Add("    final $name = ${srcVar}.fold<double>(0.0, (s, e) => s + e.${field});")
            }
            'groupCount' {
                $field = $m.field
                # Build via string concat to avoid PS issues with Dart {} syntax
                $line1 = "    final $name = <String, int>" + "{};"
                $line2 = "    for (final e in $srcVar) " + "{"
                $line3 = "      final key = e.${field}.toString();"
                $line4 = "      $name[key] = ($name[key] ?? 0) + 1;"
                $line5 = "    }"
                $computeLines.Add($line1)
                $computeLines.Add($line2)
                $computeLines.Add($line3)
                $computeLines.Add($line4)
                $computeLines.Add($line5)
            }
            'latest' {
                $limit = if ($m.limit) { $m.limit } else { 5 }
                $sortField = if ($m.sortBy) { $m.sortBy } else { 'createdAt' }
                $computeLines.Add("    final sorted${name} = List.of($srcVar)..sort((a, b) => b.${sortField}.compareTo(a.${sortField}));")
                $computeLines.Add("    final $name = sorted${name}.take($limit).toList();")
            }
            'average' {
                $field = $m.field
                $computeLines.Add("    final $name = ${srcVar}.isEmpty ? 0.0 : ${srcVar}.fold<double>(0.0, (s, e) => s + (e.${field} ?? 0.0)) / ${srcVar}.length;")
            }
            default {
                $computeLines.Add("    // TODO: implement operation '$op' for metric '$name'")
            }
        }
    }

    # Build projection constructor args
    $projArgs = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $metrics) {
        $projArgs.Add("      $($m.name): $($m.name),")
    }
    $projArgs.Add("      generatedAt: DateTime.now(),")

    # Unique imports
    $uniqueProviderImports = $providerImports | Select-Object -Unique
    $uniqueSourceImports = $sourceImports | Select-Object -Unique

    # Constructor field assignments -- only first gets `:`, rest are plain
    $ctorAssignments = [System.Collections.Generic.List[string]]::new()
    $isFirst = $true
    foreach ($srcProp in $sources) {
        $srcKey = $srcProp.Name
        if ($isFirst) {
            $ctorAssignments.Add("      : _${srcKey}Provider = ${srcKey}Provider")
            $isFirst = $false
        }
        else {
            $ctorAssignments.Add("        _${srcKey}Provider = ${srcKey}Provider")
        }
    }
    $ctorAssignStr = ($ctorAssignments -join ",`n") + ";"

    $content = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../projections/${fname}_projection.dart';
$($uniqueProviderImports -join "`n")
$($uniqueSourceImports -join "`n")

class Get${fclass}UseCase {
$($providerFields -join "`n")

  Get${fclass}UseCase({
$($ctorParams -join "`n")
  })$ctorAssignStr

  Future<Either<Failure, ${fclass}Projection>> call() async {
$($loadSteps -join "`n")

$($computeLines -join "`n")

    return Right(${fclass}Projection(
$($projArgs -join "`n")
    ));
  }
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\get_${fname}_usecase.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateProjection'

