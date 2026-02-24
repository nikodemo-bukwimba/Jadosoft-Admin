import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nav_appbar_config.dart';
import 'nav_item.dart';
import 'nav_rail_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NavState extends Equatable {
  const NavState({
    required this.selectedPath,
    required this.displayMode,
    required this.history,
    this.customWidth,
    this.appBarConfig = NavAppBarConfig.empty,
  });

  final String selectedPath;
  final NavRailDisplayMode displayMode;
  final List<String> history;

  /// Non-null when the user has dragged the rail to an intermediate or
  /// snapped-but-different-from-default width.  Null = use mode default.
  final double? customWidth;

  final NavAppBarConfig appBarConfig;

  bool get canGoBack => history.length > 1;

  NavState copyWith({
    String? selectedPath,
    NavRailDisplayMode? displayMode,
    List<String>? history,
    double? customWidth,
    bool clearCustomWidth = false,
    NavAppBarConfig? appBarConfig,
  }) => NavState(
    selectedPath: selectedPath ?? this.selectedPath,
    displayMode: displayMode ?? this.displayMode,
    history: history ?? this.history,
    customWidth: clearCustomWidth ? null : (customWidth ?? this.customWidth),
    appBarConfig: appBarConfig ?? this.appBarConfig,
  );

  @override
  List<Object?> get props => [
    selectedPath,
    displayMode,
    history,
    customWidth,
    appBarConfig,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Cubit
// ─────────────────────────────────────────────────────────────────────────────

class NavCubit extends Cubit<NavState> {
  NavCubit({
    required this.router,
    required this.items,
    NavRailDisplayMode initialDisplayMode = NavRailDisplayMode.iconsAndLabels,
    String prefsKey = 'adaptive_nav_display_mode',
  }) : _prefsKey = prefsKey,
       _widthPrefsKey = '${prefsKey}_width',
       super(
         NavState(
           selectedPath: _currentPath(router),
           displayMode: initialDisplayMode,
           history: [_currentPath(router)],
         ),
       ) {
    _routerListener = () {
      final path = _currentPath(router);
      if (path != state.selectedPath) {
        emit(
          state.copyWith(selectedPath: path, history: [...state.history, path]),
        );
      }
    };
    router.routerDelegate.addListener(_routerListener);
    _loadPreferences();
  }

  final GoRouter router;
  final List<NavItem> items;
  final String _prefsKey;
  final String _widthPrefsKey;
  late final VoidCallback _routerListener;

  static String _currentPath(GoRouter r) =>
      r.routerDelegate.currentConfiguration.uri.path;

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedMode = prefs.getString(_prefsKey);
      final savedWidth = prefs.getDouble(_widthPrefsKey);

      NavRailDisplayMode? mode;
      if (savedMode != null) {
        mode = NavRailDisplayMode.values.firstWhere(
          (m) => m.name == savedMode,
          orElse: () => state.displayMode,
        );
      }

      if (mode != null || savedWidth != null) {
        emit(state.copyWith(displayMode: mode, customWidth: savedWidth));
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, state.displayMode.name);
      if (state.customWidth != null) {
        await prefs.setDouble(_widthPrefsKey, state.customWidth!);
      } else {
        await prefs.remove(_widthPrefsKey);
      }
    } catch (_) {}
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void navigateTo(String path) => router.go(path);

  void goBack() {
    if (!state.canGoBack) return;
    final newHistory = state.history.sublist(0, state.history.length - 1);
    router.go(newHistory.last);
    emit(state.copyWith(selectedPath: newHistory.last, history: newHistory));
  }

  /// Navigates back to [index] in the history stack, trimming everything after.
  /// Used by the breadcrumb trail to jump to an earlier point.
  void navigateToHistoryIndex(int index) {
    if (index < 0 || index >= state.history.length - 1) return;
    final newHistory = state.history.sublist(0, index + 1);
    router.go(newHistory.last);
    emit(state.copyWith(selectedPath: newHistory.last, history: newHistory));
  }

  // ── Display mode ──────────────────────────────────────────────────────────

  void setDisplayMode(NavRailDisplayMode mode, {bool clearCustomWidth = true}) {
    emit(state.copyWith(displayMode: mode, clearCustomWidth: clearCustomWidth));
    _savePreferences();
  }

  void cycleDisplayMode() {
    const modes = NavRailDisplayMode.values;
    final next = modes[(modes.indexOf(state.displayMode) + 1) % modes.length];
    setDisplayMode(next);
  }

  // ── Width ─────────────────────────────────────────────────────────────────

  /// Updates width during an active drag — does NOT persist yet.
  void setCustomWidth(double width) {
    emit(state.copyWith(customWidth: width));
  }

  /// Called on drag-end after snapping.  Persists the final value.
  void commitCustomWidth(double width) {
    emit(state.copyWith(customWidth: width));
    _savePreferences();
  }

  // ── Item helpers ──────────────────────────────────────────────────────────

  bool isItemActive(NavItem item) {
    if (item.isButton) return false;
    if (item.path == state.selectedPath) return true;
    return item.allDescendantPaths.contains(state.selectedPath);
  }

  /// Searches the full item tree for the display label matching [path].
  String? labelForPath(String path) => _findLabel(items, path);

  String? _findLabel(List<NavItem> nodes, String path) {
    for (final node in nodes) {
      if (node.path == path) return node.label;
      final hit = _findLabel(node.children, path);
      if (hit != null) return hit;
    }
    return null;
  }

  /// History as `(path, label)` records — ready for breadcrumb rendering.
  List<({String path, String label})> get historyWithLabels =>
      state.history.map((p) => (path: p, label: labelForPath(p) ?? p)).toList();

  // ── AppBar config ─────────────────────────────────────────────────────────

  void setAppBarConfig(NavAppBarConfig config) =>
      emit(state.copyWith(appBarConfig: config));

  void clearAppBarConfig() =>
      emit(state.copyWith(appBarConfig: NavAppBarConfig.empty));

  @override
  Future<void> close() {
    router.routerDelegate.removeListener(_routerListener);
    return super.close();
  }
}
