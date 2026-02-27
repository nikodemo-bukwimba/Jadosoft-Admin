# ============================================================
# WorkflowGenerator.psm1  — Level 3
# ============================================================

function Invoke-GenerateWorkflow {
    param([hashtable]$Ctx, [scriptblock]$NewFile)

    $config = $Ctx.Config
    $tokens = $Ctx.Tokens
    $fDir = $Ctx.FeatureDir
    $fname = $tokens.FNAME
    $fclass = $tokens.FCLASS

    $primaryEntityName = $config.entities.PSObject.Properties |
    Where-Object { $_.Value.primary -eq $true } |
    Select-Object -First 1 -ExpandProperty Name

    # ── Domain events ─────────────────────────────────────────
    $eventClasses = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $config.workflow -and $null -ne $config.workflow.events) {
        foreach ($evt in $config.workflow.events) {
            $eName = $evt.name
            $fields = (if ($null -eq $evt.fields) { @('id') } else { $evt.fields }) | ForEach-Object {
                "  final String $_;"
            }
            $ctorArgs = (if ($null -eq $evt.fields) { @('id') } else { $evt.fields }) | ForEach-Object {
                "    required this.$_,"
            }
            $eventClasses.Add(@"

class $eName extends ${fclass}DomainEvent {
$($fields -join "`n")

  const $eName({
$($ctorArgs -join "`n")
    required super.occurredAt,
  });
}
"@)
        }
    }

    $eventsContent = @"
// ${fname}_domain_events.dart
// Level 3 — Domain events emitted after workflow completion.
// Other features can subscribe without coupling to this feature's internals.
// TODO: Replace with events meaningful to your domain.

abstract class ${fclass}DomainEvent {
  final String   entityId;
  final DateTime occurredAt;

  const ${fclass}DomainEvent({
    required this.entityId,
    required this.occurredAt,
  });
}
$($eventClasses -join "`n")
"@
    & $NewFile (Join-Path $fDir "domain\events\${fname}_domain_events.dart") $eventsContent

    # ── Workflow ───────────────────────────────────────────────
    # …existing code…
    # ── Workflow ───────────────────────────────────────────────
    $steps = if ($null -eq $config.workflow.steps) {
        @(
            @{ name = 'validatePreconditions'; label = 'Validate'; canFail = $true; rollback = $false; description = 'Check pre-conditions' }
            @{ name = 'executeCoreOperation'; label = 'Execute'; canFail = $false; rollback = $true; description = 'Core domain operation' }
            @{ name = 'executePostProcessing'; label = 'Notify'; canFail = $true; rollback = $false; description = 'Side effects + notifications' }
        )
    }
    else {
        $config.workflow.steps
    }

    $stepMethods = [System.Collections.Generic.List[string]]::new()
    $stepCallbacks = [System.Collections.Generic.List[string]]::new()
    # …existing code…

    foreach ($step in $steps) {
        $sName = if ($null -eq $step.name) { $step['name'] } else { $step.name }
        $sDesc = if ($null -eq $step.description) { if ($null -eq $step['description']) { $sName } else { $step['description'] } } else { $step.description }
        $canFail = if ($null -eq $step.canFail) { if ($null -eq $step['canFail']) { $true } else { $step['canFail'] } } else { $step.canFail }

        $stepCallbacks.Add(@"
    // ── Step: $sName ─────────────────────────────────────
    // $sDesc
    final ${sName}Result = await _${sName}(entityId);
    if (${sName}Result != null) {
      return Left($(if ($canFail) { "WorkflowFailure(${sName}Result)" } else { "GenericFailure(${sName}Result)" }));
    }
"@)

        $stepMethods.Add(@"
  /// $sDesc
  /// Return null to continue. Return error message to halt.
  // TODO: Implement this step
  Future<String?> _${sName}(String entityId) async {
    return null; // null = step passed
  }
"@)
    }

    $workflowContent = @"
// ${fname}_workflow.dart
// Level 3 — Ordered step executor with domain event emission.
// Steps run sequentially. First failure halts execution.
// TODO: Implement each step method with your actual domain logic.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../events/${fname}_domain_events.dart';
import '../repositories/${fname}_repository.dart';

typedef WorkflowEventCallback = void Function(${fclass}DomainEvent event);

class ${fclass}Workflow {
  final ${fclass}Repository    _repository;
  WorkflowEventCallback?       _onEvent;

  ${fclass}Workflow({required ${fclass}Repository repository})
      : _repository = repository;

  void setEventCallback(WorkflowEventCallback callback) {
    _onEvent = callback;
  }

  /// Execute the full workflow for the given entity ID.
  Future<Either<Failure, void>> execute(String entityId) async {
$($stepCallbacks -join "`n")

    // ── Emit completion event ─────────────────────────────────
    // TODO: Replace with the appropriate event for your workflow
    _onEvent?.call(${fclass}DomainEvent(
      entityId:   entityId,
      occurredAt: DateTime.now(),
    ) as dynamic);

    return const Right(null);
  }

  // ── Step implementations ──────────────────────────────────────
$($stepMethods -join "`n")
}

// ── Custom failures ───────────────────────────────────────────
class WorkflowFailure extends Failure {
  const WorkflowFailure(super.message);
}
"@
    & $NewFile (Join-Path $fDir "domain\workflows\${fname}_workflow.dart") $workflowContent
}

Export-ModuleMember -Function Invoke-GenerateWorkflow


# ============================================================
# ProviderGenerator.psm1 — Cross-feature belongsTo adapters
# ============================================================

function Invoke-GenerateProviders {
    param([hashtable]$Ctx, [scriptblock]$NewFile)

    $config = $Ctx.Config
    $tokens = $Ctx.Tokens
    $fDir = $Ctx.FeatureDir
    $fname = $tokens.FNAME
    $graph = $Ctx.Graph
    $extRels = $graph.ExternalRelationships[$tokens.FNAME]

    if (-not $extRels -or $extRels.Count -eq 0) { return }

    # Group by external entity (one provider interface per unique external entity)
    $providerByEntity = @{}
    foreach ($rel in $extRels) {
        $key = "$($rel.ExternalFeature)_$($rel.ExternalEntity)"
        if (-not $providerByEntity.ContainsKey($key)) {
            $providerByEntity[$key] = $rel
        }
    }

    foreach ($key in $providerByEntity.Keys) {
        $rel = $providerByEntity[$key]
        $extEntity = $rel.ExternalEntity       # User
        $extFeature = $rel.ExternalFeature       # auth
        $displayField = $rel.DisplayField          # name
        $searchable = $rel.Searchable
        $extEntitySnake = ConvertTo-SnakeCase $extEntity
        $extFeatureClass = (Get-Culture).TextInfo.ToTitleCase(
            $extFeature.Replace('_', ' ')
        ).Replace(' ', '')

        # ── Provider interface ────────────────────────────────
        $searchMethod = if ($searchable) {
            "  Future<List<${extEntity}Ref>> search(String query);"
        }
        else {
            "  Future<List<${extEntity}Ref>> getAll();"
        }

        $providerContent = @"
// ${extEntitySnake}_provider.dart
// Abstract interface — allows this feature to look up ${extEntity} data
// from the ${extFeature} feature WITHOUT importing its internals.
// DI wiring in injection_container.dart connects this to the real repository.

abstract class ${extEntity}Provider {
$searchMethod
  Future<${extEntity}Ref?> getById(String id);
}

/// Minimal read-only reference to a ${extEntity}.
/// Only the fields this feature needs — nothing more.
class ${extEntity}Ref {
  final String id;
  final String $displayField;    // display field from ${extFeature}.$extEntity

  const ${extEntity}Ref({
    required this.id,
    required this.$displayField,
  });
}
"@
        & $NewFile (Join-Path $fDir "domain\providers\${extEntitySnake}_provider.dart") $providerContent

        # ── Adapter implementation ────────────────────────────
        $adaptGetAll = if ($searchable) {
            "  Future<List<${extEntity}Ref>> search(String query) async {"
        }
        else {
            "  Future<List<${extEntity}Ref>> getAll() async {"
        }

        $adapterContent = @"
// ${extFeature}_${extEntitySnake}_provider_adapter.dart
// Adapts the ${extFeature} feature's repository to ${extEntity}Provider.
// Lives in THIS feature (${fname}). The ${extFeature} feature never knows we exist.
// TODO: Replace _repository type with the actual ${extFeatureClass}Repository import.

import '../../../${extFeature}/domain/repositories/${extFeature}_repository.dart';
import '../../domain/providers/${extEntitySnake}_provider.dart';

class ${extFeatureClass}${extEntity}ProviderAdapter implements ${extEntity}Provider {
  final ${extFeatureClass}Repository _repository;

  const ${extFeatureClass}${extEntity}ProviderAdapter({
    required ${extFeatureClass}Repository repository,
  }) : _repository = repository;

  @override
  $adaptGetAll
    final result = await _repository.getAll();
    return result.fold(
      (_)      => const [],
      (items)  => items.map((u) => ${extEntity}Ref(
        id:            u.id,
        ${displayField}: u.$displayField,
      )).toList(),
    );
  }

  @override
  Future<${extEntity}Ref?> getById(String id) async {
    final result = await _repository.getById(id);
    return result.fold(
      (_)    => null,
      (item) => ${extEntity}Ref(id: item.id, ${displayField}: item.$displayField),
    );
  }
}
"@
        & $NewFile (Join-Path $fDir "data\providers\${extFeature}_${extEntitySnake}_provider_adapter.dart") $adapterContent
    }
}

Export-ModuleMember -Function Invoke-GenerateProviders


# ============================================================
# DiRouterGenerator.psm1 — Appends to injection_container + app_router
# ============================================================

function Update-InjectionContainer {
    param([hashtable]$Ctx)

    $config = $Ctx.Config
    $tokens = $Ctx.Tokens
    $pRoot = $Ctx.ProjectRoot
    $fname = $tokens.FNAME
    $fclass = $tokens.FCLASS
    $maturity = $Ctx.Maturity
    $graph = $Ctx.Graph
    $isDryRun = $Ctx.DryRun

    $diPath = Join-Path $pRoot "lib\config\di\injection_container.dart"

    if (-not (Test-Path $diPath)) {
        Write-Warning "injection_container.dart not found at: $diPath  — skipping DI wiring"
        return
    }

    $primaryEntityName = $config.entities.PSObject.Properties |
    Where-Object { $_.Value.primary -eq $true } |
    Select-Object -First 1 -ExpandProperty Name

    $isRemote = ($null -ne $config.storage) -and ($config.storage.remote -eq $true)
    $isLocal = ($null -ne $config.storage) -and ($config.storage.local -eq $true)

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("")
    $lines.Add("  // ── $fclass (generated $(Get-Date -Format 'yyyy-MM-dd')) ─────────")

    # Cross-feature provider wiring
    $extRels = $graph.ExternalRelationships[$fname]
    if ($extRels -and $extRels.Count -gt 0) {
        $providerByEntity = @{}
        foreach ($rel in $extRels) {
            $key = "$($rel.ExternalFeature)_$($rel.ExternalEntity)"
            if (-not $providerByEntity.ContainsKey($key)) {
                $providerByEntity[$key] = $rel
            }
        }
        foreach ($key in $providerByEntity.Keys) {
            $rel = $providerByEntity[$key]
            $extEntity = $rel.ExternalEntity
            $extFeature = $rel.ExternalFeature
            $extFeatureClass = (Get-Culture).TextInfo.ToTitleCase($extFeature.Replace('_', ' ')).Replace(' ', '')
            $extEntitySnake = ConvertTo-SnakeCase $extEntity
            $lines.Add("  sl.registerLazySingleton<${extEntity}Provider>(")
            $lines.Add("    () => ${extFeatureClass}${extEntity}ProviderAdapter(repository: sl<${extFeatureClass}Repository>()),")
            $lines.Add("  );")
        }
    }

    if ($isRemote) {
        $lines.Add("  sl.registerLazySingleton<${fclass}RemoteDataSource>(")
        $lines.Add("    () => ${fclass}RemoteDataSourceImpl(dio: sl()),")
        $lines.Add("  );")
    }
    if ($isLocal) {
        $lines.Add("  sl.registerLazySingleton<${fclass}LocalDataSource>(")
        $lines.Add("    () => ${fclass}LocalDataSourceImpl(db: sl()),")
        $lines.Add("  );")
    }

    $repoArgs = @()
    if ($isRemote) { $repoArgs += "remoteDataSource: sl()" }
    if ($isLocal) { $repoArgs += "localDataSource:  sl()" }
    $repoArgStr = $repoArgs -join ", "

    $lines.Add("  sl.registerLazySingleton<${fclass}Repository>(")
    $lines.Add("    () => ${fclass}RepositoryImpl($repoArgStr),")
    $lines.Add("  );")

    if ($maturity -ge 2) {
        $lines.Add("  sl.registerLazySingleton<${fclass}TransitionGuard>(")
        $lines.Add("    () => const ${fclass}TransitionGuard(),")
        $lines.Add("  );")
        $lines.Add("  sl.registerLazySingleton<${fclass}DomainService>(")
        $lines.Add("    () => ${fclass}DomainService(repository: sl(), guard: sl()),")
        $lines.Add("  );")
    }

    # Use cases
    $lines.Add("  sl.registerLazySingleton(() => GetAll${fclass}UseCase(sl()));")
    $lines.Add("  sl.registerLazySingleton(() => Get${fclass}UseCase(sl()));")
    $lines.Add("  sl.registerLazySingleton(() => Create${fclass}UseCase(sl()));")
    $lines.Add("  sl.registerLazySingleton(() => Update${fclass}UseCase(sl()));")
    $lines.Add("  sl.registerLazySingleton(() => Delete${fclass}UseCase(sl()));")

    if ($maturity -ge 2 -and $config.stateMachine) {
        foreach ($t in $config.stateMachine.transitions) {
            $tPascal = $t.name.Substring(0, 1).ToUpper() + $t.name.Substring(1)
            $lines.Add("  sl.registerLazySingleton(() => ${tPascal}${fclass}UseCase(sl()));")
        }
    }

    # BLoC factory
    $blocArgs = [System.Collections.Generic.List[string]]::new()
    $blocArgs.Add("getAllUseCase: sl()")
    $blocArgs.Add("getUseCase: sl()")
    $blocArgs.Add("createUseCase: sl()")
    $blocArgs.Add("updateUseCase: sl()")
    $blocArgs.Add("deleteUseCase: sl()")

    if ($maturity -ge 2 -and $config.stateMachine) {
        foreach ($t in $config.stateMachine.transitions) {
            $blocArgs.Add("$($t.name)UseCase: sl()")
        }
    }
    $blocArgStr = $blocArgs -join ", "

    $lines.Add("  sl.registerFactory<${fclass}Bloc>(() => ${fclass}Bloc($blocArgStr));")

    # Form cubit
    $primaryEntity = $config.entities.$primaryEntityName
    if (($null -ne $primaryEntity.ui) -and ($null -ne $primaryEntity.ui.form) -and ($null -ne $primaryEntity.ui.form.inline) -and ($primaryEntity.ui.form.inline.Count -gt 0)) {
        $lines.Add("  sl.registerFactory<${fclass}FormCubit>(")
        $lines.Add("    () => ${fclass}FormCubit(createUseCase: sl(), updateUseCase: sl()),")
        $lines.Add("  );")
    }

    # Append to file
    $diContent = Get-Content $diPath -Raw
    $appendStr = $lines -join "`n"

    # Insert before closing brace of the setup function
    $insertMarker = '// ── END GENERATOR MANAGED'
    if ($diContent.Contains($insertMarker)) {
        $diContent = $diContent.Replace(
            $insertMarker,
            "$appendStr`n  $insertMarker"
        )
    }
    else {
        $diContent += "`n$appendStr`n"
    }

    if (-not $isDryRun) {
        Set-Content -Path $diPath -Value $diContent -Encoding UTF8
    }
    else {
        Write-Host "    [DRY RUN] Would append $($lines.Count) DI lines to injection_container.dart" -ForegroundColor DarkGray
    }
}

function Update-AppRouter {
    param([hashtable]$Ctx)

    $config = $Ctx.Config
    $tokens = $Ctx.Tokens
    $pRoot = $Ctx.ProjectRoot
    $fname = $tokens.FNAME
    $fclass = $tokens.FCLASS
    $flabel = $tokens.FLABEL
    $maturity = $Ctx.Maturity
    $isDryRun = $Ctx.DryRun

    $routerPath = Join-Path $pRoot "lib\app\routes\app_router.dart"

    if (-not (Test-Path $routerPath)) {
        Write-Warning "app_router.dart not found at: $routerPath — skipping route wiring"
        return
    }

    $primaryEntityName = $config.entities.PSObject.Properties |
    Where-Object { $_.Value.primary -eq $true } |
    Select-Object -First 1 -ExpandProperty Name

    $primaryEntity = $config.entities.$primaryEntityName
    $hasInline = (($null -ne $primaryEntity.ui) -and ($null -ne $primaryEntity.ui.form) -and ($null -ne $primaryEntity.ui.form.inline) -and ($primaryEntity.ui.form.inline.Count -gt 0))

    $formProvider = if ($hasInline) {
        @"
          BlocProvider<${fclass}FormCubit>(
            create: (_) => sl<${fclass}FormCubit>(),
          ),
"@
    }
    else { '' }

    $routeBlock = @"

    // ── $flabel routes (generated $(Get-Date -Format 'yyyy-MM-dd')) ────────────────
    GoRoute(
      path: '/${fname}s',
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider<${fclass}Bloc>(
            create: (_) => sl<${fclass}Bloc>()
                ..add(${fclass}LoadAllRequested()),
          ),
        ],
        child: const ${fclass}ListPage(),
      ),
      routes: [
        GoRoute(
          path:    'create',
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider<${fclass}Bloc>(create: (_) => sl<${fclass}Bloc>()),
$formProvider            ],
            child: const ${fclass}FormPage(mode: FormMode.create),
          ),
        ),
        GoRoute(
          path:    ':id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return BlocProvider<${fclass}Bloc>(
              create: (_) => sl<${fclass}Bloc>()
                  ..add(${fclass}LoadOneRequested(id)),
              child: const ${fclass}DetailPage(),
            );
          },
          routes: [
            GoRoute(
              path:    'edit',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return MultiBlocProvider(
                  providers: [
                    BlocProvider<${fclass}Bloc>(create: (_) => sl<${fclass}Bloc>()),
$formProvider                  ],
                  child: ${fclass}FormPage(mode: FormMode.edit, id: id),
                );
              },
            ),
          ],
        ),
      ],
    ),
"@

    $routerContent = Get-Content $routerPath -Raw
    $insertMarker = '// ── END GENERATOR ROUTES'

    if ($routerContent.Contains($insertMarker)) {
        $routerContent = $routerContent.Replace(
            $insertMarker,
            "$routeBlock  $insertMarker"
        )
    }
    else {
        $routerContent += "`n$routeBlock`n"
    }

    if (-not $isDryRun) {
        Set-Content -Path $routerPath -Value $routerContent -Encoding UTF8
    }
    else {
        Write-Host "    [DRY RUN] Would append $fclass routes to app_router.dart" -ForegroundColor DarkGray
    }
}

function ConvertTo-SnakeCase([string]$PascalCase) {
    return ($PascalCase -creplace '([A-Z])', '_$1').TrimStart('_').ToLower()
}

Export-ModuleMember -Function @(
    'Invoke-GenerateWorkflow',
    'Invoke-GenerateProviders',
    'Update-InjectionContainer',
    'Update-AppRouter'
)
