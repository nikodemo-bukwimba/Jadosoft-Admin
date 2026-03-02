# ============================================================
# Level5PageGenerator.psm1
# Generates:
#   presentation/pages/{fname}_page.dart
#   presentation/widgets/{fname}_operation_card.dart
#   presentation/widgets/{fname}_sync_status.dart
# ============================================================

function Invoke-GenerateIntegrationPages {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    _Gen-OperationCard -Ctx $Ctx -NewFile $NewFile
    _Gen-SyncStatus    -Ctx $Ctx -NewFile $NewFile
    _Gen-Page          -Ctx $Ctx -NewFile $NewFile
}

function _Gen-OperationCard {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $content = @"
import 'package:flutter/material.dart';

class ${fclass}OperationCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isLoading;
  final String? error;
  final VoidCallback? onExecute;
  final IconData icon;

  const ${fclass}OperationCard({
    super.key,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    this.error,
    this.onExecute,
    this.icon = Icons.sync,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: error != null
                        ? scheme.errorContainer
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    error != null ? Icons.error_outline : icon,
                    color: error != null ? scheme.error : scheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleSmall),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                else if (onExecute != null)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'Execute',
                    onPressed: onExecute,
                  ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_operation_card.dart") $content
}

function _Gen-SyncStatus {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $content = @"
import 'package:flutter/material.dart';

class ${fclass}SyncStatus extends StatelessWidget {
  final DateTime? lastSyncAt;
  final bool isLoading;

  const ${fclass}SyncStatus({
    super.key,
    this.lastSyncAt,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLoading ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.sync : Icons.check_circle_outline,
            size: 16,
            color: isLoading ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLoading
                  ? 'Syncing...'
                  : lastSyncAt != null
                      ? 'Last sync: ' + _formatTime(lastSyncAt!)
                      : 'Not synced yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '`${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '`${diff.inHours}h ago';
    return dt.toIso8601String().split('T').first;
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_sync_status.dart") $content
}

function _Gen-Page {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $fDir   = $Ctx.FeatureDir
    $intg   = $Ctx.Config.integration
    $ops    = @($intg.operations)

    # Build operation card widgets
    $opCards = [System.Collections.Generic.List[string]]::new()
    $iconPalette = @('Icons.cloud_download', 'Icons.cloud_upload', 'Icons.send', 'Icons.refresh', 'Icons.sync', 'Icons.get_app', 'Icons.publish')

    for ($i = 0; $i -lt $ops.Count; $i++) {
        $op = $ops[$i]
        $opName  = $op.name
        $opClass = ConvertTo-PascalCase $opName
        $opLabel = if ($op.label) { $op.label } else { ConvertTo-HumanLabel $opName }
        $opDesc  = if ($op.description) { $op.description } else { "$($op.method.ToUpper()) $($op.path)" }
        $icon    = if ($op.icon) { $op.icon } else { $iconPalette[$i % $iconPalette.Count] }
        $method  = $op.method.ToUpper()

        # Only GET ops without path params get a quick-execute button
        $hasPathParam = $op.path -match '\{(\w+)\}'
        $canAutoExec  = ($method -eq 'GET') -and (-not $hasPathParam)

        $onExecStr = if ($canAutoExec) {
            "              onExecute: () => context.read<${fclass}Cubit>().$opName(),"
        } else {
            "              // Requires parameters — wire up from your UI"
        }

        $opCards.Add(@"
              ${fclass}OperationCard(
                title: '$opLabel',
                subtitle: '$opDesc',
                icon: $icon,
                isLoading: state.is${opClass}Loading,
                error: state.${opName}Error,
$onExecStr
              ),
              const SizedBox(height: 8),
"@)
    }

    # Webhook section
    $whSection = ''
    if ($intg.webhooks -and $intg.webhooks.Count -gt 0) {
        $whItems = [System.Collections.Generic.List[string]]::new()
        foreach ($wh in $intg.webhooks) {
            $whLabel = if ($wh.label) { $wh.label } else { ConvertTo-HumanLabel $wh.name }
            $whEvent = $wh.event
            $whItems.Add(@"
                    ListTile(
                      leading: const Icon(Icons.webhook, size: 20),
                      title: Text('$whLabel'),
                      subtitle: Text('Event: $whEvent'),
                      dense: true,
                    ),
"@)
        }

        $whSection = @"

              const SizedBox(height: 24),
              Text('Webhooks', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
$($whItems -join "`n")
                  ],
                ),
              ),
"@
    }

    $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/${fname}_cubit.dart';
import '../cubit/${fname}_state.dart';
import '../widgets/${fname}_operation_card.dart';
import '../widgets/${fname}_sync_status.dart';

class ${fclass}Page extends StatelessWidget {
  const ${fclass}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$flabel'),
      ),
      body: BlocBuilder<${fclass}Cubit, ${fclass}State>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              ${fclass}SyncStatus(
                lastSyncAt: state.lastSyncAt,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 16),
              Text('Operations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
$($opCards -join "`n")
$whSection
              ],
            ),
          );
        },
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\pages\${fname}_page.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateIntegrationPages'
