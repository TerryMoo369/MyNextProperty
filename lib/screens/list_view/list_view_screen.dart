import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/search_filter_provider.dart';
import '../../Data/repository.dart';
import '../../services/ScoringService.dart';
import '../../widgets/list_view/indicator_breakdown.dart';
import '../../widgets/list_view/location_map_card.dart';
import '../../widgets/list_view/location_selector.dart';

class ListViewScreen extends StatefulWidget {
  const ListViewScreen({super.key});

  @override
  State<ListViewScreen> createState() => _ListViewScreenState();
}

class _ListViewScreenState extends State<ListViewScreen> {
  final DataRepository _repository = DataRepository();

  Map<String, Map<String, double>> _rawDatabaseData = {}; // db values
  Map<String, Map<String, String>> _formattedData = {};   // Format UI values
  Map<String, Map<String, double>> _indicatorScores = {}; // 1-10 Scores per metric
  Map<String, double> _overallScores = {};                // Average of all active metrics

  bool _isLoading = false;
  String? _selectedBreakdownLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<SearchFilterProvider>(context, listen: false);
    final locations = provider.selectedLocations;

    if (locations.isEmpty) {
      if (mounted) {
        setState(() {
          _rawDatabaseData = {};
          _formattedData = {};
          _overallScores = {};
          _indicatorScores = {};
          _selectedBreakdownLocation = null;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    // Normalize location names for database matching
    List<String> dbStates = locations.map((loc) {
      if (loc.contains('Kuala Lumpur')) return 'W.P. Kuala Lumpur';
      if (loc.contains('Putrajaya')) return 'W.P. Putrajaya';
      if (loc.contains('Labuan')) return 'W.P. Labuan';
      if (loc.contains('Semenanjung Malaysia')) return 'Semenanjung Malaysia';
      if (loc.contains('Kelantan')) return 'Kelantan';
      if (loc.contains('Penang')) return 'Pulau Pinang';
      return loc.split(',').first;
    }).toList();

    // Fetch all datasets concurrently for fast loading
    final results = await Future.wait([
      _repository.getPopulation(dbStates),
      _repository.getEconomyMetrics(dbStates),
      _repository.getCrime(dbStates),
      _repository.getDrugCrime(dbStates),
      _repository.getHealthcare(dbStates),
      _repository.getEducation(dbStates),
      _repository.getUtilities(dbStates),
      _repository.getEnvironment(dbStates)
    ]);

    final pop = results[0];
    final econ = results[1];
    final crime = results[2];
    final drugCrime = results[3];
    final health = results[4];
    final education = results[5];
    final utilities = results[6];
    final environment = results[7];

    Map<String, Map<String, double>> newData = {};
    Map<String, Map<String, String>> newFormattedData = {};

    for (int i = 0; i < locations.length; i++) {
      String rawLoc = locations[i];
      String dbState = dbStates[i];
      newData[rawLoc] = {};
      newFormattedData[rawLoc] = {};

      // Helper to safely extract double from the DB maps
      double getVal(List<Map<String, dynamic>> dbList, String column) {
        final row = dbList.firstWhere(
          // Changed to .contains() to handle API name variations
                (e) => e['state_name'].toString().contains(dbState),
            orElse: () => {}
        );
        return (row[column] as num?)?.toDouble() ?? 0.0;
      }

      // Map all 21 Indicators to their specific Database Columns
      newData[rawLoc]!['Total Population'] = getVal(pop, 'total_population');

      newData[rawLoc]!['Cost of Living (CPI)'] = getVal(econ, 'cpi');
      newData[rawLoc]!['Mean Income'] = getVal(econ, 'mean_income');
      newData[rawLoc]!['Median Income'] = getVal(econ, 'median_income');
      newData[rawLoc]!['Expenditure'] = getVal(econ, 'expenditure');
      newData[rawLoc]!['Poverty Rate'] = getVal(econ, 'poverty_rate');
      newData[rawLoc]!['Income Inequality'] = getVal(econ, 'gini_coefficient');
      newData[rawLoc]!['GDP'] = getVal(econ, 'gdp');
      newData[rawLoc]!['Labour Force'] = getVal(econ, 'labour_force');
      newData[rawLoc]!['Workforce Participation'] = getVal(econ, 'participation_rate');
      newData[rawLoc]!['Unemployment Rate'] = getVal(econ, 'unemployment');

      newData[rawLoc]!['General Crime'] = getVal(crime, 'total_crimes');
      newData[rawLoc]!['Drug Crime'] = getVal(drugCrime, 'total_drug_cases');

      newData[rawLoc]!['Hospital Beds'] = getVal(health, 'total_beds');
      newData[rawLoc]!['Healthcare Staff'] = getVal(health, 'total_staff');

      newData[rawLoc]!['Teachers'] = getVal(education, 'total_teachers');
      newData[rawLoc]!['Literacy Rate'] = getVal(education, 'literacy_rate');

      newData[rawLoc]!['Electricity Access'] = getVal(utilities, 'electricity_access');
      newData[rawLoc]!['Water Access'] = getVal(utilities, 'water_access');
      newData[rawLoc]!['Sanitation'] = getVal(utilities, 'sanitation_access');

      newData[rawLoc]!['Green Space'] = getVal(environment, 'green_space_area');

      // Format the raw values immediately for the UI
      for(var filter in SearchFilterProvider.availableFilters) {
        double val = newData[rawLoc]![filter] ?? 0.0;
        newFormattedData[rawLoc]![filter] = ScoringService.formatRawData(filter, val);
      }
    }

    _rawDatabaseData = newData;
    _formattedData = newFormattedData;
    _calculateScores(provider, locations);

    if (_selectedBreakdownLocation == null || !locations.contains(_selectedBreakdownLocation)) {
      _selectedBreakdownLocation = locations.isNotEmpty ? locations.first : null;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _calculateScores(SearchFilterProvider provider, List<String> locations) {
    _overallScores.clear();
    _indicatorScores.clear();

    // Setup empty maps
    for (var loc in locations) {
      _indicatorScores[loc] = {};
    }

    final activeFilters = provider.activeFilters;

    // Score each metric relatively across all selected locations
    for (var filter in activeFilters) {
      // Extract the raw values for this specific filter across all locations
      Map<String, double> filterValuesToCompare = {};
      for (var loc in locations) {
        filterValuesToCompare[loc] = _rawDatabaseData[loc]?[filter] ?? 0.0;
      }

      // Delegate to the industrial scoring service
      Map<String, double> normalizedScores = ScoringService.calculateNormalizedScores(filter, filterValuesToCompare);

      // Save the generated scores
      for (var loc in locations) {
        _indicatorScores[loc]![filter] = normalizedScores[loc] ?? 0.0;
      }
    }

    // Calculate the Overall Location Score (Average of all active filter scores)
    for (var loc in locations) {
      double totalScore = 0;
      int count = 0;

      for (var filter in activeFilters) {
        double score = _indicatorScores[loc]![filter] ?? 0.0;
        if (score > 0) { // Only average metrics that actually have data
          totalScore += score;
          count++;
        }
      }
      _overallScores[loc] = count > 0 ? (totalScore / count) : 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SearchFilterProvider>(
        builder: (context, provider, child) {
          final locations = provider.selectedLocations;

          // Re-fetch data if locations are added/removed from the Explore Panel
          if (locations.length != _rawDatabaseData.length && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
          }

          // Re-calculate scores dynamically if filters change in the Bottom Sheet
          if (!_isLoading && locations.isNotEmpty) {
            _calculateScores(provider, locations);
          }

          return ListView(
            padding: const EdgeInsets.only(top: 110, bottom: 120, left: 20, right: 20),
            children: [
              Text(
                'Location Score',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              LocationMapCard(
                isDark: isDark,
                locations: locations,
                overallScores: _overallScores,
                selectedLocation: _selectedBreakdownLocation,
              ),
              const SizedBox(height: 20),
              if (locations.isNotEmpty) ...[
                LocationSelector(
                  isDark: isDark,
                  locations: locations,
                  selectedLocation: _selectedBreakdownLocation,
                  onLocationSelected: (loc) => setState(() => _selectedBreakdownLocation = loc),
                ),
                const SizedBox(height: 20),
                IndicatorBreakdown(
                  isDark: isDark,
                  provider: provider,
                  selectedLocation: _selectedBreakdownLocation,
                  indicatorScores: _indicatorScores,
                  formattedData: _formattedData, // Passes the beautiful strings instead of raw doubles
                ),
              ]
            ],
          );
        }
    );
  }
}