import 'package:flutter/material.dart';

class CatalogTabNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool conversionEnabled;

  const CatalogTabNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.conversionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTabItem(context, 0, Icons.grid_view_rounded, 'Catalog'),
        const SizedBox(width: 8),
        _buildTabItem(context, 1, Icons.history_rounded, 'History'),
        if (conversionEnabled) ...[
          const SizedBox(width: 8),
          _buildTabItem(context, 2, Icons.swap_horiz_rounded, 'Convert'),
        ],
      ],
    );
  }

  Widget _buildTabItem(
      BuildContext context, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    const primary = Color.fromARGB(255, 59, 49, 165);

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? primary : const Color(0xFFE0E0E0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF757575)),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
