// main.dart
// ─────────────────────────────────────────────────────────────
// App entry point. Intentionally minimal.
//
// Responsibilities (and only these):
//   - Ensure Flutter bindings are ready
//   - Initialise the dependency injection container
//   - Hand off to HMSCPPD
//
// Everything else (theme, routing, BLoCs) lives in app/app.dart.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'config/di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const HMSCPPD());
}
