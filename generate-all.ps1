# ============================================================
# Generate-All.ps1
# Orchestrator — generates multiple features from a manifest
# or from a list of config paths passed directly.
#
# Usage:
#   .\Generate-All.ps1
#   .\Generate-All.ps1 -ManifestPath .\custom.manifest.json
#   .\Generate-All.ps1 -Configs @("Maishell\level_0\config.json","Maishell\level_1\config.json")
#   .\Generate-All.ps1 -DryRun
#   .\Generate-All.ps1 -Force
#   .\Generate-All.ps1 -StopOnError
# ============================================================

param(
    # Path to manifest file (default: maishell.manifest.json next to this script)
    [string]$ManifestPath = (Join-Path $PSScriptRoot "maishell.manifest.json"),

    # Alternatively, pass config paths directly — skips manifest entirely
    [string[]]$Configs,

    # Pass through to each generator
    [switch]$DryRun,
    [switch]$Force,

    # Halt the entire run on first failure (default: continue and report)
    [switch]$StopOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── Helpers ───────────────────────────────────────────────────
function Write-Header([string]$t) {
    Write-Host "`n================================================================" -ForegroundColor DarkCyan
    Write-Host "  $t" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor DarkCyan
}
function Write-Section([string]$t) {
    Write-Host "`n  ── $t" -ForegroundColor DarkYellow
}
function Write-Step([string]$t) { Write-Host "     > $t" }
function Write-OK([string]$t) { Write-Host "     [OK] $t" -ForegroundColor Green }
function Write-Fail([string]$t) { Write-Host "     [FAIL] $t" -ForegroundColor Red }
function Write-Skip([string]$t) { Write-Host "     [SKIP] $t" -ForegroundColor DarkGray }
function Write-Warn([string]$t) { Write-Host "     [WARN] $t" -ForegroundColor Yellow }

# ── Resolve the generator script for a given maturity level ──
function Get-GeneratorScript([int]$Maturity) {
    $name = "Generate-Level${Maturity}.ps1"
    $path = Join-Path $PSScriptRoot "Maishell\level_${Maturity}\${name}"
    if (-not (Test-Path $path)) {
        throw "Generator script not found: $path"
    }
    return $path
}

Write-Header "MAISHELL — Batch Feature Generator"

# ── Build the job list ────────────────────────────────────────
$jobs = [System.Collections.Generic.List[hashtable]]::new()

if ($Configs -and $Configs.Count -gt 0) {
    # ── Mode A: explicit config paths passed via -Configs ─────
    Write-Step "Mode: explicit -Configs list ($($Configs.Count) entries)"
    foreach ($cp in $Configs) {
        $jobs.Add(@{ ConfigPath = $cp; Force = $Force.IsPresent })
    }
}
else {
    # ── Mode B: read manifest ─────────────────────────────────
    if (-not (Test-Path $ManifestPath)) {
        Write-Fail "Manifest not found: $ManifestPath"
        Write-Host "  Create maishell.manifest.json next to this script, or pass -Configs directly." -ForegroundColor Yellow
        exit 1
    }

    Write-Step "Mode: manifest  →  $ManifestPath"
    $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

    if ($null -eq $manifest.features -or $manifest.features.Count -eq 0) {
        Write-Fail "Manifest has no 'features' entries."
        exit 1
    }

    foreach ($entry in $manifest.features) {
        if ($entry.skip -eq $true) {
            Write-Skip "Skipping (skip: true): $($entry.config)"
            continue
        }
        # Per-entry force overrides global -Force
        $entryForce = $Force.IsPresent -or ($entry.force -eq $true)
        $jobs.Add(@{ ConfigPath = $entry.config; Force = $entryForce })
    }
}

if ($jobs.Count -eq 0) {
    Write-Warn "No features to generate after applying skip filters."
    exit 0
}

# ── Load each config and resolve maturity ─────────────────────
Write-Section "Resolving configs"

$resolved = [System.Collections.Generic.List[hashtable]]::new()

foreach ($job in $jobs) {
    $rawPath = $job.ConfigPath

    # Resolve relative to the script root
    $configPath = if ([System.IO.Path]::IsPathRooted($rawPath)) {
        $rawPath
    }
    else {
        Join-Path $PSScriptRoot $rawPath
    }

    if (-not (Test-Path $configPath)) {
        Write-Fail "Config not found: $configPath"
        if ($StopOnError) { exit 1 }
        $resolved.Add(@{
                ConfigPath = $configPath
                Status     = 'MISSING'
                Label      = $rawPath
                Maturity   = $null
            })
        continue
    }

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $maturity = [int]$config.feature.maturity
        $label = if ($config.feature.label) { $config.feature.label } else { $config.feature.name }

        $resolved.Add(@{
                ConfigPath = $configPath
                Status     = 'PENDING'
                Label      = $label
                Maturity   = $maturity
                Force      = $job.Force
            })
        Write-OK "$label  (Level $maturity)  →  $configPath"
    }
    catch {
        Write-Fail "Failed to parse config: $configPath — $_"
        if ($StopOnError) { exit 1 }
        $resolved.Add(@{
                ConfigPath = $configPath
                Status     = 'PARSE_ERROR'
                Label      = $rawPath
                Maturity   = $null
            })
    }
}

# ── Sort: ascending maturity so lower levels wire in first ────
$ordered = $resolved | Where-Object { $_.Status -eq 'PENDING' } |
Sort-Object { $_.Maturity }

$skipped = $resolved | Where-Object { $_.Status -ne 'PENDING' }

$total = $ordered.Count
$passed = 0
$failed = 0
$results = [System.Collections.Generic.List[hashtable]]::new()

# ── Carry over already-failed/missing entries into results ────
foreach ($s in $skipped) {
    $results.Add($s)
}

# ── Run generators ────────────────────────────────────────────
Write-Section "Generating $total feature(s)"

foreach ($job in $ordered) {
    $label = $job.Label
    $maturity = $job.Maturity
    $cfgPath = $job.ConfigPath

    Write-Host ""
    Write-Host "  ┌─ [$($results.Count + 1)/$($total + $skipped.Count)] $label  (Level $maturity)" -ForegroundColor Cyan

    try {
        $genScript = Get-GeneratorScript -Maturity $maturity

        # Build argument list
        $args = @("-ConfigPath", $cfgPath, "-ProjectRoot", $PSScriptRoot)
        if ($DryRun) { $args += "-DryRun" }
        if ($job.Force) { $args += "-Force" }

        & $genScript @args

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "Generator exited with code $LASTEXITCODE"
        }

        Write-Host "  └─ " -NoNewline -ForegroundColor Cyan
        Write-Host "DONE" -ForegroundColor Green
        $job.Status = 'OK'
        $passed++
    }
    catch {
        Write-Host "  └─ " -NoNewline -ForegroundColor Cyan
        Write-Fail "FAILED: $_"
        $job.Status = 'FAILED'
        $job.Error = "$_"
        $failed++

        if ($StopOnError) {
            Write-Warn "-StopOnError is set — aborting remaining features."
            # Add current and push remaining as SKIPPED
            $results.Add($job)
            $remaining = $ordered | Where-Object { $_.Status -eq 'PENDING' }
            foreach ($r in $remaining) { $r.Status = 'ABORTED'; $results.Add($r) }
            break
        }
    }

    $results.Add($job)
}

# ── Summary table ─────────────────────────────────────────────
Write-Header "Summary"

$colW = 30
Write-Host ("  {0,-$colW} {1,-8} {2}" -f "Feature", "Level", "Status") -ForegroundColor White
Write-Host ("  {0,-$colW} {1,-8} {2}" -f ("-" * ($colW - 1)), "-------", "------") -ForegroundColor DarkGray

foreach ($r in $results) {
    $lvl = if ($null -ne $r.Maturity) { "Level $($r.Maturity)" } else { "?" }
    $statusColor = switch ($r.Status) {
        'OK' { 'Green' }
        'PENDING' { 'Gray' }
        'FAILED' { 'Red' }
        'ABORTED' { 'DarkYellow' }
        'MISSING' { 'Red' }
        'PARSE_ERROR' { 'Red' }
        default { 'Gray' }
    }
    Write-Host ("  {0,-$colW} {1,-8} " -f $r.Label, $lvl) -NoNewline
    Write-Host $r.Status -ForegroundColor $statusColor
    if ($r.Error) {
        Write-Host ("  {0,-$colW}          {1}" -f "", $r.Error) -ForegroundColor DarkRed
    }
}

Write-Host ""
$dryTag = if ($DryRun) { "  [DRY RUN — no files written]" } else { "" }
if ($failed -eq 0) {
    Write-Host "  $passed/$total features generated successfully.$dryTag" -ForegroundColor Green
}
else {
    Write-Host "  $passed/$total succeeded, $failed failed.$dryTag" -ForegroundColor Yellow
}
Write-Host ""

exit $failed