import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_filter_provider.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  // Helper method to map indicators to icons
  IconData _getIconForFilter(String filter) {
    switch (filter) {
      case 'Total Population': return Icons.groups;
      case 'Cost of Living (CPI)': return Icons.account_balance_wallet;
      case 'Mean Income': return Icons.attach_money;
      case 'Median Income': return Icons.money;
      case 'Expenditure': return Icons.shopping_cart;
      case 'Poverty Rate': return Icons.trending_down;
      case 'Income Inequality': return Icons.balance;
      case 'GDP': return Icons.auto_graph;
      case 'Labour Force': return Icons.engineering;
      case 'Workforce Participation': return Icons.work;
      case 'Unemployment Rate': return Icons.work_off;
      case 'General Crime': return Icons.local_police;
      case 'Drug Crime': return Icons.medication_liquid;
      case 'Hospital Beds': return Icons.bed;
      case 'Healthcare Staff': return Icons.health_and_safety;
      case 'Teachers': return Icons.school;
      case 'Literacy Rate': return Icons.menu_book;
      case 'Electricity Access': return Icons.bolt;
      case 'Water Access': return Icons.water_drop;
      case 'Sanitation': return Icons.cleaning_services;
      case 'Green Space': return Icons.park;
      default: return Icons.analytics;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filterProvider = Provider.of<SearchFilterProvider>(context);

    // Background and card colors based on theme
    final sheetBgColor = isDark ? const Color(0xFF000000).withOpacity(0.85) : const Color(0xFFF2F2F7).withOpacity(0.9);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90, // Taller sheet for more content
          color: sheetBgColor,
          child: Column(
            children: [
              // TOP HEADER BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    // Circular Close Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 20, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Pill Reset Button
                    GestureDetector(
                      onTap: () => filterProvider.resetFilters(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Reset',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Title
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const Spacer(),

                    // Done Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A84FF), // Vivid iOS Blue
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (filterProvider.isMapView)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Map View allows only one filter selection',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),

              // SCROLLABLE FILTER LIST
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionHeader('Economic & Wealth'),
                    _buildGroupedCard(
                      context: context,
                      cardColor: cardColor,
                      isDark: isDark,
                      provider: filterProvider,
                      filters: [
                        'Cost of Living (CPI)', 'Mean Income', 'Median Income',
                        'Expenditure', 'Poverty Rate', 'Income Inequality',
                        'GDP', 'Labour Force', 'Workforce Participation', 'Unemployment Rate'
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Demographics & Safety'),
                    _buildGroupedCard(
                      context: context,
                      cardColor: cardColor,
                      isDark: isDark,
                      provider: filterProvider,
                      filters: [
                        'Total Population', 'General Crime', 'Drug Crime'
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Public Amenities & Environment'),
                    _buildGroupedCard(
                      context: context,
                      cardColor: cardColor,
                      isDark: isDark,
                      provider: filterProvider,
                      filters: [
                        'Hospital Beds', 'Healthcare Staff', 'Teachers',
                        'Literacy Rate', 'Electricity Access', 'Water Access',
                        'Sanitation', 'Green Space'
                      ],
                    ),

                    const SizedBox(height: 50), // Bottom padding
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Header Text
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Inset Grouped Card containing multiple list items
  Widget _buildGroupedCard({
    required BuildContext context,
    required Color cardColor,
    required bool isDark,
    required SearchFilterProvider provider,
    required List<String> filters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isSelected = provider.activeFilters.contains(filter);
          final isLast = index == filters.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(
                  _getIconForFilter(filter),
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  size: 22,
                ),
                title: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF0A84FF), size: 24)
                    : const SizedBox.shrink(), // Hides checkmark if unselected
                onTap: () => provider.toggleFilter(filter),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 52), // Align divider with text
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}