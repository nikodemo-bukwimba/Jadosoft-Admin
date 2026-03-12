import 'package:flutter/material.dart';

/// View modes — mirrors File Explorer: Cards, Grid (Small Icons), List, Details.
enum ProductViewMode { cards, grid, list, details }

extension ProductViewModeX on ProductViewMode {
  String get label => switch (this) {
    ProductViewMode.cards   => 'Cards',
    ProductViewMode.grid    => 'Grid',
    ProductViewMode.list    => 'List',
    ProductViewMode.details => 'Details',
  };

  IconData get icon => switch (this) {
    ProductViewMode.cards   => Icons.dashboard_outlined,
    ProductViewMode.grid    => Icons.grid_view_rounded,
    ProductViewMode.list    => Icons.view_list_outlined,
    ProductViewMode.details => Icons.table_rows_outlined,
  };
}

/// Compact toggle bar for switching between view modes. Sits in the AppBar.
class ViewModeToggle extends StatelessWidget {
  final ProductViewMode current;
  final ValueChanged<ProductViewMode> onChanged;

  const ViewModeToggle({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ProductViewMode.values.map((mode) {
          final selected = mode == current;
          return Tooltip(
            message: mode.label,
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  mode.icon,
                  size: 18,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}