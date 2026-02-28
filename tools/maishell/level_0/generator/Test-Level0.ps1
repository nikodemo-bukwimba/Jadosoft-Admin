# ============================================================
# Test-Level0.ps1
# Automated test for Level 0 generator.
#
# Usage:
#   cd tools\generator
#   .\tests\Test-Level0.ps1
#
# What it does:
#   1. Creates a temp mock project with boundary markers
#   2. Runs the Level 0 generator
#   3. Compares generated Dart against expected output
#   4. Verifies wiring was inserted correctly
#   5. Reports pass/fail per check
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GenRoot  = Split-Path $PSScriptRoot -Parent
$TestRoot = $PSScriptRoot
$TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) "hala_gen_test_$(Get-Random)"

$passed = 0
$failed = 0

function Assert-True {
    param([string]$Name, [bool]$Condition, [string]$Detail = '')

    if ($Condition) {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:passed++
    }
    else {
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "         $Detail" -ForegroundColor Yellow }
        $script:failed++
    }
}

function Assert-FileExists {
    param([string]$Path, [string]$Label)
    Assert-True $Label (Test-Path $Path) "File not found: $Path"
}

function Assert-FileContains {
    param([string]$Path, [string]$Needle, [string]$Label)

    if (-not (Test-Path $Path)) {
        Assert-True $Label $false "File not found: $Path"
        return
    }
    $content = Get-Content $Path -Raw
    Assert-True $Label ($content.Contains($Needle)) "String not found: '$Needle'"
}

function Assert-FileNotContains {
    param([string]$Path, [string]$Needle, [string]$Label)

    if (-not (Test-Path $Path)) {
        Assert-True $Label $false "File not found: $Path"
        return
    }
    $content = Get-Content $Path -Raw
    Assert-True $Label (-not $content.Contains($Needle)) "Unexpected string found: '$Needle'"
}

function Assert-FilesMatch {
    param([string]$ActualPath, [string]$ExpectedPath, [string]$Label)

    if (-not (Test-Path $ActualPath)) {
        Assert-True $Label $false "Actual file not found: $ActualPath"
        return
    }
    if (-not (Test-Path $ExpectedPath)) {
        Assert-True $Label $false "Expected file not found: $ExpectedPath"
        return
    }

    $actual   = (Get-Content $ActualPath -Raw).Trim().Replace("`r`n", "`n")
    $expected = (Get-Content $ExpectedPath -Raw).Trim().Replace("`r`n", "`n")

    if ($actual -eq $expected) {
        Assert-True $Label $true
    }
    else {
        Assert-True $Label $false "Content mismatch. Run diff to compare."

        # Show first difference for debugging
        $aLines = $actual -split "`n"
        $eLines = $expected -split "`n"
        $maxLines = [Math]::Max($aLines.Count, $eLines.Count)
        for ($i = 0; $i -lt $maxLines; $i++) {
            $aLine = if ($i -lt $aLines.Count) { $aLines[$i] } else { '<missing>' }
            $eLine = if ($i -lt $eLines.Count) { $eLines[$i] } else { '<missing>' }
            if ($aLine -ne $eLine) {
                Write-Host "         Line $($i + 1):" -ForegroundColor Yellow
                Write-Host "           Expected: $eLine" -ForegroundColor Yellow
                Write-Host "           Actual:   $aLine" -ForegroundColor Yellow
                break
            }
        }
    }
}

# ── Setup ──────────────────────────────────────────────────
Write-Host ""
Write-Host "===============================================" -ForegroundColor DarkCyan
Write-Host " Level 0 Generator — Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Temp dir: $TempDir"

# Create temp mock project
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

# ── Run generator ──────────────────────────────────────────
Write-Host ""
Write-Host "--- Running generator ---" -ForegroundColor DarkGray

$configPath = Join-Path $TestRoot "level0_about.config.json"

& (Join-Path $GenRoot "Generate-Level0.ps1") `
    -ConfigPath $configPath `
    -ProjectRoot $TempDir `
    -Force

Write-Host ""
Write-Host "--- Running assertions ---" -ForegroundColor DarkGray
Write-Host ""

# ── Test 1: File structure ─────────────────────────────────
Write-Host "  File structure:" -ForegroundColor White

$featureDir = Join-Path $TempDir "lib\features\about"

Assert-FileExists `
    (Join-Path $featureDir "presentation\pages\about_page.dart") `
    "about_page.dart exists"

Assert-FileExists `
    (Join-Path $featureDir "presentation\widgets\about_widget.dart") `
    "about_widget.dart exists"

# Verify ONLY 2 files generated (no domain, no data, no BLoC)
$fileCount = (Get-ChildItem $featureDir -Recurse -File).Count
Assert-True "Exactly 2 files generated (got $fileCount)" ($fileCount -eq 2)

# Verify NO domain or data directories
Assert-True "No domain/ directory" (-not (Test-Path (Join-Path $featureDir "domain")))
Assert-True "No data/ directory"   (-not (Test-Path (Join-Path $featureDir "data")))

# ── Test 2: Dart content matches expected ──────────────────
Write-Host ""
Write-Host "  Dart content:" -ForegroundColor White

Assert-FilesMatch `
    (Join-Path $featureDir "presentation\pages\about_page.dart") `
    (Join-Path $TestRoot "expected\about\presentation\pages\about_page.dart") `
    "about_page.dart matches expected output"

Assert-FilesMatch `
    (Join-Path $featureDir "presentation\widgets\about_widget.dart") `
    (Join-Path $TestRoot "expected\about\presentation\widgets\about_widget.dart") `
    "about_widget.dart matches expected output"

# ── Test 3: Page content correctness ───────────────────────
Write-Host ""
Write-Host "  Page correctness:" -ForegroundColor White

$pageFile = Join-Path $featureDir "presentation\pages\about_page.dart"

Assert-FileContains $pageFile "class AboutPage extends StatelessWidget" `
    "Page is StatelessWidget (not Stateful)"

Assert-FileContains $pageFile "import '../widgets/about_widget.dart'" `
    "Page imports its widget"

Assert-FileContains $pageFile "const Text('About')" `
    "AppBar uses feature label"

Assert-FileContains $pageFile "AboutWidget()" `
    "Page renders the widget"

Assert-FileNotContains $pageFile "flutter_bloc" `
    "Page does NOT import flutter_bloc"

Assert-FileNotContains $pageFile "BlocProvider" `
    "Page does NOT use BlocProvider"

Assert-FileNotContains $pageFile "repository" `
    "Page does NOT reference repository"

# ── Test 4: Widget content correctness ─────────────────────
Write-Host ""
Write-Host "  Widget correctness:" -ForegroundColor White

$widgetFile = Join-Path $featureDir "presentation\widgets\about_widget.dart"

Assert-FileContains $widgetFile "class AboutWidget extends StatelessWidget" `
    "Widget is StatelessWidget"

Assert-FileContains $widgetFile "'About'" `
    "Widget displays feature label"

Assert-FileNotContains $widgetFile "flutter_bloc" `
    "Widget does NOT import flutter_bloc"

Assert-FileNotContains $widgetFile "async" `
    "Widget has no async calls"

# ── Test 5: Route wiring ──────────────────────────────────
Write-Host ""
Write-Host "  Route wiring:" -ForegroundColor White

$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"

Assert-FileContains $routerFile "import '../../features/about/presentation/pages/about_page.dart'" `
    "Router imports AboutPage"

Assert-FileContains $routerFile "static const String aboutPage = '/about'" `
    "Router declares route constant"

Assert-FileContains $routerFile "const AboutPage()" `
    "Router creates AboutPage"

Assert-FileContains $routerFile "MaterialPageRoute" `
    "Router uses MaterialPageRoute (not GoRoute)"

Assert-FileNotContains $routerFile "BlocProvider" `
    "Router does NOT wrap in BlocProvider (Level 0)"

Assert-FileNotContains $routerFile "GoRoute" `
    "Router does NOT use GoRoute"

# ── Test 6: Shell nav wiring ──────────────────────────────
Write-Host ""
Write-Host "  Shell nav wiring:" -ForegroundColor White

$navFile = Join-Path $TempDir "lib\app\shell\shell_nav_items.dart"

Assert-FileContains $navFile "import '../../features/about/presentation/pages/about_page.dart'" `
    "Nav imports AboutPage"

Assert-FileContains $navFile "label:      'About'" `
    "Nav tab uses feature label"

Assert-FileContains $navFile "Icons.info_outlined" `
    "Nav tab uses config icon"

Assert-FileContains $navFile "Icons.info" `
    "Nav tab uses config activeIcon"

Assert-FileContains $navFile "const AboutPage()" `
    "Nav tab uses const page (no BlocProvider)"

Assert-FileNotContains $navFile "BlocProvider" `
    "Nav does NOT use BlocProvider (Level 0)"

# ── Test 7: Validation rejects invalid configs ────────────
Write-Host ""
Write-Host "  Validation:" -ForegroundColor White

Import-Module (Join-Path $GenRoot "modules\Validator.psm1") -Force

# Valid config
$validConfig = Get-Content $configPath -Raw | ConvertFrom-Json
$validErrors = Invoke-ConfigValidation -Config $validConfig
Assert-True "Valid config passes validation (0 errors)" ($validErrors.Count -eq 0)

# Invalid: missing name
$badConfig1 = '{"feature":{"label":"X","purpose":"X","maturity":0,"permission":"x"}}' | ConvertFrom-Json
$err1 = Invoke-ConfigValidation -Config $badConfig1
Assert-True "Missing name rejected" ($err1 -join ' ').Contains('feature.name is required')

# Invalid: non-snake_case name
$badConfig2 = '{"feature":{"name":"MyFeature","label":"X","purpose":"X","maturity":0,"permission":"x"}}' | ConvertFrom-Json
$err2 = Invoke-ConfigValidation -Config $badConfig2
Assert-True "PascalCase name rejected" ($err2 -join ' ').Contains('snake_case')

# Invalid: storage declared at Level 0
$badConfig3 = '{"feature":{"name":"x","label":"X","purpose":"X","maturity":0,"permission":"x"},"storage":{"remote":true}}' | ConvertFrom-Json
$err3 = Invoke-ConfigValidation -Config $badConfig3
Assert-True "Storage at Level 0 rejected" ($err3 -join ' ').Contains('must NOT declare')

# Invalid: stateMachine at Level 0
$badConfig4 = '{"feature":{"name":"x","label":"X","purpose":"X","maturity":0,"permission":"x"},"stateMachine":{}}' | ConvertFrom-Json
$err4 = Invoke-ConfigValidation -Config $badConfig4
Assert-True "StateMachine at Level 0 rejected" ($err4 -join ' ').Contains('must NOT declare')

# Invalid: maturity out of range
$badConfig5 = '{"feature":{"name":"x","label":"X","purpose":"X","maturity":9,"permission":"x"}}' | ConvertFrom-Json
$err5 = Invoke-ConfigValidation -Config $badConfig5
Assert-True "Maturity 9 rejected" ($err5 -join ' ').Contains('must be 0-5')

# ── Cleanup ────────────────────────────────────────────────
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

# ── Summary ────────────────────────────────────────────────
Write-Host ""
Write-Host "===============================================" -ForegroundColor DarkCyan
$total = $passed + $failed
if ($failed -eq 0) {
    Write-Host " ALL $total TESTS PASSED" -ForegroundColor Green
}
else {
    Write-Host " $passed/$total passed, $failed FAILED" -ForegroundColor Red
}
Write-Host "===============================================" -ForegroundColor DarkCyan
Write-Host ""

exit $failed
