import 'package:flutter/material.dart';
import 'package:mynextproperty/services/geo_location_service.dart';
import 'package:mynextproperty/utils/list_view/list_view_helpers.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../providers/search_filter_provider.dart';
import '../../Data/repository.dart';
import '../../widgets/list_view/location_map_card.dart';

enum GraphMode { bar, pie }

class GraphViewScreen extends StatefulWidget {
  const GraphViewScreen({super.key});

  @override
  State<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends State<GraphViewScreen> {
  final GeoLocationService _geoLocationService = GeoLocationService();
  final DataRepository _repository = DataRepository();

  final TooltipBehavior _tooltipBehavior = TooltipBehavior(
    enable: true,
    tooltipPosition: TooltipPosition.pointer,
  );
  final SelectionBehavior _selectionBehavior = SelectionBehavior(enable: true);
  Map<String, Map<String, double>> _categoryStats = {};

  bool _isLoading = false;
  int _loadedLocations = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<SearchFilterProvider>(
          context,
          listen: false,
        );
        _fetchData(provider);
      }
    });
  }

  Future<void> _fetchData(SearchFilterProvider provider) async {
    if (!mounted) return;

    final locations = provider.selectedLocations;

    if (locations.isEmpty) {
      if (mounted) {
        setState(() {
          _categoryStats = {};
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    List<String> states = [
      for (final loc in locations)
        await _geoLocationService.getStateFromAddress(loc),
    ].nonNulls.toList();
    Map<String, Map<String, double>> temp = {};

    temp["Total Population"] = {
      for (var item in await _repository.getPopulation(states))
        item["state_name"]: (item["total_population"] as num).toDouble(),
    };
    temp["Cost of Living (CPI)"] = {};
    temp['Mean Income'] = {};
    temp['Median Income'] = {};
    temp['Expenditure'] = {};
    temp['Poverty Rate'] = {};
    temp['Income Inequality'] = {};
    temp['GDP'] = {};
    temp['Labour Force'] = {};
    temp['Workforce Participation'] = {};
    temp['Unemployment Rate'] = {};
    for (var item in await _repository.getEconomyMetrics(states)) {
      temp["Cost of Living (CPI)"]![item["state_name"]] =
          (item["cpi"] as num?)?.toDouble() ?? 0.0;
      temp["Mean Income"]![item["state_name"]] =
          (item["mean_income"] as num?)?.toDouble() ?? 0.0;
      temp["Median Income"]![item["state_name"]] =
          (item["median_income"] as num?)?.toDouble() ?? 0.0;
      temp["Expenditure"]![item["state_name"]] =
          (item["expenditure"] as num?)?.toDouble() ?? 0.0;
      temp["Poverty Rate"]![item["state_name"]] =
          (item["poverty_rate"] as num?)?.toDouble() ?? 0.0;
      temp["Income Inequality"]![item["state_name"]] =
          (item["gini_coefficient"] as num?)?.toDouble() ?? 0.0;
      temp["GDP"]![item["state_name"]] =
          (item["gdp"] as num?)?.toDouble() ?? 0.0;
      temp["Labour Force"]![item["state_name"]] =
          (item["labour_force"] as num?)?.toDouble() ?? 0.0;
      temp["Workforce Participation"]![item["state_name"]] =
          (item["participation_rate"] as num?)?.toDouble() ?? 0.0;
      temp["Unemployment Rate"]![item["state_name"]] =
          (item["unemployment"] as num?)?.toDouble() ?? 0.0;
    }
    temp["General Crime"] = {
      for (var item in await _repository.getCrime(states))
        item["state_name"]: (item["total_crimes"] as num).toDouble(),
    };
    temp["Drug Crime"] = {
      for (var item in await _repository.getDrugCrime(states))
        item["state_name"]: (item["total_drug_cases"] as num).toDouble(),
    };
    temp["Hospital Beds"] = {};
    temp["Healthcare Staff"] = {};
    for (var item in await _repository.getHealthcare(states)) {
      temp["Hospital Beds"]![item["state_name"]] =
          (item["total_beds"] as num?)?.toDouble() ?? 0.0;
      temp["Healthcare Staff"]![item["state_name"]] =
          (item["total_staff"] as num?)?.toDouble() ?? 0.0;
    }
    temp["Teachers"] = {};
    temp["Literacy Rate"] = {};
    for (var item in await _repository.getHealthcare(states)) {
      temp["Teachers"]![item["state_name"]] =
          (item["total_teachers"] as num?)?.toDouble() ?? 0.0;
      temp["Literacy Rate"]![item["state_name"]] =
          (item["literacy_rate"] as num?)?.toDouble() ?? 0.0;
    }
    temp["Electricity Access"] = {};
    temp["Water Access"] = {};
    temp["Sanitation"] = {};
    for (var item in await _repository.getHealthcare(states)) {
      temp["Electricity Access"]![item["state_name"]] =
          (item["electricity_access"] as num?)?.toDouble() ?? 0.0;
      temp["Water Access"]![item["state_name"]] =
          (item["water_access"] as num?)?.toDouble() ?? 0.0;
      temp["Sanitation"]![item["state_name"]] =
          (item["sanitation_access"] as num?)?.toDouble() ?? 0.0;
    }
    temp["Green Space"] = {
      for (var item in await _repository.getEnvironment(states))
        item["state_name"]: (item["green_space_area"] as num).toDouble(),
    };

    if (mounted) {
      setState(() {
        _categoryStats = temp;
        _isLoading = false;
        _loadedLocations = states.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SearchFilterProvider>(
      builder: (context, provider, child) {
        final locations = provider.selectedLocations;

        if (locations.length != _loadedLocations && !_isLoading) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fetchData(provider),
          );
        }

        List<SfCartesianChart> barCharts = [];

        for (var filter in provider.activeFilters) {
          barCharts.add(
            SfCartesianChart(
              title: ChartTitle(text: filter),
              primaryXAxis: CategoryAxis(title: AxisTitle(text: "States")),
              tooltipBehavior: _tooltipBehavior,
              series: [
                ColumnSeries<MapEntry<String, double>, String>(
                  name: "States",
                  dataSource: _categoryStats[filter]?.entries.toList() ?? [],
                  xValueMapper: (item, _) => item.key,
                  yValueMapper: (item, _) => item.value,
                  pointColorMapper: (_, i) =>
                      ListViewHelpers.getColorForIndex(i),
                  selectionBehavior: _selectionBehavior,
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(
            top: 110,
            bottom: 120,
            left: 20,
            right: 20,
          ),
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
              overallScores: {},
              selectedLocation: null,
            ),
            if (locations.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...barCharts,
            ],
          ],
        );
      },
    );
  }
}
