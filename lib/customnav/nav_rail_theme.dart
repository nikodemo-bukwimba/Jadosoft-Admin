import 'package:flutter/material.dart';

enum NavRailDisplayMode { iconsOnly, labelsOnly, iconsAndLabels }

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
    // ── Resize handle ─────────────────────────────────────────────────────
    this.enableResize,
    this.resizeHandleWidth,
    this.resizeHandleColor,
    this.resizeHandleHoverColor,
  });

  final double? railWidth;
  final double? railCollapsedWidth;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? selectedItemBackgroundColor;
  final Color? buttonItemColor;
  final Color? buttonItemBackgroundColor;
  final Color? indicatorColor;
  final TextStyle? labelStyle;
  final Color? flyoutBackgroundColor;
  final double? flyoutElevation;
  final BorderRadius? flyoutBorderRadius;
  final Color? appBarBackgroundColor;
  final double? appBarHeight;
  final Color? dividerColor;
  final BorderRadius? itemBorderRadius;

  /// Whether the rail can be resized by dragging its right edge. Default: true.
  final bool? enableResize;

  /// Width of the drag handle zone in logical pixels. Default: 6.
  final double? resizeHandleWidth;

  /// Handle color at rest. Defaults to [ColorScheme.outlineVariant].
  final Color? resizeHandleColor;

  /// Handle color while hovered or dragging. Defaults to primary × 0.3.
  final Color? resizeHandleHoverColor;

  NavRailThemeData resolve(ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    return NavRailThemeData(
      railWidth: railWidth ?? 240,
      railCollapsedWidth: railCollapsedWidth ?? 72,
      backgroundColor: backgroundColor ?? cs.surface,
      selectedItemColor: selectedItemColor ?? cs.onSecondaryContainer,
      unselectedItemColor: unselectedItemColor ?? cs.onSurfaceVariant,
      selectedItemBackgroundColor:
          selectedItemBackgroundColor ?? cs.secondaryContainer,
      buttonItemColor: buttonItemColor ?? cs.onPrimary,
      buttonItemBackgroundColor: buttonItemBackgroundColor ?? cs.primary,
      indicatorColor: indicatorColor ?? cs.secondaryContainer,
      labelStyle: labelStyle ?? tt.labelMedium,
      flyoutBackgroundColor: flyoutBackgroundColor ?? cs.surfaceContainerHigh,
      flyoutElevation: flyoutElevation ?? 3,
      flyoutBorderRadius: flyoutBorderRadius ?? BorderRadius.circular(12),
      appBarBackgroundColor: appBarBackgroundColor ?? cs.surface,
      appBarHeight: appBarHeight ?? 64,
      dividerColor: dividerColor ?? cs.surface,
      itemBorderRadius: itemBorderRadius ?? BorderRadius.circular(12),
      enableResize: enableResize ?? true,
      resizeHandleWidth: resizeHandleWidth ?? 0,
      resizeHandleColor: resizeHandleColor ?? cs.surface,
      resizeHandleHoverColor:
          resizeHandleHoverColor ?? cs.primary.withOpacity(0.3),
    );
  }

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
    bool? enableResize,
    double? resizeHandleWidth,
    Color? resizeHandleColor,
    Color? resizeHandleHoverColor,
  }) => NavRailThemeData(
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
    flyoutBackgroundColor: flyoutBackgroundColor ?? this.flyoutBackgroundColor,
    flyoutElevation: flyoutElevation ?? this.flyoutElevation,
    flyoutBorderRadius: flyoutBorderRadius ?? this.flyoutBorderRadius,
    appBarBackgroundColor: appBarBackgroundColor ?? this.appBarBackgroundColor,
    appBarHeight: appBarHeight ?? this.appBarHeight,
    dividerColor: dividerColor ?? this.dividerColor,
    itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
    enableResize: enableResize ?? this.enableResize,
    resizeHandleWidth: resizeHandleWidth ?? this.resizeHandleWidth,
    resizeHandleColor: resizeHandleColor ?? this.resizeHandleColor,
    resizeHandleHoverColor:
        resizeHandleHoverColor ?? this.resizeHandleHoverColor,
  );

  @override
  NavRailThemeData lerp(NavRailThemeData? other, double t) {
    if (other == null) return this;
    return NavRailThemeData(
      railWidth: _lerpDouble(railWidth, other.railWidth, t),
      railCollapsedWidth: _lerpDouble(
        railCollapsedWidth,
        other.railCollapsedWidth,
        t,
      ),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      selectedItemColor: Color.lerp(
        selectedItemColor,
        other.selectedItemColor,
        t,
      ),
      unselectedItemColor: Color.lerp(
        unselectedItemColor,
        other.unselectedItemColor,
        t,
      ),
      selectedItemBackgroundColor: Color.lerp(
        selectedItemBackgroundColor,
        other.selectedItemBackgroundColor,
        t,
      ),
      buttonItemColor: Color.lerp(buttonItemColor, other.buttonItemColor, t),
      buttonItemBackgroundColor: Color.lerp(
        buttonItemBackgroundColor,
        other.buttonItemBackgroundColor,
        t,
      ),
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      flyoutBackgroundColor: Color.lerp(
        flyoutBackgroundColor,
        other.flyoutBackgroundColor,
        t,
      ),
      flyoutElevation: _lerpDouble(flyoutElevation, other.flyoutElevation, t),
      flyoutBorderRadius: BorderRadius.lerp(
        flyoutBorderRadius,
        other.flyoutBorderRadius,
        t,
      ),
      appBarBackgroundColor: Color.lerp(
        appBarBackgroundColor,
        other.appBarBackgroundColor,
        t,
      ),
      appBarHeight: _lerpDouble(appBarHeight, other.appBarHeight, t),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t),
      itemBorderRadius: BorderRadius.lerp(
        itemBorderRadius,
        other.itemBorderRadius,
        t,
      ),
      // Discrete — don't lerp booleans or handle sizes mid-transition
      enableResize: t < 0.5 ? enableResize : other.enableResize,
      resizeHandleWidth: _lerpDouble(
        resizeHandleWidth,
        other.resizeHandleWidth,
        t,
      ),
      resizeHandleColor: Color.lerp(
        resizeHandleColor,
        other.resizeHandleColor,
        t,
      ),
      resizeHandleHoverColor: Color.lerp(
        resizeHandleHoverColor,
        other.resizeHandleHoverColor,
        t,
      ),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return ((a ?? 0.0) + ((b ?? 0.0) - (a ?? 0.0)) * t);
  }
}
