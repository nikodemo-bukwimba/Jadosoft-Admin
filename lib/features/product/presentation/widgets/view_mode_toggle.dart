import 'package:flutter/material.dart';

/// The four display modes for the product list.
enum ProductViewMode {
  grid,
  card,
  list,
  table;

  IconData get icon {
    switch (this) {
      case ProductViewMode.grid:
        return Icons.grid_view_rounded;
      case ProductViewMode.card:
        return Icons.view_agenda_rounded;
      case ProductViewMode.list:
        return Icons.view_list_rounded;
      case ProductViewMode.table:
        return Icons.table_rows_rounded;
    }
  }

  String get tooltip {
    switch (this) {
      case ProductViewMode.grid:
        return 'Grid View';
      case ProductViewMode.card:
        return 'Card View';
      case ProductViewMode.list:
        return 'List View';
      case ProductViewMode.table:
        return 'Table View';
    }
  }
}

/// A segmented toggle for switching between product view modes.
class ViewModeToggle extends StatelessWidget {
  final ProductViewMode currentMode;
  final ValueChanged<ProductViewMode> onModeChanged;

  const ViewModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ProductViewMode.values.map((mode) {
          final isSelected = mode == currentMode;
          return Tooltip(
            message: mode.tooltip,
            child: InkWell(
              onTap: () => onModeChanged(mode),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  mode.icon,
                  size: 18,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
