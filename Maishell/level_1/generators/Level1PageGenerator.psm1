# ============================================================
# Level1PageGenerator.psm1 -- Pages + Widgets
# PS7 SAFETY: All Dart method calls (.toIso8601String, .toStringAsFixed,
# ?.toString) are built via string concat to prevent PS7 null-conditional
# parsing: "item." + $fn + ".method()" instead of "item.$fn.method()"
# ============================================================

function Invoke-GeneratePages {
  param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $flabel = $Ctx.Tokens.FLABEL
  $fDir = $Ctx.FeatureDir
  $meta = Get-PrimaryEntityMeta -Config $Ctx.Config
  $eName = $meta.Name
  $eSnake = $meta.Snake

  _Gen-ListPage   -Ctx $Ctx -NewFile $NewFile -Meta $meta
  _Gen-DetailPage -Ctx $Ctx -NewFile $NewFile -Meta $meta
  _Gen-FormPage   -Ctx $Ctx -NewFile $NewFile -Meta $meta
  _Gen-CardWidget -Ctx $Ctx -NewFile $NewFile -Meta $meta
}

function _Gen-ListPage {
  param($Ctx, $NewFile, $Meta)
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $flabel = $Ctx.Tokens.FLABEL
  $fDir = $Ctx.FeatureDir
  $lowerLabel = $flabel.ToLower()

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
              SnackBar(
                content: Text(state.message),
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
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $flabel = $Ctx.Tokens.FLABEL
  $fDir = $Ctx.FeatureDir
  $eName = $Meta.Name
  $eSnake = $Meta.Snake

  # Build field display rows from detail.header + detail.body
  $detailFields = [System.Collections.Generic.List[string]]::new()
  $headerFields = @()
  $bodyFields = @()
  if ($Meta.Ui -and $Meta.Ui.detail) {
    if ($Meta.Ui.detail.header) { $headerFields = @($Meta.Ui.detail.header) }
    if ($Meta.Ui.detail.body) { $bodyFields = @($Meta.Ui.detail.body) }
  }
  $allDetailFields = $headerFields + $bodyFields
  if ($allDetailFields.Count -eq 0) {
    $allDetailFields = @($Meta.Fields | ForEach-Object { $_.Name })
  }

  foreach ($fn in $allDetailFields) {
    $f = $Meta.Fields | Where-Object { $_.Name -eq $fn } | Select-Object -First 1
    if (-not $f) { continue }
    $label = $f.Label

    # FIX: use string concat to protect Dart methods from PS7 null-conditional parsing
    # PS7 eats "$fn?.method()" and "$fn.nonDotNetMethod()" inside double-quoted strings
    if ($f.IsNullable) {
      $accessor = switch ($f.Type) {
        'DateTime' { "item." + $fn + "?.toIso8601String().split('T').first ?? ''" }
        default { "item." + $fn + "?.toString() ?? ''" }
      }
    }
    else {
      $accessor = switch ($f.Type) {
        'DateTime' { "item." + $fn + ".toIso8601String().split('T').first" }
        'bool' { "item." + $fn + ".toString()" }
        'int' { "item." + $fn + ".toString()" }
        'double' { "item." + $fn + ".toStringAsFixed(2)" }
        default { "item." + $fn }
      }
    }
    $detailFields.Add("                    _buildField(context, '$label', $accessor),")
  }

  $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${fname}_bloc.dart';
import '../bloc/${fname}_event.dart';
import '../bloc/${fname}_state.dart';

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
      body: BlocBuilder<${fclass}Bloc, ${fclass}State>(
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
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
$($detailFields -join "`n")
                    ],
                  ),
                ),
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
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $flabel = $Ctx.Tokens.FLABEL
  $fDir = $Ctx.FeatureDir

  # Determine form fields from config
  $createFields = @()
  if ($Meta.Ui -and $Meta.Ui.form -and $Meta.Ui.form.create) {
    $createFields = @($Meta.Ui.form.create)
  }
  else {
    $createFields = @($Meta.Fields | Where-Object { -not $_.IsReadonly -and -not $_.IsPrimary } | ForEach-Object { $_.Name })
  }

  # Controller declarations
  $controllerDecls = [System.Collections.Generic.List[string]]::new()
  $disposeStmts = [System.Collections.Generic.List[string]]::new()
  $formFieldCodes = [System.Collections.Generic.List[string]]::new()
  $paramArgs = [System.Collections.Generic.List[string]]::new()

  foreach ($fn in $createFields) {
    $f = $Meta.Fields | Where-Object { $_.Name -eq $fn } | Select-Object -First 1
    if (-not $f) { continue }
    $widget = Get-FormWidgetType -ConfigType $f.Type

    if ($widget -eq 'SwitchListTile') {
      $controllerDecls.Add("  bool _${fn}Value = false;")
      $paramArgs.Add("        ${fn}: _${fn}Value,")
    }
    else {
      $controllerDecls.Add("  final _${fn}Controller = TextEditingController();")
      $disposeStmts.Add("    _${fn}Controller.dispose();")
      if ($f.Type -eq 'int') {
        $paramArgs.Add("        ${fn}: int.tryParse(_${fn}Controller.text) ?? 0,")
      }
      elseif ($f.Type -eq 'double') {
        $paramArgs.Add("        ${fn}: double.tryParse(_${fn}Controller.text) ?? 0.0,")
      }
      elseif ($f.Type -eq 'DateTime') {
        $paramArgs.Add("        ${fn}: DateTime.tryParse(_${fn}Controller.text) ?? DateTime.now(),")
      }
      else {
        $paramArgs.Add("        ${fn}: _${fn}Controller.text,")
      }
    }

    $formFieldCodes.Add((Get-FormFieldCode -FieldName $fn -FieldMeta $f))
  }

  $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/${fname}_bloc.dart';
import '../bloc/${fname}_event.dart';
import '../bloc/${fname}_state.dart';
import '../../domain/usecases/create_${fname}_usecase.dart';

enum ${fclass}FormMode { create, edit }

class ${fclass}FormPage extends StatefulWidget {
  final ${fclass}FormMode mode;
  final String? id;

  const ${fclass}FormPage({
    super.key,
    this.mode = ${fclass}FormMode.create,
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
    final isCreate = widget.mode == ${fclass}FormMode.create;

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
  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $fDir = $Ctx.FeatureDir
  $eName = $Meta.Name
  $eSnake = $Meta.Snake

  $titleField = 'id'
  $subtitleField = $null
  if ($Meta.Ui -and $Meta.Ui.card) {
    if ($Meta.Ui.card.title) { $titleField = $Meta.Ui.card.title }
    if ($Meta.Ui.card.subtitle) { $subtitleField = $Meta.Ui.card.subtitle }
  }

  # FIX: use string concat for Dart ?. to avoid PS7 null-conditional
  $subtitleLine = ''
  if ($subtitleField) {
    $subtitleLine = "        subtitle: Text(item." + $subtitleField + "?.toString() ?? ''),"
  }

  $content = @"
import 'package:flutter/material.dart';
import '../../domain/entities/${eSnake}_entity.dart';

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
$subtitleLine        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: scheme.error),
          tooltip: 'Delete',
          onPressed: () => _confirmDelete(context),
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

Export-ModuleMember -Function 'Invoke-GeneratePages'