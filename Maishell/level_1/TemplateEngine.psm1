# ============================================================
# TemplateEngine.psm1
# Shared helpers for all generator levels.
# ============================================================

function ConvertTo-SnakeCase {
    param([Parameter(Mandatory)][string]$Name)
    $result = [regex]::Replace($Name, '(?<!^)([A-Z])', '_$1')
    return $result.ToLower()
}

function ConvertTo-PascalCase {
    param([Parameter(Mandatory)][string]$Name)
    return (Get-Culture).TextInfo.ToTitleCase(
        $Name.Replace('_', ' ')
    ).Replace(' ', '')
}

function ConvertTo-HumanLabel {
    param([Parameter(Mandatory)][string]$Name)
    $spaced = [regex]::Replace($Name, '(?<!^)([A-Z])', ' $1')
    return (Get-Culture).TextInfo.ToTitleCase($spaced)
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

# ── Level 1+ helpers ──────────────────────────────────────

function Get-DartType {
    param([Parameter(Mandatory)][string]$ConfigType, [bool]$Nullable = $false)
    $base = switch ($ConfigType) {
        'String'   { 'String' }
        'int'      { 'int' }
        'double'   { 'double' }
        'bool'     { 'bool' }
        'DateTime' { 'DateTime' }
        default    { $ConfigType }
    }
    if ($Nullable) { return "$base?" }
    return $base
}

function Get-JsonParseExpr {
    param([Parameter(Mandatory)][string]$ConfigType, [Parameter(Mandatory)][string]$JsonKey, [bool]$Nullable = $false)
    switch ($ConfigType) {
        'String'   { if ($Nullable) { "json['$JsonKey'] as String?" } else { "json['$JsonKey'] as String" } }
        'int'      { if ($Nullable) { "json['$JsonKey'] as int?" }    else { "json['$JsonKey'] as int" } }
        'double'   { if ($Nullable) { "(json['$JsonKey'] as num?)?.toDouble()" } else { "(json['$JsonKey'] as num).toDouble()" } }
        'bool'     { if ($Nullable) { "json['$JsonKey'] as bool?" }   else { "json['$JsonKey'] as bool? ?? false" } }
        'DateTime' {
            if ($Nullable) { "json['$JsonKey'] != null ? DateTime.parse(json['$JsonKey'] as String) : null" }
            else           { "DateTime.parse(json['$JsonKey'] as String)" }
        }
        default { "json['$JsonKey']" }
    }
}

function Get-JsonWriteExpr {
    param([Parameter(Mandatory)][string]$ConfigType, [Parameter(Mandatory)][string]$FieldName, [bool]$Nullable = $false)
    $n = if ($Nullable) { '?' } else { '' }
    switch ($ConfigType) {
        'DateTime' { "${FieldName}${n}.toIso8601String()" }
        default    { $FieldName }
    }
}

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

function Get-PrimaryEntityMeta {
    param([Parameter(Mandatory)][psobject]$Config)
    $entityName = $Config.entities.PSObject.Properties |
        Where-Object { $_.Value.primary -eq $true } |
        Select-Object -First 1 -ExpandProperty Name
    $entity = $Config.entities.$entityName
    $snake  = ConvertTo-SnakeCase $entityName

    $fields = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($prop in $entity.fields.PSObject.Properties) {
        $fd = $prop.Value
        $isNullable = ($null -ne $fd.nullable) -and ($fd.nullable -eq $true)
        $isReadonly = ($null -ne $fd.readonly) -and ($fd.readonly -eq $true)
        $isPrimary  = ($null -ne $fd.primary)  -and ($fd.primary  -eq $true)
        $cfgType    = if ($fd.type) { $fd.type } else { 'String' }

        $fields.Add(@{
            Name       = $prop.Name
            Def        = $fd
            Type       = $cfgType
            DartType   = Get-DartType -ConfigType $cfgType -Nullable $isNullable
            SnakeCase  = ConvertTo-SnakeCase $prop.Name
            Label      = ConvertTo-HumanLabel $prop.Name
            IsNullable = $isNullable
            IsReadonly = $isReadonly
            IsPrimary  = $isPrimary
            Validation = $fd.validation
        })
    }

    return @{
        Name     = $entityName
        Snake    = $snake
        Entity   = $entity
        Fields   = $fields
        Api      = $entity.api
        Ui       = $entity.ui
        Endpoint = if ($entity.api -and $entity.api.endpoint) { $entity.api.endpoint } else { "/$snake`s" }
    }
}

function Get-ValidationLines {
    param([Parameter(Mandatory)][string]$FieldName, [Parameter(Mandatory)][string]$ConfigType,
          [psobject]$Validation, [string]$Accessor = "p.$FieldName")
    if ($null -eq $Validation) { return @() }
    $lines = [System.Collections.Generic.List[string]]::new()
    $vp = $Validation.PSObject.Properties

    $req = $vp | Where-Object { $_.Name -eq 'required' } | Select-Object -First 1
    if ($req -and $req.Value.value -eq $true) {
        $msg = if ($req.Value.message) { $req.Value.message } else { "$FieldName is required" }
        if ($ConfigType -eq 'String') {
            $lines.Add("    if ($Accessor.trim().isEmpty) {")
        } else {
            $lines.Add("    if ($Accessor == null) {")
        }
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $minLen = $vp | Where-Object { $_.Name -eq 'minLength' } | Select-Object -First 1
    if ($minLen) {
        $msg = if ($minLen.Value.message) { $minLen.Value.message } else { "$FieldName is too short" }
        $lines.Add("    if ($Accessor.trim().length < $($minLen.Value.value)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $maxLen = $vp | Where-Object { $_.Name -eq 'maxLength' } | Select-Object -First 1
    if ($maxLen) {
        $msg = if ($maxLen.Value.message) { $maxLen.Value.message } else { "$FieldName is too long" }
        $lines.Add("    if ($Accessor.trim().length > $($maxLen.Value.value)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $minVal = $vp | Where-Object { $_.Name -eq 'min' } | Select-Object -First 1
    if ($minVal) {
        $msg = if ($minVal.Value.message) { $minVal.Value.message } else { "$FieldName is too small" }
        $lines.Add("    if ($Accessor < $($minVal.Value.value)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $maxVal = $vp | Where-Object { $_.Name -eq 'max' } | Select-Object -First 1
    if ($maxVal) {
        $msg = if ($maxVal.Value.message) { $maxVal.Value.message } else { "$FieldName is too large" }
        $lines.Add("    if ($Accessor > $($maxVal.Value.value)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $regex = $vp | Where-Object { $_.Name -eq 'regex' } | Select-Object -First 1
    if ($regex) {
        $msg = if ($regex.Value.message) { $regex.Value.message } else { "$FieldName has invalid format" }
        $lines.Add("    if (!RegExp(r'$($regex.Value.value)').hasMatch($Accessor)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $email = $vp | Where-Object { $_.Name -eq 'email' } | Select-Object -First 1
    if ($email -and $email.Value.value -eq $true) {
        $msg = if ($email.Value.message) { $email.Value.message } else { "Invalid email address" }
        $lines.Add("    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch($Accessor)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    $oneOf = $vp | Where-Object { $_.Name -eq 'oneOf' } | Select-Object -First 1
    if ($oneOf) {
        $msg = if ($oneOf.Value.message) { $oneOf.Value.message } else { "Invalid value for $FieldName" }
        $vals = ($oneOf.Value.value | ForEach-Object { "'$_'" }) -join ', '
        $lines.Add("    if (![$vals].contains($Accessor)) {")
        $lines.Add("      return const Left(ValidationFailure('$msg'));")
        $lines.Add("    }")
    }

    return $lines
}

function Get-FormFieldCode {
    param([Parameter(Mandatory)][string]$FieldName, [Parameter(Mandatory)][hashtable]$FieldMeta)
    $label = $FieldMeta.Label
    $type  = $FieldMeta.Type
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
            $checks.Add("                        if (v == null || v.trim().isEmpty) return '$msg';")
        }
        $minLen = $vp | Where-Object { $_.Name -eq 'minLength' } | Select-Object -First 1
        if ($minLen) {
            $msg = if ($minLen.Value.message) { $minLen.Value.message } else { "$label is too short" }
            $checks.Add("                        if (v != null && v.trim().length < $($minLen.Value.value)) return '$msg';")
        }
        $maxLen = $vp | Where-Object { $_.Name -eq 'maxLength' } | Select-Object -First 1
        if ($maxLen) {
            $msg = if ($maxLen.Value.message) { $maxLen.Value.message } else { "$label is too long" }
            $checks.Add("                        if (v != null && v.trim().length > $($maxLen.Value.value)) return '$msg';")
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
$validatorBlock                ),
                const SizedBox(height: 16),
"@
}

Export-ModuleMember -Function @(
    'ConvertTo-SnakeCase', 'ConvertTo-PascalCase', 'ConvertTo-HumanLabel', 'Get-NamingTokens',
    'Get-DartType', 'Get-JsonParseExpr', 'Get-JsonWriteExpr', 'Get-FormWidgetType',
    'Get-KeyboardType', 'Get-PrimaryEntityMeta', 'Get-ValidationLines', 'Get-FormFieldCode'
)
