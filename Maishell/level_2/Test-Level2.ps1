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
function Assert-FileNotExists([string]$P, [string]$L) { Assert-True $L (-not (Test-Path $P)) "Unexpectedly found: $P" }
function Assert-FC([string]$P, [string]$N, [string]$L) {
    if (-not (Test-Path $P)) { Assert-True $L $false "Not found: $P"; return }
    Assert-True $L ((Get-Content $P -Raw).Contains($N)) "'$N' not found"
}
function Assert-FNC([string]$P, [string]$N, [string]$L) {
    if (-not (Test-Path $P)) { Assert-True $L $false "Not found: $P"; return }
    Assert-True $L (-not (Get-Content $P -Raw).Contains($N)) "'$N' unexpectedly found"
}

Write-Host "`n===============================================" -ForegroundColor DarkCyan
Write-Host " Level 2 Generator - Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

Write-Host "`n--- Running generator (Project) ---" -ForegroundColor White

& (Join-Path $GenRoot "Generate-Level2.ps1") `
    -ConfigPath (Join-Path $TestRoot "level2_project.config.json") `
    -ProjectRoot $TempDir -Force

$fd = Join-Path $TempDir "lib\features\project"

# ── FILE STRUCTURE ─────────────────────────────────────────
Write-Host "`n  File structure (Level 2 = CRUD + StateMachine, NO workflow):" -ForegroundColor White
Assert-FileExists (Join-Path $fd "domain\entities\project_entity.dart")               "entity"
Assert-FileExists (Join-Path $fd "domain\repositories\project_repository.dart")       "repo interface"
Assert-FileExists (Join-Path $fd "domain\usecases\get_all_project_usecase.dart")      "getAll"
Assert-FileExists (Join-Path $fd "domain\usecases\get_project_usecase.dart")          "get"
Assert-FileExists (Join-Path $fd "domain\usecases\create_project_usecase.dart")       "create"
Assert-FileExists (Join-Path $fd "domain\usecases\update_project_usecase.dart")       "update"
Assert-FileExists (Join-Path $fd "domain\usecases\delete_project_usecase.dart")       "delete"
Assert-FileExists (Join-Path $fd "domain\value_objects\project_status.dart")          "status enum"
Assert-FileExists (Join-Path $fd "domain\guards\project_transition_guard.dart")       "guard"
Assert-FileExists (Join-Path $fd "domain\services\project_domain_service.dart")       "domain service"
Assert-FileExists (Join-Path $fd "data\models\project_model.dart")                    "model"
Assert-FileExists (Join-Path $fd "data\datasources\project_remote_datasource.dart")   "remote ds"
Assert-FileExists (Join-Path $fd "data\repositories\project_repository_impl.dart")    "repo impl"
Assert-FileExists (Join-Path $fd "presentation\bloc\project_bloc.dart")               "bloc"
Assert-FileExists (Join-Path $fd "presentation\bloc\project_event.dart")              "event"
Assert-FileExists (Join-Path $fd "presentation\bloc\project_state.dart")              "state"
Assert-FileExists (Join-Path $fd "presentation\pages\project_list_page.dart")         "list page"
Assert-FileExists (Join-Path $fd "presentation\pages\project_detail_page.dart")       "detail page"
Assert-FileExists (Join-Path $fd "presentation\pages\project_form_page.dart")         "form page"
Assert-FileExists (Join-Path $fd "presentation\widgets\project_card.dart")            "card"
Assert-FileExists (Join-Path $fd "presentation\widgets\project_status_badge.dart")    "status badge"
Assert-FileExists (Join-Path $TempDir "lib\core\enums\form_mode.dart")                "FormMode in core"

# NO workflow files
Assert-FileNotExists (Join-Path $fd "domain\events\project_domain_events.dart")       "NO domain events (Level 2)"
Assert-FileNotExists (Join-Path $fd "domain\workflow\project_workflow_executor.dart")  "NO workflow executor (Level 2)"

# ── STATUS ENUM ────────────────────────────────────────────
Write-Host "`n  Status enum:" -ForegroundColor White
$statusFile = Join-Path $fd "domain\value_objects\project_status.dart"
Assert-FC $statusFile "enum ProjectStatus {"          "enum"
Assert-FC $statusFile "planning,"                     "planning"
Assert-FC $statusFile "active,"                       "active"
Assert-FC $statusFile "onHold,"                       "onHold"
Assert-FC $statusFile "completed,"                    "completed"
Assert-FC $statusFile "archived,"                     "archived"
Assert-FC $statusFile "canTransitionTo(ProjectStatus" "canTransitionTo"
Assert-FC $statusFile "displayName"                   "displayName"
Assert-FC $statusFile "Color get color"               "color"

# ── ENTITY WITH STATUS ────────────────────────────────────
Write-Host "`n  Entity:" -ForegroundColor White
$entityFile = Join-Path $fd "domain\entities\project_entity.dart"
Assert-FC $entityFile "import '../value_objects/project_status.dart'" "imports status"
Assert-FC $entityFile "final ProjectStatus status;"                    "status field"
Assert-FC $entityFile "final String name;"                             "name field"
Assert-FC $entityFile "final double? budget;"                          "nullable double"
Assert-FC $entityFile "final bool isPublic;"                           "bool field"
Assert-FC $entityFile "final DateTime? startDate;"                     "nullable DateTime"
Assert-FC $entityFile "this.status = ProjectStatusX.initial"           "default status"

# ── MODEL ──────────────────────────────────────────────────
Write-Host "`n  Model:" -ForegroundColor White
$modelFile = Join-Path $fd "data\models\project_model.dart"
Assert-FC $modelFile "ProjectStatus.values.firstWhere"  "status deserialization"
Assert-FC $modelFile "status.name"                       "status serialization"
Assert-FC $modelFile "'is_public'"                       "snake_case bool"
Assert-FC $modelFile "'start_date'"                      "snake_case DateTime"

# ── GUARD ──────────────────────────────────────────────────
Write-Host "`n  Guard:" -ForegroundColor White
$guardFile = Join-Path $fd "domain\guards\project_transition_guard.dart"
Assert-FC $guardFile "class ProjectTransitionGuard"       "class"
Assert-FC $guardFile "current.canTransitionTo(target)"    "uses enum method"

# ── DOMAIN SERVICE ─────────────────────────────────────────
Write-Host "`n  Domain service:" -ForegroundColor White
$svcFile = Join-Path $fd "domain\services\project_domain_service.dart"
Assert-FC $svcFile "class ProjectDomainService"            "class"
Assert-FC $svcFile "final ProjectRepository repository"    "repo dep"
Assert-FC $svcFile "final ProjectTransitionGuard guard"    "guard dep"
Assert-FC $svcFile "entity.copyWith(status: validTarget)"  "apply"

# ── BLOC TRANSITIONS ──────────────────────────────────────
Write-Host "`n  BLoC:" -ForegroundColor White
$blocFile = Join-Path $fd "presentation\bloc\project_bloc.dart"
Assert-FC $blocFile "final ProjectDomainService domainService"  "domain service"
Assert-FC $blocFile "on<ProjectActivateRequested>"               "activate handler"
Assert-FC $blocFile "on<ProjectPauseRequested>"                  "pause handler"
Assert-FC $blocFile "on<ProjectResumeRequested>"                 "resume handler"
Assert-FC $blocFile "on<ProjectCompleteRequested>"               "complete handler"
Assert-FC $blocFile "on<ProjectArchiveRequested>"                "archive handler"
Assert-FC $blocFile "domainService.transition("                  "calls domain service"

# ── EVENTS ─────────────────────────────────────────────────
Write-Host "`n  Events:" -ForegroundColor White
$eventFile = Join-Path $fd "presentation\bloc\project_event.dart"
Assert-FC $eventFile "class ProjectActivateRequested"  "activate"
Assert-FC $eventFile "class ProjectPauseRequested"     "pause"
Assert-FC $eventFile "class ProjectResumeRequested"    "resume"
Assert-FC $eventFile "class ProjectCompleteRequested"  "complete"
Assert-FC $eventFile "class ProjectArchiveRequested"   "archive"

# ── DETAIL PAGE ────────────────────────────────────────────
Write-Host "`n  Detail page:" -ForegroundColor White
$detailFile = Join-Path $fd "presentation\pages\project_detail_page.dart"
Assert-FC $detailFile "ProjectStatusBadge(status: item.status)"     "badge"
Assert-FC $detailFile "ProjectActivateRequested(item.id)"            "activate button"
Assert-FC $detailFile "ProjectPauseRequested(item.id)"               "pause button"
Assert-FC $detailFile "ProjectStatus.planning"                       "from-state guard"
Assert-FC $detailFile "ProjectStatus.active"                         "from-state guard"
Assert-FC $detailFile "Text('Actions'"                               "actions section"

# ── FORM PAGE ──────────────────────────────────────────────
Write-Host "`n  Form page:" -ForegroundColor White
$formFile = Join-Path $fd "presentation\pages\project_form_page.dart"
Assert-FC $formFile "import '../../../../core/enums/form_mode.dart'"    "FormMode from core"
Assert-FNC $formFile "enum FormMode"                                     "NO local FormMode"
Assert-FC $formFile "_nameController = TextEditingController()"          "String controller"
Assert-FC $formFile "_budgetController = TextEditingController()"        "double controller"
Assert-FC $formFile "bool _isPublicValue = false;"                       "bool state var"
Assert-FC $formFile "SwitchListTile"                                      "bool widget"
Assert-FC $formFile "showDatePicker"                                      "date picker"
Assert-FNC $formFile "_isPublicController"                                "NO controller for bool"

# ── CARD ───────────────────────────────────────────────────
Write-Host "`n  Card:" -ForegroundColor White
$cardFile = Join-Path $fd "presentation\widgets\project_card.dart"
Assert-FC $cardFile "ProjectStatusBadge(status: item.status, compact: true)" "compact badge"
Assert-FC $cardFile "item.name"                                                "title field"

# ── DI WIRING ─────────────────────────────────────────────
Write-Host "`n  DI wiring:" -ForegroundColor White
$diFile = Join-Path $TempDir "lib\config\di\injection_container.dart"
Assert-FC $diFile "ProjectRemoteDataSourceImpl(dio: sl())"       "datasource"
Assert-FC $diFile "ProjectRepositoryImpl(remoteDataSource: sl())" "repo"
Assert-FC $diFile "GetAllProjectUseCase(sl())"                     "getAll"
Assert-FC $diFile "ProjectTransitionGuard()"                        "guard"
Assert-FC $diFile "ProjectDomainService("                           "domain service"
Assert-FC $diFile "repository: sl(), guard: sl()"                   "service deps"
Assert-FC $diFile "domainService: sl()"                              "bloc gets service"

# Level 2 specific: NO workflow in DI
Assert-FNC $diFile "WorkflowExecutor"                                "NO workflow executor in DI"
Assert-FNC $diFile "workflow_executor"                                "NO workflow import in DI"

# ── ROUTER ─────────────────────────────────────────────────
Write-Host "`n  Router:" -ForegroundColor White
$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"
Assert-FC $routerFile "case projectList:"                          "list route"
Assert-FC $routerFile "case projectCreate:"                        "create route"
Assert-FC $routerFile "case projectDetail:"                        "detail route"
Assert-FC $routerFile "case projectEdit:"                          "edit route"
Assert-FC $routerFile "BlocProvider"                                "BlocProvider"
Assert-FC $routerFile "import '../../core/enums/form_mode.dart'"   "FormMode from core"
Assert-FNC $routerFile "GoRoute"                                    "NO GoRoute"

# ── NAV ────────────────────────────────────────────────────
Write-Host "`n  Nav:" -ForegroundColor White
$navFile = Join-Path $TempDir "lib\app\shell\shell_nav_items.dart"
Assert-FC $navFile "label:      'Project'"          "label"
Assert-FC $navFile "Icons.folder_outlined"           "icon"

# ── Cleanup ────────────────────────────────────────────────
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n===============================================" -ForegroundColor DarkCyan
$total = $passed + $failed
if ($failed -eq 0) { Write-Host " ALL $total TESTS PASSED" -ForegroundColor Green }
else { Write-Host " $passed/$total passed, $failed FAILED" -ForegroundColor Red }
Write-Host "===============================================`n" -ForegroundColor DarkCyan
exit $failed
