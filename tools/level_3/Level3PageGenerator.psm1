# ============================================================
# Level3PageGenerator.psm1 — Pages + Widgets + Status Badge
# FIX: FormMode imported from core (no duplicate enum)
# FIX: Get-FormFieldCode properly called for each field
# ============================================================

function Invoke-GeneratePages {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    $meta = Get-PrimaryEntityMeta -Config $Ctx.Config

    # Generate shared FormMode enum in core (idempotent marker-based)
    _Gen-FormModeEnum -Ctx $Ctx -NewFile $NewFile

    _Gen-ListPage      -Ctx $Ctx -NewFile $NewFile -Meta $meta
    _Gen-DetailPage    -Ctx $Ctx -NewFile $NewFile -Meta $meta
    _Gen-FormPage      -Ctx $Ctx -NewFile $NewFile -Meta $meta
    _Gen-CardWidget    -Ctx $Ctx -NewFile $NewFile -Meta $meta
    _Gen-StatusBadge   -Ctx $Ctx -NewFile $NewFile
}

function _Gen-FormModeEnum {
    param($Ctx, $NewFile)
    $pRoot = $Ctx.ProjectRoot
    $path  = Join-Path $pRoot "lib\core\enums\form_mode.dart"

    # Only generate if it doesn't exist yet
    if (Test-Path $path) { return }

    $content = @"
/// Shared enum used by all feature form pages.
/// Generated once — safe across multiple features.
enum FormMode { create, edit }
"@
    & $NewFile $path $content
}

function _Gen-ListPage {
    param($Ctx, $NewFile, $Meta)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $fDir   = $Ctx.FeatureDir

    $emptyMsg = 'No items found.'
    if ($Meta.Ui -and $Meta.Ui.list -and $Meta.Ui.list.emptyMessage) {
        $emptyMsg = $Meta.Ui.list.emptyMessage
    }

    $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${fname}_bloc.dart';
import '../bloc/${fname}_event.dart';
import '../bloc/${fname}_state.dart';
import '../widgets/${fname}_card.dart';

class ${fclass}ListPage extends StatefulWidget {
  const ${fclass}ListPage({super.key});

  @override
  State<${fclass}ListPage> createState() => _${fclass}ListPageState();
}

class _${fclass}ListPageState extends State<${fclass}ListPage> {
  @override
  void initState() {
    super.initState();
    context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('${flabel}s')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .pushNamed('/${fname}s/create')
            .then((_) => context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested())),
        child: const Icon(Icons.add),
      ),
      body: BlocConsumer<${fclass}Bloc, ${fclass}State>(
        listener: (context, state) {
          if (state is ${fclass}OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested());
          }
          if (state is ${fclass}Failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: scheme.error),
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
                  Text('$emptyMsg', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          if (state is ${fclass}Failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ${fclass}ListLoaded) {
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (_, i) => ${fclass}Card(
                  item: state.items[i],
                  onTap: () => Navigator.of(context)
                      .pushNamed('/${fname}s/detail', arguments: {'id': state.items[i].id})
                      .then((_) => context.read<${fclass}Bloc>().add(${fclass}LoadAllRequested())),
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
    & $NewFile (Join-Path $fDir "presentation\pages\${fname}_list_page.dart") $content
}

function _Gen-DetailPage {
    param($Ctx, $NewFile, $Meta)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $fDir   = $Ctx.FeatureDir
    $sm     = $Ctx.Config.stateMachine

    # Detail fields
    $allDetailFields = @()
    if ($Meta.Ui -and $Meta.Ui.detail) {
        $h = @(); $b = @()
        if ($Meta.Ui.detail.header) { $h = @($Meta.Ui.detail.header) }
        if ($Meta.Ui.detail.body)   { $b = @($Meta.Ui.detail.body) }
        $allDetailFields = $h + $b
    }
    if ($allDetailFields.Count -eq 0) {
        $allDetailFields = @($Meta.Fields | ForEach-Object { $_.Name })
    }

    $detailRows = [System.Collections.Generic.List[string]]::new()
    foreach ($fn in $allDetailFields) {
        $f = $Meta.Fields | Where-Object { $_.Name -eq $fn } | Select-Object -First 1
        if (-not $f) { continue }
        $accessor = switch ($f.Type) {
            'DateTime' { "item.$fn?.toIso8601String().split('T').first ?? ''" }
            'bool'     { "item.$fn.toString()" }
            'int'      { "item.$fn.toString()" }
            'double'   { "item.$fn.toStringAsFixed(2)" }
            default    { "item.$fn" }
        }
        if ($f.IsNullable -and $f.Type -ne 'DateTime') { $accessor = "item.$fn?.toString() ?? ''" }
        $detailRows.Add("                    _buildField(context, '$($f.Label)', $accessor),")
    }

    # Transition buttons
    $transitions = @($sm.transitions)
    $transButtons = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $transitions) {
        $tClass   = ConvertTo-PascalCase $t.name
        $tLabel   = if ($t.label) { $t.label } else { ConvertTo-HumanLabel $t.name }
        $fromList = ($t.from | ForEach-Object { "${fclass}Status.$_" }) -join ', '

        $transButtons.Add(@"
                    if ([$fromList].contains(item.status))
                      FilledButton.tonal(
                        onPressed: () => context.read<${fclass}Bloc>()
                            .add(${fclass}${tClass}Requested(item.id)),
                        child: const Text('$tLabel'),
                      ),
"@)
    }

    $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${fname}_bloc.dart';
import '../bloc/${fname}_event.dart';
import '../bloc/${fname}_state.dart';
import '../../domain/value_objects/${fname}_status.dart';
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
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              final state = context.read<${fclass}Bloc>().state;
              if (state is ${fclass}DetailLoaded) {
                Navigator.of(context).pushNamed(
                  '/${fname}s/edit',
                  arguments: {'id': state.item.id},
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<${fclass}Bloc, ${fclass}State>(
        listener: (context, state) {
          if (state is ${fclass}OperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.updatedItem != null) {
              context.read<${fclass}Bloc>()
                  .add(${fclass}LoadOneRequested(state.updatedItem!.id));
            }
          }
          if (state is ${fclass}Failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
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
                  // Header with status badge
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.id,
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ${fclass}StatusBadge(status: item.status),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Transition actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Actions', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
$($transButtons -join "`n")
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail fields
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
$($detailRows -join "`n")
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
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\pages\${fname}_detail_page.dart") $content
}

function _Gen-FormPage {
    param($Ctx, $NewFile, $Meta)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $fDir   = $Ctx.FeatureDir

    # Determine form fields
    $createFields = @()
    if ($Meta.Ui -and $Meta.Ui.form -and $Meta.Ui.form.create) {
        $createFields = @($Meta.Ui.form.create)
    } else {
        $createFields = @($Meta.Fields | Where-Object { -not $_.IsReadonly -and -not $_.IsPrimary } | ForEach-Object { $_.Name })
    }

    $controllerDecls = [System.Collections.Generic.List[string]]::new()
    $disposeStmts    = [System.Collections.Generic.List[string]]::new()
    $formFieldCodes  = [System.Collections.Generic.List[string]]::new()
    $paramArgs       = [System.Collections.Generic.List[string]]::new()

    foreach ($fn in $createFields) {
        $f = $Meta.Fields | Where-Object { $_.Name -eq $fn } | Select-Object -First 1
        if (-not $f) { continue }
        $widget = Get-FormWidgetType -ConfigType $f.Type

        if ($widget -eq 'SwitchListTile') {
            $controllerDecls.Add("  bool _${fn}Value = false;")
            $paramArgs.Add("        '$fn': _${fn}Value,")
        } else {
            $controllerDecls.Add("  final _${fn}Controller = TextEditingController();")
            $disposeStmts.Add("    _${fn}Controller.dispose();")
            if ($f.Type -eq 'int') {
                $paramArgs.Add("        '$fn': int.tryParse(_${fn}Controller.text) ?? 0,")
            } elseif ($f.Type -eq 'double') {
                $paramArgs.Add("        '$fn': double.tryParse(_${fn}Controller.text) ?? 0.0,")
            } elseif ($f.Type -eq 'DateTime') {
                $paramArgs.Add("        '$fn': DateTime.tryParse(_${fn}Controller.text) ?? DateTime.now(),")
            } else {
                $paramArgs.Add("        '$fn': _${fn}Controller.text,")
            }
        }

        $formFieldCodes.Add((Get-FormFieldCode -FieldName $fn -FieldMeta $f))
    }

    # FIX: Import FormMode from core — no local enum definition
    $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/enums/form_mode.dart';
import '../bloc/${fname}_bloc.dart';
import '../bloc/${fname}_event.dart';
import '../bloc/${fname}_state.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';

class ${fclass}FormPage extends StatefulWidget {
  final FormMode mode;
  final String? id;

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

$($controllerDecls -join "`n")

  bool _isSubmitting = false;

  @override
  void dispose() {
$($disposeStmts -join "`n")
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
                content: Text(state.message),
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
$($formFieldCodes -join "`n")
                const SizedBox(height: 24),
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

    context.read<${fclass}Bloc>().add(
      ${fclass}CreateRequested(
        Create${fclass}Params(
$($paramArgs -join "`n")
        ),
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\pages\${fname}_form_page.dart") $content
}

function _Gen-CardWidget {
    param($Ctx, $NewFile, $Meta)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir
    $eName  = $Meta.Name
    $eSnake = $Meta.Snake

    $titleField    = 'id'
    $subtitleField = $null
    if ($Meta.Ui -and $Meta.Ui.card) {
        if ($Meta.Ui.card.title)    { $titleField    = $Meta.Ui.card.title }
        if ($Meta.Ui.card.subtitle) { $subtitleField = $Meta.Ui.card.subtitle }
    }

    $subtitleLine = ''
    if ($subtitleField) {
        $subtitleLine = "        subtitle: Text(item.$subtitleField?.toString() ?? ''),"
    }

    $content = @"
import 'package:flutter/material.dart';
import '../../domain/entities/${eSnake}_entity.dart';
import '../../domain/value_objects/${fname}_status.dart';
import '${fname}_status_badge.dart';

class ${fclass}Card extends StatelessWidget {
  final ${eName}Entity item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
        title: Text(
          item.$titleField,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
$subtitleLine        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ${fclass}StatusBadge(status: item.status, compact: true),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: scheme.error),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Remove "\${item.$titleField}"? This cannot be undone.'),
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
    & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_card.dart") $content
}

function _Gen-StatusBadge {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $content = @"
import 'package:flutter/material.dart';
import '../../domain/value_objects/${fname}_status.dart';

class ${fclass}StatusBadge extends StatelessWidget {
  final ${fclass}Status status;
  final bool compact;

  const ${fclass}StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_status_badge.dart") $content
}

Export-ModuleMember -Function 'Invoke-GeneratePages'
