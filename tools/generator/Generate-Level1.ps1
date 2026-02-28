# ============================================================
# Generate-Level1.ps1 — Level 1 CRUD Feature Generator
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
$GenRoot = Join-Path $PSScriptRoot "generators"
Import-Module (Join-Path $ModuleRoot "MetaHelpers.psm1") -Force
Import-Module (Join-Path $ModuleRoot "TemplateEngine.psm1")         -Force
Import-Module (Join-Path $ModuleRoot "Validator.psm1")              -Force
Import-Module (Join-Path $GenRoot    "Level1EntityGenerator.psm1")  -Force
Import-Module (Join-Path $GenRoot    "Level1DataGenerator.psm1")    -Force
Import-Module (Join-Path $GenRoot    "Level1UseCaseGenerator.psm1") -Force
Import-Module (Join-Path $GenRoot    "Level1BlocGenerator.psm1")    -Force
Import-Module (Join-Path $GenRoot    "Level1PageGenerator.psm1")    -Force
Import-Module (Join-Path $GenRoot    "Level1WiringGenerator.psm1")  -Force

function Write-Header([string]$t) { Write-Host "`n===============================================" -ForegroundColor DarkCyan; Write-Host " $t" -ForegroundColor Cyan; Write-Host "===============================================" -ForegroundColor DarkCyan }
function Write-Step([string]$t) { Write-Host "  > $t" }
function Write-Success([string]$t) { Write-Host "  [OK] $t" -ForegroundColor Green }
function Write-Fail([string]$t) { Write-Host "`n  [ERROR] $t`n" -ForegroundColor Red }

function New-GeneratedFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Content)
    if ($DryRun) { Write-Host "    [DRY RUN] $Path" -ForegroundColor DarkGray; return }
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Success (Split-Path $Path -Leaf)
}

Write-Header "HALA FCA - Level 1 CRUD Feature Generator"

$ConfigPath = Resolve-Path $ConfigPath
if (-not (Test-Path $ConfigPath)) { Write-Fail "Config not found: $ConfigPath"; exit 1 }

Write-Step "Loading config: $ConfigPath"
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

Write-Header "Phase A - Validation"
$errors = Invoke-ConfigValidation -Config $config
if ($errors.Count -gt 0) {
    Write-Fail "Validation failed with $($errors.Count) error(s):"
    foreach ($e in $errors) { Write-Host "    - $e" -ForegroundColor Red }
    exit 1
}
Write-Success "Schema valid"

$maturity = [int]$config.feature.maturity
if ($maturity -ne 1) { Write-Fail "This generator handles Level 1 only. Config declares maturity $maturity."; exit 1 }

$tokens = Get-NamingTokens -FeatureConfig $config.feature
Write-Step "Feature: $($tokens.FLABEL) (Level 1 — CRUD)"

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
    Maturity    = 1
}

Write-Step "Generating entity..."
Invoke-GenerateEntity -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "Generating data layer (repo + model + datasource)..."
Invoke-GenerateData -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "Generating use cases..."
Invoke-GenerateUseCases -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "Generating BLoC..."
Invoke-GenerateBloc -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "Generating pages + widgets..."
Invoke-GeneratePages -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "Wiring DI..."
Update-InjectionContainer -Ctx $ctx

Write-Step "Wiring routes..."
Update-AppRouter -Ctx $ctx

Write-Step "Wiring shell navigation..."
Update-ShellNavItems -Ctx $ctx

Write-Header "Generation Complete"
if ($DryRun) {
    Write-Host "  [DRY RUN] No files written" -ForegroundColor Yellow
}
else {
    $fileCount = 0
    if (Test-Path $featureDir) { $fileCount = (Get-ChildItem $featureDir -Recurse -File).Count }
    Write-Success "$fileCount files generated in lib/features/$($tokens.FNAME)"
}
Write-Host ""
