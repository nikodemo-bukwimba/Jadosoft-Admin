# ============================================================
# Level1EntityGenerator.psm1 -- Domain entity only
# ============================================================

function Invoke-GenerateEntity {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $fname = $Ctx.Tokens.FNAME
    $fDir  = $Ctx.FeatureDir
    $meta  = Get-PrimaryEntityMeta -Config $Ctx.Config
    $eName = $meta.Name
    $eSnake = $meta.Snake

    # Field declarations
    $fieldDecls = ($meta.Fields | ForEach-Object {
        "  final $($_.DartType) $($_.Name);"
    }) -join "`n"

    # Constructor params
    $ctorParams = ($meta.Fields | ForEach-Object {
        $req = if ($_.IsNullable) { '' } else { 'required ' }
        "    ${req}this.$($_.Name),"
    }) -join "`n"

    # copyWith params
    $copyParams = ($meta.Fields | ForEach-Object {
        "    $($_.DartType.TrimEnd('?'))? $($_.Name),"
    }) -join "`n"

    # copyWith body
    $copyBody = ($meta.Fields | ForEach-Object {
        "      $($_.Name): $($_.Name) ?? this.$($_.Name),"
    }) -join "`n"

    $content = @"
import 'package:equatable/equatable.dart';

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
  List<Object?> get props => [$($meta.Fields | ForEach-Object { $_.Name } | Join-String -Separator ', ')];
}
"@

    & $NewFile (Join-Path $fDir "domain\entities\${eSnake}_entity.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateEntity'

