# ============================================================
# TemplateEngine.psm1
# Token substitution engine + Dart code generation helpers.
#
# Token convention (conflict-free with Dart syntax):
#   FNAME   → snake_case feature name  (project)
#   FCLASS  → PascalCase class name    (Project)
#   FUPPER  → UPPER_CASE               (PROJECT)
#   FLABEL  → Human label              (Project)
#   FPERM   → Permission prefix        (projects)
# ============================================================

# ── Core token replacement ────────────────────────────────────
function Invoke-TokenReplace {
    param(
        [Parameter(Mandatory)][string]$Template,
        [Parameter(Mandatory)][hashtable]$Tokens
    )

    $result = $Template
    foreach ($key in $Tokens.Keys) {
        $result = $result.Replace($key, $Tokens[$key])
    }
    return $result
}

# ── Dart type helpers ─────────────────────────────────────────
function Get-DartType {
    param([string]$ConfigType, [bool]$Nullable = $false)

    $baseType = switch -Wildcard ($ConfigType) {
        'String' { 'String' }
        'String (multiline)' { 'String' }
        'int' { 'int' }
        'double' { 'double' }
        'bool' { 'bool' }
        'DateTime' { 'DateTime' }
        'DateTime (time)' { 'DateTime' }
        '*Status' { $ConfigType }   # e.g. ProjectStatus
        default { $ConfigType }
    }

    # FIX: was `return if (...) { } else { }` — invalid PowerShell syntax.
    # Wrapped in $() so the if-expression is evaluated as a value before return.
    return $(if ($Nullable) { "$baseType?" } else { $baseType })
}

function Get-FormWidget {
    param([string]$ConfigType, [string]$FieldName)

    switch -Wildcard ($ConfigType) {
        'String' { return 'TextFormField' }
        'String (multiline)' { return 'TextFormField' }   # + maxLines: 5
        'int' { return 'TextFormField' }   # + keyboardType: number
        'double' { return 'TextFormField' }   # + keyboardType: decimal
        'bool' { return 'SwitchListTile' }
        'DateTime' { return 'DatePickerFormField' }
        'DateTime (time)' { return 'TimePickerFormField' }
        '*Status' { return 'DropdownButtonFormField' }
        default { return 'TextFormField' }
    }
}

# ── Dart field generation ─────────────────────────────────────
function Get-EntityFields {
    param([object]$Fields, [string]$Indent = '  ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        $dartType = Get-DartType -ConfigType $f.type -Nullable ($f.nullable -eq $true)
        $lines.Add("${Indent}final $dartType $fName;")
    }
    return $lines -join "`n"
}

function Get-ConstructorParams {
    param([object]$Fields, [string]$Indent = '    ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        $required = if ($f.nullable -eq $true) { '' } else { 'required ' }
        $lines.Add("${Indent}${required}this.$fName,")
    }
    return $lines -join "`n"
}

function Get-CopyWithParams {
    param([object]$Fields, [string]$Indent = '    ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        $dartType = Get-DartType -ConfigType $f.type -Nullable $true   # always nullable in copyWith
        $lines.Add("${Indent}$dartType $fName,")
    }
    return $lines -join "`n"
}

function Get-CopyWithBody {
    param([object]$Fields, [string]$Indent = '      ', [string]$ClassName)

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $lines.Add("${Indent}${fName}: ${fName} ?? this.${fName},")
    }
    return $lines -join "`n"
}

# ── Validation gate generation ────────────────────────────────
function Get-ValidationGate {
    param([object]$Fields, [string]$ParamsVar = 'p', [string]$Indent = '    ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        if (-not $f.validation) { continue }
        if ($f.primary -eq $true) { continue }   # server-assigned, never in params
        # readonly fields ARE validated on create (e.g. ownerId: required but immutable after)

        $val = $f.validation
        $accessor = "$ParamsVar.$fName"

        if ($val.required -and $val.required.value -eq $true) {
            $msg = if ($val.required.message) { $val.required.message } else { "$fName is required" }
            $lines.Add("${Indent}if ($accessor == null || $accessor.toString().trim().isEmpty) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.minLength) {
            $msg = if ($val.minLength.message) { $val.minLength.message } else { "$fName is too short" }
            $len = $val.minLength.value
            $lines.Add("${Indent}if ($accessor.length < $len) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.maxLength) {
            $msg = if ($val.maxLength.message) { $val.maxLength.message } else { "$fName is too long" }
            $len = $val.maxLength.value
            $lines.Add("${Indent}if ($accessor.length > $len) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.min) {
            $msg = if ($val.min.message) { $val.min.message } else { "$fName is too small" }
            $min = $val.min.value
            $lines.Add("${Indent}if ($accessor < $min) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.max) {
            $msg = if ($val.max.message) { $val.max.message } else { "$fName is too large" }
            $max = $val.max.value
            $lines.Add("${Indent}if ($accessor > $max) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.email -and $val.email.value -eq $true) {
            $msg = if ($val.email.message) { $val.email.message } else { "Invalid email address" }
            $lines.Add("${Indent}if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch($accessor)) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.regex) {
            $msg = if ($val.regex.message) { $val.regex.message } else { "$fName has invalid format" }
            $regex = $val.regex.value
            $lines.Add("${Indent}if (!RegExp(r'$regex').hasMatch($accessor)) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.oneOf) {
            $msg = if ($val.oneOf.message) { $val.oneOf.message } else { "$fName has invalid value" }
            $options = ($val.oneOf.value | ForEach-Object { "'$_'" }) -join ', '
            $lines.Add("${Indent}const _valid${fName} = [$options];")
            $lines.Add("${Indent}if (!_valid${fName}.contains($accessor)) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }
    }

    # FIX: was `return if (...) { } else { }` — invalid PowerShell syntax.
    # Wrapped in $() so the if-expression is evaluated as a value before return.
    return $(if ($lines.Count -gt 0) {
            $lines -join "`n"
        }
        else {
            "${Indent}// No validation rules declared for this entity"
        })
}

# ── Form field widget generation ──────────────────────────────
function Get-FormFields {
    param([object]$Fields, [string[]]$FieldList, [string]$Indent = '          ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $FieldList) {
        if (-not $Fields.PSObject.Properties[$fName]) { continue }
        $f = $Fields.$fName
        $widget = Get-FormWidget -ConfigType $f.type -FieldName $fName
        $label = (Get-Culture).TextInfo.ToTitleCase($fName -replace '([A-Z])', ' $1')

        switch ($widget) {
            'SwitchListTile' {
                $lines.Add("${Indent}SwitchListTile(")
                $lines.Add("${Indent}  title: const Text('$label'),")
                $lines.Add("${Indent}  value: _${fName}Value,")
                $lines.Add("${Indent}  onChanged: (v) => setState(() => _${fName}Value = v),")
                $lines.Add("${Indent}),")
            }
            'DatePickerFormField' {
                $lines.Add("${Indent}// TODO: DatePickerFormField for $fName")
                $lines.Add("${Indent}TextFormField(")
                $lines.Add("${Indent}  decoration: const InputDecoration(labelText: '$label'),")
                $lines.Add("${Indent}  controller: _${fName}Controller,")
                $lines.Add("${Indent}  readOnly: true,")
                $lines.Add("${Indent}  onTap: () => _pick${fName}Date(context),")
                if ($f.validation -and $f.validation.required -and $f.validation.required.value -eq $true) {
                    $msg = if ($f.validation.required.message) { $f.validation.required.message } else { "$fName is required" }
                    $lines.Add("${Indent}  validator: (v) => (v == null || v.isEmpty) ? '$msg' : null,")
                }
                $lines.Add("${Indent}),")
            }
            default {
                $kbType = switch -Wildcard ($f.type) {
                    'int' { "`n${Indent}  keyboardType: TextInputType.number," }
                    'double' { "`n${Indent}  keyboardType: const TextInputType.numberWithOptions(decimal: true)," }
                    'String (multiline)' { "`n${Indent}  maxLines: 5," }
                    default { '' }
                }
                $lines.Add("${Indent}TextFormField(")
                $lines.Add("${Indent}  decoration: const InputDecoration(labelText: '$label'),")
                $lines.Add("${Indent}  controller: _${fName}Controller,$kbType")

                $validatorLines = @()
                if ($f.validation -and $f.validation.required -and $f.validation.required.value -eq $true) {
                    $msg = if ($f.validation.required.message) { $f.validation.required.message } else { "$fName is required" }
                    $validatorLines += "if (v == null || v.trim().isEmpty) return '$msg';"
                }
                if ($f.validation -and $f.validation.minLength) {
                    $msg = if ($f.validation.minLength.message) { $f.validation.minLength.message } else { "$fName is too short" }
                    $len = $f.validation.minLength.value
                    $validatorLines += "if (v!.length < $len) return '$msg';"
                }
                if ($f.validation -and $f.validation.maxLength) {
                    $msg = if ($f.validation.maxLength.message) { $f.validation.maxLength.message } else { "$fName is too long" }
                    $len = $f.validation.maxLength.value
                    $validatorLines += "if (v!.length > $len) return '$msg';"
                }

                if ($validatorLines.Count -gt 0) {
                    $validatorBody = ($validatorLines | ForEach-Object { "${Indent}    $_" }) -join "`n"
                    $lines.Add("${Indent}  validator: (v) {")
                    $lines.Add($validatorBody)
                    $lines.Add("${Indent}    return null;")
                    $lines.Add("${Indent}  },")
                }

                $lines.Add("${Indent}),")
            }
        }
        $lines.Add("${Indent}const SizedBox(height: 16),")
    }

    return $lines -join "`n"
}

# ── JSON fromJson field mapping generation ────────────────────
function Get-FromJsonFields {
    param([object]$Fields, [string]$Indent = '      ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        $nullable = $f.nullable -eq $true

        $expr = switch -Wildcard ($f.type) {
            'DateTime' {
                if ($nullable) { "json['$fName'] != null ? DateTime.parse(json['$fName'] as String) : null" }
                else { "DateTime.parse(json['$fName'] as String)" }
            }
            'DateTime (time)' {
                if ($nullable) { "json['$fName'] != null ? DateTime.parse(json['$fName'] as String) : null" }
                else { "DateTime.parse(json['$fName'] as String)" }
            }
            'int' {
                if ($nullable) { "json['$fName'] as int?" }
                else { "json['$fName'] as int" }
            }
            'double' {
                if ($nullable) { "(json['$fName'] as num?)?.toDouble()" }
                else { "(json['$fName'] as num).toDouble()" }
            }
            'bool' {
                if ($nullable) { "json['$fName'] as bool?" }
                else { "json['$fName'] as bool? ?? false" }
            }
            default {
                if ($nullable) { "json['$fName'] as String?" }
                else { "json['$fName'] as String" }
            }
        }
        $lines.Add("${Indent}${fName}: $expr,")
    }
    return $lines -join "`n"
}

# ── JSON toJson field mapping generation ─────────────────────
function Get-ToJsonFields {
    param([object]$Fields, [string]$Indent = '      ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        $expr = switch -Wildcard ($f.type) {
            'DateTime' { "$fName?.toIso8601String()" }
            'DateTime (time)' { "$fName?.toIso8601String()" }
            '*Status' { "$fName.name" }
            default { $fName }
        }
        $lines.Add("${Indent}'${fName}': ${expr},")
    }
    return $lines -join "`n"
}

Export-ModuleMember -Function @(
    'Invoke-TokenReplace',
    'Get-DartType',
    'Get-FormWidget',
    'Get-EntityFields',
    'Get-ConstructorParams',
    'Get-CopyWithParams',
    'Get-CopyWithBody',
    'Get-ValidationGate',
    'Get-FormFields',
    'Get-FromJsonFields',
    'Get-ToJsonFields'
)