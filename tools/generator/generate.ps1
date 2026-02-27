# ============================================================
# HALA FCA - Feature Generator
# Two-Phase Config-Driven Code Generator
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

# ------------------------------------------------------------
# Module Imports
# ------------------------------------------------------------

$ModuleRoot = Join-Path $PSScriptRoot "modules"
$GenRoot = Join-Path $PSScriptRoot "generators"

$modules = @(
    Join-Path $ModuleRoot "Validator.psm1"
    Join-Path $ModuleRoot "DependencyGraph.psm1"
    Join-Path $ModuleRoot "TemplateEngine.psm1"
    Join-Path $GenRoot    "EntityGenerator.psm1"
    Join-Path $GenRoot    "RepositoryGenerator.psm1"
    Join-Path $GenRoot    "UseCaseGenerator.psm1"
    Join-Path $GenRoot    "BlocGenerator.psm1"
    Join-Path $GenRoot    "PageGenerator.psm1"
    Join-Path $GenRoot    "StateMachineGenerator.psm1"
    Join-Path $GenRoot    "WorkflowGenerator.psm1"
    Join-Path $GenRoot    "DiRouterGenerator.psm1"
)

foreach ($m in $modules) {
    Import-Module $m -Force
}

# ------------------------------------------------------------
# Console Helpers (ASCII only)
# ------------------------------------------------------------

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

function Write-Warn([string]$Text) {
    Write-Host "  [WARN] $Text" -ForegroundColor Yellow
}

function Write-Fail([string]$Text) {
    Write-Host ""
    Write-Host "  [ERROR] $Text" -ForegroundColor Red
    Write-Host ""
}

function New-GeneratedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    if ($DryRun) {
        Write-Host "    DRY RUN -> $Path" -ForegroundColor DarkGray
        return
    }

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    Set-Content -Path $Path -Value $Content -Encoding UTF8
    Write-Success (Split-Path $Path -Leaf)
}

# ------------------------------------------------------------
# Entry
# ------------------------------------------------------------

Write-Header "HALA FCA Feature Generator"

$ConfigPath = Resolve-Path $ConfigPath

if (-not (Test-Path $ConfigPath)) {
    Write-Fail "Config not found: $ConfigPath"
    exit 1
}

Write-Step "Loading config: $ConfigPath"
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# ------------------------------------------------------------
# PHASE A - ANALYSIS
# ------------------------------------------------------------

Write-Header "Phase A - Analysis"

Write-Step "Validating schema..."
$errors = Invoke-ConfigValidation -Config $config
if ($null -ne $errors -and $errors.Count -gt 0) {
    Write-Fail "Schema validation failed with $($errors.Count) error(s)"
    foreach ($e in $errors) {
        Write-Host "    - $e" -ForegroundColor Red
    }
    exit 1
}
Write-Success "Schema valid"

# Naming tokens
$featureName = $config.feature.name
$featureClass = (Get-Culture).TextInfo.ToTitleCase(
    $featureName.Replace("_", " ")
).Replace(" ", "")
$featureUpper = $featureName.ToUpper()
$featureLabel = $config.feature.label
$maturity = [int]$config.feature.maturity
$permission = $config.feature.permission

Write-Step "Feature: $featureLabel (maturity $maturity)"

$featureDir = Join-Path $ProjectRoot "lib/features/$featureName"

if ((Test-Path $featureDir) -and -not $Force) {
    Write-Fail "Feature '$featureName' already exists at: $featureDir"
    exit 1
}

# Dependency graph
Write-Step "Building dependency graph..."

$featuresRoot = Join-Path $ProjectRoot "lib/features"
$allConfigPaths = Get-ChildItem -Path $featuresRoot `
    -Filter "feature.config.json" `
    -Recurse `
    -ErrorAction SilentlyContinue

$allConfigs = @{}
foreach ($cp in $allConfigPaths) {
    $c = Get-Content $cp.FullName -Raw | ConvertFrom-Json
    $allConfigs[$c.feature.name] = $c
}

$allConfigs[$featureName] = $config

$graph = Build-DependencyGraph -Configs $allConfigs

if ($graph.CircularDependencies.Count -gt 0) {
    Write-Fail "Circular dependencies detected"
    foreach ($cycle in $graph.CircularDependencies) {
        Write-Host "    $cycle" -ForegroundColor Red
    }
    exit 1
}

$crossFeatureDeps = @()
if ($graph.Dependencies.ContainsKey($featureName)) {
    $crossFeatureDeps = $graph.Dependencies[$featureName]
}

if ($crossFeatureDeps.Count -gt 0) {
    Write-Step "Cross-feature dependencies: $($crossFeatureDeps -join ', ')"
}
else {
    Write-Step "No cross-feature dependencies"
}

Write-Success "Dependency graph clean"

# ------------------------------------------------------------
# PHASE B - GENERATION
# ------------------------------------------------------------

Write-Header "Phase B - Generation (Maturity $maturity)"

$tokens = @{
    FNAME  = $featureName
    FCLASS = $featureClass
    FUPPER = $featureUpper
    FLABEL = $featureLabel
    FPERM  = $permission
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

if ($maturity -ge 0) {
    Write-Step "Generating presentation layer..."
    Invoke-GeneratePresentation -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

if ($maturity -ge 1) {
    Write-Step "Generating domain..."
    Invoke-GenerateDomain     -Ctx $ctx -NewFile ${function:New-GeneratedFile}
    Invoke-GenerateRepository -Ctx $ctx -NewFile ${function:New-GeneratedFile}
    Invoke-GenerateUseCases   -Ctx $ctx -NewFile ${function:New-GeneratedFile}
    Invoke-GenerateData       -Ctx $ctx -NewFile ${function:New-GeneratedFile}
    Invoke-GenerateBloc       -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

if ($maturity -ge 2) {
    Write-Step "Generating state machine..."
    Invoke-GenerateStateMachine -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

if ($maturity -ge 3) {
    Write-Step "Generating workflow..."
    Invoke-GenerateWorkflow -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

if ($crossFeatureDeps.Count -gt 0) {
    Write-Step "Generating cross-feature providers..."
    Invoke-GenerateProviders -Ctx $ctx -NewFile ${function:New-GeneratedFile}
}

Write-Step "Wiring DI..."
Update-InjectionContainer -Ctx $ctx

Write-Step "Wiring routes..."
Update-AppRouter -Ctx $ctx

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

Write-Header "Generation Complete"

if ($DryRun) {
    Write-Warn "Dry run - no files written"
}
else {
    $fileCount = 0
    if (Test-Path $featureDir) {
        $fileCount = (Get-ChildItem $featureDir -Recurse -File).Count
    }

    Write-Success "$fileCount files generated in lib/features/$featureName"
    Write-Success "DI updated"
    Write-Success "Routes updated"
}

Write-Host ""