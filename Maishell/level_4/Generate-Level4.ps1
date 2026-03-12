# ============================================================
# Generate-Level4.ps1 -- Level 4: Aggregator / Dashboard
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

Import-Module (Join-Path $ModuleRoot "TemplateEngine.psm1")              -Force
Import-Module (Join-Path $ModuleRoot "Validator.psm1")                   -Force
Import-Module (Join-Path $GenRoot    "Level4ProjectionGenerator.psm1")   -Force
Import-Module (Join-Path $GenRoot    "Level4CubitGenerator.psm1")        -Force
Import-Module (Join-Path $GenRoot    "Level4PageGenerator.psm1")         -Force
Import-Module (Join-Path $GenRoot    "Level4WiringGenerator.psm1")       -Force

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

Write-Header "HALA FCA - Level 4 Feature Generator (Aggregator / Dashboard)"

$ConfigPath = Resolve-Path $ConfigPath
if (-not (Test-Path $ConfigPath)) { Write-Fail "Config not found: $ConfigPath"; exit 1 }

Write-Step "Loading config: $ConfigPath"
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# -- Validation --
$maturity = [int]$config.feature.maturity
if ($maturity -ne 4) { Write-Fail "This generator handles Level 4 only. Config declares maturity $maturity."; exit 1 }
if ($null -eq $config.sources -or ($config.sources.PSObject.Properties | Measure-Object).Count -eq 0) {
    Write-Fail "Level 4 requires a 'sources' block with at least 1 source."; exit 1
}
if ($null -eq $config.projection -or $null -eq $config.projection.metrics -or $config.projection.metrics.Count -eq 0) {
    Write-Fail "Level 4 requires 'projection.metrics' with at least 1 metric."; exit 1
}

# Validate each metric
foreach ($m in $config.projection.metrics) {
    if (-not $m.name) { Write-Fail "Each metric must have a 'name'."; exit 1 }
    if (-not $m.type) { Write-Fail "Metric '$($m.name)' must have a 'type'."; exit 1 }
    if (-not $m.source) { Write-Fail "Metric '$($m.name)' must have a 'source'."; exit 1 }
    if (-not $m.operation) { Write-Fail "Metric '$($m.name)' must have an 'operation'."; exit 1 }
    $validOps = @('count', 'sum', 'sumNonNull', 'average', 'groupCount', 'latest')
    if ($m.operation -notin $validOps) { Write-Fail "Metric '$($m.name)' operation '$($m.operation)' not in: $($validOps -join ', ')"; exit 1 }
    # Verify source exists
    $srcNames = @($config.sources.PSObject.Properties | ForEach-Object { $_.Name })
    if ($m.source -notin $srcNames) { Write-Fail "Metric '$($m.name)' references source '$($m.source)' not in sources: $($srcNames -join ', ')"; exit 1 }
}

$tokens = Get-NamingTokens -FeatureConfig $config.feature
Write-Step "Feature: $($tokens.FLABEL) (Level 4 Aggregator)"

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
    Maturity    = 4
}

Write-Step "1. Projection + providers + use case..."
Invoke-GenerateProjection -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "2. Cubit (state management)..."
Invoke-GenerateCubit -Ctx $ctx -NewFile ${function:New-GeneratedFile}

Write-Step "3. Dashboard page + widgets..."
Invoke-GenerateDashboardPages -Ctx $ctx -NewFile ${function:New-GeneratedFile}

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

