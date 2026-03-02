# ============================================================
# Test-Level4.ps1 — Level 4 Aggregator Generator Test Suite
# Usage: cd tools\generator && .\tests\Test-Level4.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GenRoot  = Split-Path $PSScriptRoot -Parent
$TestRoot = $PSScriptRoot
$TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) "hala_gen_l4_$(Get-Random)"

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
Write-Host " Level 4 Aggregator Generator - Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

Write-Host "`n--- Running generator (Sales Dashboard, Level 4) ---" -ForegroundColor White

& (Join-Path $GenRoot "Generate-Level4.ps1") `
    -ConfigPath (Join-Path $TestRoot "level4_sales_dashboard.config.json") `
    -ProjectRoot $TempDir -Force

$fd = Join-Path $TempDir "lib\features\sales_dashboard"

# ═══════════════════════════════════════════════════════════
# FILE STRUCTURE — Level 4 specific files
# ═══════════════════════════════════════════════════════════
Write-Host "`n  File structure:" -ForegroundColor White
Assert-FileExists (Join-Path $fd "domain\projections\sales_dashboard_projection.dart")   "projection"
Assert-FileExists (Join-Path $fd "domain\providers\order_data_provider.dart")            "order provider interface"
Assert-FileExists (Join-Path $fd "data\providers\order_data_provider_impl.dart")         "order provider impl"
Assert-FileExists (Join-Path $fd "domain\usecases\get_sales_dashboard_usecase.dart")     "usecase"
Assert-FileExists (Join-Path $fd "presentation\cubit\sales_dashboard_cubit.dart")        "cubit"
Assert-FileExists (Join-Path $fd "presentation\cubit\sales_dashboard_state.dart")        "cubit state"
Assert-FileExists (Join-Path $fd "presentation\pages\sales_dashboard_dashboard_page.dart") "dashboard page"
Assert-FileExists (Join-Path $fd "presentation\widgets\sales_dashboard_metric_card.dart")  "metric card"

# Level 4 must NOT have CRUD files
Assert-FileNotExists (Join-Path $fd "domain\entities")     "NO entity dir"
Assert-FileNotExists (Join-Path $fd "domain\repositories") "NO repo dir"
Assert-FileNotExists (Join-Path $fd "presentation\bloc")   "NO bloc dir"

# ═══════════════════════════════════════════════════════════
# PROJECTION CLASS
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Projection:" -ForegroundColor White
$projFile = Join-Path $fd "domain\projections\sales_dashboard_projection.dart"
Assert-FC $projFile "class SalesDashboardProjection extends Equatable"  "class extends Equatable"
Assert-FC $projFile "final int totalOrders;"                             "count metric"
Assert-FC $projFile "final double totalRevenue;"                         "sum metric"
Assert-FC $projFile "final double averageOrderValue;"                    "average metric"
Assert-FC $projFile "final Map<String, int> ordersByStatus;"             "groupCount metric"
Assert-FC $projFile "final DateTime generatedAt;"                        "timestamp field"
Assert-FC $projFile "required this.totalOrders,"                         "ctor param"
Assert-FC $projFile "required this.generatedAt,"                         "ctor timestamp param"

# ═══════════════════════════════════════════════════════════
# PROVIDER — abstract interface
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Provider interface:" -ForegroundColor White
$provIntFile = Join-Path $fd "domain\providers\order_data_provider.dart"
Assert-FC $provIntFile "abstract class OrderDataProvider"                  "abstract class"
Assert-FC $provIntFile "Future<Either<Failure, List<OrderEntity>>> getAll" "getAll signature"
Assert-FC $provIntFile "features/order/domain/entities/order_entity.dart"  "source entity import"

# ═══════════════════════════════════════════════════════════
# PROVIDER — concrete impl
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Provider impl:" -ForegroundColor White
$provImplFile = Join-Path $fd "data\providers\order_data_provider_impl.dart"
Assert-FC $provImplFile "class OrderDataProviderImpl implements OrderDataProvider"  "implements interface"
Assert-FC $provImplFile "final OrderRepository _repository;"                         "repo field"
Assert-FC $provImplFile "_repository.getAll()"                                       "delegates to repo"

# ═══════════════════════════════════════════════════════════
# USE CASE — orchestrates sources + computes metrics
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Use case:" -ForegroundColor White
$ucFile = Join-Path $fd "domain\usecases\get_sales_dashboard_usecase.dart"
Assert-FC  $ucFile "class GetSalesDashboardUseCase"              "class name"
Assert-FC  $ucFile "final OrderDataProvider _orderProvider;"     "provider field"
Assert-FC  $ucFile "Future<Either<Failure, SalesDashboardProjection>> call()" "call signature"
# Load step — isLeft guard (not fold+async)
Assert-FC  $ucFile "orderResult.isLeft()"                        "isLeft guard"
Assert-FC  $ucFile "orderResult.getOrElse("                      "getOrElse extract"
Assert-FNC $ucFile "(entity) async {"                            "NO async fold"
# Metric computations
Assert-FC  $ucFile "orderList.length"                            "count operation"
Assert-FC  $ucFile "orderList.fold<double>"                      "sum/avg operation"
Assert-FC  $ucFile "<String, int>"                               "groupCount map type"
Assert-FC  $ucFile "e.status.toString()"                         "groupCount field access"
Assert-FC  $ucFile ".take(5).toList()"                           "latest limit"
Assert-FC  $ucFile "b.createdAt.compareTo(a.createdAt)"          "latest sort"
# Projection construction
Assert-FC  $ucFile "SalesDashboardProjection("                   "returns projection"
Assert-FC  $ucFile "generatedAt: DateTime.now()"                 "timestamp"

# ═══════════════════════════════════════════════════════════
# CUBIT — state management
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Cubit:" -ForegroundColor White
$cubitFile = Join-Path $fd "presentation\cubit\sales_dashboard_cubit.dart"
Assert-FC $cubitFile "class SalesDashboardCubit extends Cubit<SalesDashboardState>" "extends Cubit"
Assert-FC $cubitFile "final GetSalesDashboardUseCase _getProjection;"                "usecase dep"
Assert-FC $cubitFile "Future<void> load() async"                                      "load method"
Assert-FC $cubitFile "emit(SalesDashboardLoading())"                                  "emits loading"
Assert-FC $cubitFile "emit(SalesDashboardLoaded(projection))"                         "emits loaded"
Assert-FC $cubitFile "emit(SalesDashboardError("                                      "emits error"
Assert-FC $cubitFile "Future<void> refresh()"                                         "refresh method"

# ═══════════════════════════════════════════════════════════
# CUBIT STATE
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Cubit state:" -ForegroundColor White
$stateFile = Join-Path $fd "presentation\cubit\sales_dashboard_state.dart"
Assert-FC $stateFile "abstract class SalesDashboardState extends Equatable"    "base state"
Assert-FC $stateFile "class SalesDashboardInitial extends SalesDashboardState" "initial"
Assert-FC $stateFile "class SalesDashboardLoading extends SalesDashboardState" "loading"
Assert-FC $stateFile "class SalesDashboardLoaded extends SalesDashboardState"  "loaded"
Assert-FC $stateFile "class SalesDashboardError extends SalesDashboardState"   "error"
Assert-FC $stateFile "final SalesDashboardProjection projection;"               "projection in loaded"

# ═══════════════════════════════════════════════════════════
# DASHBOARD PAGE
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Dashboard page:" -ForegroundColor White
$pageFile = Join-Path $fd "presentation\pages\sales_dashboard_dashboard_page.dart"
Assert-FC  $pageFile "class SalesDashboardDashboardPage extends StatelessWidget"   "class declaration"
Assert-FC  $pageFile "BlocBuilder<SalesDashboardCubit, SalesDashboardState>"       "uses BlocBuilder"
Assert-FC  $pageFile "SalesDashboardMetricCard("                                    "uses metric card"
Assert-FC  $pageFile "GridView.count("                                              "grid layout"
Assert-FC  $pageFile "crossAxisCount: 2"                                            "2-column grid"
Assert-FC  $pageFile "RefreshIndicator("                                            "pull to refresh"
Assert-FC  $pageFile "context.read<SalesDashboardCubit>().refresh()"                "refresh action"
# Metric cards — check all metrics rendered
Assert-FC  $pageFile "'Total Orders'"                                                "count card"
Assert-FC  $pageFile "'Total Revenue'"                                               "sum card"
Assert-FC  $pageFile "'Avg Order Value'"                                             "average card"
Assert-FC  $pageFile "Icons.receipt_long"                                            "custom icon"
Assert-FC  $pageFile "Icons.attach_money"                                            "custom icon 2"
# Status breakdown section
Assert-FC  $pageFile "Text('Breakdown'"                                              "breakdown section"
Assert-FC  $pageFile "projection.ordersByStatus.entries"                              "iterates groups"
# Recent orders section
Assert-FC  $pageFile "'Recent Orders'"                                                "recent section"
Assert-FC  $pageFile "item.orderNumber"                                               "displayField"
# No PS→Dart bugs
Assert-FNC $pageFile "item..toString()"                                               "NO double-dot"
Assert-FNC $pageFile "projection..length"                                             "NO double-dot"

# ═══════════════════════════════════════════════════════════
# METRIC CARD WIDGET
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Metric card widget:" -ForegroundColor White
$cardFile = Join-Path $fd "presentation\widgets\sales_dashboard_metric_card.dart"
Assert-FC $cardFile "class SalesDashboardMetricCard extends StatelessWidget"  "class declaration"
Assert-FC $cardFile "final String title;"                                      "title field"
Assert-FC $cardFile "final String value;"                                      "value field"
Assert-FC $cardFile "final IconData icon;"                                     "icon field"
Assert-FC $cardFile "final Color color;"                                       "color field"
Assert-FC $cardFile "headlineMedium"                                           "big number style"

# ═══════════════════════════════════════════════════════════
# DI WIRING
# ═══════════════════════════════════════════════════════════
Write-Host "`n  DI wiring:" -ForegroundColor White
$diFile = Join-Path $TempDir "lib\config\di\injection_container.dart"
Assert-FC  $diFile "Level 4 Aggregator"                                "level label"
Assert-FC  $diFile "OrderDataProviderImpl(repository: sl())"           "provider registration"
Assert-FC  $diFile "GetSalesDashboardUseCase("                         "usecase registration"
Assert-FC  $diFile "orderProvider: sl()"                                "provider injected"
Assert-FC  $diFile "SalesDashboardCubit(getProjection: sl())"          "cubit registration"
Assert-FNC $diFile "BLoC"                                               "NO BLoC (uses Cubit)"
Assert-FNC $diFile "WorkflowExecutor"                                   "NO workflow"
Assert-FNC $diFile "TransitionGuard"                                    "NO guard"

# ═══════════════════════════════════════════════════════════
# ROUTER
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Router:" -ForegroundColor White
$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"
Assert-FC $routerFile "case salesDashboardDashboard:"                              "dashboard route"
Assert-FC $routerFile "sl<SalesDashboardCubit>()..load()"                          "cubit created with load"
Assert-FC $routerFile "SalesDashboardDashboardPage()"                              "page widget"
Assert-FC $routerFile "Level 4 Aggregator"                                          "level comment"

# ═══════════════════════════════════════════════════════════
# NAV
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Nav:" -ForegroundColor White
$navFile = Join-Path $TempDir "lib\app\shell\shell_nav_items.dart"
Assert-FC $navFile "label:      'Sales Dashboard'"    "label"
Assert-FC $navFile "Icons.dashboard_outlined"          "icon"
Assert-FC $navFile "SalesDashboardCubit"               "cubit in nav"

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
