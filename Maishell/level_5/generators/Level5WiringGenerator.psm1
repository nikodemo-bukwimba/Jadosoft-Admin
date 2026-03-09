# ============================================================
# Level5WiringGenerator.psm1 — DI + Routes + Nav for Integration
# FIX: Routes use GoRouter GoRoute, not MaterialPageRoute
# FIX: Nav uses permission-gated NavItem, not ShellTabConfig
# ============================================================

function _Insert-AboveMarker {
    param([string]$Content, [string]$Marker, [string]$Insert)
    $lines = $Content -split "`n"
    $result = [System.Collections.Generic.List[string]]::new()
    $inserted = $false
    foreach ($line in $lines) {
        if (-not $inserted -and $line.TrimStart().StartsWith($Marker.TrimStart())) {
            foreach ($iLine in ($Insert -split "`n")) { $result.Add($iLine) }
            $inserted = $true
        }
        $result.Add($line)
    }
    if (-not $inserted) { Write-Warning "Marker not found: $Marker" }
    return $result -join "`n"
}

function Update-InjectionContainer {
    param([Parameter(Mandatory)][hashtable]$Ctx)
    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $pRoot = $Ctx.ProjectRoot
    $config = $Ctx.Config
    $isDryRun = $Ctx.DryRun
    $intg = $config.integration

    $diPath = Join-Path $pRoot "lib\config\di\injection_container.dart"
    if (-not (Test-Path $diPath)) { Write-Warning "injection_container.dart not found"; return }

    $imports = [System.Collections.Generic.List[string]]::new()
    $imports.Add("import 'package:fca/features/${fname}/data/client/${fname}_client.dart';")
    $imports.Add("import 'package:fca/features/${fname}/domain/services/${fname}_service.dart';")
    $imports.Add("import 'package:fca/features/${fname}/presentation/cubit/${fname}_cubit.dart';")
    if ($intg.webhooks -and $intg.webhooks.Count -gt 0) {
        $imports.Add("import 'package:fca/features/${fname}/domain/services/${fname}_webhook_handler.dart';")
    }

    $regs = [System.Collections.Generic.List[string]]::new()
    $regs.Add("")
    $regs.Add("  // ── ${fclass} (Level 5 Integration) ──────────────────")

    # Client
    $regs.Add("  sl.registerLazySingleton(() => ${fclass}Client(dio: sl()));")

    # Service
    $regs.Add("  sl.registerLazySingleton(() => ${fclass}Service(client: sl()));")

    # Webhook handler
    if ($intg.webhooks -and $intg.webhooks.Count -gt 0) {
        $regs.Add("  sl.registerLazySingleton(() => ${fclass}WebhookHandler());")
    }

    # Cubit
    $regs.Add("  sl.registerFactory<${fclass}Cubit>(")
    $regs.Add("    () => ${fclass}Cubit(service: sl()),")
    $regs.Add("  );")

    $content = Get-Content $diPath -Raw
    $content = _Insert-AboveMarker -Content $content `
        -Marker '// ── END GENERATOR FEATURE IMPORTS' `
        -Insert ($imports -join "`n")
    $content = _Insert-AboveMarker -Content $content `
        -Marker '// ── END GENERATOR MANAGED' `
        -Insert ($regs -join "`n")

    if (-not $isDryRun) {
        Set-Content -Path $diPath -Value $content -Encoding UTF8
        Write-Host "  [OK] injection_container.dart updated" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update injection_container.dart" -ForegroundColor DarkGray
    }
}

function Update-AppRouter {
    param([Parameter(Mandatory)][hashtable]$Ctx)
    $fname = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $pRoot = $Ctx.ProjectRoot
    $isDryRun = $Ctx.DryRun

    $routerPath = Join-Path $pRoot "lib\app\routes\app_router.dart"
    if (-not (Test-Path $routerPath)) { Write-Warning "app_router.dart not found"; return }

    # ── Imports ────────────────────────────────────────────
    $imports = @(
        "import '../../features/${fname}/presentation/pages/${fname}_page.dart';",
        "import '../../features/${fname}/presentation/cubit/${fname}_cubit.dart';",
        "import '../../config/di/injection_container.dart';",
        "import 'package:flutter_bloc/flutter_bloc.dart';"
    ) -join "`n"

    # ── Route constant — integration has one page only ─────
    $consts = "  static const String ${fname}Page = '/${fname}';"

    # ── GoRoute entry inside ShellRoute ───────────────────
    $goRoute = @"

            // $flabel (Level 5 Integration, generated $(Get-Date -Format 'yyyy-MM-dd'))
            GoRoute(
              path: ${fname}Page,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<${fclass}Cubit>(),
                child: const ${fclass}Page(),
              ),
            ),
"@

    $content = Get-Content $routerPath -Raw
    $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR FEATURE PAGE IMPORTS' -Insert $imports
    $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR ROUTE CONSTANTS'      -Insert $consts
    $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR ROUTES'               -Insert $goRoute

    if (-not $isDryRun) {
        Set-Content -Path $routerPath -Value $content -Encoding UTF8
        Write-Host "  [OK] app_router.dart updated" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update app_router.dart" -ForegroundColor DarkGray
    }
}

function Update-ShellNavItems {
    param([Parameter(Mandatory)][hashtable]$Ctx)
    $fname = $Ctx.Tokens.FNAME
    $flabel = $Ctx.Tokens.FLABEL
    $config = $Ctx.Config
    $pRoot = $Ctx.ProjectRoot
    $isDryRun = $Ctx.DryRun

    $navPath = Join-Path $pRoot "lib\app\shell\shell_nav_items.dart"
    if (-not (Test-Path $navPath)) { Write-Warning "shell_nav_items.dart not found"; return }

    # ── Permission slug + icon from config ─────────────────
    $fperm = $config.feature.permission
    $icon = if ($config.feature.icon) { $config.feature.icon } else { 'Icons.cloud_outlined' }

    # ── NavItem entry — permission-gated, path-only ────────
    $navItem = @"

      // $flabel (Level 5 Integration, generated $(Get-Date -Format 'yyyy-MM-dd'))
      if (auth.can('${fperm}.view'))
        NavItem(
          id:    '${fname}',
          label: '$flabel',
          icon:  $icon,
          path:  AppRouter.${fname}Page,
        ),
"@

    $content = Get-Content $navPath -Raw
    $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR TABS' -Insert $navItem

    if (-not $isDryRun) {
        Set-Content -Path $navPath -Value $content -Encoding UTF8
        Write-Host "  [OK] shell_nav_items.dart updated" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update shell_nav_items.dart" -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function @('Update-InjectionContainer', 'Update-AppRouter', 'Update-ShellNavItems')