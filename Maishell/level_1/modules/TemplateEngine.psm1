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

# ── Shared helper: PascalCase → snake_case ────────────────────
# Single canonical definition — all other modules import from here.
function ConvertTo-SnakeCase {
    param([Parameter(Mandatory)][string]$PascalCase)
    return ($PascalCase -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
}

# ── Shared helper: camelCase/snake_case → Human Label ─────────
function ConvertTo-HumanLabel {
    param([Parameter(Mandatory)][string]$Name)
    # camelCase → spaced: insert space before uppercase
    $spaced = $Name -creplace '([A-Z])', ' $1'
    # snake_case → spaced
    $spaced = $spaced.Replace('_', ' ')
    # Title-case each word
    return (Get-Culture).TextInfo.ToTitleCase($spaced.Trim().ToLower())
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
        '*Status' { $ConfigType }
        default { $ConfigType }
    }

    if ($Nullable) { return ($baseType + '?') } else { return $baseType }
}

function Get-FormWidget {
    param([string]$ConfigType, [string]$FieldName)

    switch -Wildcard ($ConfigType) {
        'String' { return 'TextFormField' }
        'String (multiline)' { return 'TextFormField' }
        'int' { return 'TextFormField' }
        'double' { return 'TextFormField' }
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
        # Always nullable in copyWith signature
        $lines.Add("${Indent} $fName,")
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
    param([object]$Fields, [string]$ParamsVar = 'params', [string]$Indent = '    ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $Fields.PSObject.Properties.Name) {
        $f = $Fields.$fName
        if (-not $f.validation) { continue }
        if ($f.primary -eq $true) { continue }

        $val = $f.validation
        $accessor = "$ParamsVar.$fName"
        $label = ConvertTo-HumanLabel $fName

        if ($val.required -and $val.required.value -eq $true) {
            $msg = if ($val.required.message) { $val.required.message } else { "$label is required" }
            # For String types, check null and empty
            if ($f.type -eq 'String' -or $f.type -eq 'String (multiline)') {
                $lines.Add("${Indent}if ($accessor.trim().isEmpty) {")
            }
            else {
                $lines.Add("${Indent}if ($accessor == null) {")
            }
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.minLength) {
            $msg = if ($val.minLength.message) { $val.minLength.message } else { "$label too short" }
            $len = $val.minLength.value
            $lines.Add("${Indent}if ($accessor.length < $len) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.maxLength) {
            $msg = if ($val.maxLength.message) { $val.maxLength.message } else { "$label too long" }
            $len = $val.maxLength.value
            $lines.Add("${Indent}if ($accessor.length > $len) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.min) {
            $msg = if ($val.min.message) { $val.min.message } else { "$label too small" }
            $min = $val.min.value
            $lines.Add("${Indent}if ($accessor < $min) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.max) {
            $msg = if ($val.max.message) { $val.max.message } else { "$label too large" }
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
            $msg = if ($val.regex.message) { $val.regex.message } else { "$label has invalid format" }
            $regex = $val.regex.value
            $lines.Add("${Indent}if (!RegExp(r'$regex').hasMatch($accessor)) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }

        if ($val.oneOf) {
            $msg = if ($val.oneOf.message) { $val.oneOf.message } else { "$label has invalid value" }
            $options = ($val.oneOf.value | ForEach-Object { "'$_'" }) -join ', '
            $lines.Add("${Indent}const _valid${fName} = [$options];")
            $lines.Add("${Indent}if (!_valid${fName}.contains($accessor)) {")
            $lines.Add("${Indent}  return Left(ValidationFailure('$msg'));")
            $lines.Add("${Indent}}")
        }
    }

    if ($lines.Count -gt 0) {
        return $lines -join "`n"
    }
    else {
        return "${Indent}// No validation rules declared for this entity"
    }
}

# ── Form field widget generation ──────────────────────────────
# FIX: Generates proper labels, proper bool state variables, proper validators
function Get-FormFields {
    param([object]$Fields, [string[]]$FieldList, [string]$Indent = '          ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $FieldList) {
        if (-not $Fields.PSObject.Properties[$fName]) { continue }
        $f = $Fields.$fName
        $widget = Get-FormWidget -ConfigType $f.type -FieldName $fName
        $label = ConvertTo-HumanLabel $fName

        switch ($widget) {
            'SwitchListTile' {
                $lines.Add("${Indent}SwitchListTile(")
                $lines.Add("${Indent}  title: const Text('$label'),")
                $lines.Add("${Indent}  value: _${fName}Value,")
                $lines.Add("${Indent}  onChanged: (v) => setState(() => _${fName}Value = v),")
                $lines.Add("${Indent}),")
            }
            'DatePickerFormField' {
                $lines.Add("${Indent}TextFormField(")
                $lines.Add("${Indent}  decoration: const InputDecoration(labelText: '$label'),")
                $lines.Add("${Indent}  controller: _${fName}Controller,")
                $lines.Add("${Indent}  readOnly: true,")
                $lines.Add("${Indent}  onTap: () => _pick${fName}Date(context),")
                if ($f.validation -and $f.validation.required -and $f.validation.required.value -eq $true) {
                    $msg = if ($f.validation.required.message) { $f.validation.required.message } else { "$label is required" }
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
                    $msg = if ($f.validation.required.message) { $f.validation.required.message } else { "$label is required" }
                    $validatorLines += "if (v == null || v.trim().isEmpty) return '$msg';"
                }
                if ($f.validation -and $f.validation.minLength) {
                    $msg = if ($f.validation.minLength.message) { $f.validation.minLength.message } else { "$label too short" }
                    $len = $f.validation.minLength.value
                    $validatorLines += "if (v != null && v.length < $len) return '$msg';"
                }
                if ($f.validation -and $f.validation.maxLength) {
                    $msg = if ($f.validation.maxLength.message) { $f.validation.maxLength.message } else { "$label too long" }
                    $len = $f.validation.maxLength.value
                    $validatorLines += "if (v != null && v.length > $len) return '$msg';"
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

# ── Form controller declarations ──────────────────────────────
# FIX: Bool fields get state variables, non-bool get TextEditingControllers
function Get-FormControllerDeclarations {
    param([object]$Fields, [string[]]$FieldList, [string]$Indent = '  ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $FieldList) {
        if (-not $Fields.PSObject.Properties[$fName]) { continue }
        $f = $Fields.$fName
        $widget = Get-FormWidget -ConfigType $f.type -FieldName $fName

        if ($widget -eq 'SwitchListTile') {
            $default = if ($f.default -eq $true) { 'true' } else { 'false' }
            $lines.Add("${Indent}bool _${fName}Value = $default;")
        }
        else {
            $lines.Add("${Indent}final _${fName}Controller = TextEditingController();")
        }
    }
    return $lines -join "`n"
}

# ── Form dispose calls ───────────────────────────────────────
# FIX: Only dispose TextEditingControllers, not bool state variables
function Get-FormDisposeStatements {
    param([object]$Fields, [string[]]$FieldList, [string]$Indent = '    ')

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($fName in $FieldList) {
        if (-not $Fields.PSObject.Properties[$fName]) { continue }
        $f = $Fields.$fName
        $widget = Get-FormWidget -ConfigType $f.type -FieldName $fName

        if ($widget -ne 'SwitchListTile') {
            $lines.Add("${Indent}_${fName}Controller.dispose();")
        }
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
            'DateTime' { "${fName}?.toIso8601String()" }
            'DateTime (time)' { "${fName}?.toIso8601String()" }
            '*Status' { "${fName}.name" }
            default { $fName }
        }
        $lines.Add("${Indent}'${fName}': ${expr},")
    }
    return $lines -join "`n"
}
function Get-NamingTokens {
    param([Parameter(Mandatory)][psobject]$FeatureConfig)

    $name = $FeatureConfig.name

    return @{
        FNAME  = $name
        FCLASS = ConvertTo-PascalCase $name
        FUPPER = $name.ToUpper()
        FLABEL = $FeatureConfig.label
    }
}
function ConvertTo-PascalCase {
    param([Parameter(Mandatory)][string]$Name)
    $spaced = [regex]::Replace($Name, '(?<!^)([A-Z])', ' $1')
    return (Get-Culture).TextInfo.ToTitleCase(
        $spaced.Replace('_', ' ')
    ).Replace(' ', '')
}

# ── Form widget type resolution ──────────────────────────────
function Get-FormWidgetType {
    param([Parameter(Mandatory)][string]$ConfigType)
    switch ($ConfigType) {
        'bool'     { 'SwitchListTile' }
        'DateTime' { 'DatePicker' }
        default    { 'TextFormField' }
    }
}

function Get-KeyboardType {
    param([Parameter(Mandatory)][string]$ConfigType)
    switch ($ConfigType) {
        'int'    { 'TextInputType.number' }
        'double' { 'const TextInputType.numberWithOptions(decimal: true)' }
        default  { 'TextInputType.text' }
    }
}

# ── Complete form field code generation ──────────────────────
function Get-FormFieldCode {
    param(
        [Parameter(Mandatory)][string]$FieldName,
        [Parameter(Mandatory)]$FieldMeta
    )
    $label  = if ($FieldMeta.Label) { $FieldMeta.Label } else { ($FieldName -creplace '([A-Z])', ' $1').Trim() }
    $type   = if ($FieldMeta.Type) { $FieldMeta.Type } else { $FieldMeta.DartType -replace '\?$', '' }
    $widget = Get-FormWidgetType -ConfigType $type
    $validation = $FieldMeta.Validation

    if ($widget -eq 'SwitchListTile') {
        return @"
                SwitchListTile(
                  title: const Text('$label'),
                  value: _${FieldName}Value,
                  onChanged: (v) => setState(() => _${FieldName}Value = v),
                ),
                const SizedBox(height: 16),
"@
    }

    if ($widget -eq 'DatePicker') {
        return @"
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _${FieldName}Controller.text =
                          picked.toIso8601String().split('T').first;
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _${FieldName}Controller,
                      decoration: const InputDecoration(
                        labelText: '$label',
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
"@
    }

    $keyboard = Get-KeyboardType -ConfigType $type
    $checks = [System.Collections.Generic.List[string]]::new()
    if ($validation) {
        $vp = $validation.PSObject.Properties
        $req = $vp | Where-Object { $_.Name -eq 'required' } | Select-Object -First 1
        if ($req -and $req.Value.value -eq $true) {
            $msg = if ($req.Value.message) { $req.Value.message } else { "$label is required" }
            $checks.Add("                    if (v == null || v.trim().isEmpty) return '$msg';")
        }
        $minLen = $vp | Where-Object { $_.Name -eq 'minLength' } | Select-Object -First 1
        if ($minLen) {
            $msg = if ($minLen.Value.message) { $minLen.Value.message } else { "$label is too short" }
            $checks.Add("                    if (v != null && v.trim().length < $($minLen.Value.value)) return '$msg';")
        }
        $maxLen = $vp | Where-Object { $_.Name -eq 'maxLength' } | Select-Object -First 1
        if ($maxLen) {
            $msg = if ($maxLen.Value.message) { $maxLen.Value.message } else { "$label is too long" }
            $checks.Add("                    if (v != null && v.trim().length > $($maxLen.Value.value)) return '$msg';")
        }
    }
    $validatorBlock = ''
    if ($checks.Count -gt 0) {
        $validatorBlock = @"
                  validator: (v) {
$($checks -join "`n")
                    return null;
                  },
"@
    }

    return @"
                TextFormField(
                  controller: _${FieldName}Controller,
                  decoration: const InputDecoration(
                    labelText: '$label',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: $keyboard,
$validatorBlock
                ),
                const SizedBox(height: 16),
"@
}

Export-ModuleMember -Function @(
    'Invoke-TokenReplace',
    'ConvertTo-SnakeCase',
    'ConvertTo-PascalCase',
    'ConvertTo-HumanLabel',
    'Get-DartType',
    'Get-FormWidget',
    'Get-FormWidgetType',
    'Get-KeyboardType',
    'Get-FormFieldCode',
    'Get-EntityFields',
    'Get-ConstructorParams',
    'Get-CopyWithParams',
    'Get-CopyWithBody',
    'Get-ValidationGate',
    'Get-FormFields',
    'Get-FormControllerDeclarations',
    'Get-FormDisposeStatements',
    'Get-FromJsonFields',
    'Get-ToJsonFields',
    'Get-NamingTokens'
)