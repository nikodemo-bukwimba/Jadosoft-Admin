# ============================================================
# MetaHelpers.psm1 - Entity Metadata Resolver
# ============================================================

function Get-PrimaryEntityMeta {
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )

    if (-not $Config.entities) {
        throw "Config has no 'entities' section."
    }

    $primaryEntry = $null
    foreach ($entityName in $Config.entities.PSObject.Properties.Name) {
        $entity = $Config.entities.$entityName
        if ($entity.primary -eq $true) {
            $primaryEntry = @{ Name = $entityName; Data = $entity }
            break
        }
    }

    if (-not $primaryEntry) {
        throw "No primary entity defined in config."
    }

    $entityName = $primaryEntry.Name
    $entity = $primaryEntry.Data

    if (-not $entity.fields) {
        throw "Primary entity '$entityName' has no fields."
    }

    $fields = @()

    foreach ($fieldName in $entity.fields.PSObject.Properties.Name) {
        $field = $entity.fields.$fieldName

        $isNullable = if ($field.PSObject.Properties.Name -contains "nullable") { $field.nullable } else { $false }
        $baseType = $field.type
        $dartType = if ($isNullable) { $baseType + '?' } else { $baseType }

        # SnakeCase: -creplace is case-SENSITIVE so only uppercase get underscore prefix
        $snakeCase = ($fieldName -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()

        # FIX: title-case the label so "createdAt" -> "Created At" not "created At"
        $rawLabel = ($fieldName -creplace '([A-Z])', ' $1').Trim()
        $labelValue = (Get-Culture).TextInfo.ToTitleCase($rawLabel.ToLower())

        $fields += [pscustomobject]@{
            Name       = $fieldName
            SnakeCase  = $snakeCase
            Type       = $baseType
            DartType   = $dartType
            IsNullable = $isNullable
            IsPrimary  = if ($field.PSObject.Properties.Name -contains "primary") { $field.primary } else { $false }
            IsReadonly = if ($field.PSObject.Properties.Name -contains "readonly") { $field.readonly } else { $false }
            Validation = if ($field.PSObject.Properties.Name -contains "validation") { $field.validation } else { $null }
            Label      = $labelValue
        }
    }

    # Pass through UI and API config from entity block
    $ui = if ($entity.PSObject.Properties.Name -contains "ui") { $entity.ui }  else { $null }
    $api = if ($entity.PSObject.Properties.Name -contains "api") { $entity.api } else { $null }

    return [pscustomobject]@{
        Name   = $entityName
        Snake  = ($entityName -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
        Fields = $fields
        Ui     = $ui
        Api    = $api
    }
}

function Get-JsonParseExpr {
    param(
        [string]$ConfigType,
        [string]$JsonKey,
        [bool]$Nullable
    )

    switch ($ConfigType) {
        "String" {
            if ($Nullable) { return "json['$JsonKey'] as String?" }
            else { return "json['$JsonKey'] as String" }
        }
        "int" {
            if ($Nullable) { return "json['$JsonKey'] as int?" }
            else { return "json['$JsonKey'] as int" }
        }
        "double" {
            if ($Nullable) { return "(json['$JsonKey'] as num?)?.toDouble()" }
            else { return "(json['$JsonKey'] as num).toDouble()" }
        }
        "bool" {
            if ($Nullable) { return "json['$JsonKey'] as bool?" }
            else { return "json['$JsonKey'] as bool? ?? false" }
        }
        "DateTime" {
            if ($Nullable) {
                return "json['$JsonKey'] != null ? DateTime.parse(json['$JsonKey'] as String) : null"
            }
            return "DateTime.parse(json['$JsonKey'] as String)"
        }
        default { return "json['$JsonKey']" }
    }
}

function Get-JsonWriteExpr {
    param(
        [string]$ConfigType,
        [string]$FieldName,
        [bool]$Nullable
    )

    switch ($ConfigType) {
        "DateTime" {
            if ($Nullable) {
                return ($FieldName + "?.toIso8601String()")
            }
            else {
                return ($FieldName + ".toIso8601String()")
            }
        }
        default {
            return $FieldName
        }
    }
}

# -- Per-field validation line generation (for use cases) -----
function Get-ValidationLines {
    param(
        [Parameter(Mandatory)][string]$FieldName,
        [Parameter(Mandatory)][string]$ConfigType,
        [Parameter(Mandatory)]$Validation
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $accessor = "p.$FieldName"
    $rawLabel = ($FieldName -creplace '([A-Z])', ' $1').Trim()
    $label = (Get-Culture).TextInfo.ToTitleCase($rawLabel.ToLower())
    # FIX: removed stray "Label = $label" that was invoking Windows label.exe
    # and injecting "Access Denied" into the generated Dart code

    $vProps = $Validation.PSObject.Properties

    $req = $vProps | Where-Object { $_.Name -eq 'required' } | Select-Object -First 1
    if ($req -and $req.Value.value -eq $true) {
        $msg = if ($req.Value.message) { $req.Value.message } else { "$label is required" }
        if ($ConfigType -eq 'String' -or $ConfigType -eq 'String (multiline)') {
            $lines.Add("    if ($accessor.trim().isEmpty) {")
        }
        else {
            $lines.Add("    if ($accessor == null) {")
        }
        $lines.Add("      return Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $minLen = $vProps | Where-Object { $_.Name -eq 'minLength' } | Select-Object -First 1
    if ($minLen) {
        $msg = if ($minLen.Value.message) { $minLen.Value.message } else { "$label too short" }
        $val = $minLen.Value.value
        $lines.Add("    if ($accessor.length < $val) {")
        $lines.Add("      return Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $maxLen = $vProps | Where-Object { $_.Name -eq 'maxLength' } | Select-Object -First 1
    if ($maxLen) {
        $msg = if ($maxLen.Value.message) { $maxLen.Value.message } else { "$label too long" }
        $val = $maxLen.Value.value
        $lines.Add("    if ($accessor.length > $val) {")
        $lines.Add("      return Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $min = $vProps | Where-Object { $_.Name -eq 'min' } | Select-Object -First 1
    if ($min) {
        $msg = if ($min.Value.message) { $min.Value.message } else { "$label too small" }
        $val = $min.Value.value
        $lines.Add("    if ($accessor < $val) {")
        $lines.Add("      return Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $max = $vProps | Where-Object { $_.Name -eq 'max' } | Select-Object -First 1
    if ($max) {
        $msg = if ($max.Value.message) { $max.Value.message } else { "$label too large" }
        $val = $max.Value.value
        $lines.Add("    if ($accessor > $val) {")
        $lines.Add("      return Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    return $lines
}


Export-ModuleMember -Function @(
    'Get-JsonParseExpr',
    'Get-JsonWriteExpr',
    'Get-PrimaryEntityMeta',
    'Get-ValidationLines'
)