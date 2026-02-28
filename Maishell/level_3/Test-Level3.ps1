# ============================================================
# Test-Level3.ps1 — Level 3 Generator Test Suite
# Usage: cd tools\generator && .\tests\Test-Level3.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GenRoot  = Split-Path $PSScriptRoot -Parent
$TestRoot = $PSScriptRoot
$TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) "hala_gen_l3_$(Get-Random)"

$passed = 0; $failed = 0

function Assert-True([string]$Name, [bool]$Cond, [string]$Detail = '') {
    if ($Cond) { Write-Host "  [PASS] $Name" -ForegroundColor Green; $script:passed++ }
    else { Write-Host "  [FAIL] $Name" -ForegroundColor Red; if ($Detail) { Write-Host "         $Detail" -ForegroundColor Yellow }; $script:failed++ }
}
function Assert-FileExists([string]$P, [string]$L) { Assert-True $L (Test-Path $P) "Not found: $P" }
function Assert-FC([string]$P, [string]$N, [string]$L) {
    if (-not (Test-Path $P)) { Assert-True $L $false "Not found: $P"; return }
    Assert-True $L ((Get-Content $P -Raw).Contains($N)) "'$N' not found"
}
function Assert-FNC([string]$P, [string]$N, [string]$L) {
    if (-not (Test-Path $P)) { Assert-True $L $false "Not found: $P"; return }
    Assert-True $L (-not (Get-Content $P -Raw).Contains($N)) "'$N' unexpectedly found"
}

Write-Host "`n===============================================" -ForegroundColor DarkCyan
Write-Host " Level 3 Generator - Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan

# Setup mock project
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

# Run generator
Write-Host "`n--- Running generator (Order) ---" -ForegroundColor White

& (Join-Path $GenRoot "Generate-Level3.ps1") `
    -ConfigPath (Join-Path $TestRoot "level3_order.config.json") `
    -ProjectRoot $TempDir -Force

$fd = Join-Path $TempDir "lib\features\order"

# ── FILE STRUCTURE ─────────────────────────────────────────
Write-Host "`n  File structure:" -ForegroundColor White
Assert-FileExists (Join-Path $fd "domain\entities\order_entity.dart")                "entity"
Assert-FileExists (Join-Path $fd "domain\repositories\order_repository.dart")        "repo interface"
Assert-FileExists (Join-Path $fd "domain\usecases\get_all_order_usecase.dart")       "getAll use case"
Assert-FileExists (Join-Path $fd "domain\usecases\get_order_usecase.dart")           "get use case"
Assert-FileExists (Join-Path $fd "domain\usecases\create_order_usecase.dart")        "create use case"
Assert-FileExists (Join-Path $fd "domain\usecases\update_order_usecase.dart")        "update use case"
Assert-FileExists (Join-Path $fd "domain\usecases\delete_order_usecase.dart")        "delete use case"
Assert-FileExists (Join-Path $fd "domain\value_objects\order_status.dart")           "status enum"
Assert-FileExists (Join-Path $fd "domain\guards\order_transition_guard.dart")        "transition guard"
Assert-FileExists (Join-Path $fd "domain\services\order_domain_service.dart")        "domain service"
Assert-FileExists (Join-Path $fd "domain\events\order_domain_events.dart")           "domain events"
Assert-FileExists (Join-Path $fd "domain\workflow\order_workflow_executor.dart")      "workflow executor"
Assert-FileExists (Join-Path $fd "data\models\order_model.dart")                     "model"
Assert-FileExists (Join-Path $fd "data\datasources\order_remote_datasource.dart")    "remote ds"
Assert-FileExists (Join-Path $fd "data\repositories\order_repository_impl.dart")     "repo impl"
Assert-FileExists (Join-Path $fd "presentation\bloc\order_bloc.dart")                "bloc"
Assert-FileExists (Join-Path $fd "presentation\bloc\order_event.dart")               "event"
Assert-FileExists (Join-Path $fd "presentation\bloc\order_state.dart")               "state"
Assert-FileExists (Join-Path $fd "presentation\pages\order_list_page.dart")          "list page"
Assert-FileExists (Join-Path $fd "presentation\pages\order_detail_page.dart")        "detail page"
Assert-FileExists (Join-Path $fd "presentation\pages\order_form_page.dart")          "form page"
Assert-FileExists (Join-Path $fd "presentation\widgets\order_card.dart")             "card widget"
Assert-FileExists (Join-Path $fd "presentation\widgets\order_status_badge.dart")     "status badge"

# FormMode in core
Assert-FileExists (Join-Path $TempDir "lib\core\enums\form_mode.dart") "FormMode in core/enums"

$fileCount = (Get-ChildItem $fd -Recurse -File).Count
Assert-True "File count: $fileCount (expected ~23)" ($fileCount -ge 22 -and $fileCount -le 25)

# ── STATUS ENUM ────────────────────────────────────────────
Write-Host "`n  Status enum:" -ForegroundColor White
$statusFile = Join-Path $fd "domain\value_objects\order_status.dart"
Assert-FC $statusFile "enum OrderStatus {"         "enum declaration"
Assert-FC $statusFile "draft,"                     "draft state"
Assert-FC $statusFile "submitted,"                 "submitted state"
Assert-FC $statusFile "approved,"                  "approved state"
Assert-FC $statusFile "rejected,"                  "rejected state"
Assert-FC $statusFile "fulfilled,"                 "fulfilled state"
Assert-FC $statusFile "canTransitionTo(OrderStatus target)" "canTransitionTo method"
Assert-FC $statusFile "String get displayName"     "displayName getter"
Assert-FC $statusFile "Color get color"            "color getter"
Assert-FC $statusFile "OrderStatus.initial"        "initial constant"

# ── ENTITY WITH STATUS ────────────────────────────────────
Write-Host "`n  Entity with status:" -ForegroundColor White
$entityFile = Join-Path $fd "domain\entities\order_entity.dart"
Assert-FC $entityFile "import '../value_objects/order_status.dart'"  "imports status"
Assert-FC $entityFile "final OrderStatus status;"                     "status field"
Assert-FC $entityFile "final String orderNumber;"                     "orderNumber field"
Assert-FC $entityFile "final double totalAmount;"                     "double field"
Assert-FC $entityFile "final bool isUrgent;"                          "bool field"
Assert-FC $entityFile "final String? notes;"                          "nullable field"
Assert-FC $entityFile "this.status = OrderStatusX.initial"            "status default value"
Assert-FC $entityFile "OrderEntity copyWith("                         "copyWith"

# ── MODEL JSON HANDLING ────────────────────────────────────
Write-Host "`n  Model:" -ForegroundColor White
$modelFile = Join-Path $fd "data\models\order_model.dart"
Assert-FC $modelFile "import '../../domain/value_objects/order_status.dart'"  "imports status"
Assert-FC $modelFile "OrderStatus.values.firstWhere"                          "status fromJson"
Assert-FC $modelFile "status.name"                                            "status toJson"
Assert-FC $modelFile "'total_amount'"                                         "snake_case totalAmount"
Assert-FC $modelFile "'is_urgent'"                                            "snake_case isUrgent"
Assert-FC $modelFile "as num).toDouble()"                                     "double parse"
Assert-FC $modelFile "as bool? ?? false"                                      "bool parse"

# ── TRANSITION GUARD ──────────────────────────────────────
Write-Host "`n  Transition guard:" -ForegroundColor White
$guardFile = Join-Path $fd "domain\guards\order_transition_guard.dart"
Assert-FC $guardFile "class OrderTransitionGuard"            "class"
Assert-FC $guardFile "current.canTransitionTo(target)"       "uses canTransitionTo"
Assert-FC $guardFile "HUMAN CUSTOMIZATION ZONE"              "customization zone"

# ── DOMAIN SERVICE ─────────────────────────────────────────
Write-Host "`n  Domain service:" -ForegroundColor White
$svcFile = Join-Path $fd "domain\services\order_domain_service.dart"
Assert-FC $svcFile "class OrderDomainService"                "class"
Assert-FC $svcFile "final OrderRepository repository"        "repo dependency"
Assert-FC $svcFile "final OrderTransitionGuard guard"        "guard dependency"
Assert-FC $svcFile "Future<Either<Failure, OrderEntity>> transition(" "transition method"
Assert-FC $svcFile "entity.copyWith(status: validTarget)"    "apply step"

# ── DOMAIN EVENTS ──────────────────────────────────────────
Write-Host "`n  Domain events:" -ForegroundColor White
$eventsFile = Join-Path $fd "domain\events\order_domain_events.dart"
Assert-FC $eventsFile "abstract class OrderDomainEvent"         "base event"
Assert-FC $eventsFile "class OrderCreatedEvent"                  "created event"
Assert-FC $eventsFile "class OrderStatusChangedEvent"            "status changed event"
Assert-FC $eventsFile "class OrderDeletedEvent"                  "deleted event"
Assert-FC $eventsFile "class OrderValidateInventoryEvent"        "workflow step event"
Assert-FC $eventsFile "class OrderProcessPaymentEvent"           "workflow step event"
Assert-FC $eventsFile "class OrderSendConfirmationEvent"         "workflow step event"
Assert-FC $eventsFile "String get name =>"                       "name getter"
Assert-FC $eventsFile "Map<String, dynamic> toMap()"             "toMap"

# ── WORKFLOW EXECUTOR ──────────────────────────────────────
Write-Host "`n  Workflow executor:" -ForegroundColor White
$wfFile = Join-Path $fd "domain\workflow\order_workflow_executor.dart"
Assert-FC $wfFile "class OrderWorkflowExecutor"              "class"
Assert-FC $wfFile "_validateInventory(OrderEntity entity)"   "step 1 method"
Assert-FC $wfFile "_processPayment(OrderEntity entity)"      "step 2 method"
Assert-FC $wfFile "_sendConfirmation(OrderEntity entity)"    "step 3 method"
Assert-FC $wfFile "_rollback(OrderEntity entity"             "rollback method"
Assert-FC $wfFile "completedSteps.add"                        "tracks completed"

# ── BLOC WITH TRANSITIONS ─────────────────────────────────
Write-Host "`n  BLoC:" -ForegroundColor White
$blocFile = Join-Path $fd "presentation\bloc\order_bloc.dart"
Assert-FC $blocFile "final OrderDomainService domainService"     "domain service dep"
Assert-FC $blocFile "required this.domainService"                 "domainService in ctor"
Assert-FC $blocFile "on<OrderSubmitRequested>"                    "submit handler reg"
Assert-FC $blocFile "on<OrderApproveRequested>"                   "approve handler reg"
Assert-FC $blocFile "on<OrderRejectRequested>"                    "reject handler reg"
Assert-FC $blocFile "on<OrderFulfillRequested>"                   "fulfill handler reg"
Assert-FC $blocFile "on<OrderReviseRequested>"                    "revise handler reg"
Assert-FC $blocFile "domainService.transition("                   "calls domain service"
Assert-FC $blocFile "OrderStatus.submitted"                       "target status"

# ── EVENTS FILE ────────────────────────────────────────────
Write-Host "`n  Events:" -ForegroundColor White
$eventFile = Join-Path $fd "presentation\bloc\order_event.dart"
Assert-FC $eventFile "class OrderSubmitRequested extends OrderEvent"  "submit event"
Assert-FC $eventFile "class OrderApproveRequested extends OrderEvent" "approve event"
Assert-FC $eventFile "class OrderRejectRequested extends OrderEvent"  "reject event"
Assert-FC $eventFile "class OrderFulfillRequested extends OrderEvent" "fulfill event"
Assert-FC $eventFile "class OrderReviseRequested extends OrderEvent"  "revise event"

# ── STATES FILE ────────────────────────────────────────────
Write-Host "`n  States:" -ForegroundColor White
$stateFile = Join-Path $fd "presentation\bloc\order_state.dart"
Assert-FC $stateFile "final OrderEntity? updatedItem"     "updatedItem for transitions"

# ── DETAIL PAGE WITH TRANSITIONS ──────────────────────────
Write-Host "`n  Detail page:" -ForegroundColor White
$detailFile = Join-Path $fd "presentation\pages\order_detail_page.dart"
Assert-FC $detailFile "OrderStatusBadge(status: item.status)"      "status badge"
Assert-FC $detailFile "OrderSubmitRequested(item.id)"               "submit button"
Assert-FC $detailFile "OrderApproveRequested(item.id)"              "approve button"
Assert-FC $detailFile "OrderRejectRequested(item.id)"               "reject button"
Assert-FC $detailFile "OrderStatus.draft"                           "from-state guard"
Assert-FC $detailFile "OrderStatus.submitted"                       "from-state guard"
Assert-FC $detailFile "Text('Actions'"                              "actions section"
Assert-FC $detailFile "state.updatedItem"                           "reload after transition"

# ── FORM PAGE — FormMode FIX ──────────────────────────────
Write-Host "`n  Form page (FormMode fix):" -ForegroundColor White
$formFile = Join-Path $fd "presentation\pages\order_form_page.dart"
Assert-FC $formFile "import '../../../../core/enums/form_mode.dart'"  "imports FormMode from core"
Assert-FNC $formFile "enum FormMode"                                    "NO local FormMode enum"
Assert-FC $formFile "_orderNumberController = TextEditingController()"  "String controller"
Assert-FC $formFile "_totalAmountController = TextEditingController()"  "double controller"
Assert-FC $formFile "bool _isUrgentValue = false;"                      "bool state var"
Assert-FC $formFile "SwitchListTile"                                     "bool widget"
Assert-FNC $formFile "_isUrgentController"                               "NO controller for bool"
Assert-FC $formFile "double.tryParse(_totalAmountController.text)"       "double parse submit"

# ── CARD WITH STATUS BADGE ─────────────────────────────────
Write-Host "`n  Card widget:" -ForegroundColor White
$cardFile = Join-Path $fd "presentation\widgets\order_card.dart"
Assert-FC $cardFile "OrderStatusBadge(status: item.status, compact: true)" "compact badge"
Assert-FC $cardFile "item.orderNumber"                                       "title field"
Assert-FC $cardFile "item.customerName"                                      "subtitle field"

# ── STATUS BADGE WIDGET ────────────────────────────────────
Write-Host "`n  Status badge:" -ForegroundColor White
$badgeFile = Join-Path $fd "presentation\widgets\order_status_badge.dart"
Assert-FC $badgeFile "class OrderStatusBadge"              "class"
Assert-FC $badgeFile "final OrderStatus status"            "status prop"
Assert-FC $badgeFile "status.displayName"                   "uses displayName"
Assert-FC $badgeFile "status.color"                         "uses color"

# ── DI WIRING ─────────────────────────────────────────────
Write-Host "`n  DI wiring:" -ForegroundColor White
$diFile = Join-Path $TempDir "lib\config\di\injection_container.dart"
Assert-FC $diFile "OrderRemoteDataSourceImpl(dio: sl())"     "datasource"
Assert-FC $diFile "OrderRepositoryImpl(remoteDataSource: sl())" "repo impl"
Assert-FC $diFile "GetAllOrderUseCase(sl())"                   "getAll use case"
Assert-FC $diFile "OrderTransitionGuard()"                      "guard registration"
Assert-FC $diFile "OrderDomainService("                         "domain service"
Assert-FC $diFile "repository: sl(), guard: sl()"               "service dependencies"
Assert-FC $diFile "OrderWorkflowExecutor()"                     "workflow executor"
Assert-FC $diFile "domainService: sl()"                          "bloc gets domainService"
Assert-FC $diFile "order_transition_guard.dart"                  "guard import"
Assert-FC $diFile "order_domain_service.dart"                    "service import"
Assert-FC $diFile "order_workflow_executor.dart"                 "executor import"

# ── ROUTER WIRING ─────────────────────────────────────────
Write-Host "`n  Route wiring:" -ForegroundColor White
$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"
Assert-FC $routerFile "case orderList:"                          "list route"
Assert-FC $routerFile "case orderCreate:"                        "create route"
Assert-FC $routerFile "case orderDetail:"                        "detail route"
Assert-FC $routerFile "case orderEdit:"                          "edit route"
Assert-FC $routerFile "BlocProvider"                              "BlocProvider"
Assert-FC $routerFile "import '../../core/enums/form_mode.dart'" "FormMode from core"
Assert-FNC $routerFile "GoRoute"                                  "NO GoRoute"

# ── NAV WIRING ─────────────────────────────────────────────
Write-Host "`n  Nav wiring:" -ForegroundColor White
$navFile = Join-Path $TempDir "lib\app\shell\shell_nav_items.dart"
Assert-FC $navFile "label:      'Order'"             "label"
Assert-FC $navFile "Icons.receipt_long_outlined"      "icon from config"

# ── Cleanup ────────────────────────────────────────────────
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n===============================================" -ForegroundColor DarkCyan
$total = $passed + $failed
if ($failed -eq 0) { Write-Host " ALL $total TESTS PASSED" -ForegroundColor Green }
else { Write-Host " $passed/$total passed, $failed FAILED" -ForegroundColor Red }
Write-Host "===============================================`n" -ForegroundColor DarkCyan
exit $failed
