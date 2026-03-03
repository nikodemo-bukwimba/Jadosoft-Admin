# ============================================================
# Level3EntityGenerator.psm1 — Entity with status field
# ============================================================

function Invoke-GenerateEntity {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir = $Ctx.FeatureDir
    $sm = $Ctx.Config.stateMachine
    $meta = Get-PrimaryEntityMeta -Config $Ctx.Config
    $eName = $meta.Name
    $eSnake = $meta.Snake

    $statusField = $sm.field   # e.g. "status"
    $statusType = "${fclass}Status"

    # Build field list: config fields + inject status if not already declared
    $allFields = [System.Collections.Generic.List[hashtable]]::new()
    $hasStatus = $false
    foreach ($f in $meta.Fields) {
        if ($f.Name -eq $statusField) { $hasStatus = $true }
        $allFields.Add($f)
    }
    if (-not $hasStatus) {
        $allFields.Add(@{
                Name       = $statusField
                Type       = $statusType
                DartType   = $statusType
                IsNullable = $false
                IsReadonly = $false
                IsPrimary  = $false
                Label      = ConvertTo-HumanLabel $statusField
            })
    }

    # Field declarations
    $fieldDecls = ($allFields | ForEach-Object {
            $dt = if ($_.Name -eq $statusField) { $statusType } else { $_.DartType }
            "  final $dt $($_.Name);"
        }) -join "`n"

    # Constructor params
    $ctorParams = ($allFields | ForEach-Object {
            $dt = if ($_.Name -eq $statusField) { $statusType } else { $_.DartType }
            $req = if ($_.IsNullable) { '' } else { 'required ' }
            if ($_.Name -eq $statusField) {
                "    this.$($_.Name) = ${statusType}X.initial,"
            }
            else {
                "    ${req}this.$($_.Name),"
            }
        }) -join "`n"

    # copyWith params
    $copyParams = ($allFields | ForEach-Object {
            $dt = if ($_.Name -eq $statusField) { $statusType } else { $_.DartType.TrimEnd('?') }
            "    ${dt}? $($_.Name),"
        }) -join "`n"

    # copyWith body
    $copyBody = ($allFields | ForEach-Object {
            "      $($_.Name): $($_.Name) ?? this.$($_.Name),"
        }) -join "`n"

    # props
    $propsList = ($allFields | ForEach-Object { $_.Name }) -join ', '

    $content = @"
import 'package:equatable/equatable.dart';
import '../value_objects/${fname}_status.dart';

class ${eName}Entity extends Equatable {
$fieldDecls

  const ${eName}Entity({
$ctorParams
  });

  ${eName}Entity copyWith({
$copyParams
  }) {
    return ${eName}Entity(
$copyBody
    );
  }

  @override
  List<Object?> get props => [$propsList];
}
"@
    & $NewFile (Join-Path $fDir "domain\entities\${eSnake}_entity.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateEntity'