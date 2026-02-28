# Level 0 — Static Feature Generator

## What It Generates

Given a config like:
```json
{
  "feature": {
    "name": "about",
    "label": "About",
    "purpose": "Static about page",
    "maturity": 0,
    "permission": "about",
    "icon": "Icons.info_outlined",
    "activeIcon": "Icons.info"
  }
}
```

The generator produces **exactly 2 files**:

```
features/about/
└── presentation/
    ├── pages/
    │   └── about_page.dart       ← StatelessWidget, no BLoC
    └── widgets/
        └── about_widget.dart     ← StatelessWidget, no state
```

Plus wiring in:
- `app/routes/app_router.dart` — MaterialPageRoute, NO BlocProvider
- `app/shell/shell_nav_items.dart` — Tab entry, NO BlocProvider

## What It Does NOT Generate

- No `domain/` directory (no entities, no use cases, no repos)
- No `data/` directory (no datasources, no models)
- No `presentation/bloc/` (no BLoC, no events, no states)
- No DI registrations (nothing to register)

## Installation

Copy these files into your `tools/generator/` directory:

```
tools/generator/
├── Generate-Level0.ps1              ← Entry point
├── modules/
│   ├── TemplateEngine.psm1          ← Shared helpers
│   └── Validator.psm1               ← Schema validation
├── generators/
│   ├── Level0Generator.psm1         ← Page + widget generation
│   └── Level0WiringGenerator.psm1   ← Route + nav wiring
└── tests/
    ├── Test-Level0.ps1              ← Automated test suite
    ├── level0_about.config.json     ← Test config (simple)
    ├── level0_terms.config.json     ← Test config (multi-word name)
    ├── mock_project/                ← Mock project structure for tests
    │   └── lib/app/
    │       ├── routes/app_router.dart
    │       └── shell/shell_nav_items.dart
    └── expected/                    ← Expected Dart output for diff
        ├── about/
        └── terms_of_service/
```

## Usage

```powershell
# Generate a Level 0 feature
.\tools\generator\Generate-Level0.ps1 `
    -ConfigPath .\lib\features\about\feature.config.json

# Dry run (see what would be generated)
.\tools\generator\Generate-Level0.ps1 `
    -ConfigPath .\lib\features\about\feature.config.json `
    -DryRun

# Force overwrite (development only)
.\tools\generator\Generate-Level0.ps1 `
    -ConfigPath .\lib\features\about\feature.config.json `
    -Force
```

## Running Tests

```powershell
cd tools\generator
.\tests\Test-Level0.ps1
```

The test suite verifies:
- ✅ Exactly 2 files generated (no extras)
- ✅ No `domain/` or `data/` directories created
- ✅ Generated Dart matches expected output character-for-character
- ✅ Page is `StatelessWidget` (not Stateful)
- ✅ No `flutter_bloc` imports anywhere
- ✅ No `BlocProvider` references anywhere
- ✅ Route uses `MaterialPageRoute` (not `GoRoute`)
- ✅ Route has NO `BlocProvider` wrapping
- ✅ Shell tab has NO `BlocProvider` wrapping
- ✅ Validator rejects invalid configs (missing name, bad casing, storage at Level 0, etc.)

## Boundary Markers Required

Your project's `app_router.dart` and `shell_nav_items.dart` must contain these markers:

**`app_router.dart`:**
```dart
  // ── END GENERATOR FEATURE PAGE IMPORTS
  // ── END GENERATOR ROUTE CONSTANTS
  // ── GENERATOR ROUTES — append only
```

**`shell_nav_items.dart`:**
```dart
// ── END GENERATOR FEATURE IMPORTS
      // ── END GENERATOR TABS
```

The generator inserts content **above** each marker. Human-written code stays untouched.

## Config Validation Rules (Level 0)

| Rule | Enforced |
|------|----------|
| `feature.name` is snake_case | ✅ |
| `feature.label` is present | ✅ |
| `feature.purpose` is present | ✅ |
| `feature.maturity` is 0 | ✅ |
| `feature.permission` is snake_case | ✅ |
| No `storage` block allowed | ✅ |
| No `stateMachine` block allowed | ✅ |

## Generated Dart Quality

Every generated file:
- Compiles on day one (zero analyzer errors)
- Uses `const` constructors where possible
- Follows Flutter style guide (trailing commas, consistent indentation)
- Includes clear TODO comments for developer customization
- Imports only what it uses (no unused imports)
- Has zero dependency on `flutter_bloc`, repositories, or network

## What the Developer Does After Generation

1. Open `about_page.dart`
2. Replace the `AboutWidget()` with domain-specific content
3. Open `about_widget.dart`
4. Replace the placeholder Card with actual UI
5. Done — no architecture to learn, no wiring to do
