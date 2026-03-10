# ============================================================
# Validator.psm1
# Config schema validation. Returns ALL errors, never halts on first.
# Each maturity level adds its own rules via the gate pattern.
# ============================================================

<#
.SYNOPSIS
    Validates a feature.config.json against all applicable rules.
.OUTPUTS
    Array of error message strings. Empty array = valid.
#>
function Invoke-ConfigValidation {
    param([Parameter(Mandatory)][psobject]$Config)

    $errors = [System.Collections.Generic.List[string]]::new()

    # ── Feature block (required for ALL levels) ────────────
    _Validate-FeatureBlock -Config $Config -Errors $errors

    # ── Maturity-specific gates ────────────────────────────
    $maturity = $Config.feature.maturity

    if ($null -ne $maturity) {
        _Validate-MaturityGates -Config $Config -Maturity $maturity -Errors $errors
    }

    return , $errors.ToArray()
}

function _Validate-FeatureBlock {
    param([psobject]$Config, [System.Collections.Generic.List[string]]$Errors)

    if ($null -eq $Config.feature) {
        $Errors.Add("Missing required 'feature' block")
        return
    }

    $f = $Config.feature

    # name — required, snake_case only
    if ([string]::IsNullOrWhiteSpace($f.name)) {
        $Errors.Add("feature.name is required")
    }
    elseif ($f.name -notmatch '^[a-z][a-z0-9_]*$') {
        $Errors.Add("feature.name must be snake_case (lowercase letters, digits, underscores). Got: '$($f.name)'")
    }

    # label — required
    if ([string]::IsNullOrWhiteSpace($f.label)) {
        $Errors.Add("feature.label is required")
    }

    # purpose — required
    if ([string]::IsNullOrWhiteSpace($f.purpose)) {
        $Errors.Add("feature.purpose is required")
    }

    # maturity — required, must be 0-5
    if ($null -eq $f.maturity) {
        $Errors.Add("feature.maturity is required")
    }
    elseif ($f.maturity -isnot [int] -and $f.maturity -isnot [long]) {
        $Errors.Add("feature.maturity must be an integer 0-5. Got: '$($f.maturity)'")
    }
    elseif ($f.maturity -lt 0 -or $f.maturity -gt 5) {
        $Errors.Add("feature.maturity must be 0-5. Got: $($f.maturity)")
    }

    # permission — optional. If provided, must be snake_case.
    if (-not [string]::IsNullOrWhiteSpace($f.permission)) {
        if ($f.permission -notmatch '^[a-z][a-z0-9_]*$') {
            $Errors.Add("feature.permission must be snake_case. Got: '$($f.permission)'")
        }
    }
}

function _Validate-MaturityGates {
    param([psobject]$Config, [int]$Maturity, [System.Collections.Generic.List[string]]$Errors)

    # ── Level 0: No storage, no stateMachine, no entities required ──
    if ($Maturity -eq 0) {
        if ($null -ne $Config.storage) {
            $Errors.Add("Level 0 features must NOT declare a 'storage' block (no persistence at Level 0)")
        }
        if ($null -ne $Config.stateMachine) {
            $Errors.Add("Level 0 features must NOT declare a 'stateMachine' block")
        }
    }

    # ── Level 1+: Storage required ─────────────────────────
    if ($Maturity -ge 1 -and $Maturity -ne 4) {
        if ($null -eq $Config.storage) {
            $Errors.Add("Level $Maturity features require a 'storage' block")
        }
        elseif (-not $Config.storage.remote -and -not $Config.storage.local) {
            $Errors.Add("storage block must declare at least one of: remote, local")
        }
    }

    # ── Level 1+: Entities required (except Level 4) ──────
    if ($Maturity -ge 1 -and $Maturity -ne 4) {
        if ($null -eq $Config.entities) {
            $Errors.Add("Level $Maturity features require an 'entities' block")
        }
    }

    # ── Level 2+: StateMachine required ────────────────────
    if ($Maturity -ge 2 -and $Maturity -ne 4) {
        if ($null -eq $Config.stateMachine) {
            $Errors.Add("Level $Maturity features require a 'stateMachine' block")
        }
    }

    # ── Level 4: No storage (aggregators have no persistence) ──
    if ($Maturity -eq 4) {
        if ($null -ne $Config.storage) {
            $Errors.Add("Level 4 aggregator features must NOT declare a 'storage' block")
        }
    }
}

Export-ModuleMember -Function 'Invoke-ConfigValidation'