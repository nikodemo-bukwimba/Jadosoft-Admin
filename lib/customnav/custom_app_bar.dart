import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'navigation.dart';

class NavCustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NavCustomAppBar({
    super.key,
    this.logo,
    this.actions = const [],
    this.centerWidget,
    this.showBackButton = true,
    this.isDrawerMode = false,
    this.onMenuTap,
  });

  final Widget? logo;
  final List<Widget> actions;
  final Widget? centerWidget;
  final bool showBackButton;
  final bool isDrawerMode;
  final VoidCallback? onMenuTap;

  @override
  Size get preferredSize => Size.fromHeight(
    _kAppBarHeight +
        WidgetsBinding.instance.platformDispatcher.views.first.padding.top /
            WidgetsBinding
                .instance
                .platformDispatcher
                .views
                .first
                .devicePixelRatio,
  );

  static const double _kAppBarHeight = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme =
        (theme.extension<NavRailThemeData>() ?? const NavRailThemeData())
            .resolve(theme);

    return BlocBuilder<NavCubit, NavState>(
      builder: (context, state) {
        final cubit = context.read<NavCubit>();
        final showBack = showBackButton && state.canGoBack;

        final pageConfig = state.appBarConfig;
        final effectiveCenter = pageConfig.centerWidget ?? centerWidget;
        final effectiveActions = pageConfig.actions.isNotEmpty
            ? pageConfig.actions
            : actions;

        final statusBarHeight = MediaQuery.of(context).padding.top;
        return Container(
          height: (navTheme.appBarHeight ?? _kAppBarHeight) + statusBarHeight,
          color: navTheme.appBarBackgroundColor,
          padding: EdgeInsets.only(top: statusBarHeight, left: 8, right: 8),
          child: Row(
            children: [
              // ── Leading slot ──────────────────────────────────────────────
              if (isDrawerMode) ...[
                IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open menu',
                  onPressed: onMenuTap,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: showBack
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: cubit.goBack,
                        )
                      : const SizedBox.shrink(),
                ),
              ] else ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: showBack
                      ? IconButton(
                          key: const ValueKey('back'),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: 'Back',
                          onPressed: cubit.goBack,
                        )
                      : logo != null
                      ? Padding(
                          key: const ValueKey('logo'),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: logo,
                        )
                      : const SizedBox.shrink(key: ValueKey('none')),
                ),
              ],

              // ── Center slot ───────────────────────────────────────────────
              // Priority: page-level config → shell prop → breadcrumb fallback
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: effectiveCenter != null
                        ? KeyedSubtree(
                            key: ValueKey(effectiveCenter.hashCode),
                            child: effectiveCenter,
                          )
                        : _Breadcrumb(
                            key: ValueKey(state.history.length),
                            history: cubit.historyWithLabels,
                            onTapIndex: cubit.navigateToHistoryIndex,
                            navTheme: navTheme,
                          ),
                  ),
                ),
              ),

              // ── Actions ───────────────────────────────────────────────────
              ...effectiveActions.map(
                (a) =>
                    Padding(padding: const EdgeInsets.only(left: 4), child: a),
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Breadcrumb trail
// ─────────────────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    super.key,
    required this.history,
    required this.onTapIndex,
    required this.navTheme,
  });

  final List<({String path, String label})> history;
  final void Function(int index) onTapIndex;
  final NavRailThemeData navTheme;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < history.length; i++) ...[
            _BreadcrumbItem(
              label: history[i].label,
              isLast: i == history.length - 1,
              selectedColor: cs.primary,
              unselectedColor: cs.onSurfaceVariant,
              // Tapping a non-last crumb navigates back to that point.
              onTap: i < history.length - 1 ? () => onTapIndex(i) : null,
            ),
            if (i < history.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  const _BreadcrumbItem({
    required this.label,
    required this.isLast,
    required this.selectedColor,
    required this.unselectedColor,
    this.onTap,
  });

  final String label;
  final bool isLast;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isLast ? selectedColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
