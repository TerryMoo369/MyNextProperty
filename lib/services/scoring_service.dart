import 'dart:math';

class ScoringService {
  /// Determines if a higher value is GOOD (true) or BAD (false).
  static bool isPositiveIndicator(String filter) {
    const negativeIndicators = [
      'Cost of Living (CPI)',
      'Expenditure',
      'Poverty Rate',
      'Income Inequality',
      'Unemployment Rate',
      'General Crime',
      'Drug Crime',
    ];
    return !negativeIndicators.contains(filter);
  }

  /// Formats raw database numbers into beautiful, human-readable strings.
  static String formatRawData(String filter, double value) {
    if (value == 0) return 'Data Unavailable';

    switch (filter) {
      case 'Mean Income':
      case 'Median Income':
      case 'Expenditure':
        return 'RM ${_compact(value)}';
      case 'GDP':
        return 'RM ${_compact(value)}';
      case 'Poverty Rate':
      case 'Unemployment Rate':
      case 'Workforce Participation':
      case 'Literacy Rate':
      case 'Electricity Access':
      case 'Water Access':
      case 'Sanitation':
        return '${value.toStringAsFixed(1)}%';
      case 'Income Inequality':
        return value.toStringAsFixed(3); // Gini coefficient is usually 0.xxx
      case 'Total Population':
        // The dataset stores population in '000s, so we multiply by 1000
        return _compact(value * 1000);
      case 'Green Space':
        return '${_compact(value)} Hectares';
      default:
        // Crimes, Beds, Staff, Teachers, Labour force
        return _compact(value);
    }
  }

  /// Calculates a relative score from 1.0 to 10.0 based on min/max of selected locations.
  static Map<String, double> calculateNormalizedScores(
    String filter,
    Map<String, double> rawValues,
  ) {
    final scores = <String, double>{};
    if (rawValues.isEmpty) return scores;

    // Filter out missing data (0.0) for the min/max calculation
    final validValues = rawValues.values.where((v) => v > 0).toList();
    if (validValues.isEmpty) {
      for (var key in rawValues.keys) {
        scores[key] = 0.0;
      }
      return scores;
    }

    double minVal = validValues.reduce(min);
    double maxVal = validValues.reduce(max);
    bool isPositive = isPositiveIndicator(filter);

    for (var entry in rawValues.entries) {
      String loc = entry.key;
      double val = entry.value;

      if (val == 0) {
        scores[loc] = 0.0; // No score for missing data
        continue;
      }

      if (maxVal == minVal) {
        scores[loc] =
            7.5; // If all selected states are exactly equal, give a good baseline score
      } else {
        // Min-Max Normalization mapped to 1 - 10 scale
        double normalized;
        if (isPositive) {
          normalized = 1 + 9 * ((val - minVal) / (maxVal - minVal));
        } else {
          normalized = 1 + 9 * ((maxVal - val) / (maxVal - minVal));
        }
        scores[loc] = normalized;
      }
    }

    return scores;
  }

  /// Helper to compact large numbers (e.g. 1500000 -> 1.5M)
  static String _compact(double val) {
    if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}
