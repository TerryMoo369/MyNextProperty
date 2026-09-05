import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../providers/search_filter_provider.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  List<Polygon> statePolygons = [];

  //Use to get the destination
  LatLng? startPoint;

  double? ron95Price;

  String? startStateName;

  List<dynamic>? _cachedGeoJsonFeatures;

  final Map<String, LatLng> destinationPoints = {};

  final Map<String, String> destinationStates = {};

  final Map<String, List<LatLng>> destinationRoutes = {};

  final Map<String, double> destinationDistances = {};

  final Map<String, double> destinationFuelCosts = {};

  final Set<String> _processedDestinations = {};

  Set<String> selectedStateNames = {};
  final Geocoding _geocoding = Geocoding();

  final DataRepository _repository = DataRepository();

  String? _lastProcessedLocation;
  String? _lastProcessedFilter;

  Map<String, double> _currentFilterValues = {};
  int processingCount = 0;

  bool get isProcessingMap => processingCount > 0;

  @override
  void initState() {
    super.initState();
    _loadFuelPrice();
  }

  String _normalizeStateName(String stateName) {
    final String name = stateName.toLowerCase().trim();

    if (name.contains('kuala lumpur')) {
      return 'W.P. Kuala Lumpur';
    }

    if (name.contains('putrajaya')) {
      return 'W.P. Putrajaya';
    }

    if (name.contains('labuan')) {
      return 'W.P. Labuan';
    }

    if (name.contains('penang') || name.contains('pulau pinang')) {
      return 'Pulau Pinang';
    }

    if (name.contains('johor')) {
      return 'Johor';
    }

    if (name.contains('kedah')) {
      return 'Kedah';
    }

    if (name.contains('kelantan')) {
      return 'Kelantan';
    }

    if (name.contains('melaka') || name.contains('malacca')) {
      return 'Melaka';
    }

    if (name.contains('negeri sembilan')) {
      return 'Negeri Sembilan';
    }

    if (name.contains('pahang')) {
      return 'Pahang';
    }

    if (name.contains('perak')) {
      return 'Perak';
    }

    if (name.contains('perlis')) {
      return 'Perlis';
    }

    if (name.contains('sabah')) {
      return 'Sabah';
    }

    if (name.contains('sarawak')) {
      return 'Sarawak';
    }

    if (name.contains('selangor')) {
      return 'Selangor';
    }

    if (name.contains('terengganu')) {
      return 'Terengganu';
    }

    return stateName;
  }

  void _calculateAllFuelCosts() {
    if (ron95Price == null) {
      return;
    }

    const double fuelConsumption = 7.0;
    // 7 litres per 100 km

    final Map<String, double> costs = {};

    for (final entry in destinationDistances.entries) {
      final String destinationName = entry.key;
      final double distanceKm = entry.value;

      final double litresUsed = (distanceKm / 100) * fuelConsumption;

      final double fuelCost = litresUsed * ron95Price!;

      costs[destinationName] = fuelCost;

      print('===== FUEL COST =====');
      print('Destination: $destinationName');
      print('Distance: ${distanceKm.toStringAsFixed(2)} km');
      print('Fuel Used: ${litresUsed.toStringAsFixed(2)} L');
      print('Estimated Cost: RM ${fuelCost.toStringAsFixed(2)}');
    }

    if (!mounted) return;

    setState(() {
      destinationFuelCosts
        ..clear()
        ..addAll(costs);
    });
  }

  Future<void> _loadFuelPrice() async {
    try {
      final result = await _repository.getFuelPrice();

      if (result.isEmpty) {
        print('No fuel price found');
        return;
      }

      final row = result.first;

      final double? price = (row['ron95'] as num?)?.toDouble();

      if (price == null) {
        print('RON95 price unavailable');
        return;
      }

      setState(() {
        ron95Price = price;
      });

      print('===== RON95 PRICE =====');
      print('RM $ron95Price / L');

      _calculateAllFuelCosts();
    } catch (e) {
      print('===== FUEL PRICE ERROR =====');
      print(e);
    }
  }

  Future<List<dynamic>> _getGeoJsonFeatures() async {
    if (_cachedGeoJsonFeatures != null) {
      return _cachedGeoJsonFeatures!;
    }

    final String jsonString = await rootBundle.loadString(
      'assets/geo/malaysia_states.geojson',
    );

    final Map<String, dynamic> geoJson = jsonDecode(jsonString);

    _cachedGeoJsonFeatures = geoJson['features'] as List<dynamic>;

    return _cachedGeoJsonFeatures!;
  }

  Future<String?> _findStateFromPoint(LatLng point) async {
    final List<dynamic> features = await _getGeoJsonFeatures();

    for (final feature in features) {
      final String stateName = feature['properties']['state_name'];

      final List<dynamic> multiPolygon = feature['geometry']['coordinates'];

      for (final polygon in multiPolygon) {
        final List<dynamic> outerRing = polygon[0];

        if (_isPointInsidePolygon(point, outerRing)) {
          return stateName;
        }
      }
    }

    return null;
  }

  bool _isPointInsidePolygon(LatLng point, List<dynamic> polygon) {
    bool inside = false;

    final double x = point.longitude;
    final double y = point.latitude;

    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final double xi = polygon[i][0].toDouble();

      final double yi = polygon[i][1].toDouble();

      final double xj = polygon[j][0].toDouble();

      final double yj = polygon[j][1].toDouble();

      final bool intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);

      if (intersect) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }

  void _updateSelectedStates() {
    selectedStateNames.clear();

    if (startStateName != null && startStateName!.isNotEmpty) {
      selectedStateNames.add(startStateName!);
    }

    for (final stateName in destinationStates.values) {
      if (stateName.isNotEmpty) {
        selectedStateNames.add(stateName);
      }
    }
  }

  Future<void> _loadLocationFromProvider(String locationName) async {
    try {
      if (mounted) {
        setState(() {
          processingCount++;
        });
      }
      final List<Location> locations = await _geocoding.locationFromAddress(
        locationName,
      );

      if (locations.isEmpty) {
        print('Provider location not found');
        return;
      }

      final Location location = locations.first;

      final LatLng point = LatLng(location.latitude, location.longitude);

      final String? stateName = await _findStateFromPoint(point);

      if (stateName == null) {
        print('Provider state not found from GeoJSON');
        return;
      }

      if (!mounted) return;

      setState(() {
        startPoint = point;
        startStateName = stateName;

        _updateSelectedStates();
      });

      print('===== PROVIDER SOURCE =====');
      print('Location: $locationName');
      print('State: $stateName');
      print('Point: $startPoint');

      await _loadStatePolygons();
      for (final entry in destinationPoints.entries) {
        await _loadRouteForDestination(entry.key, entry.value);
      }
    } catch (e) {
      print('===== PROVIDER LOCATION ERROR =====');
      print(e);
    } finally {
      if (mounted) {
        setState(() {
          if (processingCount > 0) {
            processingCount--;
          }
        });
      }
    }
  }

  Future<void> _loadDestinationFromProvider(String locationName) async {
    try {
      if (mounted) {
        setState(() {
          processingCount++;
        });
      }
      final List<Location> locations = await _geocoding.locationFromAddress(
        locationName,
      );

      if (locations.isEmpty) {
        print('Destination not found: $locationName');
        return;
      }

      final Location location = locations.first;

      final LatLng point = LatLng(location.latitude, location.longitude);

      final String? stateName = await _findStateFromPoint(point);

      if (stateName == null) {
        print('Destination state not found from GeoJSON: $locationName');
        return;
      }

      if (!mounted) return;

      setState(() {
        destinationPoints[locationName] = point;

        destinationStates[locationName] = stateName;

        _updateSelectedStates();
      });

      print('===== PROVIDER DESTINATION =====');
      print('Location: $locationName');
      print('State: $stateName');
      print('Point: ${destinationPoints[locationName]}');

      await _loadStatePolygons();

      await _loadRouteForDestination(locationName, point);
    } catch (e) {
      print('===== DESTINATION ERROR =====');
      print(e);
    } finally {
      if (mounted) {
        setState(() {
          if (processingCount > 0) {
            processingCount--;
          }
        });
      }
    }
  }

  Future<void> _loadRouteForDestination(
    String destinationName,
    LatLng destination,
  ) async {
    if (startPoint == null) {
      return;
    }

    try {
      final LatLng start = startPoint!;

      final Uri url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Route request failed: $destinationName');
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        print('Route not found: $destinationName');
        return;
      }

      final route = data['routes'][0];

      final List<dynamic> coordinates = route['geometry']['coordinates'];

      final List<LatLng> points = [];

      for (final coordinate in coordinates) {
        points.add(LatLng(coordinate[1].toDouble(), coordinate[0].toDouble()));
      }

      final double distanceKm = (route['distance'] as num).toDouble() / 1000;

      if (!mounted) return;

      setState(() {
        destinationRoutes[destinationName] = points;
        destinationDistances[destinationName] = distanceKm;
      });

      _calculateAllFuelCosts();

      print('===== ROUTE =====');
      print('Destination: $destinationName');
      print('Distance: ${distanceKm.toStringAsFixed(2)} km');
    } catch (e) {
      print('===== ROUTE ERROR =====');
      print(e);
    }
  }

  Future<void> _loadFilterData(String filter) async {
    try {
      final features = await _getGeoJsonFeatures();

      // Get all Malaysia states from GeoJSON
      final List<String> states = features
          .map<String>(
            (feature) => feature['properties']['state_name'].toString(),
          )
          .toList();

      List<Map<String, dynamic>> rows = [];
      String valueColumn = '';

      switch (filter) {
        // =========================
        // Population
        // =========================
        case 'Total Population':
          rows = await _repository.getPopulation(states);
          valueColumn = 'total_population';
          break;

        // =========================
        // Economy
        // =========================
        case 'Cost of Living (CPI)':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'cpi';
          break;

        case 'Mean Income':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'mean_income';
          break;

        case 'Median Income':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'median_income';
          break;

        case 'Expenditure':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'expenditure';
          break;

        case 'Poverty Rate':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'poverty_rate';
          break;

        case 'Income Inequality':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'gini_coefficient';
          break;

        case 'GDP':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'gdp';
          break;

        case 'Labour Force':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'labour_force';
          break;

        case 'Workforce Participation':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'participation_rate';
          break;

        case 'Unemployment Rate':
          rows = await _repository.getEconomyMetrics(states);
          valueColumn = 'unemployment';
          break;

        // =========================
        // Crime
        // =========================
        case 'General Crime':
          rows = await _repository.getCrime(states);
          valueColumn = 'total_crimes';
          break;

        case 'Drug Crime':
          rows = await _repository.getDrugCrime(states);
          valueColumn = 'total_drug_cases';
          break;

        // =========================
        // Healthcare
        // =========================
        case 'Hospital Beds':
          rows = await _repository.getHealthcare(states);
          valueColumn = 'total_beds';
          break;

        case 'Healthcare Staff':
          rows = await _repository.getHealthcare(states);
          valueColumn = 'total_staff';
          break;

        // =========================
        // Education
        // =========================
        case 'Teachers':
          rows = await _repository.getEducation(states);
          valueColumn = 'total_teachers';
          break;

        case 'Literacy Rate':
          rows = await _repository.getEducation(states);
          valueColumn = 'literacy_rate';
          break;

        // =========================
        // Utilities
        // =========================
        case 'Electricity Access':
          rows = await _repository.getUtilities(states);
          valueColumn = 'electricity_access';
          break;

        case 'Water Access':
          rows = await _repository.getUtilities(states);
          valueColumn = 'water_access';
          break;

        case 'Sanitation':
          rows = await _repository.getUtilities(states);
          valueColumn = 'sanitation_access';
          break;

        // =========================
        // Environment
        // =========================
        case 'Green Space':
          rows = await _repository.getEnvironment(states);
          valueColumn = 'green_space_area';
          break;

        default:
          print('Unknown map filter: $filter');
          return;
      }

      final Map<String, double> values = {};

      for (final row in rows) {
        final dynamic rawValue = row[valueColumn];

        if (rawValue != null) {
          values[row['state_name'].toString()] = (rawValue as num).toDouble();
        }
      }

      _currentFilterValues = values;

      print('===== MAP FILTER =====');
      print('Filter: $filter');
      print('Column: $valueColumn');
      print('Values: $_currentFilterValues');

      await _loadStatePolygons();
    } catch (e) {
      print('===== FILTER ERROR =====');
      print('Filter: $filter');
      print(e);
    }
  }

  Future<void> _loadStatePolygons() async {
    try {
      final List<dynamic> features = await _getGeoJsonFeatures();

      final Map<String, double> valueByState = _currentFilterValues;

      if (valueByState.isEmpty) {
        return;
      }

      final double minValue = valueByState.values.reduce(
        (a, b) => a < b ? a : b,
      );

      final double maxValue = valueByState.values.reduce(
        (a, b) => a > b ? a : b,
      );

      final List<Polygon> polygons = [];

      for (final feature in features) {
        final String stateName = feature['properties']['state_name'];

        final bool isSelected = selectedStateNames.contains(stateName);

        final double? value = valueByState[stateName];

        double normalizedValue = 0;

        if (value != null && maxValue != minValue) {
          normalizedValue = (value - minValue) / (maxValue - minValue);
        }

        final List<dynamic> multiPolygon = feature['geometry']['coordinates'];

        for (final polygon in multiPolygon) {
          final outerRing = polygon[0];

          final List<LatLng> points = [];

          for (final coordinate in outerRing) {
            final double longitude = coordinate[0].toDouble();

            final double latitude = coordinate[1].toDouble();

            points.add(LatLng(latitude, longitude));
          }

          polygons.add(
            Polygon(
              points: points,
              borderColor: isSelected ? const Color(0xFFFFC107) : Colors.black,

              borderStrokeWidth: isSelected ? 3 : 1,
              label: stateName,
              color: value == null
                  ? Colors.grey.withValues(alpha: 0.4)
                  : Color.lerp(
                      Colors.cyan,
                      Colors.red,
                      normalizedValue,
                    )!.withValues(alpha: 0.45),
            ),
          );
        }
      }

      setState(() {
        statePolygons = polygons;
      });
    } catch (e) {
      print('===== GEOJSON ERROR =====');
      print(e);
    }
  }

  Widget _buildMapLegend(String selectedFilter, bool isDark) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.85)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Map Filter',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            selectedFilter,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          // Color gradient
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              gradient: const LinearGradient(colors: [Colors.cyan, Colors.red]),
            ),
          ),

          const SizedBox(height: 5),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('High', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Container(
                width: 18,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Selected state',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterProvider = Provider.of<SearchFilterProvider>(context);

    final selectedLocations = filterProvider.selectedLocations;

    final String selectedFilter = filterProvider.activeFilters.first;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_lastProcessedFilter != selectedFilter) {
      _lastProcessedFilter = selectedFilter;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFilterData(selectedFilter);
      });
    }

    if (selectedLocations.isEmpty && startPoint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          startPoint = null;
          startStateName = null;
          _lastProcessedLocation = null;
          _updateSelectedStates();
        });

        _loadStatePolygons();
      });
    }
    final currentDestinations = selectedLocations.skip(1).toSet();

    final removedDestinations = destinationPoints.keys
        .where((name) => !currentDestinations.contains(name))
        .toList();

    if (removedDestinations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          for (final name in removedDestinations) {
            destinationPoints.remove(name);
            destinationStates.remove(name);
            destinationRoutes.remove(name);
            destinationDistances.remove(name);
            destinationFuelCosts.remove(name);
            _processedDestinations.remove(name);
          }

          _updateSelectedStates();
        });

        _loadStatePolygons();
      });
    }

    print('===== MAP SEARCH LOCATIONS =====');
    print(selectedLocations);

    print('===== MAP SEARCH LOCATIONS =====');
    print(selectedLocations);

    if (selectedLocations.isNotEmpty) {
      final String location = selectedLocations.first;

      if (_lastProcessedLocation != location) {
        _lastProcessedLocation = location;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadLocationFromProvider(location);
        });
      }
    }

    if (selectedLocations.length > 1) {
      final destinations = selectedLocations.skip(1).toList();

      for (final destination in destinations) {
        if (!_processedDestinations.contains(destination)) {
          _processedDestinations.add(destination);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadDestinationFromProvider(destination);
          });
        }
      }
    }
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(4.2105, 101.9758),
                    initialZoom: 6,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.myapp',
                    ),

                    PolygonLayer(polygons: statePolygons),

                    PolylineLayer(
                      polylines: destinationRoutes.values
                          .map(
                            (points) => Polyline(
                              points: points,
                              strokeWidth: 4,
                              color: Colors.deepOrange,
                            ),
                          )
                          .toList(),
                    ),

                    MarkerLayer(
                      markers: [
                        // Source
                        if (startPoint != null)
                          Marker(
                            point: startPoint!,
                            width: 45,
                            height: 45,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.green,
                              size: 45,
                            ),
                          ),
                        // Multiple Destinations
                        ...destinationPoints.entries.map((entry) {
                          final String destinationName = entry.key;

                          final double? distance =
                              destinationDistances[destinationName];

                          final double? fuelCost =
                              destinationFuelCosts[destinationName];

                          return Marker(
                            point: entry.value,
                            width: 45,
                            height: 45,

                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,

                              offset: const Offset(0, -80),

                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  enabled: false,
                                  child: SizedBox(
                                    width: 190,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          destinationName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          distance != null
                                              ? 'Distance: ${distance.toStringAsFixed(2)} km'
                                              : 'Distance: Calculating...',
                                        ),

                                        const SizedBox(height: 4),

                                        Text(
                                          fuelCost != null
                                              ? 'Estimated Fuel: RM ${fuelCost.toStringAsFixed(2)}'
                                              : 'Fuel Cost: Calculating...',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                // Map Filter Legend
                Positioned(
                  left: 16,
                  bottom: 120,
                  child: _buildMapLegend(selectedFilter, isDark),
                ),

                // Processing notification
                if (isProcessingMap)
                  Positioned(
                    top: 80,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Processing route...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
