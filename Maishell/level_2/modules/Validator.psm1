# ============================================================
# Validator.psm1
# FIX: feature.permission is optional -- if provided, must be snake_case.
# ============================================================

function Invoke-ConfigValidation {
    param([Parameter(Mandatory)][psobject]$Config)
    $errors = [System.Collections.Generic.List[string]]::new()
    _Validate-FeatureBlock -Config $Config -Errors $errors
    $maturity = $Config.feature.maturity
    if ($null -ne $maturity) {
        _Validate-MaturityGates -Config $Config -Maturity $maturity -Errors $errors
        if ($maturity -ge 1 -and $maturity -ne 4 -and $null -ne $Config.entities) {
            _Validate-Entities -Config $Config -Errors $errors
        }
    }
    return ,$errors.ToArray()
}

function _Validate-FeatureBlock {
    param([psobject]$Config, [System.Collections.Generic.List[string]]$Errors)
    if ($null -eq $Config.feature) { $Errors.Add("Missing required 'feature' block"); return }
    $f = $Config.feature
    if ([string]::IsNullOrWhiteSpace($f.name)) { $Errors.Add("feature.name is required") }
    elseif ($f.name -notmatch '^[a-z][a-z0-9_]*$') { $Errors.Add("feature.name must be snake_case. Got: '$($f.name)'") }
    if ([string]::IsNullOrWhiteSpace($f.label))   { $Errors.Add("feature.label is required") }
    if ([string]::IsNullOrWhiteSpace($f.purpose))  { $Errors.Add("feature.purpose is required") }
    if ($null -eq $f.maturity) { $Errors.Add("feature.maturity is required") }
    elseif ($f.maturity -lt 0 -or $f.maturity -gt 5) { $Errors.Add("feature.maturity must be 0-5. Got: $($f.maturity)") }
    # permission -- optional. If provided, must be snake_case.
    if (-not [string]::IsNullOrWhiteSpace($f.permission)) {
        if ($f.permission -notmatch '^[a-z][a-z0-9_]*$') { $Errors.Add("feature.permission must be snake_case. Got: '$($f.permission)'") }
    }
}

function _Validate-MaturityGates {
    param([psobject]$Config, [int]$Maturity, [System.Collections.Generic.List[string]]$Errors)
    if ($Maturity -eq 0) {
        if ($null -ne $Config.storage)      { $Errors.Add("Level 0 features must NOT declare a 'storage' block") }
        if ($null -ne $Config.stateMachine) { $Errors.Add("Level 0 features must NOT declare a 'stateMachine' block") }
    }
    if ($Maturity -ge 1 -and $Maturity -ne 4) {
        if ($null -eq $Config.storage) { $Errors.Add("Level $Maturity features require a 'storage' block") }
        elseif (-not $Config.storage.remote -and -not $Config.storage.local) {
            $Errors.Add("storage block must declare at least one of: remote, local")
        }
        if ($null -eq $Config.entities) { $Errors.Add("Level $Maturity features require an 'entities' block") }
    }
    if ($Maturity -ge 2 -and $Maturity -ne 4) {
        if ($null -eq $Config.stateMachine) { $Errors.Add("Level $Maturity features require a 'stateMachine' block") }
    }
    if ($Maturity -eq 4) {
        if ($null -ne $Config.storage) { $Errors.Add("Level 4 aggregator features must NOT declare a 'storage' block") }
    }
}

function _Validate-Entities {
    param([psobject]$Config, [System.Collections.Generic.List[string]]$Errors)
    $entityProps = $Config.entities.PSObject.Properties
    if ($entityProps.Count -eq 0) { $Errors.Add("entities block must contain at least one entity"); return }

    $primaryCount = 0
    foreach ($ep in $entityProps) {
        $eName = $ep.Name
        $eDef  = $ep.Value
        if ($eDef.primary -eq $true) { $primaryCount++ }

        if ($null -eq $eDef.fields) { $Errors.Add("Entity '$eName' must declare a 'fields' block"); continue }
        $fieldProps = $eDef.fields.PSObject.Properties
        if ($fieldProps.Count -eq 0) { $Errors.Add("Entity '$eName' must have at least one field") }

        $hasPK = $false
        foreach ($fp in $fieldProps) {
            $fName = $fp.Name
            $fDef  = $fp.Value
            if ($fName -cmatch '^[A-Z]') { $Errors.Add("Field '$eName.$fName' must be camelCase") }
            if ($fDef.primary -eq $true) { $hasPK = $true }
            $validTypes = @('String','int','double','bool','DateTime')
            if ($fDef.type -and $fDef.type -notin $validTypes -and $fDef.type -notmatch 'Status$' -and $fDef.type -notmatch '^List<' -and $fDef.type -notmatch '^Map<') {
                $Errors.Add("Field '$eName.$fName' has unknown type '$($fDef.type)'")
            }
        }
        if (-not $hasPK) { $Errors.Add("Entity '$eName' must have at least one field with primary: true") }

        if ($eDef.ui -and $eDef.ui.form) {
            $declaredFields = @($fieldProps | ForEach-Object { $_.Name })
            foreach ($formType in @('create','edit')) {
                $formFields = $eDef.ui.form.$formType
                if ($null -ne $formFields) {
                    foreach ($ff in $formFields) {
                        if ($ff -notin $declaredFields) {
                            $Errors.Add("UI form.$formType references undeclared field '$ff' in entity '$eName'")
                        }
                        $ffDef = $eDef.fields.$ff
                        if ($ffDef -and $ffDef.readonly -eq $true) {
                            $Errors.Add("UI form.$formType includes readonly field '$ff' in entity '$eName'")
                        }
                    }
                }
            }
        }

        if ($eDef.relationships) {
            $relProps = $eDef.relationships.PSObject.Properties
            $declaredEntityNames = @($entityProps | ForEach-Object { $_.Name })
            foreach ($rp in $relProps) {
                $rName = $rp.Name
                $rDef  = $rp.Value
                if ($rDef.type -eq 'hasMany' -or $rDef.type -eq 'hasOne') {
                    if ($rDef.entity -notin $declaredEntityNames) {
                        $Errors.Add("Relationship '$eName.$rName' references undeclared entity '$($rDef.entity)'")
                    }
                }
                if ($rDef.type -eq 'belongsTo') {
                    if (-not $rDef.entity)  { $Errors.Add("belongsTo '$eName.$rName' must declare 'entity'") }
                    if (-not $rDef.feature) { $Errors.Add("belongsTo '$eName.$rName' must declare 'feature'") }
                }
            }
        }
    }
    if ($primaryCount -eq 0) { $Errors.Add("Exactly one entity must have primary: true (found 0)") }
    if ($primaryCount -gt 1) { $Errors.Add("Exactly one entity must have primary: true (found $primaryCount)") }
}

Export-ModuleMember -Function 'Invoke-ConfigValidation'

