# ============================================================
# TemplateEngine.psm1
# Shared helpers for all generator levels.
# Each level adds helpers here as needed — never duplicated.
# ============================================================

<#
.SYNOPSIS
    Converts a PascalCase or camelCase string to snake_case.
.EXAMPLE
    ConvertTo-SnakeCase "ProjectMember"  → "project_member"
    ConvertTo-SnakeCase "about"          → "about"
#>
function ConvertTo-SnakeCase {
    param([Parameter(Mandatory)][string]$Name)

    # Insert underscore before each uppercase letter, then lowercase everything
    $result = [regex]::Replace($Name, '(?<!^)([A-Z])', '_$1')
    return $result.ToLower()
}

<#
.SYNOPSIS
    Converts a snake_case string to PascalCase.
.EXAMPLE
    ConvertTo-PascalCase "project_member"  → "ProjectMember"
    ConvertTo-PascalCase "about"           → "About"
#>
function ConvertTo-PascalCase {
    param([Parameter(Mandatory)][string]$Name)

    return (Get-Culture).TextInfo.ToTitleCase(
        $Name.Replace('_', ' ')
    ).Replace(' ', '')
}

<#
.SYNOPSIS
    Converts a camelCase or PascalCase field name to a human-readable label.
.EXAMPLE
    ConvertTo-HumanLabel "firstName"  → "First Name"
    ConvertTo-HumanLabel "isActive"   → "Is Active"
    ConvertTo-HumanLabel "id"         → "Id"
#>
function ConvertTo-HumanLabel {
    param([Parameter(Mandatory)][string]$Name)

    $spaced = [regex]::Replace($Name, '(?<!^)([A-Z])', ' $1')
    return (Get-Culture).TextInfo.ToTitleCase($spaced)
}

<#
.SYNOPSIS
    Derives all standard naming tokens from a feature config.
.OUTPUTS
    Hashtable with FNAME, FCLASS, FUPPER, FLABEL
#>
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

Export-ModuleMember -Function @(
    'ConvertTo-SnakeCase',
    'ConvertTo-PascalCase',
    'ConvertTo-HumanLabel',
    'Get-NamingTokens'
)
