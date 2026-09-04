import 'package:flutter/material.dart';
import '../../utils/list_view/list_view_helpers.dart';

class LocationSelector extends StatelessWidget {
  final bool isDark;
  final List<String> locations;
  final String? selectedLocation;
  final ValueChanged<String> onLocationSelected;

  const LocationSelector({
    super.key,
    required this.isDark,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: locations.asMap().entries.map((entry) {
          int idx = entry.key;
          String loc = entry.value;
          bool isSelected = loc == selectedLocation;

          return GestureDetector(
            onTap: () => onLocationSelected(loc),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? ListViewHelpers.getColorForIndex(idx) : (isDark ? Colors.white10 : Colors.black12),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  ListViewHelpers.getShapeIndicator(idx),
                  const SizedBox(width: 8),
                  Text(
                    loc.split(',').first,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}