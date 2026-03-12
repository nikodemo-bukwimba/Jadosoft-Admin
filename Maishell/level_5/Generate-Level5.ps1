# ============================================================
# Generate-Level5.ps1 -- Level 5: External Integration
# ============================================================

param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [string]$ProjectRoot = (Get-Location).Path,
    [switch]$DryRun,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ModuleRoot = Join-Path $PSScriptRoot "modules"
$GenRoot    = Join-Path $PSScriptRoot "generators"

Import-Module (Join-Path $ModuleRoot "TemplateEngine.psm1")            -Force
Import-Module (Join-Path $ModuleRoot "Validator.psm1")                 -Force
Import-Module (Join-Path $GenRoot    "Level5ClientGenerator.psm1")     -Force
Import-Module (Join-Path $GenRoot    "Level5CubitGenerator.psm1")      -Force
Import-Module (Join-Path $GenRoot    "Level5PageGenerator.psm1")       -Force
Import-Module (Join-Path $GenRoot    "Level5WiringGenerator.psm1")     -Force

function Write-Header([string]$t) { Write-Host "`n===============================================" -ForegroundColor DarkCyan; Write-Host " $t" -ForegroundColor Cyan; Write-Host "===============================================" -ForegroundColor DarkCyan }
function Write-Step([string]$t)    { Write-Host "  > $t" }
function Write-Success([string]$t) { Write-Host "  [OK] $t" -ForegroundColor Green }
function Write-Fail([string]$t)    { Write-Host "`n  [ERROR] $t`n" -ForegroundColor Red }

function New-GeneratedFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    if ($DryRun) { Write-Host "    [DRY RUN] $Path" -ForegroundColor DarkGray; return }
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Success (Split-Path $Path -Leaf)
}

Write-Header "HALA FCA - Level 5 Feature Generator (External Integration)"

$ConfigPath = Resolve-Path $ConfigPath
if (-not (Test-Path $ConfigPath)) { Write-Fail "Config not found: $ConfigPath"; exit 1 }

Write-Step "Loading config: $ConfigPath"
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# -- Validation --
$maturity = [int]$config.feature.maturity
if ($maturity -ne 5) { Write-Fail "This generator handles Level 5 only. Config declares maturity $maturity."; exit 1 }
if ($null -eq $config.integration) { Write-Fail "Level 5 requires an 'integration' block."; exit 1 }
if ($null -eq $config.integration.baseUrl -or $config.integration.baseUrl -eq '') { Write-Fail "integration.baseUrl is required."; exit 1 }
if ($null -eq $config.integration.operations -or $config.integration.operations.Count -eq 0) { Write-Fail "integration.operations must have at least 1 operation."; exit 1 }

foreach ($op in $config.integration.operations) {
    if (-not $op.name) { Write-Fail "Each operation must have a 'name'."; exit 1 }
    if (-not $op.method) { Write-Fail "Operation '$($op.name)' must have a 'method'."; exit 1 }
    if (-not $op.path) { Write-Fail "Operation '$($op.name)' must have a 'path'."; exit 1 }
    $validMethods = @('GET', 'POST', 'PUT', 'PATCH', 'DELETE')
    if ($op.method.ToUpper() -notin $validMethods) { Write-Fail "Operation '$($op.name)' method '$($op.method)' not in: $($validMethods -join ', ')"; exit 1 }
    # POST/PUT/PATCH should have requestFields
    if ($op.method.ToUpper() -in @('POST', 'PUT', 'PATCH') -and (-not $op.requestFields -or $op.requestFields.Count -eq 0)) {
        Write-Warning "Operation '$($op.name)' ($($op.method)) has no requestFields -- request DTO will be skipped."
    }
    # Non-DELETE should have responseFields
    if ($op.method.ToUpper() -ne 'DELETE' -and (-not $op.responseFields -or $op.responseFields.Count -eq 0)) {
        Write-Warning "Operation '$($op.name)' ($($op.method)) has no responseFields -- response DTO will be empty."
    }
}

# Validate webhooks if present
if ($config.integration.webhooks) {
    foreach ($wh in $config.integration.webhooks) {
        if (-not $wh.name) { Write-Fail "Each webhook must have a 'name'."; exit 1 }
        if (-not $wh.event) { Write-Fail "Webhook '$($wh.name)' must have an 'event'."; exit 1 }
    }
}

$tokens = Get-NamingTokens -FeatureConfig $config.feature
Write-Step "Feature: $($tokens.FLABEL) (Level 5 Integration)"

$featureDir = Join-Path $ProjectRoot "lib/features/$($tokens.FNAME)"
if ((Test-Path $featureDir) -and -not $Force) {
    Write-Fail "Feature '$($tokens.FNAME)' already exists at: $featureDir"
    exit 1
}

Write-Header "Phase B - Generation"

$ctx = @{
    Config      = $config
    Tokens      = $tokens
    FeatureDir  = $featureDir
    ProjectRoot = $ProjectRoot
    DryRun      = $DryRun.IsPresent
    Maturity    = 5
}

Write-Step "1. Client + DTOs + service (+ webhooks)..."
Invoke-GenerateIntegrationClient -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "2. Cubit (sync status)..."
Invoke-GenerateIntegrationCubit -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "3. Pages + widgets..."
Invoke-GenerateIntegrationPages -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "4. Wiring DI..."
Update-InjectionContainer -Ctx $ctx

Write-Step "5. Wiring routes..."
Update-AppRouter -Ctx $ctx

Write-Step "6. Wiring shell navigation..."
Update-ShellNavItems -Ctx $ctx

Write-Header "Generation Complete"
if ($DryRun) {
    Write-Host "  [DRY RUN] No files written" -ForegroundColor Yellow
} else {
    $fileCount = 0
    if (Test-Path $featureDir) { $fileCount = (Get-ChildItem $featureDir -Recurse -File).Count }
    Write-Success "$fileCount files generated in lib/features/$($tokens.FNAME)"
}
Write-Host ""

