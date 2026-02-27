# Phase 3 — PowerShell Generator
## Flutter Clean Architecture · Config-Driven Two-Phase Generator

---

## 1. What the Generator Is

The generator is a **two-phase compiler** that reads a `feature.config.json` and produces a fully working Flutter feature — all layers, all files, all wiring — ready for the developer to extend with domain-specific logic.

It is not a scaffolding tool. It does not produce empty files with TODO markers. It produces code that compiles and runs on day one.

---

## 2. File Structure

```
tools/
└── generator/
    ├── generate.ps1                    ← Entry point
    ├── modules/
    │   ├── Validator.psm1              ← Schema validation (50+ rules)
    │   ├── DependencyGraph.psm1        ← Cross-feature graph + cycle detection
    │   └── TemplateEngine.psm1         ← Token engine + Dart code helpers
    └── generators/
        ├── EntityGenerator.psm1        ← Domain entities, models, use cases, repository impl
        ├── BlocGenerator.psm1          ← BLoC, events, states, form cubit
        ├── PageGenerator.psm1          ← List page, detail page, form page, card widget
        ├── StateMachineGenerator.psm1  ← Status enum, transition guard, domain service, status badge
        ├── WorkflowGenerator.psm1      ← Domain events, workflow step executor
        ├── DiRouterGenerator.psm1      ← Provider adapters, DI wiring, route wiring
        ├── RepositoryGenerator.psm1    ← (delegated to EntityGenerator)
        └── UseCaseGenerator.psm1       ← (delegated to EntityGenerator)
```

---

## 3. Two-Phase Execution

### Phase A — Analysis

Before a single file is written, the generator builds a complete picture.

```
1. Load config from path
2. Validate schema (Validator.psm1) — all errors reported together, never partial
3. Derive naming tokens (FNAME, FCLASS, FUPPER, FLABEL)
4. Check for existing feature folder — HALT if found
5. Discover all other feature.config.json files in lib/features/
6. Build dependency graph (DependencyGraph.psm1)
7. Detect circular dependencies — HALT if found
8. Identify cross-feature belongsTo relationships
```

The generator never enters Phase B with an invalid config. The config either fully validates or fully rejects — no partial generation.

### Phase B — Generation

Code is emitted in dependency order. Files are created atomically per feature.

```
Level 0  →  presentation/pages/ + widgets/
Level 1  →  domain/ + data/ + presentation/bloc/ + pages/ + widgets/
Level 2  →  + state machine (status enum, guard, domain service, status badge)
Level 3  →  + workflow (domain events, step executor)
Level 4  →  aggregator structure (no data layer)
Level 5  →  + integration client + retry policy
All      →  cross-feature provider interfaces + adapters
All      →  DI registration appended to injection_container.dart
All      →  Routes appended to app_router.dart
```

---

## 4. Token System

Every generated Dart file uses four tokens that the template engine replaces:

| Token | Replaces with | Example |
|---|---|---|
| `FNAME` | snake_case feature name | `project` |
| `FCLASS` | PascalCase class name | `Project` |
| `FUPPER` | UPPER_CASE | `PROJECT` |
| `FLABEL` | Human-readable label | `Project` |

These tokens never conflict with Dart syntax. Dart's own `$variable` interpolation passes through the PowerShell single-quoted here-strings unchanged.

---

## 5. Dynamic Code Generation

The template engine generates dynamic Dart constructs from config data. This is what separates the generator from simple text substitution.

**Field declarations** — from `entities.{name}.fields`:
```dart
// Config input:
"name": { "type": "String", "nullable": false }
"budget": { "type": "double", "nullable": false }

// Generated output:
final String name;
final double budget;
```

**Validation gates** — from `fields.{name}.validation`:
```dart
// Config input:
"name": { "validation": { "required": { "value": true, "message": "Name is required" },
                          "minLength": { "value": 3, "message": "Name too short" } } }
// Generated output (in use case):
if (p.name.trim().isEmpty) {
  return const Left(ValidationFailure('Name is required'));
}
if (p.name.length < 3) {
  return const Left(ValidationFailure('Name too short'));
}
```

**State machine** — from `stateMachine.states` and `stateMachine.transitions`:
```dart
// Config input:
"states": [{ "name": "draft" }, { "name": "active" }, { "name": "completed" }],
"transitions": [{ "name": "activate", "from": ["draft"], "to": "active" }]

// Generated output (in ProjectStatus enum):
bool canTransitionTo(ProjectStatus next) {
  const allowed = {
    ProjectStatus.draft:     [ProjectStatus.active],
    ProjectStatus.active:    [ProjectStatus.completed],
    ProjectStatus.completed: [],
  };
  return allowed[this]?.contains(next) ?? false;
}
```

**Nested serialization** — from `relationships.{name}` with `type: hasMany`:
```dart
// Config input:
"members": { "type": "hasMany", "entity": "ProjectMember" }

// Generated output (in ProjectModel.fromJson):
members: (json['members'] as List<dynamic>?)
    ?.map((e) => ProjectMemberModel.fromJson(e as Map<String, dynamic>))
    .toList() ?? const [],
```

**Cross-feature provider** — from `relationships.{name}` with `type: belongsTo` and `feature`:
```dart
// Config input:
"owner": { "type": "belongsTo", "entity": "User", "feature": "auth" }

// Generated output:
// project/domain/providers/user_provider.dart (abstract interface)
abstract class UserProvider {
  Future<List<UserRef>> search(String query);
  Future<UserRef?> getById(String id);
}

// project/data/providers/auth_user_provider_adapter.dart (adapter)
class AuthUserProviderAdapter implements UserProvider { ... }

// injection_container.dart (auto-wired)
sl.registerLazySingleton<UserProvider>(
  () => AuthUserProviderAdapter(repository: sl<AuthRepository>()),
);
```

---

## 6. One-Shot Rule

Once generated, a feature folder is permanent human territory. The generator enforces this:

```
Feature folder exists?  → HALT with clear error message
Feature folder absent?  → Generate and hand over
```

The only exception is `--Force` which exists only for generator development. It is never used in production workflows.

The only files the generator ever modifies after initial creation are:
- `lib/config/di/injection_container.dart` — append-only, new DI registrations
- `lib/app/routes/app_router.dart` — append-only, new route blocks

---

## 7. Injection Container Boundary Markers

To support append-only updates, both files need boundary markers:

**`injection_container.dart`:**
```dart
Future<void> init() async {
  // ... existing human-written registrations ...

  // ── GENERATOR MANAGED — append only ─────────────────────────
  // ── END GENERATOR MANAGED ────────────────────────────────────
}
```

**`app_router.dart`:**
```dart
final router = GoRouter(
  routes: [
    // ... existing human-written routes ...

    // ── GENERATOR ROUTES — append only ──────────────────────
    // ── END GENERATOR ROUTES ────────────────────────────────
  ],
);
```

The generator inserts new content immediately before the `END` marker. Human routes and DI registrations remain untouched above the managed section.

---

## 8. Usage

```powershell
# Basic usage — generate from config
.\tools\generator\generate.ps1 -ConfigPath .\lib\features\project\feature.config.json

# Dry run — see what would be generated without writing files
.\tools\generator\generate.ps1 -ConfigPath .\lib\features\project\feature.config.json -DryRun

# Specify project root (if running from a different directory)
.\tools\generator\generate.ps1 `
    -ConfigPath .\lib\features\project\feature.config.json `
    -ProjectRoot C:\workspace\hala_fca
```

**Expected output:**
```
  ═══════════════════════════════════════════
  HALA FCA · Feature Generator
  ═══════════════════════════════════════════

  ▸ Loading config: ...\feature.config.json

  ═══════════════════════════════════════════
  Phase A · Analysis
  ═══════════════════════════════════════════

  ▸ Validating schema...
  ✓ Schema valid
  ▸ Feature: Project (maturity 2)
  ▸ Building dependency graph...
  ▸ Cross-feature dependencies: auth
  ✓ Dependency graph clean

  ═══════════════════════════════════════════
  Phase B · Generation (Maturity 2)
  ═══════════════════════════════════════════

  ▸ Generating presentation layer...
  ✓ project_list_page.dart
  ✓ project_detail_page.dart
  ✓ project_form_page.dart
  ✓ project_card.dart
  ▸ Generating domain layer...
  ✓ project_entity.dart
  ✓ project_member_entity.dart
  ✓ project_milestone_entity.dart
  ✓ project_repository.dart
  ✓ create_project_usecase.dart
  ✓ get_all_projects_usecase.dart
  ... (all use cases)
  ▸ Generating data layer...
  ✓ project_model.dart
  ✓ project_remote_datasource.dart
  ✓ project_local_datasource.dart
  ✓ project_repository_impl.dart
  ▸ Generating BLoC...
  ✓ project_bloc.dart
  ✓ project_event.dart
  ✓ project_state.dart
  ✓ project_form_cubit.dart
  ▸ Generating state machine...
  ✓ project_status.dart
  ✓ project_transition_guard.dart
  ✓ project_domain_service.dart
  ✓ project_status_badge.dart
  ▸ Generating cross-feature provider interfaces + adapters...
  ✓ user_provider.dart
  ✓ auth_user_provider_adapter.dart
  ▸ Wiring DI registrations...
  ▸ Wiring routes...

  ═══════════════════════════════════════════
  Generation Complete
  ═══════════════════════════════════════════

  ✓ 34 files generated in: lib/features/project
  ✓ DI registrations appended to: config/di/injection_container.dart
  ✓ Routes appended to: app/routes/app_router.dart

  This feature is now human territory.
  Implement domain-specific logic in:
    lib/features/project/domain/guards/project_transition_guard.dart
    lib/features/project/domain/usecases/ (validation gates)
    lib/features/project/presentation/ (UI customization)
```

---

## 9. Dependency Graph Algorithm

The generator uses **DFS cycle detection** + **Kahn's topological sort**.

**Cycle detection** (DFS with in-stack tracking):
```
For each unvisited node:
  Mark as visited + in-stack
  For each neighbor:
    If in-stack → cycle found
    If not visited → recurse
  Remove from in-stack
```

**Topological sort** (Kahn's BFS):
```
Compute in-degree for all nodes
Queue all nodes with in-degree 0
While queue not empty:
  Dequeue node → add to sorted list
  For each dependent: decrement in-degree
  If in-degree reaches 0 → enqueue
```

Generation follows the topological order. Leaf features (no external dependencies) are generated first. Features that depend on them are generated after.

---

## 10. What Each Module Owns

| Module | Generates |
|---|---|
| `Validator.psm1` | Nothing. Validates only. Returns error list. |
| `DependencyGraph.psm1` | Nothing. Builds graph only. Returns graph object. |
| `TemplateEngine.psm1` | Nothing. Provides helpers for code generation. |
| `EntityGenerator.psm1` | `domain/entities/`, `domain/repositories/`, `domain/usecases/`, `data/models/`, `data/datasources/`, `data/repositories/` |
| `BlocGenerator.psm1` | `presentation/bloc/` |
| `PageGenerator.psm1` | `presentation/pages/`, `presentation/widgets/` |
| `StateMachineGenerator.psm1` | `domain/value_objects/`, `domain/guards/`, `domain/services/`, `presentation/widgets/*_status_badge.dart` |
| `WorkflowGenerator.psm1` | `domain/events/`, `domain/workflows/` |
| `DiRouterGenerator.psm1` | `domain/providers/`, `data/providers/`, appends to `injection_container.dart`, appends to `app_router.dart` |

---

## 11. Developer Handoff — What to Implement After Generation

After the generator runs, the developer's job is clear and bounded.

**Always implement (Level 1+):**
- Replace placeholder entity fields with real domain fields
- Fix API endpoint paths in the remote datasource
- Map controller values to `Create{Feature}Params` in the form page's `_submit()` method
- Update `fromJson` / `toJson` field names if the API uses different naming conventions

**Level 2+ implement:**
- Implement domain invariants in `domain/guards/{feature}_transition_guard.dart`

**Level 3+ implement:**
- Implement workflow step methods in `domain/workflows/{feature}_workflow.dart`

**Level 5 implement:**
- Connect the real external service SDK in `data/integrations/{feature}_integration_client.dart`

**Never rewrite:**
- Architecture layers (Clean Architecture structure)
- Error handling (Either + Failure hierarchy)
- BLoC wiring (event → usecase → state)
- State machine transitions (structure and canTransitionTo logic)
- DI registrations (auto-wired)
- Routes (auto-wired)

The generator builds the foundation. The developer builds the domain intelligence.

---

*Phase 3 complete. Phase 4 targets auto-wiring verification + integration testing of the generator.*
