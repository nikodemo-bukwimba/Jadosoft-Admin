# ============================================================
# Test-Level2.ps1 — Level 2 Generator Test Suite
# Usage: cd tools\generator && .\tests\Test-Level2.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GenRoot  = Split-Path $PSScriptRoot -Parent
$TestRoot = $PSScriptRoot
$TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) "hala_gen_l2_$(Get-Random)"

$passed = 0; $failed = 0

function Assert-True([string]$Name, [bool]$Cond, [string]$Detail = '') {
    if ($Cond) { Write-Host "  [PASS] $Name" -ForegroundColor Green; $script:passed++ }
    else { Write-Host "  [FAIL] $Name" -ForegroundColor Red; if ($Detail) { Write-Host "         $Detail" -ForegroundColor Yellow }; $script:failed++ }
}
function Assert-FileExists([string]$P, [string]$L) { Assert-True $L (Test-Path $P) "Not found: $P" }
function Assert-FileNotExists([string]$P, [string]$L) { Assert-True $L (-not (Test-Path $P)) "Found unexpectedly: $P" }
function Assert-FC([string]$P, [string]$N, [string]$L) {
    if (-not (Test-Path $P)) { Assert-True $L $false "File not found: $P"; return }
    Assert-True $L ((Get-Content $P -Raw).Contains($N)) "'$N' not found in $(Split-Path $P -Leaf)"
}
function Assert-FNC([string]$P, [string]$N, [string]$L) {
    if (-not (Test-Path $P)) { Assert-True $L $false "File not found: $P"; return }
    Assert-True $L (-not (Get-Content $P -Raw).Contains($N)) "'$N' unexpectedly found in $(Split-Path $P -Leaf)"
}

Write-Host "`n===============================================" -ForegroundColor DarkCyan
Write-Host " Level 2 Generator - Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

Write-Host "`n--- Running generator (Project, Level 2) ---" -ForegroundColor White

& (Join-Path $GenRoot "Generate-Level2.ps1") `
    -ConfigPath (Join-Path $TestRoot "level2_project.config.json") `
    -ProjectRoot $TempDir -Force

$fd = Join-Path $TempDir "lib\features\project"

# ═══════════════════════════════════════════════════════════
# FILE STRUCTURE
# ═══════════════════════════════════════════════════════════
Write-Host "`n  File structure:" -ForegroundColor White
Assert-FileExists (Join-Path $fd "domain\entities\project_entity.dart")             "entity"
Assert-FileExists (Join-Path $fd "domain\repositories\project_repository.dart")     "repo interface"
Assert-FileExists (Join-Path $fd "domain\usecases\get_all_project_usecase.dart")    "getAll UC"
Assert-FileExists (Join-Path $fd "domain\usecases\get_project_usecase.dart")        "get UC"
Assert-FileExists (Join-Path $fd "domain\usecases\create_project_usecase.dart")     "create UC"
Assert-FileExists (Join-Path $fd "domain\usecases\update_project_usecase.dart")     "update UC"
Assert-FileExists (Join-Path $fd "domain\usecases\delete_project_usecase.dart")     "delete UC"
Assert-FileExists (Join-Path $fd "domain\value_objects\project_status.dart")        "status enum"
Assert-FileExists (Join-Path $fd "domain\guards\project_transition_guard.dart")     "guard"
Assert-FileExists (Join-Path $fd "domain\services\project_domain_service.dart")     "domain service"
Assert-FileExists (Join-Path $fd "data\models\project_model.dart")                  "model"
Assert-FileExists (Join-Path $fd "data\datasources\project_remote_datasource.dart") "remote ds"
Assert-FileExists (Join-Path $fd "data\repositories\project_repository_impl.dart")  "repo impl"
Assert-FileExists (Join-Path $fd "presentation\bloc\project_bloc.dart")             "bloc"
Assert-FileExists (Join-Path $fd "presentation\bloc\project_event.dart")            "event"
Assert-FileExists (Join-Path $fd "presentation\bloc\project_state.dart")            "state"
Assert-FileExists (Join-Path $fd "presentation\pages\project_list_page.dart")       "list page"
Assert-FileExists (Join-Path $fd "presentation\pages\project_detail_page.dart")     "detail page"
Assert-FileExists (Join-Path $fd "presentation\pages\project_form_page.dart")       "form page"
Assert-FileExists (Join-Path $fd "presentation\widgets\project_card.dart")          "card"
Assert-FileExists (Join-Path $fd "presentation\widgets\project_status_badge.dart")  "status badge"
Assert-FileExists (Join-Path $TempDir "lib\core\enums\form_mode.dart")              "FormMode core"

# NO workflow files (Level 2 ≠ Level 3)
Assert-FileNotExists (Join-Path $fd "domain\events\project_domain_events.dart")      "NO domain events"
Assert-FileNotExists (Join-Path $fd "domain\workflow\project_workflow_executor.dart") "NO workflow executor"

# ═══════════════════════════════════════════════════════════
# STATUS ENUM
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Status enum:" -ForegroundColor White
$statusFile = Join-Path $fd "domain\value_objects\project_status.dart"
Assert-FC $statusFile "enum ProjectStatus {"            "enum declaration"
Assert-FC $statusFile "planning,"                       "state: planning"
Assert-FC $statusFile "active,"                         "state: active"
Assert-FC $statusFile "onHold,"                         "state: onHold"
Assert-FC $statusFile "completed,"                      "state: completed"
Assert-FC $statusFile "archived,"                       "state: archived"
Assert-FC $statusFile "canTransitionTo(ProjectStatus"   "canTransitionTo method"
Assert-FC $statusFile "displayName"                     "displayName getter"
Assert-FC $statusFile "Color get color"                 "color getter"
# Bug 2 fix: map key must NOT have quotes or spaces before state name
Assert-FC  $statusFile "ProjectStatus.planning:"        "map key no quotes"
Assert-FNC $statusFile "ProjectStatus. planning"        "map key no space before state"
Assert-FNC $statusFile "ProjectStatus.'planning'"       "map key no quoted state"

# ═══════════════════════════════════════════════════════════
# ENTITY — Bug 9 fix: nullable types must have type name
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Entity:" -ForegroundColor White
$entityFile = Join-Path $fd "domain\entities\project_entity.dart"
Assert-FC  $entityFile "final ProjectStatus status;"      "status field typed"
Assert-FC  $entityFile "final String name;"                "name field typed"
Assert-FC  $entityFile "final double? budget;"             "budget nullable typed"
Assert-FC  $entityFile "final String? description;"        "description nullable typed"
Assert-FC  $entityFile "final DateTime? startDate;"        "startDate nullable typed"
Assert-FC  $entityFile "final bool isPublic;"              "bool field typed"
Assert-FNC $entityFile "final  "                           "NO empty type (Bug 9 fix)"
# copyWith — nullable param must have type
Assert-FC  $entityFile "String? description,"              "copyWith nullable String param"
Assert-FC  $entityFile "double? budget,"                   "copyWith nullable double param"
Assert-FNC $entityFile "? description,"                    "NO bare ? param (Bug 9 fix)"
Assert-FNC $entityFile "? budget,"                         "NO bare ? param (Bug 9 fix)"

# ═══════════════════════════════════════════════════════════
# GUARD — Bug 1 fix: Dart interpolation preserved
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Guard:" -ForegroundColor White
$guardFile = Join-Path $fd "domain\guards\project_transition_guard.dart"
Assert-FC  $guardFile "class ProjectTransitionGuard"               "class exists"
Assert-FC  $guardFile "current.canTransitionTo(target)"            "uses enum method"
# The error message MUST have ${current.displayName} — not empty
Assert-FNC $guardFile "from \ to \"                                "NO escaped-empty interpolation (Bug 1)"
Assert-FC  $guardFile '${current.displayName}'                     "Dart interpolation preserved"
Assert-FC  $guardFile '${target.displayName}'                      "Dart interpolation preserved"

# ═══════════════════════════════════════════════════════════
# DOMAIN SERVICE — Bug 10 fix: no fold+async
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Domain service:" -ForegroundColor White
$svcFile = Join-Path $fd "domain\services\project_domain_service.dart"
Assert-FC  $svcFile "class ProjectDomainService"             "class exists"
Assert-FC  $svcFile "final ProjectRepository repository"     "repo dep"
Assert-FC  $svcFile "final ProjectTransitionGuard guard"     "guard dep"
Assert-FC  $svcFile "entity.copyWith(status: validTarget)"   "applies transition"
# Must use isLeft/getOrElse, NOT fold+async
Assert-FC  $svcFile "loadResult.isLeft()"                    "isLeft guard (Bug 10 fix)"
Assert-FC  $svcFile "loadResult.getOrElse("                  "getOrElse extract (Bug 10 fix)"
Assert-FNC $svcFile "(entity) async {"                       "NO async fold callback (Bug 10 fix)"

# ═══════════════════════════════════════════════════════════
# MODEL — status serialization
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Model:" -ForegroundColor White
$modelFile = Join-Path $fd "data\models\project_model.dart"
Assert-FC $modelFile "ProjectStatus.values.firstWhere"  "status fromJson"
Assert-FC $modelFile "status.name"                       "status toJson"

# ═══════════════════════════════════════════════════════════
# BLOC — transitions
# ═══════════════════════════════════════════════════════════
Write-Host "`n  BLoC:" -ForegroundColor White
$blocFile = Join-Path $fd "presentation\bloc\project_bloc.dart"
Assert-FC $blocFile "final ProjectDomainService domainService"  "domain service dep"
Assert-FC $blocFile "on<ProjectActivateRequested>"               "activate handler"
Assert-FC $blocFile "on<ProjectPauseRequested>"                  "pause handler"
Assert-FC $blocFile "on<ProjectResumeRequested>"                 "resume handler"
Assert-FC $blocFile "on<ProjectCompleteRequested>"               "complete handler"
Assert-FC $blocFile "on<ProjectArchiveRequested>"                "archive handler"
Assert-FC $blocFile "domainService.transition("                  "calls domain service"

# ═══════════════════════════════════════════════════════════
# EVENTS
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Events:" -ForegroundColor White
$eventFile = Join-Path $fd "presentation\bloc\project_event.dart"
Assert-FC $eventFile "class ProjectActivateRequested"  "activate event"
Assert-FC $eventFile "class ProjectPauseRequested"     "pause event"
Assert-FC $eventFile "class ProjectResumeRequested"    "resume event"
Assert-FC $eventFile "class ProjectCompleteRequested"  "complete event"
Assert-FC $eventFile "class ProjectArchiveRequested"   "archive event"

# ═══════════════════════════════════════════════════════════
# DETAIL PAGE — Bug 3 fix: accessors must have field name
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Detail page:" -ForegroundColor White
$detailFile = Join-Path $fd "presentation\pages\project_detail_page.dart"
Assert-FC  $detailFile "ProjectStatusBadge(status: item.status)"     "status badge"
Assert-FC  $detailFile "ProjectActivateRequested(item.id)"            "activate button"
Assert-FC  $detailFile "ProjectPauseRequested(item.id)"               "pause button"
Assert-FC  $detailFile "ProjectStatus.planning"                       "from-state guard"
Assert-FC  $detailFile "Text('Actions'"                               "actions section"
# Bug 3 fix: accessor must have field name, not item..toString()
Assert-FNC $detailFile "item..toString()"                              "NO double-dot (Bug 3 fix)"
Assert-FNC $detailFile "item. .toString()"                             "NO space-dot (Bug 3 fix)"
# Nullable fields must have proper accessor
Assert-FC  $detailFile "item.description"                              "description accessor exists"
Assert-FC  $detailFile "item.budget"                                   "budget accessor exists"

# ═══════════════════════════════════════════════════════════
# FORM PAGE — Bug 4 + FormMode fix
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Form page:" -ForegroundColor White
$formFile = Join-Path $fd "presentation\pages\project_form_page.dart"
Assert-FC  $formFile "import '../../../../core/enums/form_mode.dart'"   "FormMode from core"
Assert-FNC $formFile "enum FormMode"                                     "NO local FormMode enum"
# Controllers
Assert-FC  $formFile "_nameController = TextEditingController()"        "String controller"
Assert-FC  $formFile "_budgetController = TextEditingController()"      "double controller"
Assert-FC  $formFile "bool _isPublicValue = false;"                     "bool state var"
Assert-FC  $formFile "SwitchListTile"                                    "bool widget"
Assert-FC  $formFile "showDatePicker"                                    "date picker"
Assert-FNC $formFile "_isPublicController"                               "NO controller for bool"
# Bug 4 fix: named params, NOT map literal
Assert-FNC $formFile "'name':"                                           "NO map-quoted name param (Bug 4 fix)"
Assert-FNC $formFile "'budget':"                                         "NO map-quoted budget param (Bug 4 fix)"
Assert-FC  $formFile "name: _nameController.text,"                      "named param syntax"

# ═══════════════════════════════════════════════════════════
# CARD — Bug 5 fix: subtitle must have dot + field name
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Card:" -ForegroundColor White
$cardFile = Join-Path $fd "presentation\widgets\project_card.dart"
Assert-FC  $cardFile "ProjectStatusBadge(status: item.status, compact: true)"  "compact badge"
Assert-FC  $cardFile "item.name"                                                "title accessor"
# Bug 5 fix: subtitle must be item.description, not itemdescription
Assert-FC  $cardFile "item.description"                                         "subtitle dot-access"
Assert-FNC $cardFile "itemdescription"                                          "NO missing dot (Bug 5 fix)"

# ═══════════════════════════════════════════════════════════
# DI WIRING — no workflow
# ═══════════════════════════════════════════════════════════
Write-Host "`n  DI wiring:" -ForegroundColor White
$diFile = Join-Path $TempDir "lib\config\di\injection_container.dart"
Assert-FC  $diFile "ProjectRemoteDataSourceImpl(dio: sl())"       "datasource"
Assert-FC  $diFile "ProjectRepositoryImpl(remoteDataSource: sl())" "repo"
Assert-FC  $diFile "GetAllProjectUseCase(sl())"                     "getAll UC"
Assert-FC  $diFile "ProjectTransitionGuard()"                        "guard"
Assert-FC  $diFile "ProjectDomainService("                           "domain service"
Assert-FC  $diFile "repository: sl(), guard: sl()"                   "service deps"
Assert-FC  $diFile "domainService: sl()"                              "bloc gets service"
Assert-FC  $diFile "Level 2"                                          "level label"
Assert-FNC $diFile "WorkflowExecutor"                                 "NO workflow in DI"
Assert-FNC $diFile "workflow_executor"                                 "NO workflow import"

# ═══════════════════════════════════════════════════════════
# ROUTER
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Router:" -ForegroundColor White
$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"
Assert-FC $routerFile "case projectList:"                         "list route"
Assert-FC $routerFile "case projectCreate:"                       "create route"
Assert-FC $routerFile "case projectDetail:"                       "detail route"
Assert-FC $routerFile "case projectEdit:"                         "edit route"
Assert-FC $routerFile "import '../../core/enums/form_mode.dart'"  "FormMode from core"

# ═══════════════════════════════════════════════════════════
# NAV
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Nav:" -ForegroundColor White
$navFile = Join-Path $TempDir "lib\app\shell\shell_nav_items.dart"
Assert-FC $navFile "label:      'Project'"   "label"
Assert-FC $navFile "Icons.folder_outlined"    "icon"

# ═══════════════════════════════════════════════════════════
# CLEANUP + SUMMARY
# ═══════════════════════════════════════════════════════════
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n===============================================" -ForegroundColor DarkCyan
$total = $passed + $failed
if ($failed -eq 0) { Write-Host " ALL $total TESTS PASSED" -ForegroundColor Green }
else { Write-Host " $passed/$total passed, $failed FAILED" -ForegroundColor Red }
Write-Host "===============================================`n" -ForegroundColor DarkCyan
exit $failed
