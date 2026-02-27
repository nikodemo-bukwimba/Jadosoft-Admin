# ============================================================
# HALA FCA — Feature Generator
# Phase 3 · Two-Phase Config-Driven Code Generator
#
# Usage:
#   .\generate.ps1 -ConfigPath .\lib\features\project\feature.config.json
#   .\generate.ps1 -ConfigPath .\lib\features\project\feature.config.json -DryRun
#
# The generator NEVER modifies an existing feature folder.
# It only appends to injection_container.dart and app_router.dart.
# ============================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath,

    [string]$ProjectRoot = (Get-Location).Path,

    [switch]$DryRun,

    [switch]$Force  # Allow regenerating (for development of generator itself)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Module imports ────────────────────────────────────────────
$ModuleRoot = Join-Path $PSScriptRoot 'modules'
$GenRoot = Join-Path $PSScriptRoot 'generators'

Import-Module (Join-Path $ModuleRoot 'Validator.psm1')      -Force
Import-Module (Join-Path $ModuleRoot 'DependencyGraph.psm1') -Force
Import-Module (Join-Path $ModuleRoot 'TemplateEngine.psm1')  -Force

Import-Module (Join-Path $GenRoot 'EntityGenerator.psm1')       -Force
Import-Module (Join-Path $GenRoot 'RepositoryGenerator.psm1')   -Force
Import-Module (Join-Path $GenRoot 'UseCaseGenerator.psm1')      -Force
Import-Module (Join-Path $GenRoot 'BlocGenerator.psm1')         -Force
Import-Module (Join-Path $GenRoot 'PageGenerator.psm1')         -Force
Import-Module (Join-Path $GenRoot 'StateMachineGenerator.psm1') -Force
Import-Module (Join-Path $GenRoot 'WorkflowGenerator.psm1')     -Force
Import-Module (Join-Path $GenRoot 'DiRouterGenerator.psm1')     -Force

# ── Helpers ───────────────────────────────────────────────────
function Write-Header([string]$text) {
    Write-Host ""
    Write-Host "  ═══════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host "  ═══════════════════════════════════════════" -ForegroundColor DarkCyan
}

function Write-Step([string]$text) {
    Write-Host "  ▸ $text" -ForegroundColor White
}

function Write-Success([string]$text) {
    Write-Host "  ✓ $text" -ForegroundColor Green
}

function Write-Warn([string]$text) {
    Write-Host "  ⚠ $text" -ForegroundColor Yellow
}

function Write-Fail([string]$text) {
    Write-Host ""
    Write-Host "  ✗ ERROR: $text" -ForegroundColor Red
    Write-Host ""
}

function New-GeneratedFile {
    param([string]$Path, [string]$Content)

    if ($DryRun) {
        Write-Host "    [DRY RUN] Would create: $Path" -ForegroundColor DarkGray
        return
    }

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Success (Split-Path $Path -Leaf)
}

# ── Entry point ───────────────────────────────────────────────
Write-Header "HALA FCA · Feature Generator"

# 1. Resolve config path
$ConfigPath = Resolve-Path $ConfigPath
if (-not (Test-Path $ConfigPath)) {
    Write-Fail "Config not found: $ConfigPath"
    exit 1
}

Write-Step "Loading config: $ConfigPath"
$configJson = Get-Content $ConfigPath -Raw
$config = $configJson | ConvertFrom-Json

# ── PHASE A: ANALYSIS ─────────────────────────────────────────
Write-Header "Phase A · Analysis"

# 2. Validate config schema
Write-Step "Validating schema..."
$errors = Invoke-ConfigValidation -Config $config
if ($errors.Count -gt 0) {
    Write-Fail "Schema validation failed with $($errors.Count) error(s):"
    foreach ($e in $errors) {
        Write-Host "    • $e" -ForegroundColor Red
    }
    exit 1
}
Write-Success "Schema valid"

# 3. Derive naming tokens
$featureName = $config.feature.name                           # snake_case: project
$featureClass = (Get-Culture).TextInfo.ToTitleCase(            # PascalCase: Project
    $featureName.Replace('_', ' ')
).Replace(' ', '')
$featureUpper = $featureName.ToUpper()                         # UPPER: PROJECT
$featureLabel = $config.feature.label                          # Label: Project
$maturity = [int]$config.feature.maturity
$permission = $config.feature.permission

Write-Step "Feature: $featureLabel (maturity $maturity)"

# 4. Check for existing feature folder — hard gate
$featureDir = Join-Path $ProjectRoot "lib\features\$featureName"
if ((Test-Path $featureDir) -and -not $Force) {
    Write-Fail "Feature '$featureName' already exists at: $featureDir"
    Write-Host "  Once generated, a feature is human territory." -ForegroundColor Yellow
    Write-Host "  Use -Force only during generator development." -ForegroundColor Yellow
    exit 1
}

# 5. Discover all other configs for cross-feature dependency graph
Write-Step "Building dependency graph..."
$allConfigPaths = Get-ChildItem -Path (Join-Path $ProjectRoot 'lib\features') `
    -Filter 'feature.config.json' -Recurse -ErrorAction SilentlyContinue

$allConfigs = @{}
foreach ($cp in $allConfigPaths) {
    $c = (Get-Content $cp.FullName -Raw) | ConvertFrom-Json
    $allConfigs[$c.feature.name] = $c
}
$allConfigs[$featureName] = $config  # include the one being generated

$graph = Build-DependencyGraph -Configs $allConfigs
if ($graph.CircularDependencies.Count -gt 0) {
    Write-Fail "Circular dependencies detected:"
    foreach ($cycle in $graph.CircularDependencies) {
        Write-Host "    $cycle" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "  Resolution: extract the shared concept to shared/domain/" -ForegroundColor Yellow
    exit 1
}

$crossFeatureDeps = $graph.Dependencies[$featureName]
if ($crossFeatureDeps.Count -gt 0) {
    Write-Step "Cross-feature dependencies: $($crossFeatureDeps -join ', ')"
}
else {
    Write-Step "No cross-feature dependencies"
}
Write-Success "Dependency graph clean"

# ── PHASE B: GENERATION ───────────────────────────────────────
Write-Header "Phase B · Generation (Maturity $maturity)"

# Token map passed to every generator
$tokens = @{
    FNAME  = $featureName   # project
    FCLASS = $featureClass  # Project
    FUPPER = $featureUpper  # PROJECT
    FLABEL = $featureLabel  # Project
    FPERM  = $permission    # projects
}

$ctx = @{
    Config      = $config
    Tokens      = $tokens
    FeatureDir  = $featureDir
    ProjectRoot = $ProjectRoot
    DryRun      = $DryRun.IsPresent
    Maturity    = $maturity
    Graph       = $graph
    AllConfigs  = $allConfigs
}

# ── Level 0 ───────────────────────────────────────────────────
if ($maturity -ge 0) {
    Write-Step "Generating presentation layer..."
    Invoke-GeneratePresentation -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

# ── Level 1 ───────────────────────────────────────────────────
if ($maturity -ge 1) {
    Write-Step "Generating domain entities..."
    Invoke-GenerateDomain -Ctx $ctx -NewFile ${function:New-GeneratedFile}

    Write-Step "Generating repository interface + implementation..."
    Invoke-GenerateRepository -Ctx $ctx -NewFile ${function:New-GeneratedFile}

    Write-Step "Generating use cases..."
    Invoke-GenerateUseCases -Ctx $ctx -NewFile ${function:New-GeneratedFile}

    Write-Step "Generating data layer (models + datasources)..."
    Invoke-GenerateData -Ctx $ctx -NewFile ${function:New-GeneratedFile}

    Write-Step "Generating BLoC..."
    Invoke-GenerateBloc -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

# ── Level 2 ───────────────────────────────────────────────────
if ($maturity -ge 2) {
    Write-Step "Generating state machine..."
    Invoke-GenerateStateMachine -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

# ── Level 3 ───────────────────────────────────────────────────
if ($maturity -ge 3) {
    Write-Step "Generating workflow..."
    Invoke-GenerateWorkflow -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

# ── Cross-feature providers ───────────────────────────────────
if ($crossFeatureDeps.Count -gt 0) {
    Write-Step "Generating cross-feature provider interfaces + adapters..."
    Invoke-GenerateProviders -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

# ── DI + Router ───────────────────────────────────────────────
Write-Step "Wiring DI registrations..."
Update-InjectionContainer -Ctx $ctx

Write-Step "Wiring routes..."
Update-AppRouter -Ctx $ctx

# ── Summary ───────────────────────────────────────────────────
Write-Header "Generation Complete"

if ($DryRun) {
    Write-Warn "DRY RUN — no files were written"
}
else {
    $fileCount = (Get-ChildItem $featureDir -Recurse -File -ErrorAction SilentlyContinue).Count
    Write-Success "$fileCount files generated in: lib/features/$featureName"
    Write-Success "DI registrations appended to: config/di/injection_container.dart"
    Write-Success "Routes appended to: app/routes/app_router.dart"
    Write-Host ""
    Write-Host "  This feature is now human territory." -ForegroundColor DarkCyan
    Write-Host "  Implement domain-specific logic in:" -ForegroundColor DarkCyan
    if ($maturity -ge 2) {
        Write-Host "    lib/features/$featureName/domain/guards/${featureName}_transition_guard.dart" -ForegroundColor DarkGray
    }
    if ($maturity -ge 3) {
        Write-Host "    lib/features/$featureName/domain/workflows/${featureName}_workflow.dart" -ForegroundColor DarkGray
    }
    Write-Host "    lib/features/$featureName/domain/usecases/ (validation gates)" -ForegroundColor DarkGray
    Write-Host "    lib/features/$featureName/presentation/ (UI customization)" -ForegroundColor DarkGray
}

Write-Host ""