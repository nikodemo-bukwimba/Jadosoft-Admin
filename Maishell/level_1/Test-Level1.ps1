# ============================================================
# Test-Level1.ps1 — Automated test for Level 1 generator
# Usage: cd tools\generator && .\tests\Test-Level1.ps1
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$GenRoot  = Split-Path $PSScriptRoot -Parent
$TestRoot = $PSScriptRoot
$TempDir  = Join-Path ([System.IO.Path]::GetTempPath()) "hala_gen_l1_$(Get-Random)"

$passed = 0; $failed = 0

function Assert-True([string]$Name, [bool]$Cond, [string]$Detail = '') {
    if ($Cond) { Write-Host "  [PASS] $Name" -ForegroundColor Green; $script:passed++ }
    else { Write-Host "  [FAIL] $Name" -ForegroundColor Red; if ($Detail) { Write-Host "         $Detail" -ForegroundColor Yellow }; $script:failed++ }
}
function Assert-FileExists([string]$Path, [string]$Label) { Assert-True $Label (Test-Path $Path) "Not found: $Path" }
function Assert-FileContains([string]$Path, [string]$Needle, [string]$Label) {
    if (-not (Test-Path $Path)) { Assert-True $Label $false "Not found: $Path"; return }
    Assert-True $Label ((Get-Content $Path -Raw).Contains($Needle)) "'$Needle' not found"
}
function Assert-FileNotContains([string]$Path, [string]$Needle, [string]$Label) {
    if (-not (Test-Path $Path)) { Assert-True $Label $false "Not found: $Path"; return }
    Assert-True $Label (-not (Get-Content $Path -Raw).Contains($Needle)) "'$Needle' unexpectedly found"
}

Write-Host "`n===============================================" -ForegroundColor DarkCyan
Write-Host " Level 1 Generator - Test Suite" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor DarkCyan

# ── Setup mock project ─────────────────────────────────────
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
Copy-Item -Path (Join-Path $TestRoot "mock_project\*") -Destination $TempDir -Recurse -Force

# ── Test A: Category (minimal config) ─────────────────────
Write-Host "`n--- Test A: Category (minimal) ---" -ForegroundColor White

& (Join-Path $GenRoot "Generate-Level1.ps1") `
    -ConfigPath (Join-Path $TestRoot "level1_category.config.json") `
    -ProjectRoot $TempDir -Force

$fd = Join-Path $TempDir "lib\features\category"

Write-Host "`n  File structure:" -ForegroundColor White
Assert-FileExists (Join-Path $fd "domain\entities\category_entity.dart")             "entity"
Assert-FileExists (Join-Path $fd "domain\repositories\category_repository.dart")     "repo interface"
Assert-FileExists (Join-Path $fd "domain\usecases\get_all_category_usecase.dart")    "getAll usecase"
Assert-FileExists (Join-Path $fd "domain\usecases\get_category_usecase.dart")        "get usecase"
Assert-FileExists (Join-Path $fd "domain\usecases\create_category_usecase.dart")     "create usecase"
Assert-FileExists (Join-Path $fd "domain\usecases\update_category_usecase.dart")     "update usecase"
Assert-FileExists (Join-Path $fd "domain\usecases\delete_category_usecase.dart")     "delete usecase"
Assert-FileExists (Join-Path $fd "data\models\category_model.dart")                  "model"
Assert-FileExists (Join-Path $fd "data\datasources\category_remote_datasource.dart") "remote ds"
Assert-FileExists (Join-Path $fd "data\repositories\category_repository_impl.dart")  "repo impl"
Assert-FileExists (Join-Path $fd "presentation\bloc\category_bloc.dart")             "bloc"
Assert-FileExists (Join-Path $fd "presentation\bloc\category_event.dart")            "event"
Assert-FileExists (Join-Path $fd "presentation\bloc\category_state.dart")            "state"
Assert-FileExists (Join-Path $fd "presentation\pages\category_list_page.dart")       "list page"
Assert-FileExists (Join-Path $fd "presentation\pages\category_detail_page.dart")     "detail page"
Assert-FileExists (Join-Path $fd "presentation\pages\category_form_page.dart")       "form page"
Assert-FileExists (Join-Path $fd "presentation\widgets\category_card.dart")          "card widget"

$fileCount = (Get-ChildItem $fd -Recurse -File).Count
Assert-True "Exactly 17 files generated (got $fileCount)" ($fileCount -eq 17)

Write-Host "`n  Entity:" -ForegroundColor White
$entityFile = Join-Path $fd "domain\entities\category_entity.dart"
Assert-FileContains $entityFile "class CategoryEntity extends Equatable" "extends Equatable"
Assert-FileContains $entityFile "final String id;"    "has id field"
Assert-FileContains $entityFile "final String name;"  "has name field"
Assert-FileContains $entityFile "final DateTime createdAt;" "has createdAt field"
Assert-FileContains $entityFile "CategoryEntity copyWith("  "has copyWith"

Write-Host "`n  Repository interface:" -ForegroundColor White
$repoFile = Join-Path $fd "domain\repositories\category_repository.dart"
Assert-FileContains $repoFile "abstract class CategoryRepository"          "abstract class"
Assert-FileContains $repoFile "Future<Either<Failure, List<CategoryEntity>>> getAll()" "getAll"
Assert-FileContains $repoFile "Future<Either<Failure, void>> delete(String id)"        "delete"
Assert-FileContains $repoFile "import '../entities/category_entity.dart'"              "correct entity import path"

Write-Host "`n  Model:" -ForegroundColor White
$modelFile = Join-Path $fd "data\models\category_model.dart"
Assert-FileContains $modelFile "class CategoryModel extends CategoryEntity"  "extends entity"
Assert-FileContains $modelFile "factory CategoryModel.fromJson"               "fromJson"
Assert-FileContains $modelFile "Map<String, dynamic> toJson()"                "toJson"
Assert-FileContains $modelFile "factory CategoryModel.fromEntity"             "fromEntity"
Assert-FileContains $modelFile "'created_at'"                                  "snake_case JSON key"

Write-Host "`n  Remote datasource:" -ForegroundColor White
$dsFile = Join-Path $fd "data\datasources\category_remote_datasource.dart"
Assert-FileContains $dsFile "CategoryRemoteDataSourceImpl({required Dio dio})" "named Dio param"
Assert-FileContains $dsFile "final Dio _dio;"                                    "private _dio field"
Assert-FileContains $dsFile "await _dio.get('/categories')"                      "correct endpoint"
Assert-FileContains $dsFile "await _dio.post('/categories'"                      "POST endpoint"
Assert-FileNotContains $dsFile "this.dio)"                                       "NO positional dio"

Write-Host "`n  Repo impl:" -ForegroundColor White
$implFile = Join-Path $fd "data\repositories\category_repository_impl.dart"
Assert-FileContains $implFile "class CategoryRepositoryImpl implements CategoryRepository"  "implements interface"
Assert-FileContains $implFile "CategoryRemoteDataSource remoteDataSource"                    "takes datasource"
Assert-FileContains $implFile "CategoryModel.fromEntity(entity)"                             "uses fromEntity"
Assert-FileContains $implFile "import '../../domain/repositories/category_repository.dart'"  "correct repo import"
Assert-FileNotContains $implFile "isActive_repository"                                       "NO wrong import path"

Write-Host "`n  Create usecase validation:" -ForegroundColor White
$createFile = Join-Path $fd "domain\usecases\create_category_usecase.dart"
Assert-FileContains $createFile "class CreateCategoryParams"               "params class"
Assert-FileContains $createFile "final String name;"                        "param field"
Assert-FileContains $createFile "Category name is required"                 "validation message"
Assert-FileContains $createFile "Name too short"                            "minLength validation"
Assert-FileContains $createFile "import '../repositories/category_repository.dart'" "correct import (feature name)"
Assert-FileNotContains $createFile "import '../repositories/name_repository.dart'"  "NO field-name import"

Write-Host "`n  BLoC:" -ForegroundColor White
$blocFile = Join-Path $fd "presentation\bloc\category_bloc.dart"
Assert-FileContains $blocFile "class CategoryBloc extends Bloc<CategoryEvent, CategoryState>" "class declaration"
Assert-FileContains $blocFile "required this.getAllUseCase"  "all use cases injected"
Assert-FileContains $blocFile "required this.deleteUseCase"  "delete use case"
Assert-FileContains $blocFile "import '../../domain/usecases/get_all_category_usecase.dart'" "correct import"

Write-Host "`n  Form page:" -ForegroundColor White
$formFile = Join-Path $fd "presentation\pages\category_form_page.dart"
Assert-FileContains $formFile "final _nameController = TextEditingController()"  "controller for name"
Assert-FileContains $formFile "_nameController.dispose()"                         "dispose controller"
Assert-FileContains $formFile "Category name is required"                         "form validation"
Assert-FileContains $formFile "name: _nameController.text"                        "param mapping"
Assert-FileNotContains $formFile "_isActiveController"                             "NO bool controller (no bool fields)"

Write-Host "`n  Card widget:" -ForegroundColor White
$cardFile = Join-Path $fd "presentation\widgets\category_card.dart"
Assert-FileContains $cardFile "item.name"                                          "displays title field"
Assert-FileContains $cardFile "import '../../domain/entities/category_entity.dart'" "correct entity import"

Write-Host "`n  DI wiring:" -ForegroundColor White
$diFile = Join-Path $TempDir "lib\config\di\injection_container.dart"
Assert-FileContains $diFile "CategoryRemoteDataSourceImpl(dio: sl())"  "datasource DI"
Assert-FileContains $diFile "CategoryRepositoryImpl(remoteDataSource: sl())" "repo DI"
Assert-FileContains $diFile "GetAllCategoryUseCase(sl())"              "getAll DI"
Assert-FileContains $diFile "CategoryBloc("                             "bloc factory"

Write-Host "`n  Route wiring:" -ForegroundColor White
$routerFile = Join-Path $TempDir "lib\app\routes\app_router.dart"
Assert-FileContains $routerFile "case categoryList:"          "list route"
Assert-FileContains $routerFile "case categoryCreate:"        "create route"
Assert-FileContains $routerFile "case categoryDetail:"        "detail route"
Assert-FileContains $routerFile "case categoryEdit:"          "edit route"
Assert-FileContains $routerFile "BlocProvider"                "BlocProvider wrapping"
Assert-FileContains $routerFile "MaterialPageRoute"           "MaterialPageRoute"
Assert-FileNotContains $routerFile "GoRoute"                  "NO GoRoute"

# ── Test B: Task (rich config — multiple types) ───────────
Write-Host "`n--- Test B: Task (rich config) ---" -ForegroundColor White

# Reset mock project
Remove-Item -Path (Join-Path $TempDir "lib\features") -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $TestRoot "mock_project\lib\config") -Destination (Join-Path $TempDir "lib\config") -Recurse -Force
Copy-Item -Path (Join-Path $TestRoot "mock_project\lib\app") -Destination (Join-Path $TempDir "lib\app") -Recurse -Force

& (Join-Path $GenRoot "Generate-Level1.ps1") `
    -ConfigPath (Join-Path $TestRoot "level1_task.config.json") `
    -ProjectRoot $TempDir -Force

$fd2 = Join-Path $TempDir "lib\features\task"

Write-Host "`n  Multi-type entity:" -ForegroundColor White
$taskEntity = Join-Path $fd2 "domain\entities\task_entity.dart"
Assert-FileContains $taskEntity "final String title;"      "String field"
Assert-FileContains $taskEntity "final String? description;" "nullable String"
Assert-FileContains $taskEntity "final int priority;"       "int field"
Assert-FileContains $taskEntity "final double? estimatedHours;" "nullable double"
Assert-FileContains $taskEntity "final bool isCompleted;"   "bool field"
Assert-FileContains $taskEntity "final DateTime? dueDate;"  "nullable DateTime"

Write-Host "`n  Multi-type model JSON:" -ForegroundColor White
$taskModel = Join-Path $fd2 "data\models\task_model.dart"
Assert-FileContains $taskModel "'estimated_hours'"   "snake_case for camelCase"
Assert-FileContains $taskModel "'is_completed'"      "snake_case for bool"
Assert-FileContains $taskModel "'due_date'"           "snake_case for DateTime"
Assert-FileContains $taskModel "as num).toDouble()"   "double parse"
Assert-FileContains $taskModel "as bool? ?? false"    "bool parse with default"

Write-Host "`n  Multi-type form:" -ForegroundColor White
$taskForm = Join-Path $fd2 "presentation\pages\task_form_page.dart"
Assert-FileContains $taskForm "_titleController = TextEditingController()"       "String controller"
Assert-FileContains $taskForm "_priorityController = TextEditingController()"    "int controller"
Assert-FileContains $taskForm "_estimatedHoursController = TextEditingController()" "double controller"
Assert-FileContains $taskForm "bool _isCompletedValue = false;"                  "bool state var"
Assert-FileContains $taskForm "SwitchListTile"                                    "bool widget"
Assert-FileContains $taskForm "showDatePicker"                                    "date picker"
Assert-FileContains $taskForm "int.tryParse(_priorityController.text)"            "int parse in submit"
Assert-FileContains $taskForm "double.tryParse(_estimatedHoursController.text)"   "double parse in submit"
Assert-FileNotContains $taskForm "_isCompletedController"                          "NO controller for bool"

Write-Host "`n  Multi-type validation:" -ForegroundColor White
$taskCreate = Join-Path $fd2 "domain\usecases\create_task_usecase.dart"
Assert-FileContains $taskCreate "p.title.trim().isEmpty"          "String required check"
Assert-FileContains $taskCreate "p.title.trim().length < 3"       "minLength check"
Assert-FileContains $taskCreate "p.title.trim().length > 200"     "maxLength check"
Assert-FileContains $taskCreate "p.priority < 1"                   "min check"
Assert-FileContains $taskCreate "p.priority > 5"                   "max check"

# ── Cleanup ────────────────────────────────────────────────
Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n===============================================" -ForegroundColor DarkCyan
$total = $passed + $failed
if ($failed -eq 0) { Write-Host " ALL $total TESTS PASSED" -ForegroundColor Green }
else { Write-Host " $passed/$total passed, $failed FAILED" -ForegroundColor Red }
Write-Host "===============================================`n" -ForegroundColor DarkCyan
exit $failed
