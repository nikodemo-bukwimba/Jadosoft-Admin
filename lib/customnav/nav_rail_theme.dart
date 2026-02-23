import 'package:flutter/material.dart';

/// Controls how the rail renders its items.
enum NavRailDisplayMode {
  /// Shows only icons. Rail collapses to [NavRailThemeData.railCollapsedWidth].
  iconsOnly,

  /// Shows only text labels. Rail expands to [NavRailThemeData.railWidth].
  labelsOnly,

  /// Shows icons and labels side-by-side. Rail expands to [NavRailThemeData.railWidth].
  iconsAndLabels,
}

/// A [ThemeExtension] that exposes Material 3 design tokens for the nav rail.
///
/// Add it to your [ThemeData] to globally style every [AdaptiveNavShell]:
/// ```dart
/// ThemeData(
///   extensions: [
///     NavRailThemeData(
///       railWidth: 260,
///       backgroundColor: Colors.indigo.shade50,
///     ),
///   ],
/// )
/// ```
///
/// Any unset value falls back to the app's [ColorScheme] / [TextTheme] M3 tokens.
@immutable
class NavRailThemeData extends ThemeExtension<NavRailThemeData> {
  const NavRailThemeData({
    this.railWidth,
    this.railCollapsedWidth,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedItemBackgroundColor,
    this.buttonItemColor,
    this.buttonItemBackgroundColor,
    this.indicatorColor,
    this.labelStyle,
    this.flyoutBackgroundColor,
    this.flyoutElevation,
    this.flyoutBorderRadius,
    this.appBarBackgroundColor,
    this.appBarHeight,
    this.dividerColor,
    this.itemBorderRadius,
  });

  // ── Rail dimensions ──────────────────────────────────────────────────────
  /// Width when showing icons + labels (or labels only). Default: 240.
  final double? railWidth;

  /// Width when showing icons only. Default: 72.
  final double? railCollapsedWidth;

  // ── Colors ───────────────────────────────────────────────────────────────
  /// Rail background. Defaults to M3 `surfaceContainer`.
  final Color? backgroundColor;

  /// Foreground color for the selected item. Defaults to `onSecondaryContainer`.
  final Color? selectedItemColor;

  /// Foreground color for unselected items. Defaults to `onSurfaceVariant`.
  final Color? unselectedItemColor;

  /// Background fill of the selected item tile. Defaults to `secondaryContainer`.
  final Color? selectedItemBackgroundColor;

  /// Foreground color of button-style items. Defaults to `onPrimary`.
  final Color? buttonItemColor;

  /// Background fill of button-style items. Defaults to `primary`.
  final Color? buttonItemBackgroundColor;

  /// Indicator color (reserved for future indicator widget). Defaults to `secondaryContainer`.
  final Color? indicatorColor;

  // ── Typography ───────────────────────────────────────────────────────────
  /// Label text style. Defaults to `labelMedium`.
  final TextStyle? labelStyle;

  // ── Flyout ───────────────────────────────────────────────────────────────
  /// Background of the flyout panel. Defaults to `surfaceContainerHigh`.
  final Color? flyoutBackgroundColor;

  /// Material elevation of the flyout card. Default: 3.
  final double? flyoutElevation;

  /// Corner radius of the flyout card. Default: 12px circular.
  final BorderRadius? flyoutBorderRadius;

  // ── AppBar ───────────────────────────────────────────────────────────────
  /// AppBar background. Defaults to `surface`.
  final Color? appBarBackgroundColor;

  /// AppBar height. Default: 64.
  final double? appBarHeight;

  // ── Misc ─────────────────────────────────────────────────────────────────
  /// Color of the rail/appbar dividers. Defaults to `outlineVariant`.
  final Color? dividerColor;

  /// Corner radius of each nav item tile. Default: 12px circular.
  final BorderRadius? itemBorderRadius;

  // ── Resolve against ThemeData ─────────────────────────────────────────────

  /// Returns a fully-populated copy, filling every null field from [theme]'s
  /// M3 color tokens and text theme.
  NavRailThemeData resolve(ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return NavRailThemeData(
      railWidth: railWidth ?? 240,
      railCollapsedWidth: railCollapsedWidth ?? 72,
      backgroundColor: backgroundColor ?? cs.surfaceContainer,
      selectedItemColor: selectedItemColor ?? cs.onSecondaryContainer,
      unselectedItemColor: unselectedItemColor ?? cs.onSurfaceVariant,
      selectedItemBackgroundColor:
          selectedItemBackgroundColor ?? cs.secondaryContainer,
      buttonItemColor: buttonItemColor ?? cs.onPrimary,
      buttonItemBackgroundColor:
          buttonItemBackgroundColor ?? cs.primary,
      indicatorColor: indicatorColor ?? cs.secondaryContainer,
      labelStyle: labelStyle ?? tt.labelMedium,
      flyoutBackgroundColor:
          flyoutBackgroundColor ?? cs.surfaceContainerHigh,
      flyoutElevation: flyoutElevation ?? 3,
      flyoutBorderRadius:
          flyoutBorderRadius ?? BorderRadius.circular(12),
      appBarBackgroundColor: appBarBackgroundColor ?? cs.surface,
      appBarHeight: appBarHeight ?? 64,
      dividerColor: dividerColor ?? cs.outlineVariant,
      itemBorderRadius: itemBorderRadius ?? BorderRadius.circular(12),
    );
  }

  // ── ThemeExtension overrides ──────────────────────────────────────────────

  @override
  NavRailThemeData copyWith({
    double? railWidth,
    double? railCollapsedWidth,
    Color? backgroundColor,
    Color? selectedItemColor,
    Color? unselectedItemColor,
    Color? selectedItemBackgroundColor,
    Color? buttonItemColor,
    Color? buttonItemBackgroundColor,
    Color? indicatorColor,
    TextStyle? labelStyle,
    Color? flyoutBackgroundColor,
    double? flyoutElevation,
    BorderRadius? flyoutBorderRadius,
    Color? appBarBackgroundColor,
    double? appBarHeight,
    Color? dividerColor,
    BorderRadius? itemBorderRadius,
  }) =>
      NavRailThemeData(
        railWidth: railWidth ?? this.railWidth,
        railCollapsedWidth: railCollapsedWidth ?? this.railCollapsedWidth,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        selectedItemColor: selectedItemColor ?? this.selectedItemColor,
        unselectedItemColor: unselectedItemColor ?? this.unselectedItemColor,
        selectedItemBackgroundColor:
            selectedItemBackgroundColor ?? this.selectedItemBackgroundColor,
        buttonItemColor: buttonItemColor ?? this.buttonItemColor,
        buttonItemBackgroundColor:
            buttonItemBackgroundColor ?? this.buttonItemBackgroundColor,
        indicatorColor: indicatorColor ?? this.indicatorColor,
        labelStyle: labelStyle ?? this.labelStyle,
        flyoutBackgroundColor:
            flyoutBackgroundColor ?? this.flyoutBackgroundColor,
        flyoutElevation: flyoutElevation ?? this.flyoutElevation,
        flyoutBorderRadius: flyoutBorderRadius ?? this.flyoutBorderRadius,
        appBarBackgroundColor:
            appBarBackgroundColor ?? this.appBarBackgroundColor,
        appBarHeight: appBarHeight ?? this.appBarHeight,
        dividerColor: dividerColor ?? this.dividerColor,
        itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
      );

  @override
  NavRailThemeData lerp(NavRailThemeData? other, double t) {
    if (other == null) return this;
    return NavRailThemeData(
      railWidth: _lerpDouble(railWidth, other.railWidth, t),
      railCollapsedWidth:
          _lerpDouble(railCollapsedWidth, other.railCollapsedWidth, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      selectedItemColor:
          Color.lerp(selectedItemColor, other.selectedItemColor, t),
      unselectedItemColor:
          Color.lerp(unselectedItemColor, other.unselectedItemColor, t),
      selectedItemBackgroundColor: Color.lerp(
          selectedItemBackgroundColor, other.selectedItemBackgroundColor, t),
      buttonItemColor: Color.lerp(buttonItemColor, other.buttonItemColor, t),
      buttonItemBackgroundColor: Color.lerp(
          buttonItemBackgroundColor, other.buttonItemBackgroundColor, t),
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      flyoutBackgroundColor:
          Color.lerp(flyoutBackgroundColor, other.flyoutBackgroundColor, t),
      flyoutElevation: _lerpDouble(flyoutElevation, other.flyoutElevation, t),
      flyoutBorderRadius:
          BorderRadius.lerp(flyoutBorderRadius, other.flyoutBorderRadius, t),
      appBarBackgroundColor:
          Color.lerp(appBarBackgroundColor, other.appBarBackgroundColor, t),
      appBarHeight: _lerpDouble(appBarHeight, other.appBarHeight, t),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t),
      itemBorderRadius:
          BorderRadius.lerp(itemBorderRadius, other.itemBorderRadius, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return ((a ?? 0.0) + ((b ?? 0.0) - (a ?? 0.0)) * t);
  }
}
