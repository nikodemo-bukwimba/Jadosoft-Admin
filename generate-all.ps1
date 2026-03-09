# ═══════════════════════════════════════════════════════════════
# HMSCP Platform Admin — Maishell Batch Generator
# ═══════════════════════════════════════════════════════════════
#
# Run from your Flutter project root where Maishell/ folder exists.
#
# Usage:
#   PS> .\generate-all.ps1
#
# Prerequisites:
#   - Flutter Clean Architecture template already scaffolded
#   - Auth feature already present (from template)
#   - Maishell generator scripts in .\Maishell\level_N\
#
# Generation Order Matters:
#   1. Level 1 features first (they define entities other features depend on)
#   2. Level 4 dashboard last (it aggregates from Level 1 features)
#
# After Generation:
#   1. Check injection_container.dart — ensure all DI registrations are wired
#   2. Check app_router.dart — ensure all routes are registered
#   3. Check shell_nav_items.dart — ensure nav tabs appear
#   4. Update core/constants/app_constants.dart with your API base URL
#
# API Note:
#   The users feature requires a GET /api/v1/admin/users endpoint.
#   Add this route to modules/Platform/Routes/api.php if not present:
#     Route::apiResource('users', UserAdminController::class)->only(['index', 'show', 'update']);
#
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  HMSCP Platform Admin — Maishell Feature Generation" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# ── Feature configs in dependency order ──
$configs = @(
    # Level 1 — CRUD features (entities that others reference)
    @{ Level = 1; Path = ".\configs\actor_types.json";          Label = "Actor Types" }
    @{ Level = 1; Path = ".\configs\platform_permissions.json"; Label = "Platform Permissions" }
    @{ Level = 1; Path = ".\configs\platform_roles.json";       Label = "Platform Roles" }
    @{ Level = 1; Path = ".\configs\actors.json";               Label = "Actors" }
    @{ Level = 1; Path = ".\configs\organizations.json";        Label = "Organizations" }
    @{ Level = 1; Path = ".\configs\users.json";                Label = "Users" }

    # Level 4 — Aggregator dashboard (depends on Level 1 features above)
    @{ Level = 4; Path = ".\configs\admin_dashboard.json";      Label = "Admin Dashboard" }
)

$total   = $configs.Count
$success = 0
$failed  = 0

foreach ($c in $configs) {
    $idx = $configs.IndexOf($c) + 1
    Write-Host "[$idx/$total] Generating Level $($c.Level): $($c.Label)" -ForegroundColor Yellow

    if (-not (Test-Path $c.Path)) {
        Write-Host "  ERROR: Config not found: $($c.Path)" -ForegroundColor Red
        $failed++
        continue
    }

    $script = ".\Maishell\level_$($c.Level)\Generate-Level$($c.Level).ps1"

    if (-not (Test-Path $script)) {
        Write-Host "  ERROR: Generator not found: $script" -ForegroundColor Red
        $failed++
        continue
    }

    try {
        & $script -ConfigPath $c.Path
        Write-Host "  OK" -ForegroundColor Green
        $success++
    }
    catch {
        Write-Host "  FAILED: $_" -ForegroundColor Red
        $failed++
    }

    Write-Host ""
}

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Done. $success succeeded, $failed failed out of $total." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($success -gt 0) {
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Review lib/config/di/injection_container.dart" -ForegroundColor Gray
    Write-Host "  2. Review lib/app/routes/app_router.dart" -ForegroundColor Gray
    Write-Host "  3. Review lib/app/shell/shell_nav_items.dart" -ForegroundColor Gray
    Write-Host "  4. Run: flutter pub get" -ForegroundColor Gray
    Write-Host "  5. Run: dart run build_runner build --delete-conflicting-outputs" -ForegroundColor Gray
    Write-Host "  6. Run: flutter run -d windows" -ForegroundColor Gray
    Write-Host ""
}
