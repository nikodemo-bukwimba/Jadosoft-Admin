import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'nav_item.dart';
import 'nav_rail_theme.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the navigation rail's state.
class NavState extends Equatable {
  const NavState({
    required this.selectedPath,
    required this.displayMode,
    required this.history,
  });

  /// The currently active go_router path.
  final String selectedPath;

  /// How the rail renders its items (icons / labels / both).
  final NavRailDisplayMode displayMode;

  /// Ordered list of visited paths — used for custom back navigation.
  ///
  /// The last entry is always equal to [selectedPath].
  final List<String> history;

  bool get canGoBack => history.length > 1;

  NavState copyWith({
    String? selectedPath,
    NavRailDisplayMode? displayMode,
    List<String>? history,
  }) =>
      NavState(
        selectedPath: selectedPath ?? this.selectedPath,
        displayMode: displayMode ?? this.displayMode,
        history: history ?? this.history,
      );

  @override
  List<Object?> get props => [selectedPath, displayMode, history];
}

// ─────────────────────────────────────────────────────────────────────────────
// Cubit
// ─────────────────────────────────────────────────────────────────────────────

/// Manages navigation selection, display mode toggling, and history tracking.
///
/// Listens to [GoRouter]'s route changes so the rail stays in sync with
/// programmatic navigation, deep links, and browser back/forward.
class NavCubit extends Cubit<NavState> {
  NavCubit({
    required this.router,
    required this.items,
    NavRailDisplayMode initialDisplayMode = NavRailDisplayMode.iconsAndLabels,
  }) : super(NavState(
          selectedPath: _currentPath(router),
          displayMode: initialDisplayMode,
          history: [_currentPath(router)],
        )) {
    _routerListener = () {
      final path = _currentPath(router);
      if (path != state.selectedPath) {
        emit(state.copyWith(
          selectedPath: path,
          history: [...state.history, path],
        ));
      }
    };
    router.routerDelegate.addListener(_routerListener);
  }

  final GoRouter router;
  final List<NavItem> items;
  late final VoidCallback _routerListener;

  static String _currentPath(GoRouter r) =>
      r.routerDelegate.currentConfiguration.uri.path;

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Navigates to [path] via go_router. State updates from the listener above.
  void navigateTo(String path) => router.go(path);

  /// Navigates to the previous path in [NavState.history].
  void goBack() {
    if (!state.canGoBack) return;
    final newHistory = state.history.sublist(0, state.history.length - 1);
    router.go(newHistory.last);
    emit(state.copyWith(
      selectedPath: newHistory.last,
      history: newHistory,
    ));
  }

  // ── Display mode ──────────────────────────────────────────────────────────

  /// Sets a specific display mode.
  void setDisplayMode(NavRailDisplayMode mode) =>
      emit(state.copyWith(displayMode: mode));

  /// Cycles through all three display modes in order:
  /// `iconsAndLabels` → `iconsOnly` → `labelsOnly` → `iconsAndLabels`.
  void cycleDisplayMode() {
    const modes = NavRailDisplayMode.values;
    final next = modes[(modes.indexOf(state.displayMode) + 1) % modes.length];
    emit(state.copyWith(displayMode: next));
  }

  // ── Selection helpers ─────────────────────────────────────────────────────

  /// Returns true if [item] or any of its descendants matches [state.selectedPath].
  bool isItemActive(NavItem item) {
    if (item.isButton) return false;
    if (item.path == state.selectedPath) return true;
    return item.allDescendantPaths.contains(state.selectedPath);
  }

  @override
  Future<void> close() {
    router.routerDelegate.removeListener(_routerListener);
    return super.close();
  }
}
