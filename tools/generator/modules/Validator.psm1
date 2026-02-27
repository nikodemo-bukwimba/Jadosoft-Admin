# ============================================================
# Validator.psm1
# Validates feature.config.json against all schema rules.
# Returns a list of error strings. Empty list = valid.
# ============================================================

function Invoke-ConfigValidation {
    param([Parameter(Mandatory)][object]$Config)

    $errors = [System.Collections.Generic.List[string]]::new()

    # Script block used instead of a nested function to avoid module-scope leakage.
    $addError = { param([string]$msg) $errors.Add($msg) }

    # ── feature block ─────────────────────────────────────────
    if (-not $Config.feature) {
        & $addError "Missing required block: 'feature'"
        return $errors  # Cannot continue without feature block
    }

    $f = $Config.feature

    if (-not $f.name) {
        & $addError "feature.name is required"
    }
    elseif ($f.name -notmatch '^[a-z][a-z0-9_]*$') {
        & $addError "feature.name must be snake_case (got: '$($f.name)'"
    }

    if (-not $f.label) {
        & $addError "feature.label is required"
    }

    if (-not $f.purpose) {
        & $addError "feature.purpose is required (one sentence describing domain intent)"
    }

    if ($null -eq $f.maturity) {
        & $addError "feature.maturity is required"
    }
    elseif ($f.maturity -lt 0 -or $f.maturity -gt 5) {
        & $addError "feature.maturity must be 0-5 (got: $($f.maturity))"
    }

    if (-not $f.permission) {
        & $addError "feature.permission is required (RBAC slug prefix)"
    }
    elseif ($f.permission -notmatch '^[a-z][a-z0-9_]*$') {
        & $addError "feature.permission must be snake_case (got: '$($f.permission)'"
    }

    $maturity = [int](if ($null -eq $f.maturity) { -1 } else { $f.maturity })

    # ── storage block ─────────────────────────────────────────
    $hasStorage = $null -ne $Config.storage

    if ($maturity -eq 4 -and $hasStorage) {
        & $addError "Maturity 4 (Aggregator) must NOT declare storage — aggregators have no persistence"
    }

    if ($maturity -in @(1, 2, 3, 5) -and -not $hasStorage) {
        & $addError "Maturity $maturity requires a 'storage' block with remote and/or local set to true"
    }

    if ($hasStorage) {
        if ($null -eq $Config.storage.remote) {
            & $addError "storage.remote is required (true or false)"
        }
        if ($null -eq $Config.storage.local) {
            & $addError "storage.local is required (true or false)"
        }
        if ($Config.storage.remote -eq $false -and $Config.storage.local -eq $false) {
            & $addError "storage.remote and storage.local cannot both be false"
        }
    }

    # ── maturity-specific block requirements ──────────────────
    if ($maturity -ge 2 -and -not $Config.stateMachine) {
        & $addError "Maturity $maturity requires a 'stateMachine' block"
    }

    if ($maturity -ge 3 -and -not $Config.workflow) {
        & $addError "Maturity 3+ requires a 'workflow' block"
    }

    if ($maturity -eq 5 -and -not $Config.integration) {
        & $addError "Maturity 5 requires an 'integration' block"
    }

    # ── entities block ────────────────────────────────────────
    if ($maturity -ne 0 -and -not $Config.entities) {
        & $addError "Maturity $maturity requires an 'entities' block"
        return $errors
    }

    if ($Config.entities) {
        $entityNames = @($Config.entities.PSObject.Properties.Name)

        # Exactly one primary entity
        $primaryCount = 0
        foreach ($eName in $entityNames) {
            if ($Config.entities.$eName.primary -eq $true) { $primaryCount++ }
        }
        if ($maturity -ne 4 -and $primaryCount -ne 1) {
            & $addError "Exactly one entity must have 'primary: true' (found $primaryCount)"
        }

        foreach ($eName in $entityNames) {
            $entity = $Config.entities.$eName

            # table required if local storage
            if ($hasStorage -and $Config.storage.local -eq $true -and -not $entity.table) {
                & $addError "entities.$eName.table is required when storage.local is true"
            }

            # Validate fields
            if (-not $entity.fields) {
                & $addError "entities.$eName.fields is required"
            }
            else {
                $fieldNames = @($entity.fields.PSObject.Properties.Name)
                foreach ($fName in $fieldNames) {
                    $field = $entity.fields.$fName

                    # camelCase check
                    if ($fName -notmatch '^[a-z][a-zA-Z0-9]*$') {
                        & $addError "entities.$eName.fields.$fName must be camelCase"
                    }

                    # type required
                    if (-not $field.type) {
                        & $addError "entities.$eName.fields.$fName.type is required"
                    }

                    # Validate validation rules
                    if ($field.validation) {
                        $validRules = @(
                            'required', 'minLength', 'maxLength', 'min', 'max',
                            'regex', 'email', 'oneOf', 'unique'
                        )
                        foreach ($rule in $field.validation.PSObject.Properties.Name) {
                            if ($rule -notin $validRules) {
                                & $addError "entities.$eName.fields.$fName.validation.$rule is not a recognised rule"
                            }
                            $ruleObj = $field.validation.$rule
                            if ($null -eq $ruleObj.value) {
                                & $addError "entities.$eName.fields.$fName.validation.$rule.value is required"
                            }
                        }
                    }
                }
            }

            # Validate relationships
            if ($entity.relationships) {
                foreach ($rName in $entity.relationships.PSObject.Properties.Name) {
                    $rel = $entity.relationships.$rName

                    if (-not $rel.type) {
                        & $addError "entities.$eName.relationships.$rName.type is required"
                    }

                    $validRelTypes = @('hasMany', 'hasOne', 'belongsTo')
                    if ($rel.type -notin $validRelTypes) {
                        & $addError "entities.$eName.relationships.$rName.type must be hasMany, hasOne, or belongsTo"
                    }

                    if ($rel.type -in @('hasMany', 'hasOne')) {
                        # Internal relationship — entity must exist in same config
                        if (-not $rel.entity) {
                            & $addError "entities.$eName.relationships.$rName.entity is required"
                        }
                        elseif ($rel.entity -notin $entityNames) {
                            & $addError "entities.$eName.relationships.$rName.entity '$($rel.entity)' not found in this config"
                        }

                        if (-not $rel.foreign) {
                            & $addError "entities.$eName.relationships.$rName.foreign (foreign key field) is required"
                        }
                    }

                    if ($rel.type -eq 'belongsTo') {
                        # External relationship
                        if (-not $rel.entity) {
                            & $addError "entities.$eName.relationships.$rName.entity is required"
                        }
                        if (-not $rel.feature) {
                            & $addError "entities.$eName.relationships.$rName.feature is required for external belongsTo"
                        }
                        if (-not $rel.foreignKey) {
                            & $addError "entities.$eName.relationships.$rName.foreignKey is required"
                        }
                        if (-not $rel.displayField) {
                            & $addError "entities.$eName.relationships.$rName.displayField is required"
                        }
                    }
                }
            }

            # Validate UI hints
            if ($entity.ui) {
                $allFieldNames = if ($entity.fields) {
                    @($entity.fields.PSObject.Properties.Name)
                }
                else { @() }

                $allRelNames = if ($entity.relationships) {
                    @($entity.relationships.PSObject.Properties.Name)
                }
                else { @() }

                # form.inline must only reference hasMany internal relationships
                if ($entity.ui.form -and $entity.ui.form.inline) {
                    foreach ($inlineName in $entity.ui.form.inline) {
                        if ($inlineName -notin $allRelNames) {
                            & $addError "entities.$eName.ui.form.inline '$inlineName' must reference a declared relationship"
                        }
                        else {
                            $inlineRel = $entity.relationships.$inlineName
                            if ($inlineRel.type -ne 'hasMany') {
                                & $addError "entities.$eName.ui.form.inline '$inlineName' must be a hasMany relationship"
                            }
                        }
                    }
                }
            }
        }
    }

    # ── stateMachine block ────────────────────────────────────
    if ($Config.stateMachine -and $Config.entities) {
        $sm = $Config.stateMachine
        $entityNames = @($Config.entities.PSObject.Properties.Name)

        if (-not $sm.entity) {
            & $addError "stateMachine.entity is required"
        }
        elseif ($sm.entity -notin $entityNames) {
            & $addError "stateMachine.entity '$($sm.entity)' not found in entities"
        }

        if (-not $sm.field) {
            & $addError "stateMachine.field is required"
        }

        if (-not $sm.initial) {
            & $addError "stateMachine.initial is required"
        }

        if (-not $sm.states -or $sm.states.Count -eq 0) {
            & $addError "stateMachine.states must declare at least one state"
        }

        $stateNames = @($sm.states | ForEach-Object { $_.name })

        if ($sm.initial -notin $stateNames) {
            & $addError "stateMachine.initial '$($sm.initial)' not found in stateMachine.states"
        }

        $permPrefix = $Config.feature.permission
        foreach ($t in $sm.transitions) {
            if (-not $t.name) {
                & $addError "stateMachine.transitions: each transition must have a name"
            }
            if (-not $t.to) {
                & $addError "stateMachine.transitions.$($t.name): 'to' is required"
            }
            if (-not $t.from -or $t.from.Count -eq 0) {
                & $addError "stateMachine.transitions.$($t.name): 'from' must list at least one state"
            }

            foreach ($fromState in $t.from) {
                if ($fromState -notin $stateNames) {
                    & $addError "stateMachine.transitions.$($t.name).from '$fromState' not in declared states"
                }
            }

            if ($t.to -notin $stateNames) {
                & $addError "stateMachine.transitions.$($t.name).to '$($t.to)' not in declared states"
            }

            if ($t.to -eq $sm.initial) {
                & $addError "stateMachine.transitions.$($t.name): cannot transition TO the initial state '$($sm.initial)'"
            }

            if ($t.permission -and -not $t.permission.StartsWith("$permPrefix.")) {
                & $addError "stateMachine.transitions.$($t.name).permission must start with '$permPrefix.' (got: '$($t.permission)')"
            }
        }
    }

    return $errors
}

Export-ModuleMember -Function Invoke-ConfigValidation