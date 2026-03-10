# ============================================================
# Level2WiringGenerator.psm1 — DI + Routes + Nav (No Workflow)
# FIX: Permission is optional — NavItem is visible to all if not provided.
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
  $isRemote = $config.storage.remote -eq $true
  $isLocal = ($null -ne $config.storage.local) -and ($config.storage.local -eq $true)

  $diPath = Join-Path $pRoot "lib\config\di\injection_container.dart"
  if (-not (Test-Path $diPath)) { Write-Warning "injection_container.dart not found"; return }

  $imports = [System.Collections.Generic.List[string]]::new()
  if ($isRemote) { $imports.Add("import 'package:fca/features/${fname}/data/datasources/${fname}_remote_datasource.dart';") }
  if ($isLocal) { $imports.Add("import 'package:fca/features/${fname}/data/datasources/${fname}_local_datasource.dart';") }
  $imports.Add("import 'package:fca/features/${fname}/data/repositories/${fname}_repository_impl.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/repositories/${fname}_repository.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/usecases/get_all_${fname}_usecase.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/usecases/get_${fname}_usecase.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/usecases/create_${fname}_usecase.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/usecases/update_${fname}_usecase.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/usecases/delete_${fname}_usecase.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/guards/${fname}_transition_guard.dart';")
  $imports.Add("import 'package:fca/features/${fname}/domain/services/${fname}_domain_service.dart';")
  # NO workflow import — Level 2
  $imports.Add("import 'package:fca/features/${fname}/presentation/bloc/${fname}_bloc.dart';")

  $regs = [System.Collections.Generic.List[string]]::new()
  $regs.Add("")
  $regs.Add("  // ── ${fclass} (Level 2) ──────────────────────────────")

  if ($isRemote) {
    $regs.Add("  sl.registerLazySingleton<${fclass}RemoteDataSource>(")
    $regs.Add("    () => ${fclass}RemoteDataSourceImpl(dio: sl()),")
    $regs.Add("  );")
  }

  $repoArgs = @()
  if ($isRemote) { $repoArgs += "remoteDataSource: sl()" }
  if ($isLocal) { $repoArgs += "localDataSource: sl()" }
  $regs.Add("  sl.registerLazySingleton<${fclass}Repository>(")
  $regs.Add("    () => ${fclass}RepositoryImpl($($repoArgs -join ', ')),")
  $regs.Add("  );")

  $regs.Add("  sl.registerLazySingleton(() => GetAll${fclass}UseCase(sl()));")
  $regs.Add("  sl.registerLazySingleton(() => Get${fclass}UseCase(sl()));")
  $regs.Add("  sl.registerLazySingleton(() => Create${fclass}UseCase(sl()));")
  $regs.Add("  sl.registerLazySingleton(() => Update${fclass}UseCase(sl()));")
  $regs.Add("  sl.registerLazySingleton(() => Delete${fclass}UseCase(sl()));")

  $regs.Add("  sl.registerLazySingleton(() => ${fclass}TransitionGuard());")
  $regs.Add("  sl.registerLazySingleton(() => ${fclass}DomainService(")
  $regs.Add("    repository: sl(), guard: sl(),")
  $regs.Add("  ));")
  # NO workflow executor — Level 2

  $regs.Add("  sl.registerFactory<${fclass}Bloc>(() => ${fclass}Bloc(")
  $regs.Add("    getAllUseCase: sl(), getUseCase: sl(), createUseCase: sl(),")
  $regs.Add("    updateUseCase: sl(), deleteUseCase: sl(),")
  $regs.Add("    domainService: sl(),")
  $regs.Add("  ));")

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
    "import '../../features/${fname}/presentation/pages/${fname}_list_page.dart';",
    "import '../../features/${fname}/presentation/pages/${fname}_detail_page.dart';",
    "import '../../features/${fname}/presentation/pages/${fname}_form_page.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_bloc.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_event.dart';",
    "import '../../features/${fname}/presentation/enums/${fname}_form_node.dart';",
    "import '../../config/di/injection_container.dart';",
    "import 'package:flutter_bloc/flutter_bloc.dart';"
  ) -join "`n"

  # ── Route constants — use :id path parameters ──────────
  $consts = @"
  static const String ${fname}List   = '/${fname}s';
  static const String ${fname}Create = '/${fname}s/create';
  static const String ${fname}Detail = '/${fname}s/:id';
  static const String ${fname}Edit   = '/${fname}s/:id/edit';

  /// Helpers for building concrete paths with a known id.
  static String ${fname}DetailPath(String id) => '/${fname}s/`$id';
  static String ${fname}EditPath(String id)   => '/${fname}s/`$id/edit';
"@

  # ── GoRoute entries inside ShellRoute ─────────────────
  $goRoutes = @"

            // $flabel routes (Level 2, generated $(Get-Date -Format 'yyyy-MM-dd'))
            GoRoute(
              path: ${fname}List,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadAllRequested()),
                child: const ${fclass}ListPage(),
              ),
            ),
            GoRoute(
              path: ${fname}Create,
              builder: (_, __) => BlocProvider(
                create: (_) => sl<${fclass}Bloc>(),
                child: const ${fclass}FormPage(mode: ${fclass}FormNode.create),
              ),
            ),
            GoRoute(
              path: ${fname}Detail,
              builder: (_, state) {
                final id = state.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadOneRequested(id)),
                  child: const ${fclass}DetailPage(),
                );
              },
            ),
            GoRoute(
              path: ${fname}Edit,
              builder: (_, state) {
                final id = state.pathParameters['id'] ?? '';
                return BlocProvider(
                  create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadOneRequested(id)),
                  child: ${fclass}FormPage(mode: ${fclass}FormNode.edit, id: id),
                );
              },
            ),
"@

  $content = Get-Content $routerPath -Raw
  $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR FEATURE PAGE IMPORTS' -Insert $imports
  $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR ROUTE CONSTANTS'      -Insert $consts
  $content = _Insert-AboveMarker -Content $content -Marker '// ── END GENERATOR ROUTES'               -Insert $goRoutes

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

  # ── Permission slug (optional) + icon ─────────────────
  $fperm = $config.feature.permission
  $icon = if ($config.feature.icon) { $config.feature.icon } else { 'Icons.list_outlined' }

  # ── NavItem — permission-gated only if permission provided ──
  if (-not [string]::IsNullOrWhiteSpace($fperm)) {
    $navItem = @"

      // $flabel (Level 2, generated $(Get-Date -Format 'yyyy-MM-dd'))
      if (auth.can('${fperm}.view'))
        NavItem(
          id:    '${fname}',
          label: '$flabel',
          icon:  $icon,
          path:  AppRouter.${fname}List,
        ),
"@
  }
  else {
    $navItem = @"

      // $flabel (Level 2, generated $(Get-Date -Format 'yyyy-MM-dd'))
      NavItem(
        id:    '${fname}',
        label: '$flabel',
        icon:  $icon,
        path:  AppRouter.${fname}List,
      ),
"@
  }

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