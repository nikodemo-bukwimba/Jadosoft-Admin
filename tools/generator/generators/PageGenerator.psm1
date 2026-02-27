# ============================================================
# PageGenerator.psm1
# Generates: presentation/pages/ + presentation/widgets/
# ============================================================

function Invoke-GeneratePresentation {
  param([hashtable]$Ctx, [scriptblock]$NewFile)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $flabel = $tokens.FLABEL
  $maturity = $Ctx.Maturity

  if ($maturity -eq 0) {
    _Generate-Level0Pages -Ctx $Ctx -NewFile $NewFile
    return
  }

  $primaryEntityName = $config.entities.PSObject.Properties |
  Where-Object { $_.Value.primary -eq $true } |
  Select-Object -First 1 -ExpandProperty Name
  $primaryEntity = $config.entities.$primaryEntityName
  $primarySnake = ConvertTo-SnakeCase $primaryEntityName

  _Generate-ListPage   -Ctx $Ctx -NewFile $NewFile -PrimaryEntityName $primaryEntityName -PrimarySnake $primarySnake
  _Generate-DetailPage -Ctx $Ctx -NewFile $NewFile -PrimaryEntityName $primaryEntityName -PrimarySnake $primarySnake
  _Generate-FormPage   -Ctx $Ctx -NewFile $NewFile -PrimaryEntityName $primaryEntityName -PrimarySnake $primarySnake
  _Generate-CardWidget -Ctx $Ctx -NewFile $NewFile -PrimaryEntityName $primaryEntityName -PrimarySnake $primarySnake
}

function _Generate-Level0Pages {
  param([hashtable]$Ctx, [scriptblock]$NewFile)
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $flabel = $tokens.FLABEL

  $pageContent = @"
// ${fname}_page.dart — Level 0 Static Feature
// Replace page title, body content, and widget composition.
// No BLoC, no repository, no network call required.

import 'package:flutter/material.dart';
import '../widgets/${fname}_widget.dart';

class ${fclass}Page extends StatelessWidget {
  const ${fclass}Page({super.key});

  static const routePath = '/$fname';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$flabel')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 640),
              child: ${fclass}Widget(),
            ),
          ),
        ),
      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\pages\${fname}_page.dart") $pageContent

  $widgetContent = @"
// ${fname}_widget.dart — Level 0 Static Widget
// Replace displayed data and layout. No state, no async calls.

import 'package:flutter/material.dart';

class ${fclass}Widget extends StatelessWidget {
  const ${fclass}Widget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$flabel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // TODO: Replace with domain-specific static content
            Text(
              'Replace this with your static content.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_widget.dart") $widgetContent
}

function _Generate-ListPage {
  param([hashtable]$Ctx, [scriptblock]$NewFile, [string]$PrimaryEntityName, [string]$PrimarySnake)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $flabel = $tokens.FLABEL

  $primaryEntity = $config.entities.$PrimaryEntityName
  $emptyMsg = if ($primaryEntity.ui -and $primaryEntity.ui.list -and $primaryEntity.ui.list.emptyMessage) {
    $primaryEntity.ui.list.emptyMessage
  }
  else {
    "No ${flabel.ToLower()}s found."
  }

  $listContent = @"
// ${fname}_list_page.dart
// Working list with loading / empty / error / data states.
// Includes search bar, filter chips, and pull-to-refresh.
// TODO: Customize the card widget and filter UI for your domain.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${fname}_bloc.dart';
import '../widgets/${fname}_card.dart';

class ${fclass}ListPage extends StatefulWidget {
  const ${fclass}ListPage({super.key});

  static const routePath = '/${fname}s';

  @override
  State<${fclass}ListPage> createState() => _${fclass}ListPageState();
}

class _${fclass}ListPageState extends State<${fclass}ListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:   const Text('${flabel}s'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              controller:  _searchController,
              hintText:    'Search ${flabel.ToLower()}s...',
              leading:     const Icon(Icons.search),
              onChanged:   (q) => context.read<${fclass}Bloc>()
                                        .add(${fclass}SearchChanged(q)),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .pushNamed('/${fname}s/create')
            .then((_) => context.read<${fclass}Bloc>()
                               .add(${fclass}LoadAllRequested())),
        icon:  const Icon(Icons.add),
        label: const Text('Add ${flabel}'),
      ),
      body: BlocConsumer<${fclass}Bloc, ${fclass}State>(
        listener: (context, state) {
          if (state is ${fclass}OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: scheme.primary,
              ),
            );
            context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested());
          }
          if (state is ${fclass}Failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: scheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ${fclass}Loading || state is ${fclass}Initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ${fclass}Empty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    '$emptyMsg',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is ${fclass}Failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 16),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.read<${fclass}Bloc>()
                          .add(${fclass}LoadAllRequested()),
                      icon:  const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is ${fclass}ListLoaded) {
            return RefreshIndicator(
              onRefresh: () async => context.read<${fclass}Bloc>()
                  .add(${fclass}LoadAllRequested()),
              child: ListView.builder(
                padding:     const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount:   state.items.length,
                itemBuilder: (_, i) => ${fclass}Card(
                  item:    state.items[i],
                  onTap:   () => Navigator.of(context)
                      .pushNamed('/${fname}s/`${state.items[i].id}')
                      .then((_) => context.read<${fclass}Bloc>()
                                         .add(${fclass}LoadAllRequested())),
                  onDelete: () => context.read<${fclass}Bloc>()
                      .add(${fclass}DeleteRequested(state.items[i].id)),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\pages\${fname}_list_page.dart") $listContent
}

function _Generate-DetailPage {
  param([hashtable]$Ctx, [scriptblock]$NewFile, [string]$PrimaryEntityName, [string]$PrimarySnake)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $flabel = $tokens.FLABEL
  $maturity = $Ctx.Maturity

  # Build transition action buttons
  $transitionButtons = ''
  if ($config.stateMachine -and $maturity -ge 2) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $config.stateMachine.transitions) {
      $tPascal = $t.name.Substring(0, 1).ToUpper() + $t.name.Substring(1)
      $perm = if ($t.permission) { $t.permission } else { '' }
      $fromList = ($t.from | ForEach-Object { "${fclass}Status.$_" }) -join ', '

      $lines.Add("            // Transition: $($t.name)")
      if ($perm) {
        $lines.Add("            PermissionGuard(")
        $lines.Add("              permission: '$perm',")
        $lines.Add("              child: _buildTransitionButton(")
      }
      else {
        $lines.Add("            _buildTransitionButton(")
      }
      $lines.Add("              context: context,")
      $lines.Add("              label:   '$($t.label)',")
      $lines.Add("              visible: [${fromList}].contains(item.status),")
      $lines.Add("              onTap:   () => context.read<${fclass}Bloc>()")
      $lines.Add("                  .add(${fclass}${tPascal}Requested(item.id)),")
      if ($perm) {
        $lines.Add("            ),")
        $lines.Add("            ),")
      }
      else {
        $lines.Add("            ),")
      }
    }
    $transitionButtons = $lines -join "`n"
  }

  $statusBadge = if ($maturity -ge 2) {
    "              ${fclass}StatusBadge(status: item.status),"
  }
  else { '' }

  $permImport = if ($maturity -ge 2) {
    "import '../../../../core/rbac/permission_guard.dart';"
  }
  else { '' }

  $detailContent = @"
// ${fname}_detail_page.dart
// Detail view with header, body fields, relationship sections.
// Transition buttons are permission-gated automatically.
// TODO: Customize sections and layout for your domain.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
$permImport
import '../bloc/${fname}_bloc.dart';
import '../widgets/${fname}_status_badge.dart';

class ${fclass}DetailPage extends StatelessWidget {
  const ${fclass}DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$flabel Detail'),
        actions: [
          IconButton(
            icon:     const Icon(Icons.edit_outlined),
            tooltip:  'Edit',
            onPressed: () => Navigator.of(context)
                .pushNamed('/${fname}s/edit'),
          ),
        ],
      ),
      body: BlocConsumer<${fclass}Bloc, ${fclass}State>(
        listener: (context, state) {
          if (state is ${fclass}OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            // Refresh detail after transition
            if (state.updatedItem != null) {
              context.read<${fclass}Bloc>()
                  .add(${fclass}LoadOneRequested(state.updatedItem!.id));
            }
          }
          if (state is ${fclass}Failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ${fclass}Loading || state is ${fclass}Initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ${fclass}Failure) {
            return Center(child: Text(state.message));
          }
          if (state is ${fclass}DetailLoaded) {
            final item = state.item;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TODO: Replace with your primary display field
                                Text(
                                  item.id,
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
$statusBadge                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Transition actions ───────────────────────────
$(if ($transitionButtons) { @"
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
$transitionButtons                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
"@ })
                  // ── Body fields ──────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TODO: Replace with domain-specific field rows
                          _buildField(context, 'ID', item.id),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionButton({
    required BuildContext context,
    required String       label,
    required bool         visible,
    required VoidCallback onTap,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.tonal(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\pages\${fname}_detail_page.dart") $detailContent
}

function _Generate-FormPage {
  param([hashtable]$Ctx, [scriptblock]$NewFile, [string]$PrimaryEntityName, [string]$PrimarySnake)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $flabel = $tokens.FLABEL

  $primaryEntity = $config.entities.$PrimaryEntityName
  $createFields = @(if ($primaryEntity.ui -and $primaryEntity.ui.form -and $primaryEntity.ui.form.create) { $primaryEntity.ui.form.create } else { @() })
  $formFields = Get-FormFields -Fields $primaryEntity.fields -FieldList $createFields

  $formContent = @"
// ${fname}_form_page.dart
// Working form with validation, loading state, and error handling.
// TODO: Customize field layout and submit logic for your domain.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${fname}_bloc.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';

enum FormMode { create, edit }

class ${fclass}FormPage extends StatefulWidget {
  final FormMode mode;
  final String?  id;

  const ${fclass}FormPage({
    super.key,
    this.mode = FormMode.create,
    this.id,
  });

  @override
  State<${fclass}FormPage> createState() => _${fclass}FormPageState();
}

class _${fclass}FormPageState extends State<${fclass}FormPage> {
  final _formKey = GlobalKey<FormState>();

  // ── Field controllers ──────────────────────────────────────
  // TODO: Add/remove controllers to match fields in ui.form.create
$(($createFields | ForEach-Object {
    "  final _${_}Controller = TextEditingController();"
}) -join "`n")

  bool _isSubmitting = false;

  @override
  void dispose() {
$(($createFields | ForEach-Object {
    "    _${_}Controller.dispose();"
}) -join "`n")
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == FormMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCreate ? 'New $flabel' : 'Edit $flabel'),
      ),
      body: BlocListener<${fclass}Bloc, ${fclass}State>(
        listener: (context, state) {
          if (state is ${fclass}OperationSuccess) {
            setState(() => _isSubmitting = false);
            Navigator.of(context).pop(true);
          }
          if (state is ${fclass}Failure) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:         Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Form fields ──────────────────────────────
$formFields
                const SizedBox(height: 24),

                // ── Submit button ────────────────────────────
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isCreate ? 'Create $flabel' : 'Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    // TODO: Map controller values to Create${fclass}Params fields
    context.read<${fclass}Bloc>().add(
      ${fclass}CreateRequested(
        const Create${fclass}Params(
          // TODO: pass controller values here
        ),
      ),
    );
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\pages\${fname}_form_page.dart") $formContent
}

function _Generate-CardWidget {
  param([hashtable]$Ctx, [scriptblock]$NewFile, [string]$PrimaryEntityName, [string]$PrimarySnake)

  $config = $Ctx.Config
  $tokens = $Ctx.Tokens
  $fDir = $Ctx.FeatureDir
  $fname = $tokens.FNAME
  $fclass = $tokens.FCLASS
  $flabel = $tokens.FLABEL

  $primaryEntity = $config.entities.$PrimaryEntityName
  $cardConfig = if ($primaryEntity.ui) { $primaryEntity.ui.card } else { $null }
  $titleField = if ($cardConfig -and $cardConfig.title) { $cardConfig.title } else { 'id' }
  $subtitleField = if ($cardConfig -and $cardConfig.subtitle) { $cardConfig.subtitle } else { $null }

  $subtitleLine = if ($subtitleField) {
    "        subtitle: Text(item.$subtitleField?.toString() ?? ''),"
  }
  else { '' }

  $cardContent = @"
// ${fname}_card.dart
// Single item display card used in the list page.
// TODO: Customize the displayed fields to match your domain.

import 'package:flutter/material.dart';
import '../../domain/entities/${PrimarySnake}_entity.dart';

class ${fclass}Card extends StatelessWidget {
  final ${PrimaryEntityName}Entity item;
  final VoidCallback                onTap;
  final VoidCallback                onDelete;

  const ${fclass}Card({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        // TODO: Replace item.$titleField with your primary display field
        title: Text(
          item.$titleField,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
$subtitleLine        trailing: IconButton(
          icon:     Icon(Icons.delete_outline, color: scheme.error),
          tooltip:  'Delete',
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Confirm Delete'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}
"@
  & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_card.dart") $cardContent
}

Export-ModuleMember -Function Invoke-GeneratePresentation
