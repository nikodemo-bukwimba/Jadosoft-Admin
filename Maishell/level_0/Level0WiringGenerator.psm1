# ============================================================
# Level0WiringGenerator.psm1
# Level 0 wiring — routes + shell nav tab
#
# Level 0 has NO BLoC, NO DI registrations.
# Routes are simple MaterialPageRoute — no BlocProvider wrapping.
# Shell tab is a simple page reference — no BlocProvider wrapping.
# ============================================================

<#
.SYNOPSIS
    Appends a simple route to app_router.dart for a Level 0 feature.
    No BlocProvider wrapping — just a direct page reference.
#>
function Update-AppRouter {
    param([Parameter(Mandatory)][hashtable]$Ctx)

    $fname    = $Ctx.Tokens.FNAME
    $fclass   = $Ctx.Tokens.FCLASS
    $flabel   = $Ctx.Tokens.FLABEL
    $pRoot    = $Ctx.ProjectRoot
    $isDryRun = $Ctx.DryRun

    $routerPath = Join-Path $pRoot "lib\app\routes\app_router.dart"

    if (-not (Test-Path $routerPath)) {
        Write-Warning "app_router.dart not found at: $routerPath — skipping route wiring"
        return
    }

    # ── Import statement ───────────────────────────────────
    $import = "import '../../features/${fname}/presentation/pages/${fname}_page.dart';"

    # ── Route constant ─────────────────────────────────────
    $routeConst = "  static const String ${fname}Page = '/${fname}';"

    # ── Switch case — Level 0: no BlocProvider, just the page ──
    $routeCase = @"

      // $flabel (Level 0 — static, generated $(Get-Date -Format 'yyyy-MM-dd'))
      case ${fname}Page:
        return MaterialPageRoute(
          builder: (_) => const ${fclass}Page(),
          settings: settings,
        );
"@

    # ── Write to file ──────────────────────────────────────
    $content = Get-Content $routerPath -Raw

    # Insert import
    $importMarker = '// ── END GENERATOR FEATURE PAGE IMPORTS'
    if ($content.Contains($importMarker)) {
        $content = $content.Replace($importMarker, "$import`n$importMarker")
    }

    # Insert route constant
    $constMarker = '// ── END GENERATOR ROUTE CONSTANTS'
    if ($content.Contains($constMarker)) {
        $content = $content.Replace($constMarker, "$routeConst`n  $constMarker")
    }

    # Insert switch case
    $caseMarker = '// ── GENERATOR ROUTES — append only'
    if ($content.Contains($caseMarker)) {
        $content = $content.Replace($caseMarker, "$routeCase`n      $caseMarker")
    }

    if (-not $isDryRun) {
        Set-Content -Path $routerPath -Value $content -Encoding UTF8
        Write-Host "  [OK] app_router.dart updated with ${fclass} route" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update app_router.dart" -ForegroundColor DarkGray
    }
}

<#
.SYNOPSIS
    Appends a nav tab to shell_nav_items.dart for a Level 0 feature.
    No BlocProvider wrapping — just a const page reference.
#>
function Update-ShellNavItems {
    param([Parameter(Mandatory)][hashtable]$Ctx)

    $fname    = $Ctx.Tokens.FNAME
    $fclass   = $Ctx.Tokens.FCLASS
    $flabel   = $Ctx.Tokens.FLABEL
    $config   = $Ctx.Config
    $pRoot    = $Ctx.ProjectRoot
    $isDryRun = $Ctx.DryRun

    $navPath = Join-Path $pRoot "lib\app\shell\shell_nav_items.dart"

    if (-not (Test-Path $navPath)) {
        Write-Warning "shell_nav_items.dart not found at: $navPath — skipping nav wiring"
        return
    }

    # Determine icon from config or use defaults
    $icon       = if ($config.feature.icon)       { $config.feature.icon }       else { 'Icons.article_outlined' }
    $activeIcon = if ($config.feature.activeIcon)  { $config.feature.activeIcon }  else { 'Icons.article' }

    # ── Import statement ───────────────────────────────────
    $import = "import '../../features/${fname}/presentation/pages/${fname}_page.dart';"

    # ── Tab entry — Level 0: no BlocProvider, just const page ──
    $tabEntry = @"
      // $flabel tab (Level 0 — static, generated $(Get-Date -Format 'yyyy-MM-dd'))
      ShellTabConfig(
        label:      '$flabel',
        icon:       $icon,
        activeIcon: $activeIcon,
        page:       const ${fclass}Page(),
      ),
"@

    # ── Write to file ──────────────────────────────────────
    $content = Get-Content $navPath -Raw

    # Insert import
    $importMarker = '// ── END GENERATOR FEATURE IMPORTS'
    if ($content.Contains($importMarker)) {
        $content = $content.Replace($importMarker, "$import`n$importMarker")
    }

    # Insert tab
    $tabMarker = '// ── END GENERATOR TABS'
    if ($content.Contains($tabMarker)) {
        $content = $content.Replace($tabMarker, "$tabEntry`n      $tabMarker")
    }

    if (-not $isDryRun) {
        Set-Content -Path $navPath -Value $content -Encoding UTF8
        Write-Host "  [OK] shell_nav_items.dart updated with ${fclass} tab" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update shell_nav_items.dart" -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function @(
    'Update-AppRouter',
    'Update-ShellNavItems'
)
