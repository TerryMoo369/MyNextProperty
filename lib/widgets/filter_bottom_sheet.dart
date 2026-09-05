import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for Haptic Feedback
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
              // DRAG HANDLE
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // TOP HEADER BAR (Cleaned up)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                    // Title
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

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

              // ACTION BUTTONS (Reset & Select All)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: 'Reset',
                        icon: Icons.refresh,
                        isDark: isDark,
                        isPrimary: false,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          filterProvider.resetFilters();
                        },
                      ),
                    ),
                    if (!filterProvider.isMapView) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Select All',
                          icon: Icons.checklist,
                          isDark: isDark,
                          isPrimary: true,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            filterProvider.selectAllFilters();
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // MAP VIEW WARNING BANNER
              if (filterProvider.isMapView)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0A84FF).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF0A84FF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Map View allows only one filter selection at a time for visual clarity.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

  // Stylish Action Buttons for Reset / Select All
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF0A84FF).withOpacity(0.15)
              : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? const Color(0xFF0A84FF)
                  : (isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPrimary
                    ? const Color(0xFF0A84FF)
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header Text
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.grey.shade500,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isSelected = provider.activeFilters.contains(filter);
          final isLast = index == filters.length - 1;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0A84FF).withOpacity(0.15)
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconForFilter(filter),
                    color: isSelected
                        ? const Color(0xFF0A84FF)
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    size: 20,
                  ),
                ),
                title: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                trailing: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: const Icon(Icons.check_circle, color: Color(0xFF0A84FF), size: 24),
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.toggleFilter(filter);
                },
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 60), // Align divider perfectly with text
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