import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mynextproperty/Data/repository.dart';
import 'package:mynextproperty/services/dataSync_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/search_filter_provider.dart';
import 'package:mynextproperty/Data/Dataset.dart';

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

  final DataSyncService _syncService = DataSyncService();
  final DataRepository _repository = DataRepository();

  String? _lastProcessedLocation;
  int processingCount = 0;
  bool get isProcessingMap =>
      processingCount > 0;


  @override
  void initState() {
    super.initState();

    _loadStatePolygons();
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

    if (name.contains('penang') ||
        name.contains('pulau pinang')) {
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

    if (name.contains('melaka') ||
        name.contains('malacca')) {
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

  Future<List<dynamic>> _getGeoJsonFeatures() async {
    if (_cachedGeoJsonFeatures != null) {
      return _cachedGeoJsonFeatures!;
    }

    final String jsonString = await rootBundle.loadString(
      'assets/geo/malaysia_states.geojson',
    );

    final Map<String, dynamic> geoJson =
    jsonDecode(jsonString);

    _cachedGeoJsonFeatures =
    geoJson['features'] as List<dynamic>;

    return _cachedGeoJsonFeatures!;
  }

  Future<String?> _findStateFromPoint(LatLng point) async {
    final List<dynamic> features =
    await _getGeoJsonFeatures();

    for (final feature in features) {
      final String stateName =
      feature['properties']['state_name'];

      final List<dynamic> multiPolygon =
      feature['geometry']['coordinates'];

      for (final polygon in multiPolygon) {
        final List<dynamic> outerRing = polygon[0];

        if (_isPointInsidePolygon(
          point,
          outerRing,
        )) {
          return stateName;
        }
      }
    }

    return null;
  }

  bool _isPointInsidePolygon(
      LatLng point,
      List<dynamic> polygon,
      ) {
    bool inside = false;

    final double x = point.longitude;
    final double y = point.latitude;

    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final double xi =
      polygon[i][0].toDouble();

      final double yi =
      polygon[i][1].toDouble();

      final double xj =
      polygon[j][0].toDouble();

      final double yj =
      polygon[j][1].toDouble();

      final bool intersect =
          ((yi > y) != (yj > y)) &&
              (x <
                  (xj - xi) *
                      (y - yi) /
                      (yj - yi) +
                      xi);

      if (intersect) {
        inside = !inside;
      }

      j = i;
    }

    return inside;
  }


  void _updateSelectedStates() {
    selectedStateNames.clear();

    if (startStateName != null &&
        startStateName!.isNotEmpty) {
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
      final List<Location> locations =
      await _geocoding.locationFromAddress(locationName);

      if (locations.isEmpty) {
        print('Provider location not found');
        return;
      }

      final Location location = locations.first;

      final LatLng point = LatLng(
        location.latitude,
        location.longitude,
      );

      final String? stateName =
      await _findStateFromPoint(point);

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
        await _loadRouteForDestination(
          entry.key,
          entry.value,
        );
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

  Future<void> _loadDestinationFromProvider(String locationName,) async {
    try {
      if (mounted) {
        setState(() {
          processingCount++;
        });
      }
      final List<Location> locations =
      await _geocoding.locationFromAddress(locationName);

      if (locations.isEmpty) {
        print('Destination not found: $locationName');
        return;
      }

      final Location location = locations.first;

      final LatLng point = LatLng(
        location.latitude,
        location.longitude,
      );

      final String? stateName =
      await _findStateFromPoint(point);

      if (stateName == null) {
        print(
          'Destination state not found from GeoJSON: $locationName',
        );
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


      await _loadRouteForDestination(
        locationName,
          point,);
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

  Future<void> _loadRouteForDestination(String destinationName,
      LatLng destination,) async {
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

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        print('Route not found: $destinationName');
        return;
      }

      final route = data['routes'][0];

      final List<dynamic> coordinates =
      route['geometry']['coordinates'];

      final List<LatLng> points = [];

      for (final coordinate in coordinates) {
        points.add(
          LatLng(
            coordinate[1].toDouble(),
            coordinate[0].toDouble(),
          ),
        );
      }

      final double distanceKm =
          (route['distance'] as num).toDouble() / 1000;

      if (!mounted) return;

      setState(() {
        destinationRoutes[destinationName] = points;
        destinationDistances[destinationName] = distanceKm;
      });

      print('===== ROUTE =====');
      print('Destination: $destinationName');
      print('Distance: ${distanceKm.toStringAsFixed(2)} km');
    } catch (e) {
      print('===== ROUTE ERROR =====');
      print(e);
    }
  }

  Future<void> _loadStatePolygons() async {
    try {
      final List<dynamic> features =
      await _getGeoJsonFeatures();

      final populationData =
      await _repository.getMapPopulationData();

      final Map<String, double> populationByState = {};

      for (final row in populationData) {
        final String stateName =
        row['state_name'].toString();

        final double population =
        (row['population_000'] as num).toDouble();

        populationByState[stateName] = population;
      }

      final double minPopulation =
      populationByState.values.reduce(
            (a, b) => a < b ? a : b,
      );

      final double maxPopulation =
      populationByState.values.reduce(
            (a, b) => a > b ? a : b,
      );

      print('Min Population: $minPopulation');
      print('Max Population: $maxPopulation');

      print('===== DATABASE + GEOJSON =====');
      print(populationByState);

      final List<Polygon> polygons = [];

      for (final feature in features) {
        final String stateName =
        feature['properties']['state_name'];

        final bool isSelected =
        selectedStateNames.contains(stateName);

        final double? population =
        populationByState[stateName];

        double normalizedValue = 0;

        if (population != null) {
          normalizedValue =
              (population - minPopulation) /
                  (maxPopulation - minPopulation);
        }

        final List<dynamic> multiPolygon =
        feature['geometry']['coordinates'];

        for (final polygon in multiPolygon) {
          final outerRing = polygon[0];

          final List<LatLng> points = [];

          for (final coordinate in outerRing) {
            final double longitude =
            coordinate[0].toDouble();

            final double latitude =
            coordinate[1].toDouble();

            points.add(
              LatLng(
                latitude,
                longitude,
              ),
            );
          }

          polygons.add(
            Polygon(
              points: points,
              borderColor:
              isSelected
                  ? const Color(0xFFFFC107)
                  : Colors.black,

              borderStrokeWidth:
              isSelected ? 3 : 1,
              label: stateName,
              color: population == null
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

  @override
  Widget build(BuildContext context) {
    final filterProvider =
    Provider.of<SearchFilterProvider>(context);

    final selectedLocations =
        filterProvider.selectedLocations;

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
    final currentDestinations =
    selectedLocations.skip(1).toSet();

    final removedDestinations =
    destinationPoints.keys
        .where(
          (name) => !currentDestinations.contains(name),
    )
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
      final String location =
          selectedLocations.first;

      if (_lastProcessedLocation != location) {
        _lastProcessedLocation = location;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadLocationFromProvider(location);
        });
      }
    }

    if (selectedLocations.length > 1) {
      final destinations =
      selectedLocations.skip(1).toList();

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

                    PolygonLayer(
                      polygons: statePolygons,
                    ),

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
                        ...destinationPoints.entries.map(
                              (entry) {
                            return Marker(
                              point: entry.value,
                              width: 45,
                              height: 45,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ],
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
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                            ),
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