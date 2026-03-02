# ============================================================
# Level4PageGenerator.psm1
# Generates:
#   presentation/pages/{fname}_dashboard_page.dart
#   presentation/widgets/{fname}_metric_card.dart
# ============================================================

function Invoke-GenerateDashboardPages {
    param([Parameter(Mandatory)][hashtable]$Ctx, [Parameter(Mandatory)][scriptblock]$NewFile)

    _Gen-MetricCard    -Ctx $Ctx -NewFile $NewFile
    _Gen-DashboardPage -Ctx $Ctx -NewFile $NewFile
}

function _Gen-MetricCard {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $fDir   = $Ctx.FeatureDir

    $content = @"
import 'package:flutter/material.dart';

class ${fclass}MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ${fclass}MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 14, color: scheme.outlineVariant),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
"@
    & $NewFile (Join-Path $fDir "presentation\widgets\${fname}_metric_card.dart") $content
}

function _Gen-DashboardPage {
    param($Ctx, $NewFile)
    $fname  = $Ctx.Tokens.FNAME
    $fclass = $Ctx.Tokens.FCLASS
    $flabel = $Ctx.Tokens.FLABEL
    $fDir   = $Ctx.FeatureDir
    $config = $Ctx.Config

    $metrics = @($config.projection.metrics)

    # Build metric card widgets
    $metricCards = [System.Collections.Generic.List[string]]::new()
    $colorPalette = @('Colors.blue', 'Colors.green', 'Colors.orange', 'Colors.purple', 'Colors.red', 'Colors.teal', 'Colors.amber', 'Colors.indigo')
    $iconPalette  = @('Icons.analytics_outlined', 'Icons.attach_money', 'Icons.pie_chart_outline', 'Icons.list_alt', 'Icons.trending_up', 'Icons.bar_chart', 'Icons.show_chart', 'Icons.donut_large')

    for ($i = 0; $i -lt $metrics.Count; $i++) {
        $m = $metrics[$i]
        $color = $colorPalette[$i % $colorPalette.Count]
        $icon  = if ($m.icon) { $m.icon } else { $iconPalette[$i % $iconPalette.Count] }
        $label = if ($m.label) { $m.label } else { ConvertTo-HumanLabel $m.name }
        $mName = $m.name

        # Format value based on operation
        $valueExpr = switch ($m.operation) {
            'count'      { "projection." + $mName + ".toString()" }
            'sum'        { "projection." + $mName + ".toStringAsFixed(2)" }
            'sumNonNull' { "projection." + $mName + ".toStringAsFixed(2)" }
            'average'    { "projection." + $mName + ".toStringAsFixed(1)" }
            'groupCount' { "projection." + $mName + ".length.toString() + ' groups'" }
            'latest'     { "projection." + $mName + ".length.toString() + ' items'" }
            default      { "projection." + $mName + ".toString()" }
        }

        $metricCards.Add(@"
                ${fclass}MetricCard(
                  title: '$label',
                  value: $valueExpr,
                  icon: $icon,
                  color: $color,
                ),
"@)
    }

    # Build status breakdown section if any groupCount metric exists
    $statusSection = ''
    $groupMetric = $metrics | Where-Object { $_.operation -eq 'groupCount' } | Select-Object -First 1
    if ($groupMetric) {
        $gmName = $groupMetric.name
        # Use string concat for Dart forEach lambda with ${} interpolation
        $entryLine = "entry.key"
        $valueLine = "entry.value"

        $statusSection = @"

                  const SizedBox(height: 24),
                  Text('Breakdown', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...projection.${gmName}.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            $entryLine,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            $valueLine.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
"@
    }

    # Build recent items section if any 'latest' metric exists
    $recentSection = ''
    $latestMetric = $metrics | Where-Object { $_.operation -eq 'latest' } | Select-Object -First 1
    if ($latestMetric) {
        $lmName = $latestMetric.name
        $lLabel = if ($latestMetric.label) { $latestMetric.label } else { ConvertTo-HumanLabel $latestMetric.name }
        # Find display field from source entity
        $displayField = if ($latestMetric.displayField) { $latestMetric.displayField } else { 'id' }

        $recentSection = @"

                  const SizedBox(height: 24),
                  Text('$lLabel', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...projection.${lmName}.map((item) => Card(
                    child: ListTile(
                      title: Text(item.$displayField),
                      dense: true,
                    ),
                  )),
"@
    }

    # Build generatedAt line via concat (Dart ?.copyWith is safe but ?? needs care)
    $timestampLine = "projection.generatedAt.toIso8601String().split('T').first"

    $content = @"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/${fname}_cubit.dart';
import '../cubit/${fname}_state.dart';
import '../widgets/${fname}_metric_card.dart';

class ${fclass}DashboardPage extends StatelessWidget {
  const ${fclass}DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$flabel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<${fclass}Cubit>().refresh(),
          ),
        ],
      ),
      body: BlocBuilder<${fclass}Cubit, ${fclass}State>(
        builder: (context, state) {
          if (state is ${fclass}Loading || state is ${fclass}Initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ${fclass}Error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<${fclass}Cubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ${fclass}Loaded) {
            final projection = state.projection;
            return RefreshIndicator(
              onRefresh: () => context.read<${fclass}Cubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
$($metricCards -join "`n")
                    ],
                  ),
$statusSection
$recentSection

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Updated: ' + $timestampLine,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  ],
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
    & $NewFile (Join-Path $fDir "presentation\pages\${fname}_dashboard_page.dart") $content
}

Export-ModuleMember -Function 'Invoke-GenerateDashboardPages'
