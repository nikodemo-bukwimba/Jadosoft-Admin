# ============================================================
# Level4WiringGenerator.psm1 -- DI + Routes + Nav for Aggregator
# FIX: Routes use GoRouter GoRoute, not MaterialPageRoute
# FIX: Nav uses NavItem -- permission-gated only if permission is provided
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

    $diPath = Join-Path $pRoot "lib\config\di\injection_container.dart"
    if (-not (Test-Path $diPath)) { Write-Warning "injection_container.dart not found"; return }

    $sources = $config.sources.PSObject.Properties

    $imports = [System.Collections.Generic.List[string]]::new()
    $imports.Add("import 'package:fca/features/${fname}/domain/usecases/get_${fname}_usecase.dart';")
    $imports.Add("import 'package:fca/features/${fname}/presentation/cubit/${fname}_cubit.dart';")

    foreach ($srcProp in $sources) {
        $srcKey = $srcProp.Name
        $src = $srcProp.Value
        $srcSnake = ConvertTo-SnakeCase $srcKey
        $srcClass = ConvertTo-PascalCase $srcKey
        $imports.Add("import 'package:fca/features/${fname}/domain/providers/${srcSnake}_data_provider.dart';")
        $imports.Add("import 'package:fca/features/${fname}/data/providers/${srcSnake}_data_provider_impl.dart';")
        $imports.Add("import 'package:fca/features/$($src.feature)/domain/repositories/$($src.feature)_repository.dart';")
    }

    $regs = [System.Collections.Generic.List[string]]::new()
    $regs.Add("")
    $regs.Add("  // -- ${fclass} (Level 4 Aggregator) --")

    # Provider registrations
    foreach ($srcProp in $sources) {
        $srcKey = $srcProp.Name
        $srcClass = ConvertTo-PascalCase $srcKey
        $regs.Add("  sl.registerLazySingleton<${srcClass}DataProvider>(")
        $regs.Add("    () => ${srcClass}DataProviderImpl(repository: sl()),")
        $regs.Add("  );")
    }

    # UseCase registration
    $ucArgs = [System.Collections.Generic.List[string]]::new()
    foreach ($srcProp in $sources) {
        $srcKey = $srcProp.Name
        $ucArgs.Add("    ${srcKey}Provider: sl(),")
    }
    $regs.Add("  sl.registerLazySingleton(() => Get${fclass}UseCase(")
    foreach ($a in $ucArgs) { $regs.Add($a) }
    $regs.Add("  ));")

    # Cubit registration
    $regs.Add("  sl.registerFactory<${fclass}Cubit>(")
    $regs.Add("    () => ${fclass}Cubit(getProjection: sl()),")
    $regs.Add("  );")

    $content = Get-Content $diPath -Raw
    $content = _Insert-AboveMarker -Content $content `
        -Marker '// -- END GENERATOR FEATURE IMPORTS' `
        -Insert ($imports -join "`n")
    $content = _Insert-AboveMarker -Content $content `
        -Marker '// -- END GENERATOR MANAGED' `
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

    # -- Imports --
    $imports = @(
        "import '../../features/${fname}/presentation/pages/${fname}_dashboard_page.dart';",
        "import '../../features/${fname}/presentation/cubit/${fname}_cubit.dart';",
        "import '../../config/di/injection_container.dart';",
        "import 'package:flutter_bloc/flutter_bloc.dart';"
    ) -join "`n"

    # -- Route constant -- aggregator has one page only --
    $consts = "  static const String ${fname}Dashboard = '/${fname}/dashboard';"

    # -- GoRoute entry inside ShellRoute --
    $goRoute = @"

            // $flabel (Level 4 Aggregator, generated $(Get-Date -Format 'yyyy-MM-dd'))
            GoRoute(
              path: ${fname}Dashboard,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<${fclass}Cubit>()..load(),
                child: const ${fclass}DashboardPage(),
              ),
            ),
"@

    $content = Get-Content $routerPath -Raw
    $content = _Insert-AboveMarker -Content $content -Marker '// -- END GENERATOR FEATURE PAGE IMPORTS' -Insert $imports
    $content = _Insert-AboveMarker -Content $content -Marker '// -- END GENERATOR ROUTE CONSTANTS'      -Insert $consts
    $content = _Insert-AboveMarker -Content $content -Marker '// -- END GENERATOR ROUTES'               -Insert $goRoute

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

    # -- Permission slug (optional) + icon --
    $fperm = $config.feature.permission
    $icon = if ($config.feature.icon) { $config.feature.icon } else { 'Icons.dashboard_outlined' }

    # -- NavItem -- permission-gated only if permission provided --
    if (-not [string]::IsNullOrWhiteSpace($fperm)) {
        $navItem = @"

      // $flabel (Level 4 Aggregator, generated $(Get-Date -Format 'yyyy-MM-dd'))
      if (auth.can('${fperm}.view'))
        NavItem(
          id:    '${fname}',
          label: '$flabel',
          icon:  $icon,
          path:  AppRouter.${fname}Dashboard,
        ),
"@
    }
    else {
        $navItem = @"

      // $flabel (Level 4 Aggregator, generated $(Get-Date -Format 'yyyy-MM-dd'))
      NavItem(
        id:    '${fname}',
        label: '$flabel',
        icon:  $icon,
        path:  AppRouter.${fname}Dashboard,
      ),
"@
    }

    $content = Get-Content $navPath -Raw
    $content = _Insert-AboveMarker -Content $content -Marker '// -- END GENERATOR TABS' -Insert $navItem

    if (-not $isDryRun) {
        Set-Content -Path $navPath -Value $content -Encoding UTF8
        Write-Host "  [OK] shell_nav_items.dart updated" -ForegroundColor Green
    }
    else {
        Write-Host "    [DRY RUN] Would update shell_nav_items.dart" -ForegroundColor DarkGray
    }
}

Export-ModuleMember -Function @('Update-InjectionContainer', 'Update-AppRouter', 'Update-ShellNavItems')
