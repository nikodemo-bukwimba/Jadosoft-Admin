# ============================================================
# Generate-Level2.ps1 — Level 2: CRUD + State Machine
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

Import-Module (Join-Path $ModuleRoot "TemplateEngine.psm1")              -Force
Import-Module (Join-Path $ModuleRoot "Validator.psm1")                   -Force
Import-Module (Join-Path $GenRoot    "Level2EntityGenerator.psm1")       -Force
Import-Module (Join-Path $GenRoot    "Level2DataGenerator.psm1")         -Force
Import-Module (Join-Path $GenRoot    "Level2UseCaseGenerator.psm1")      -Force
Import-Module (Join-Path $GenRoot    "Level2StateMachineGenerator.psm1") -Force
Import-Module (Join-Path $GenRoot    "Level2BlocGenerator.psm1")         -Force
Import-Module (Join-Path $GenRoot    "Level2PageGenerator.psm1")         -Force
Import-Module (Join-Path $GenRoot    "Level2WiringGenerator.psm1")       -Force

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

Write-Header "HALA FCA - Level 2 Feature Generator (CRUD + StateMachine)"

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
if ($maturity -ne 2) { Write-Fail "This generator handles Level 2 only. Config declares maturity $maturity."; exit 1 }
if ($null -eq $config.stateMachine) { Write-Fail "Level 2 requires a 'stateMachine' block."; exit 1 }
if ($null -eq $config.stateMachine.states -or $config.stateMachine.states.Count -eq 0) { Write-Fail "stateMachine.states must have at least 1 state."; exit 1 }
if ($null -eq $config.stateMachine.transitions -or $config.stateMachine.transitions.Count -eq 0) { Write-Fail "stateMachine.transitions must have at least 1 transition."; exit 1 }

$tokens = Get-NamingTokens -FeatureConfig $config.feature
Write-Step "Feature: $($tokens.FLABEL) (Level 2)"

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
    Maturity    = 2
}

Write-Step "1. Entity (with status field)..."
Invoke-GenerateEntity -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "2. Data layer (model + datasource + repo)..."
Invoke-GenerateData -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "3. Use cases (CRUD)..."
Invoke-GenerateUseCases -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "4. State machine (enum + guard + domain service)..."
Invoke-GenerateStateMachine -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "5. BLoC (CRUD + transitions)..."
Invoke-GenerateBloc -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "6. Pages + widgets (with status badge + transitions)..."
Invoke-GeneratePages -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "7. Wiring DI..."
Update-InjectionContainer -Ctx $ctx

Write-Step "8. Wiring routes..."
Update-AppRouter -Ctx $ctx

Write-Step "9. Wiring shell navigation..."
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
