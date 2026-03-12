# ============================================================
# Generate-Level0.ps1
# Entry point for Level 0 (Static Feature) generation.
#
# Usage:
#   .\Generate-Level0.ps1 -ConfigPath .\feature.config.json
#   .\Generate-Level0.ps1 -ConfigPath .\feature.config.json -DryRun
#   .\Generate-Level0.ps1 -ConfigPath .\feature.config.json -Force
# ============================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [string]$ProjectRoot = (Get-Location).Path,

    [switch]$DryRun,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- Module imports --
$ModuleRoot = Join-Path $PSScriptRoot "modules"
$GenRoot    = Join-Path $PSScriptRoot "generators"

Import-Module (Join-Path $ModuleRoot "TemplateEngine.psm1") -Force
Import-Module (Join-Path $ModuleRoot "Validator.psm1")      -Force
Import-Module (Join-Path $GenRoot    "Level0Generator.psm1") -Force
Import-Module (Join-Path $GenRoot    "Level0WiringGenerator.psm1") -Force

# -- Console helpers --
function Write-Header([string]$Text) {
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor DarkCyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "===============================================" -ForegroundColor DarkCyan
}

function Write-Step([string]$Text) {
    Write-Host "  > $Text"
}

function Write-Success([string]$Text) {
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Fail([string]$Text) {
    Write-Host ""
    Write-Host "  [ERROR] $Text" -ForegroundColor Red
    Write-Host ""
}

function New-GeneratedFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Content
    )

    if ($DryRun) {
        Write-Host "    [DRY RUN] $Path" -ForegroundColor DarkGray
        return
    }

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Success (Split-Path $Path -Leaf)
}

# -- Entry --
Write-Header "HALA FCA - Level 0 Static Feature Generator"

# Resolve config path
$ConfigPath = Resolve-Path $ConfigPath
if (-not (Test-Path $ConfigPath)) {
    Write-Fail "Config not found: $ConfigPath"
    exit 1
}

Write-Step "Loading config: $ConfigPath"
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# -- Phase A: Validation --
Write-Header "Phase A - Validation"

$errors = Invoke-ConfigValidation -Config $config
if ($errors.Count -gt 0) {
    Write-Fail "Schema validation failed with $($errors.Count) error(s):"
    foreach ($e in $errors) {
        Write-Host "    - $e" -ForegroundColor Red
    }
    exit 1
}
Write-Success "Schema valid"

# Maturity gate -- this script only handles Level 0
$maturity = [int]$config.feature.maturity
if ($maturity -ne 0) {
    Write-Fail "This generator handles Level 0 only. Config declares maturity $maturity."
    exit 1
}

# Derive naming tokens
$tokens = Get-NamingTokens -FeatureConfig $config.feature
Write-Step "Feature: $($tokens.FLABEL) (Level 0 -- Static)"

# Feature directory
$featureDir = Join-Path $ProjectRoot "lib/features/$($tokens.FNAME)"

if ((Test-Path $featureDir) -and -not $Force) {
    Write-Fail "Feature '$($tokens.FNAME)' already exists at: $featureDir"
    Write-Host "    Use -Force to overwrite (development only)." -ForegroundColor Yellow
    exit 1
}

# -- Phase B: Generation --
Write-Header "Phase B - Generation"

$ctx = @{
    Config      = $config
    Tokens      = $tokens
    FeatureDir  = $featureDir
    ProjectRoot = $ProjectRoot
    DryRun      = $DryRun.IsPresent
    Maturity    = 0
}

Write-Step "Generating presentation layer..."
Invoke-GenerateLevel0 -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "Wiring route..."
Update-AppRouter -Ctx $ctx

Write-Step "Wiring shell navigation..."
Update-ShellNavItems -Ctx $ctx

# -- Summary --
Write-Header "Generation Complete"

if ($DryRun) {
    Write-Host "  [DRY RUN] No files written" -ForegroundColor Yellow
}
else {
    $fileCount = 0
    if (Test-Path $featureDir) {
        $fileCount = (Get-ChildItem $featureDir -Recurse -File).Count
    }
    Write-Success "$fileCount files generated in lib/features/$($tokens.FNAME)"
    Write-Success "Route wired in app_router.dart"
    Write-Success "Shell tab wired in shell_nav_items.dart"
}

Write-Host ""

