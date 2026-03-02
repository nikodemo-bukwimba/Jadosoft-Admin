# ============================================================
# MetaHelpers.psm1 — Entity Metadata Resolver
# ============================================================

function Get-PrimaryEntityMeta {
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )

    if (-not $Config.entities) {
        throw "Config has no 'entities' section."
    }

    # Find primary entity
    $primaryEntry = $null

    foreach ($entityName in $Config.entities.PSObject.Properties.Name) {
        $entity = $Config.entities.$entityName
        if ($entity.primary -eq $true) {
            $primaryEntry = @{
                Name = $entityName
                Data = $entity
            }
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

        $fields += [pscustomobject]@{
            Name       = $fieldName
            DartType   = $field.type
            IsNullable = if ($field.PSObject.Properties.Name -contains "nullable") {
                $field.nullable
            }
            else { $false }
            IsPrimary  = if ($field.PSObject.Properties.Name -contains "primary") {
                $field.primary
            }
            else { $false }
            IsReadonly = if ($field.PSObject.Properties.Name -contains "readonly") {
                $field.readonly
            }
            else { $false }
        }
    }

    return [pscustomobject]@{
        Name   = $entityName
        Snake  = ($entityName -replace '([A-Z])', '_$1').TrimStart('_').ToLower()
        Fields = $fields
    }
}
function Get-JsonParseExpr {
    param(
        [string]$ConfigType,
        [string]$JsonKey,
        [bool]$Nullable
    )

    switch ($ConfigType) {
        "String" { return $Nullable ? "json['$JsonKey'] as String?" : "json['$JsonKey'] as String" }
        "int" { return $Nullable ? "json['$JsonKey'] as int?" : "json['$JsonKey'] as int" }
        "double" { return $Nullable ? "json['$JsonKey'] as double?" : "json['$JsonKey'] as double" }
        "bool" { return $Nullable ? "json['$JsonKey'] as bool?" : "json['$JsonKey'] as bool" }
        "DateTime" {
            if ($Nullable) {
                return "json['$JsonKey'] != null ? DateTime.parse(json['$JsonKey']) : null"
            }
            return "DateTime.parse(json['$JsonKey'])"
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
            return $Nullable
            Where-Object "$FieldName?.toIso8601String()"
            : "$FieldName.toIso8601String()"
        }
        default {
            return $FieldName
        }
    }
}


Export-ModuleMember -Function @(
    'Get-JsonParseExpr',
    'Get-JsonWriteExpr',
    'Get-PrimaryEntityMeta'

)