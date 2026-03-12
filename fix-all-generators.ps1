# fix-all-generators.ps1
# Run from project root: .\fix-all-generators.ps1
# Fixes: Validator types, stateMachine.states→statuses, Level 5 module loading

$ErrorActionPreference = "Continue"
$fixed = 0

Write-Host "`n=== Fix 1: Validator — allow List<> and Map<> compound types ===" -ForegroundColor Cyan
Get-ChildItem ".\Maishell" -Recurse -Filter "Validator.psm1" | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    $old = @'
$fDef.type -notmatch 'Status$') {
'@
    $new = @'
$fDef.type -notmatch 'Status$' -and $fDef.type -notmatch '^List<' -and $fDef.type -notmatch '^Map<') {
'@
    if ($c.Contains($old)) {
        $c = $c.Replace($old, $new)
        Set-Content -Path $_.FullName -Value $c -Encoding UTF8
        Write-Host "  Fixed: $($_.Name) in $($_.Directory.Name)" -ForegroundColor Green
        $script:fixed++
    } else {
        Write-Host "  Skip (already fixed or different pattern): $($_.Name) in $($_.Directory.Name)" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== Fix 2: Generate-Level2/3 — stateMachine.states → stateMachine.statuses ===" -ForegroundColor Cyan
Get-ChildItem ".\Maishell" -Recurse -Include "*.ps1","*.psm1" | ForEach-Object {
    $c = Get-Content $_.FullName -Raw
    if ($c.Contains('.stateMachine.states')) {
        $c = $c.Replace('.stateMachine.states', '.stateMachine.statuses')
        Set-Content -Path $_.FullName -Value $c -Encoding UTF8
        Write-Host "  Fixed: $($_.Name) in $($_.Directory.Name)" -ForegroundColor Green
        $script:fixed++
    }
}

Write-Host "`n=== Fix 3: Level 5 — re-save all modules as clean UTF-8 (no BOM) ===" -ForegroundColor Cyan
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PS 7+ — UTF8 without BOM by default
    Get-ChildItem ".\Maishell\level_5\generators" -Filter "*.psm1" | ForEach-Object {
        $c = Get-Content $_.FullName -Raw
        [System.IO.File]::WriteAllText($_.FullName, $c, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  Re-saved (no BOM): $($_.Name)" -ForegroundColor Green
        $script:fixed++
    }
    Get-ChildItem ".\Maishell\level_5\modules" -Filter "*.psm1" | ForEach-Object {
        $c = Get-Content $_.FullName -Raw
        [System.IO.File]::WriteAllText($_.FullName, $c, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  Re-saved (no BOM): $($_.Name)" -ForegroundColor Green
        $script:fixed++
    }
    $l5script = ".\Maishell\level_5\Generate-Level5.ps1"
    if (Test-Path $l5script) {
        $c = Get-Content $l5script -Raw
        [System.IO.File]::WriteAllText($l5script, $c, [System.Text.UTF8Encoding]::new($false))
        Write-Host "  Re-saved (no BOM): Generate-Level5.ps1" -ForegroundColor Green
        $script:fixed++
    }
} else {
    # PS 5.1 — need explicit no-BOM encoding
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    Get-ChildItem ".\Maishell\level_5" -Recurse -Include "*.psm1","*.ps1" | ForEach-Object {
        $c = Get-Content $_.FullName -Raw
        [System.IO.File]::WriteAllText($_.FullName, $c, $utf8NoBom)
        Write-Host "  Re-saved (no BOM): $($_.Name)" -ForegroundColor Green
        $script:fixed++
    }
}

Write-Host "`n=== Fix 4: Re-save ALL generator modules as clean UTF-8 (no BOM) ===" -ForegroundColor Cyan
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
Get-ChildItem ".\Maishell" -Recurse -Include "*.psm1","*.ps1" | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    # Check for BOM (EF BB BF)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $c = [System.IO.File]::ReadAllText($_.FullName)
        [System.IO.File]::WriteAllText($_.FullName, $c, $utf8NoBom)
        Write-Host "  Removed BOM: $($_.Name)" -ForegroundColor Yellow
        $script:fixed++
    }
}

Write-Host "`n=== Diagnostic: Test Level 5 module loading ===" -ForegroundColor Cyan
try {
    Import-Module ".\Maishell\level_5\modules\TemplateEngine.psm1" -Force -ErrorAction Stop
    Write-Host "  [OK] TemplateEngine.psm1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] TemplateEngine.psm1: $_" -ForegroundColor Red
}
try {
    Import-Module ".\Maishell\level_5\generators\Level5ClientGenerator.psm1" -Force -ErrorAction Stop
    $cmd = Get-Command Invoke-GenerateIntegrationClient -ErrorAction SilentlyContinue
    if ($cmd) { Write-Host "  [OK] Invoke-GenerateIntegrationClient found" -ForegroundColor Green }
    else { Write-Host "  [FAIL] Invoke-GenerateIntegrationClient NOT exported" -ForegroundColor Red }
} catch {
    Write-Host "  [FAIL] Level5ClientGenerator.psm1: $_" -ForegroundColor Red
}
try {
    Import-Module ".\Maishell\level_5\generators\Level5CubitGenerator.psm1" -Force -ErrorAction Stop
    Write-Host "  [OK] Level5CubitGenerator.psm1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Level5CubitGenerator.psm1: $_" -ForegroundColor Red
}
try {
    Import-Module ".\Maishell\level_5\generators\Level5PageGenerator.psm1" -Force -ErrorAction Stop
    Write-Host "  [OK] Level5PageGenerator.psm1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Level5PageGenerator.psm1: $_" -ForegroundColor Red
}
try {
    Import-Module ".\Maishell\level_5\generators\Level5WiringGenerator.psm1" -Force -ErrorAction Stop
    Write-Host "  [OK] Level5WiringGenerator.psm1 loaded" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Level5WiringGenerator.psm1: $_" -ForegroundColor Red
}

Write-Host "`n=== Done — $fixed files fixed ===" -ForegroundColor Cyan
Write-Host "Re-run generation command now.`n" -ForegroundColor White
