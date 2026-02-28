# ============================================================
# Level1UseCaseGenerator.psm1 — CRUD use cases
# ============================================================

function Invoke-GenerateUseCases {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $meta   = Get-PrimaryEntityMeta -Config $Ctx.Config
    $eName  = $meta.Name
    $eSnake = $meta.Snake

    # Identify create/update fields (non-readonly, non-primary)
    $mutableFields = @($meta.Fields | Where-Object { -not $_.IsReadonly -and -not $_.IsPrimary })
    $createFormFields = @()
    if ($meta.Ui -and $meta.Ui.form -and $meta.Ui.form.create) {
        $createFormFields = @($meta.Ui.form.create)
    }
    else {
        $createFormFields = @($mutableFields | ForEach-Object { $_.Name })
    }

    # ── GetAll ────────────────────────────────────────────
    $getAllContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${eSnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class GetAll${fclass}UseCase implements UseCase<List<${eName}Entity>, NoParams> {
  final ${fclass}Repository repository;
  GetAll${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, List<${eName}Entity>>> call(NoParams _) =>
      repository.getAll();
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\get_all_${fname}_usecase.dart") $getAllContent

    # ── Get ───────────────────────────────────────────────
    $getContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${eSnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Get${fclass}Params {
  final String id;
  const Get${fclass}Params({required this.id});
}

class Get${fclass}UseCase implements UseCase<${eName}Entity, Get${fclass}Params> {
  final ${fclass}Repository repository;
  Get${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${eName}Entity>> call(Get${fclass}Params p) =>
      repository.getById(p.id);
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\get_${fname}_usecase.dart") $getContent

    # ── Create ────────────────────────────────────────────
    # Params class fields from form.create
    $createParamFields = @()
    $createCtorParams  = @()
    foreach ($fn in $createFormFields) {
        $f = $meta.Fields | Where-Object { $_.Name -eq $fn } | Select-Object -First 1
        if (-not $f) { continue }
        $createParamFields += "  final $($f.DartType) $($f.Name);"
        $req = if ($f.IsNullable) { '' } else { 'required ' }
        $createCtorParams  += "    ${req}this.$($f.Name),"
    }

    # Validation gate
    $valLines = [System.Collections.Generic.List[string]]::new()
    foreach ($fn in $createFormFields) {
        $f = $meta.Fields | Where-Object { $_.Name -eq $fn } | Select-Object -First 1
        if (-not $f -or -not $f.Validation) { continue }
        $vl = Get-ValidationLines -FieldName $f.Name -ConfigType $f.Type -Validation $f.Validation
        foreach ($l in $vl) { $valLines.Add($l) }
    }
    $valBlock = if ($valLines.Count -gt 0) { $valLines -join "`n" } else { '    // No validation rules configured' }

    # Build entity from params
    $entityCtorArgs = [System.Collections.Generic.List[string]]::new()
    foreach ($f in $meta.Fields) {
        if ($f.IsPrimary) {
            $entityCtorArgs.Add("        id: '',")
        }
        elseif ($f.Name -eq 'createdAt') {
            $entityCtorArgs.Add("        createdAt: DateTime.now(),")
        }
        elseif ($f.Name -eq 'updatedAt') {
            $entityCtorArgs.Add("        updatedAt: DateTime.now(),")
        }
        elseif ($f.IsReadonly -and $f.Type -eq 'DateTime') {
            $entityCtorArgs.Add("        $($f.Name): DateTime.now(),")
        }
        elseif ($f.IsReadonly) {
            $def = switch ($f.Type) {
                'String'   { "''" }
                'int'      { '0' }
                'double'   { '0.0' }
                'bool'     { 'false' }
                default    { "''" }
            }
            $entityCtorArgs.Add("        $($f.Name): $def,")
        }
        elseif ($f.Name -in $createFormFields) {
            $trim = if ($f.Type -eq 'String') { '.trim()' } else { '' }
            $entityCtorArgs.Add("        $($f.Name): p.$($f.Name)$trim,")
        }
        else {
            $def = switch ($f.Type) {
                'String'   { if ($f.IsNullable) { 'null' } else { "''" } }
                'int'      { if ($f.IsNullable) { 'null' } else { '0' } }
                'double'   { if ($f.IsNullable) { 'null' } else { '0.0' } }
                'bool'     { 'false' }
                'DateTime' { if ($f.IsNullable) { 'null' } else { 'DateTime.now()' } }
                default    { if ($f.IsNullable) { 'null' } else { "''" } }
            }
            $entityCtorArgs.Add("        $($f.Name): $def,")
        }
    }

    $createContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${eSnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Create${fclass}Params {
$($createParamFields -join "`n")

  const Create${fclass}Params({
$($createCtorParams -join "`n")
  });
}

class Create${fclass}UseCase implements UseCase<${eName}Entity, Create${fclass}Params> {
  final ${fclass}Repository repository;
  Create${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${eName}Entity>> call(Create${fclass}Params p) async {
    // ── Validation gate ─────────────────────────────────
$valBlock

    return repository.create(
      ${eName}Entity(
$($entityCtorArgs -join "`n")
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\create_${fname}_usecase.dart") $createContent

    # ── Update ────────────────────────────────────────────
    $updateContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/${eSnake}_entity.dart';
import '../repositories/${fname}_repository.dart';

class Update${fclass}Params {
  final ${eName}Entity entity;
  const Update${fclass}Params({required this.entity});
}

class Update${fclass}UseCase implements UseCase<${eName}Entity, Update${fclass}Params> {
  final ${fclass}Repository repository;
  Update${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, ${eName}Entity>> call(Update${fclass}Params p) async {
    return repository.update(p.entity);
  }
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\update_${fname}_usecase.dart") $updateContent

    # ── Delete ────────────────────────────────────────────
    $deleteContent = @"
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/${fname}_repository.dart';

class Delete${fclass}Params {
  final String id;
  const Delete${fclass}Params({required this.id});
}

class Delete${fclass}UseCase implements UseCase<void, Delete${fclass}Params> {
  final ${fclass}Repository repository;
  Delete${fclass}UseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Delete${fclass}Params p) =>
      repository.delete(p.id);
}
"@
    & $NewFile (Join-Path $fDir "domain\usecases\delete_${fname}_usecase.dart") $deleteContent
}

Export-ModuleMember -Function 'Invoke-GenerateUseCases'
