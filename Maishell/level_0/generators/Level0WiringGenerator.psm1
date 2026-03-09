# ============================================================
# Level0WiringGenerator.psm1
# Level 0 wiring — routes + shell nav tab
#
# Level 0 has NO BLoC, NO DI registrations.
# Routes are GoRoute entries inside ShellRoute — no BlocProvider wrapping.
# Nav item is a permission-gated NavItem — no page import needed in shell_nav_items.dart.
# ============================================================

<#
.SYNOPSIS
    Appends a GoRoute entry to app_router.dart for a Level 0 feature.
    No BlocProvider wrapping — just a direct const page reference.
#>
function Update-AppRouter {
    param([Parameter(Mandatory)][hashtable]$Ctx)

    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $pRoot = $Ctx.ProjectRoot
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

    # ── GoRoute entry — Level 0: no BlocProvider, just const page ──
    $goRoute = @"

            // $flabel (Level 0 — static, generated $(Get-Date -Format 'yyyy-MM-dd'))
            GoRoute(
              path: ${fname}Page,
              builder: (_, __) => const ${fclass}Page(),
            ),
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

    # Insert GoRoute inside ShellRoute
    $routeMarker = '// ── END GENERATOR ROUTES'
    if ($content.Contains($routeMarker)) {
        $content = $content.Replace($routeMarker, "$goRoute`n            $routeMarker")
    }

    if (-not $isDryRun) {
        Set-Content -Path $routerPath -Value $content -Encoding UTF8
        Write-Host "  [OK] app_router.dart updated with ${fclass} GoRoute" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update app_router.dart" -ForegroundColor DarkGray
    }
}

<#
.SYNOPSIS
    Appends a permission-gated NavItem to shell_nav_items.dart for a Level 0 feature.
    NavItem only needs the path — no page import required in shell_nav_items.dart.
#>
function Update-ShellNavItems {
    param([Parameter(Mandatory)][hashtable]$Ctx)

    $fname = $Ctx.Tokens.FNAME
    $flabel = $Ctx.Tokens.FLABEL
    $config = $Ctx.Config
    $pRoot = $Ctx.ProjectRoot
    $isDryRun = $Ctx.DryRun

    $navPath = Join-Path $pRoot "lib\app\shell\shell_nav_items.dart"

    if (-not (Test-Path $navPath)) {
        Write-Warning "shell_nav_items.dart not found at: $navPath — skipping nav wiring"
        return
    }

    # ── Permission slug from config ────────────────────────
    $fperm = $config.feature.permission

    # ── Icon from config or defaults ───────────────────────
    $icon = if ($config.feature.icon) { $config.feature.icon } else { 'Icons.article_outlined' }

    # ── NavItem entry — permission-gated, path-only ────────
    $navItem = @"

      // $flabel (Level 0 — static, generated $(Get-Date -Format 'yyyy-MM-dd'))
      if (auth.can('${fperm}.view'))
        NavItem(
          id:    '${fname}',
          label: '$flabel',
          icon:  $icon,
          path:  AppRouter.${fname}Page,
        ),
"@

    # ── Write to file ──────────────────────────────────────
    $content = Get-Content $navPath -Raw

    # Insert NavItem inside generator markers
    $tabMarker = '// ── END GENERATOR TABS'
    if ($content.Contains($tabMarker)) {
        $content = $content.Replace($tabMarker, "$navItem`n      $tabMarker")
    }

    if (-not $isDryRun) {
        Set-Content -Path $navPath -Value $content -Encoding UTF8
        Write-Host "  [OK] shell_nav_items.dart updated with ${flabel} NavItem" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update shell_nav_items.dart" -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function @(
    'Update-AppRouter',
    'Update-ShellNavItems'
)