# ============================================================
# Level1WiringGenerator.psm1 -- DI + Routes + Nav
# FIX: Routes use ${fclass}FormMode (feature-specific, inlined in form page),
#      not a bare FormMode that has no declaration in scope.
# FIX: Permission is optional -- NavItem is visible to all if not provided.
# ============================================================

function Update-InjectionContainer {
  param([Parameter(Mandatory)][hashtable]$Ctx)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $pRoot = $Ctx.ProjectRoot
  $config = $Ctx.Config
  $isDryRun = $Ctx.DryRun
  $meta = Get-PrimaryEntityMeta -Config $config
  $eSnake = $meta.Snake
  $isRemote = $config.storage.remote -eq $true
  $isLocal = ($null -ne $config.storage.local) -and ($config.storage.local -eq $true)

  $diPath = Join-Path $pRoot "lib\config\di\injection_container.dart"
  if (-not (Test-Path $diPath)) { Write-Warning "injection_container.dart not found -- skipping DI"; return }

  # Imports
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
  $imports.Add("import 'package:fca/features/${fname}/presentation/bloc/${fname}_bloc.dart';")

  # Registrations
  $regs = [System.Collections.Generic.List[string]]::new()
  $regs.Add("")
  $regs.Add("  // -- ${fclass} --")
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

  $regs.Add("  sl.registerFactory<${fclass}Bloc>(() => ${fclass}Bloc(")
  $regs.Add("    getAllUseCase: sl(), getUseCase: sl(), createUseCase: sl(),")
  $regs.Add("    updateUseCase: sl(), deleteUseCase: sl(),")
  $regs.Add("  ));")

  $content = Get-Content $diPath -Raw
  $importStr = $imports -join "`n"
  $regStr = $regs -join "`n"

  $importMarker = '// -- END GENERATOR FEATURE IMPORTS'
  if ($content.Contains($importMarker)) {
    $content = $content.Replace($importMarker, "$importStr`n$importMarker")
  }

  $regMarker = '// -- END GENERATOR MANAGED'
  if ($content.Contains($regMarker)) {
    $content = $content.Replace($regMarker, "$regStr`n  $regMarker")
  }

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
  if (-not (Test-Path $routerPath)) { Write-Warning "app_router.dart not found -- skipping routes"; return }

  # -- Imports --
  # NOTE: ${fclass}FormMode is defined inline in ${fname}_form_page.dart (Level 1).
  # Importing the form page file is sufficient -- no separate enum file needed.
  $imports = @(
    "import '../../features/${fname}/presentation/pages/${fname}_list_page.dart';",
    "import '../../features/${fname}/presentation/pages/${fname}_detail_page.dart';",
    "import '../../features/${fname}/presentation/pages/${fname}_form_page.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_bloc.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_event.dart';",
    "import '../../config/di/injection_container.dart';",
    "import 'package:flutter_bloc/flutter_bloc.dart';"
  ) -join "`n"

  # -- Route constants -- use :id path parameters --
  $consts = @"
  static const String ${fname}List   = '/${fname}s';
  static const String ${fname}Create = '/${fname}s/create';
  static const String ${fname}Detail = '/${fname}s/:id';
  static const String ${fname}Edit   = '/${fname}s/:id/edit';

  /// Helpers for building concrete paths with a known id.
  static String ${fname}DetailPath(String id) => '/${fname}s/`$id';
  static String ${fname}EditPath(String id)   => '/${fname}s/`$id/edit';
"@

  # -- GoRoute entries inside ShellRoute --
  # FIX: use ${fclass}FormMode (inlined enum in form page), not bare FormMode.
  $goRoutes = @"

            // $flabel routes (Level 1, generated $(Get-Date -Format 'yyyy-MM-dd'))
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
                child: const ${fclass}FormPage(mode: ${fclass}FormMode.create),
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
                  child: ${fclass}FormPage(mode: ${fclass}FormMode.edit, id: id),
                );
              },
            ),
"@

  $content = Get-Content $routerPath -Raw
  $m1 = '// -- END GENERATOR FEATURE PAGE IMPORTS'
  $m2 = '// -- END GENERATOR ROUTE CONSTANTS'
  $m3 = '// -- END GENERATOR ROUTES'

  if ($content.Contains($m1)) { $content = $content.Replace($m1, "$imports`n$m1") }
  if ($content.Contains($m2)) { $content = $content.Replace($m2, "$consts`n  $m2") }
  if ($content.Contains($m3)) { $content = $content.Replace($m3, "$goRoutes`n            $m3") }

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
  if (-not (Test-Path $navPath)) { Write-Warning "shell_nav_items.dart not found -- skipping nav"; return }

  # -- Permission slug (optional) + icon --
  $fperm = $config.feature.permission
  $icon = if ($config.feature.icon) { $config.feature.icon } else { 'Icons.list_outlined' }

  # -- NavItem -- permission-gated only if permission provided --
  if (-not [string]::IsNullOrWhiteSpace($fperm)) {
    $navItem = @"

      // $flabel (Level 1, generated $(Get-Date -Format 'yyyy-MM-dd'))
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

      // $flabel (Level 1, generated $(Get-Date -Format 'yyyy-MM-dd'))
      NavItem(
        id:    '${fname}',
        label: '$flabel',
        icon:  $icon,
        path:  AppRouter.${fname}List,
      ),
"@
  }

  $content = Get-Content $navPath -Raw
  $m1 = '// -- END GENERATOR TABS'

  if ($content.Contains($m1)) { $content = $content.Replace($m1, "$navItem`n      $m1") }

  if (-not $isDryRun) {
    Set-Content -Path $navPath -Value $content -Encoding UTF8
    Write-Host "  [OK] shell_nav_items.dart updated" -ForegroundColor Green
  }
  else {
    Write-Host "    [DRY RUN] Would update shell_nav_items.dart" -ForegroundColor DarkGray
  }
}

Export-ModuleMember -Function @('Update-InjectionContainer', 'Update-AppRouter', 'Update-ShellNavItems')
