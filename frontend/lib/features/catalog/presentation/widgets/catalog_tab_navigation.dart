import 'package:flutter/material.dart';
import 'package:rr_frontend/core/theme/app_text_styles.dart';

class CatalogTabNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CatalogTabNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(context, 0, 'Catalog', Icons.grid_view_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTabItem(context, 1, 'History', Icons.history_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildTabItem(context, 2, 'Convert', Icons.swap_horiz_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
      BuildContext context, int index, String label, IconData icon) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : theme.hintColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: isSelected
                  ? AppTextStyles.tabSelected(color: Colors.white)
                  : AppTextStyles.tabUnselected(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
