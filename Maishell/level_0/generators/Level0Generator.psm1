# ============================================================
# Level0Generator.psm1
# Level 0 — Static Feature
#
# Generates:
#   presentation/pages/{feature}_page.dart
#   presentation/widgets/{feature}_widget.dart
#
# No domain, no data, no BLoC, no network.
# Output matches Phase 1 blueprint working models exactly.
# ============================================================

function Invoke-GenerateLevel0 {
  param(
    [Parameter(Mandatory)][hashtable]$Ctx,
    [Parameter(Mandatory)][scriptblock]$NewFile
  )

  $fname = $Ctx.Tokens.FNAME
  $fclass = $Ctx.Tokens.FCLASS
  $flabel = $Ctx.Tokens.FLABEL
  $fDir = $Ctx.FeatureDir

  # ── Page ──────────────────────────────────────────────
  $pageContent = @"
// ${fname}_page.dart
// Level 0 — Static Feature
// Replace: page title, body content, widget composition.
// This page requires no BLoC, no repository, no network call.

import 'package:flutter/material.dart';
import '../widgets/${fname}_widget.dart';

class ${fclass}Page extends StatelessWidget {
  const ${fclass}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${flabel}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: Replace with domain-specific content
                  ${fclass}Widget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"@

  & $NewFile (Join-Path $fDir "presentation\pages\${fname}_page.dart") $pageContent

  # ── Widget ────────────────────────────────────────────
  $widgetContent = @"
// ${fname}_widget.dart
// Level 0 — Static Widget
// Replace: displayed data and layout.
// No state, no async calls.

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
              '${flabel}',
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

Export-ModuleMember -Function 'Invoke-GenerateLevel0'
