# ============================================================
# Test-Level5.ps1 — Level 5 Integration Generator Test Suite
# Usage: cd tools\generator && .\tests\Test-Level5.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GenRoot  = Split-Path $PSScriptRoot -Parent
$TestRoot = $PSScriptRoot
$TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) "hala_gen_l5_$(Get-Random)"

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
Write-Host " Level 5 Integration Generator - Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

Write-Host "`n--- Running generator (Payment Gateway, Level 5) ---" -ForegroundColor White

& (Join-Path $GenRoot "Generate-Level5.ps1") `
    -ConfigPath (Join-Path $TestRoot "level5_payment_gateway.config.json") `
    -ProjectRoot $TempDir -Force

$fd = Join-Path $TempDir "lib\features\payment_gateway"

# ═══════════════════════════════════════════════════════════
# FILE STRUCTURE
# ═══════════════════════════════════════════════════════════
Write-Host "`n  File structure:" -ForegroundColor White
Assert-FileExists (Join-Path $fd "data\client\payment_gateway_client.dart")             "client"
Assert-FileExists (Join-Path $fd "domain\services\payment_gateway_service.dart")        "service"
Assert-FileExists (Join-Path $fd "domain\services\payment_gateway_webhook_handler.dart") "webhook handler"
# Operation DTOs
Assert-FileExists (Join-Path $fd "domain\models\create_charge_request.dart")            "createCharge request"
Assert-FileExists (Join-Path $fd "domain\models\create_charge_response.dart")           "createCharge response"
Assert-FileExists (Join-Path $fd "domain\models\get_charge_response.dart")              "getCharge response"
Assert-FileExists (Join-Path $fd "domain\models\list_charges_response.dart")            "listCharges response"
Assert-FileExists (Join-Path $fd "domain\models\refund_charge_request.dart")            "refundCharge request"
Assert-FileExists (Join-Path $fd "domain\models\refund_charge_response.dart")           "refundCharge response"
# Webhook payloads
Assert-FileExists (Join-Path $fd "domain\models\charge_completed_webhook_payload.dart") "charge completed payload"
Assert-FileExists (Join-Path $fd "domain\models\charge_failed_webhook_payload.dart")    "charge failed payload"
Assert-FileExists (Join-Path $fd "domain\models\refund_processed_webhook_payload.dart") "refund processed payload"
# Cubit + Page
Assert-FileExists (Join-Path $fd "presentation\cubit\payment_gateway_cubit.dart")       "cubit"
Assert-FileExists (Join-Path $fd "presentation\cubit\payment_gateway_state.dart")       "state"
Assert-FileExists (Join-Path $fd "presentation\pages\payment_gateway_page.dart")        "page"
Assert-FileExists (Join-Path $fd "presentation\widgets\payment_gateway_operation_card.dart") "operation card"
Assert-FileExists (Join-Path $fd "presentation\widgets\payment_gateway_sync_status.dart")    "sync status"

# NO CRUD files
Assert-FileNotExists (Join-Path $fd "domain\entities")     "NO entity dir"
Assert-FileNotExists (Join-Path $fd "domain\repositories") "NO repo dir"
Assert-FileNotExists (Join-Path $fd "presentation\bloc")   "NO bloc dir"
# DELETE has no request/response DTOs
Assert-FileNotExists (Join-Path $fd "domain\models\delete_charge_request.dart")  "NO delete request DTO"
Assert-FileNotExists (Join-Path $fd "domain\models\delete_charge_response.dart") "NO delete response DTO"

# ═══════════════════════════════════════════════════════════
# CLIENT — retry logic + auth + operations
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Client:" -ForegroundColor White
$clientFile = Join-Path $fd "data\client\payment_gateway_client.dart"
Assert-FC $clientFile "class PaymentGatewayClient"                           "class declaration"
Assert-FC $clientFile "final Dio _dio;"                                       "dio field"
Assert-FC $clientFile "static const int _maxRetries = 3;"                     "max retries from config"
Assert-FC $clientFile "static const int _backoffMs = 1000;"                   "backoff from config"
Assert-FC $clientFile "api.paymentprovider.com/v1"                            "base URL"
Assert-FC $clientFile "Duration(seconds: 30)"                                 "timeout from config"
# Auth
Assert-FC $clientFile "void setAuthToken(String token)"                       "bearer auth method"
Assert-FC $clientFile "'Authorization'"                                        "auth header key"
Assert-FC $clientFile "'Bearer '"                                              "bearer prefix"
# Retry logic
Assert-FC $clientFile "_requestWithRetry"                                      "retry method exists"
Assert-FC $clientFile "DioExceptionType.connectionTimeout"                     "retry on timeout"
Assert-FC $clientFile "statusCode! >= 500"                                     "retry on 5xx"
Assert-FC $clientFile "1 << (attempt - 1)"                                     "exponential backoff"
# Operations
Assert-FC $clientFile "Future<CreateChargeResponse> createCharge(CreateChargeRequest request)" "createCharge sig"
Assert-FC $clientFile "_dio.post('/charges'"                                    "POST path"
Assert-FC $clientFile "request.toJson()"                                       "request serialization"
Assert-FC $clientFile "Future<GetChargeResponse> getCharge(String chargeId)"   "getCharge sig with param"
Assert-FC $clientFile "Future<ListChargesResponse> listCharges()"              "listCharges no params"
Assert-FC $clientFile "Future<void> deleteCharge(String chargeId)"             "delete returns void"
# Path param interpolation — must NOT have PS artifacts
Assert-FNC $clientFile '${chargeId}'                                           "NO Dart interpolation in path (uses concat)"

# ═══════════════════════════════════════════════════════════
# REQUEST DTOs
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Request DTOs:" -ForegroundColor White
$createReqFile = Join-Path $fd "domain\models\create_charge_request.dart"
Assert-FC $createReqFile "class CreateChargeRequest"            "class name"
Assert-FC $createReqFile "final double amount;"                  "amount field"
Assert-FC $createReqFile "final String currency;"                "currency field"
Assert-FC $createReqFile "final String? description;"            "nullable field"
Assert-FC $createReqFile "required this.amount,"                 "required param"
Assert-FC $createReqFile "this.description,"                     "optional param (no required)"
Assert-FC $createReqFile "Map<String, dynamic> toJson()"         "toJson method"
Assert-FC $createReqFile "'customer_id': customerId,"            "snake_case key"

$refundReqFile = Join-Path $fd "domain\models\refund_charge_request.dart"
Assert-FC $refundReqFile "class RefundChargeRequest"             "class name"
Assert-FC $refundReqFile "final double? amount;"                 "nullable double"

# ═══════════════════════════════════════════════════════════
# RESPONSE DTOs
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Response DTOs:" -ForegroundColor White
$createRespFile = Join-Path $fd "domain\models\create_charge_response.dart"
Assert-FC $createRespFile "class CreateChargeResponse"                  "class name"
Assert-FC $createRespFile "final String id;"                            "id field"
Assert-FC $createRespFile "factory CreateChargeResponse.fromJson"       "fromJson factory"
Assert-FC $createRespFile "(json['amount'] as num).toDouble()"          "num->double cast"
Assert-FC $createRespFile "DateTime.parse(json['created_at'] as String)" "DateTime parse"

$listRespFile = Join-Path $fd "domain\models\list_charges_response.dart"
Assert-FC $listRespFile "class ListChargesResponse"   "class name"
Assert-FC $listRespFile "final int totalCount;"       "int field"
Assert-FC $listRespFile "final bool hasMore;"         "bool field"

# ═══════════════════════════════════════════════════════════
# SERVICE — wraps client in Either
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Service:" -ForegroundColor White
$svcFile = Join-Path $fd "domain\services\payment_gateway_service.dart"
Assert-FC $svcFile "class PaymentGatewayService"                        "class name"
Assert-FC $svcFile "final PaymentGatewayClient _client;"                "client field"
Assert-FC $svcFile "Future<Either<Failure, CreateChargeResponse>> createCharge" "createCharge returns Either"
Assert-FC $svcFile "Future<Either<Failure, void>> deleteCharge"         "delete returns Either<void>"
Assert-FC $svcFile "on DioException catch (e)"                          "catches DioException"
Assert-FC $svcFile "return Left(ServerFailure("                         "wraps in ServerFailure"
Assert-FC $svcFile "return Right(result)"                                "wraps success in Right"

# ═══════════════════════════════════════════════════════════
# WEBHOOK PAYLOADS
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Webhook payloads:" -ForegroundColor White
$whCompFile = Join-Path $fd "domain\models\charge_completed_webhook_payload.dart"
Assert-FC $whCompFile "class ChargeCompletedWebhookPayload"      "class name"
Assert-FC $whCompFile "final String event;"                       "event field"
Assert-FC $whCompFile "final String chargeId;"                    "chargeId field"
Assert-FC $whCompFile "final double amount;"                      "amount field"
Assert-FC $whCompFile "final DateTime paidAt;"                    "DateTime field"
Assert-FC $whCompFile "factory ChargeCompletedWebhookPayload.fromJson" "fromJson factory"

$whFailFile = Join-Path $fd "domain\models\charge_failed_webhook_payload.dart"
Assert-FC $whFailFile "class ChargeFailedWebhookPayload"         "class name"
Assert-FC $whFailFile "final String errorCode;"                   "error code field"

# ═══════════════════════════════════════════════════════════
# WEBHOOK HANDLER
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Webhook handler:" -ForegroundColor White
$whHandler = Join-Path $fd "domain\services\payment_gateway_webhook_handler.dart"
Assert-FC $whHandler "class PaymentGatewayWebhookHandler"           "class name"
Assert-FC $whHandler "Future<Either<Failure, void>> handle("         "handle method"
Assert-FC $whHandler "case 'charge.completed':"                      "routes charge.completed"
Assert-FC $whHandler "case 'charge.failed':"                         "routes charge.failed"
Assert-FC $whHandler "case 'refund.processed':"                      "routes refund.processed"
Assert-FC $whHandler "ChargeCompletedWebhookPayload.fromJson(data)"  "deserializes payload"
Assert-FC $whHandler "_handleChargeCompleted("                       "calls handler"
Assert-FC $whHandler "_handleChargeFailed("                          "calls handler"
Assert-FC $whHandler "_handleRefundProcessed("                       "calls handler"
Assert-FC $whHandler "Unknown webhook event"                          "unknown event handling"

# ═══════════════════════════════════════════════════════════
# CUBIT STATE — per-operation tracking
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Cubit state:" -ForegroundColor White
$stateFile = Join-Path $fd "presentation\cubit\payment_gateway_state.dart"
Assert-FC $stateFile "class PaymentGatewayState extends Equatable"  "class extends Equatable"
Assert-FC $stateFile "final bool isLoading;"                         "global loading"
Assert-FC $stateFile "final DateTime? lastSyncAt;"                   "last sync timestamp"
Assert-FC $stateFile "final bool isCreateChargeLoading;"             "per-op loading"
Assert-FC $stateFile "final bool isGetChargeLoading;"                "per-op loading"
Assert-FC $stateFile "final String? createChargeError;"              "per-op error"
Assert-FC $stateFile "final ListChargesResponse? listChargesResult;" "GET result stored"
Assert-FC $stateFile "final GetChargeResponse? getChargeResult;"     "GET with param result stored"
Assert-FC $stateFile "PaymentGatewayState copyWith("                 "copyWith method"

# ═══════════════════════════════════════════════════════════
# CUBIT — operation methods
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Cubit:" -ForegroundColor White
$cubitFile = Join-Path $fd "presentation\cubit\payment_gateway_cubit.dart"
Assert-FC $cubitFile "class PaymentGatewayCubit extends Cubit<PaymentGatewayState>" "extends Cubit"
Assert-FC $cubitFile "final PaymentGatewayService _service;"          "service dep"
Assert-FC $cubitFile "Future<void> createCharge(CreateChargeRequest request)" "createCharge method"
Assert-FC $cubitFile "Future<void> getCharge(String chargeId)"        "getCharge with param"
Assert-FC $cubitFile "Future<void> listCharges()"                      "listCharges no params"
Assert-FC $cubitFile "Future<void> deleteCharge(String chargeId)"     "deleteCharge with param"
Assert-FC $cubitFile "emit(state.copyWith(isCreateChargeLoading: true"  "emits loading"
Assert-FC $cubitFile "lastSyncAt: DateTime.now()"                      "updates timestamp"

# ═══════════════════════════════════════════════════════════
# PAGE — operations list + webhook section
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Page:" -ForegroundColor White
$pageFile = Join-Path $fd "presentation\pages\payment_gateway_page.dart"
Assert-FC $pageFile "class PaymentGatewayPage extends StatelessWidget"   "class"
Assert-FC $pageFile "BlocBuilder<PaymentGatewayCubit, PaymentGatewayState>" "BlocBuilder"
Assert-FC $pageFile "PaymentGatewayOperationCard("                        "uses operation card"
Assert-FC $pageFile "PaymentGatewaySyncStatus("                           "uses sync status"
Assert-FC $pageFile "'Create Charge'"                                      "op label"
Assert-FC $pageFile "'List Charges'"                                       "op label"
Assert-FC $pageFile "'Cancel Charge'"                                      "op label"
Assert-FC $pageFile "state.isCreateChargeLoading"                          "per-op loading"
Assert-FC $pageFile "state.createChargeError"                              "per-op error"
Assert-FC $pageFile "Text('Webhooks'"                                      "webhook section"
Assert-FC $pageFile "Icons.webhook"                                        "webhook icon"
Assert-FC $pageFile "'charge.completed'"                                   "webhook event"
# Auto-execute only for GET without path params
Assert-FC $pageFile "context.read<PaymentGatewayCubit>().listCharges()"    "auto-execute listCharges"
# GET with path param should NOT have auto-execute
Assert-FC $pageFile "// Requires parameters"                                "param ops not auto-executed"

# ═══════════════════════════════════════════════════════════
# OPERATION CARD WIDGET
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Operation card:" -ForegroundColor White
$cardFile = Join-Path $fd "presentation\widgets\payment_gateway_operation_card.dart"
Assert-FC $cardFile "class PaymentGatewayOperationCard"    "class"
Assert-FC $cardFile "final bool isLoading;"                 "loading prop"
Assert-FC $cardFile "final String? error;"                  "error prop"
Assert-FC $cardFile "CircularProgressIndicator"             "spinner"
Assert-FC $cardFile "Icons.error_outline"                   "error icon"
Assert-FC $cardFile "errorContainer"                        "error styling"

# ═══════════════════════════════════════════════════════════
# SYNC STATUS WIDGET
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Sync status:" -ForegroundColor White
$syncFile = Join-Path $fd "presentation\widgets\payment_gateway_sync_status.dart"
Assert-FC $syncFile "class PaymentGatewaySyncStatus"    "class"
Assert-FC $syncFile "final DateTime? lastSyncAt;"        "timestamp prop"
Assert-FC $syncFile "_formatTime"                        "time formatter"
Assert-FC $syncFile "'Not synced yet'"                   "default text"
Assert-FC $syncFile "'Syncing...'"                       "loading text"

# ═══════════════════════════════════════════════════════════
# DI WIRING
# ═══════════════════════════════════════════════════════════
Write-Host "`n  DI wiring:" -ForegroundColor White
$diFile = Join-Path $TempDir "lib\config\di\injection_container.dart"
Assert-FC  $diFile "Level 5 Integration"                        "level label"
Assert-FC  $diFile "PaymentGatewayClient(dio: sl())"            "client registration"
Assert-FC  $diFile "PaymentGatewayService(client: sl())"        "service registration"
Assert-FC  $diFile "PaymentGatewayWebhookHandler()"             "webhook handler registration"
Assert-FC  $diFile "PaymentGatewayCubit(service: sl())"         "cubit registration"
Assert-FNC $diFile "BLoC"                                       "NO BLoC (uses Cubit)"
Assert-FNC $diFile "Repository"                                  "NO repository"

# ═══════════════════════════════════════════════════════════
# ROUTER
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Router:" -ForegroundColor White
$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"
Assert-FC $routerFile "case paymentGatewayPage:"                  "route case"
Assert-FC $routerFile "sl<PaymentGatewayCubit>()"                  "cubit created"
Assert-FC $routerFile "PaymentGatewayPage()"                       "page widget"
Assert-FC $routerFile "Level 5 Integration"                         "level comment"

# ═══════════════════════════════════════════════════════════
# NAV
# ═══════════════════════════════════════════════════════════
Write-Host "`n  Nav:" -ForegroundColor White
$navFile = Join-Path $TempDir "lib\app\shell\shell_nav_items.dart"
Assert-FC $navFile "label:      'Payments'"        "label"
Assert-FC $navFile "Icons.payment_outlined"         "icon"

# ═══════════════════════════════════════════════════════════
# PS → DART SAFETY CHECKS
# ═══════════════════════════════════════════════════════════
Write-Host "`n  PS -> Dart safety:" -ForegroundColor White
# Check ALL generated files for common PS artifacts
$allFiles = Get-ChildItem $fd -Recurse -File -Filter "*.dart"
$allClean = $true
foreach ($f in $allFiles) {
    $raw = Get-Content $f.FullName -Raw
    # Double dot (missing field name)
    if ($raw -match 'item\.\.') { Assert-True "NO double-dot in $($f.Name)" $false; $allClean = $false }
    # Empty type
    if ($raw -match 'final\s+\s+\w+;') { Assert-True "NO empty type in $($f.Name)" $false; $allClean = $false }
    # Bare ? param
    if ($raw -match '^\s+\?\s+\w+,' -and $raw -notmatch 'String\?' -and $raw -notmatch 'int\?' -and $raw -notmatch 'double\?') {
        # More targeted check
    }
}
if ($allClean) { Assert-True "All files clean of PS artifacts" $true }

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
