import 'package:flutter/material.dart';

import '../../../providers/search_filter_provider.dart';
import 'list_view_helpers.dart';

class IndicatorBreakdown extends StatelessWidget {
  final bool isDark;
  final SearchFilterProvider provider;
  final String? selectedLocation;
  final Map<String, Map<String, double>> indicatorScores;
  final Map<String, Map<String, String>> formattedData;

  const IndicatorBreakdown({
    super.key,
    required this.isDark,
    required this.provider,
    required this.selectedLocation,
    required this.indicatorScores,
    required this.formattedData,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedLocation == null) return const SizedBox.shrink();

    // Keep only indicators that have valid data in AT LEAST ONE selected location
    final activeFiltersWithData = provider.activeFilters.where((filter) {
      return formattedData.values.any((locationMetrics) {
        final value = locationMetrics[filter];
        return value != null && value != 'Data Unavailable';
      });
    }).toList();

    // If no data is available
    if (activeFiltersWithData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[500], size: 28),
            const SizedBox(height: 8),
            Text(
              'No data available for the active filter(s) in the selected region(s).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // The Upgraded Breakdown List
    return Column(
      children: activeFiltersWithData.map((filter) {
        double currentScore = indicatorScores[selectedLocation]?[filter] ?? 0.0;

        // Sort locations to create a ranked leaderboard based on their 1-10 score
        List<String> rankedLocations = List.from(provider.selectedLocations);
        rankedLocations.sort((a, b) {
          double scoreA = indicatorScores[a]?[filter] ?? 0.0;
          double scoreB = indicatorScores[b]?[filter] ?? 0.0;
          return scoreB.compareTo(scoreA); // Highest score at the top
        });

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: Icon(
              ListViewHelpers.getIconForFilter(filter),
              color: isDark ? Colors.white : Colors.black,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: currentScore),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedScore, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          animatedScore.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          height: 6,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: animatedScore / 10.0,
                              backgroundColor: isDark
                                  ? Colors.white24
                                  : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                currentScore == 0
                                    ? Colors.red
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            children: [
              Container(
                margin: const EdgeInsets.only(
                  left: 40,
                  right: 0,
                  bottom: 16,
                  top: 4,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPARISON RANKING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loop through the ranked locations and display them
                    ...rankedLocations.asMap().entries.map((entry) {
                      int rank = entry.key + 1;
                      String loc = entry.value;
                      String locData =
                          formattedData[loc]?[filter] ?? 'Data Unavailable';
                      bool isTarget = loc == selectedLocation;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#$rank',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  loc.split(',').first, // Keeps the name short
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isTarget
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isTarget
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              locData,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isTarget
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isTarget
                                    ? const Color(
                                        0xFF0A84FF,
                                      ) // Highlights target metric in Blue
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
