# ============================================================
# Level1WiringGenerator.psm1 — DI + Routes + Nav
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
  if (-not (Test-Path $diPath)) { Write-Warning "injection_container.dart not found — skipping DI"; return }

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
  $regs.Add("  // ── ${fclass} ────────────────────────────────────────")
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

  $importMarker = '// ── END GENERATOR FEATURE IMPORTS'
  if ($content.Contains($importMarker)) {
    $content = $content.Replace($importMarker, "$importStr`n$importMarker")
  }

  $regMarker = '// ── END GENERATOR MANAGED'
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
  if (-not (Test-Path $routerPath)) { Write-Warning "app_router.dart not found — skipping routes"; return }

  $imports = @(
    "import '../../features/${fname}/presentation/pages/${fname}_list_page.dart';",
    "import '../../features/${fname}/presentation/pages/${fname}_detail_page.dart';",
    "import '../../features/${fname}/presentation/pages/${fname}_form_page.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_bloc.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_event.dart';",
    "import '../../config/di/injection_container.dart';",
    "import 'package:flutter_bloc/flutter_bloc.dart';"
  ) -join "`n"

  $consts = @"
  static const String ${fname}List   = '/${fname}s';
  static const String ${fname}Create = '/${fname}s/create';
  static const String ${fname}Detail = '/${fname}s/detail';
  static const String ${fname}Edit   = '/${fname}s/edit';
"@

  $cases = @"

      // $flabel routes (Level 1, generated $(Get-Date -Format 'yyyy-MM-dd'))
      case ${fname}List:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadAllRequested()),
            child: const ${fclass}ListPage(),
          ),
          settings: settings,
        );

      case ${fname}Create:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<${fclass}Bloc>(),
            child: const ${fclass}FormPage(mode: ${fclass}FormMode.create),
          ),
          settings: settings,
        );

      case ${fname}Detail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadOneRequested(id)),
            child: const ${fclass}DetailPage(),
          ),
          settings: settings,
        );

      case ${fname}Edit:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final id = args['id'] as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadOneRequested(id)),
            child: ${fclass}FormPage(mode: ${fclass}FormMode.edit, id: id),
          ),
          settings: settings,
        );
"@

  $content = Get-Content $routerPath -Raw
  $m1 = '// ── END GENERATOR FEATURE PAGE IMPORTS'
  $m2 = '// ── END GENERATOR ROUTE CONSTANTS'
  $m3 = '// ── GENERATOR ROUTES — append only'

  if ($content.Contains($m1)) { $content = $content.Replace($m1, "$imports`n$m1") }
  if ($content.Contains($m2)) { $content = $content.Replace($m2, "$consts`n  $m2") }
  if ($content.Contains($m3)) { $content = $content.Replace($m3, "$cases`n      $m3") }

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
  $fclass = $Ctx.Tokens.FCLASS
  $flabel = $Ctx.Tokens.FLABEL
  $config = $Ctx.Config
  $pRoot = $Ctx.ProjectRoot
  $isDryRun = $Ctx.DryRun

  $navPath = Join-Path $pRoot "lib\app\shell\shell_nav_items.dart"
  if (-not (Test-Path $navPath)) { Write-Warning "shell_nav_items.dart not found — skipping nav"; return }

  $icon = if ($config.feature.icon) { $config.feature.icon }       else { 'Icons.list_outlined' }
  $activeIcon = if ($config.feature.activeIcon) { $config.feature.activeIcon }  else { 'Icons.list' }

  $imports = @(
    "import '../../features/${fname}/presentation/pages/${fname}_list_page.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_bloc.dart';",
    "import '../../features/${fname}/presentation/bloc/${fname}_event.dart';",
    "import '../../config/di/injection_container.dart';",
    "import 'package:flutter_bloc/flutter_bloc.dart';"
  ) -join "`n"

  $tab = @"
      // $flabel tab (Level 1, generated $(Get-Date -Format 'yyyy-MM-dd'))
      ShellTabConfig(
        label:      '$flabel',
        icon:       $icon,
        activeIcon: $activeIcon,
        page: BlocProvider(
          create: (_) => sl<${fclass}Bloc>()..add(${fclass}LoadAllRequested()),
          child: const ${fclass}ListPage(),
        ),
      ),
"@

  $content = Get-Content $navPath -Raw
  $m1 = '// ── END GENERATOR FEATURE IMPORTS'
  $m2 = '// ── END GENERATOR TABS'

  if ($content.Contains($m1)) { $content = $content.Replace($m1, "$imports`n$m1") }
  if ($content.Contains($m2)) { $content = $content.Replace($m2, "$tab`n      $m2") }

  if (-not $isDryRun) {
    Set-Content -Path $navPath -Value $content -Encoding UTF8
    Write-Host "  [OK] shell_nav_items.dart updated" -ForegroundColor Green
  }
  else {
    Write-Host "    [DRY RUN] Would update shell_nav_items.dart" -ForegroundColor DarkGray
  }
}

Export-ModuleMember -Function @('Update-InjectionContainer', 'Update-AppRouter', 'Update-ShellNavItems')
