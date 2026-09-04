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
      final List<Location> locations =
      await _geocoding.locationFromAddress(locationName);

      if (locations.isEmpty) {
        print('Provider location not found');
        return;
      }

      final Location location = locations.first;

      final List<Placemark> placemarks =
      await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        print('Provider state not found');
        return;
      }

      final String rawStateName =
          placemarks.first.administrativeArea ?? '';

      final String stateName =
      _normalizeStateName(rawStateName);

      if (!mounted) return;

      setState(() {
        startPoint = LatLng(
          location.latitude,
          location.longitude,
        );

        startStateName = stateName;

        _updateSelectedStates();
      });


      print('===== PROVIDER SOURCE =====');
      print('Location: $locationName');
      print('State: $stateName');
      print('Point: $startPoint');

      await _loadStatePolygons();
    } catch (e) {
      print('===== PROVIDER LOCATION ERROR =====');
      print(e);
    }
  }

  Future<void> _loadDestinationFromProvider(
      String locationName,
      ) async {
    try {
      final List<Location> locations =
      await _geocoding.locationFromAddress(locationName);

      if (locations.isEmpty) {
        print('Destination not found: $locationName');
        return;
      }

      final Location location = locations.first;

      final List<Placemark> placemarks =
      await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        print('Destination state not found: $locationName');
        return;
      }

      final String stateName =
          placemarks.first.administrativeArea ?? '';

      if (!mounted) return;

      setState(() {
        destinationPoints[locationName] = LatLng(
          location.latitude,
          location.longitude,
        );

        destinationStates[locationName] = stateName;

        _processedDestinations.add(locationName);

        _updateSelectedStates();
      });

      print('===== PROVIDER DESTINATION =====');
      print('Location: $locationName');
      print('State: $stateName');
      print('Point: ${destinationPoints[locationName]}');

      await _loadStatePolygons();

      await _loadRouteForDestination(
          locationName,
          destinationPoints[locationName]!,);
    } catch (e) {
      print('===== DESTINATION ERROR =====');
      print(e);
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
      final String jsonString = await rootBundle.loadString(
        'assets/geo/malaysia_states.geojson',
      );

      final Map<String, dynamic> geoJson =
      jsonDecode(jsonString);

      final List<dynamic> features =
      geoJson['features'];

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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadDestinationFromProvider(destination);
          });
        }
      }
    }
    return SafeArea(
        child: Column(
          children: [

            // =========================
            // Search Area
            // =========================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                6,
              ),
              child: Column(
                children: [

                ],
              ),
            ),

            // =========================
            // Filter Area
            // =========================
            SizedBox(
              height: 45,

              child: ListView(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),

                children: [

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.tune,
                      size: 20,
                    ),
                  ),

                  _buildFilterButton(
                    text: 'Sort by',
                    showArrow: true,
                  ),

                  const SizedBox(width: 8),

                  _buildFilterButton(
                    text: 'Open now',
                  ),

                  const SizedBox(width: 8),

                  _buildFilterButton(
                    text: 'Top rated',
                  ),

                  const SizedBox(width: 8),

                  _buildFilterButton(
                    text: 'Wheelchair',
                  ),
                ],
              ),
            ),

            // =========================
            // Map Area
            // =========================
            Expanded(
              child: FlutterMap(
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  // ============================================================
  // Search Bar
  // ============================================================

  Widget _buildSearchBar({
    required TextEditingController controller,
    VoidCallback? onSearch,
    VoidCallback? onClear,
  }) {
    return SizedBox(
      height: 42,

      child: TextField(
        controller: controller,

        textInputAction: TextInputAction.search,

        onSubmitted: (value) {
          if (onSearch != null) {
            onSearch();
          }
        },

        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),

          suffixIcon: IconButton(
            icon: const Icon(
              Icons.close,
              size: 18,
            ),

            onPressed: () {
              if (onClear != null) {
                onClear();
              } else {
                controller.clear();
              }
            },
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),

            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),

            borderSide: BorderSide(
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Filter Button
  // ============================================================

  Widget _buildFilterButton({
    required String text,
    bool showArrow = false,
  }) {
    return OutlinedButton(
      onPressed: () {},

      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),

        minimumSize: const Size(
          0,
          32,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      child: Row(
        children: [

          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
            ),
          ),

          if (showArrow)
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
            ),
        ],
      ),
    );
  }
}