import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mynextproperty/Data/repository.dart';
import 'package:mynextproperty/services/dataSync_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:mynextproperty/Data/Dataset.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<Polygon> statePolygons = [];
  //Use to get the destination
  LatLng? startPoint;
  LatLng? destinationPoint;

  List<LatLng> routePoints = [];
  double? routeDistanceKm;

  double? ron95Price;
  double? estimatedFuelCost;

  String? startStateName;
  String? destinationStateName;

  Set<String> selectedStateNames = {};
  final Geocoding _geocoding = Geocoding();

  final DataSyncService _syncService = DataSyncService();
  final DataRepository _repository = DataRepository();
  final TextEditingController startController =
  TextEditingController();

  final TextEditingController destinationController =
  TextEditingController();


  @override
  void initState() {
    super.initState();

    _loadStatePolygons();
  }


  void _updateSelectedStates() {
    selectedStateNames.clear();

    if (startStateName != null &&
        startStateName!.isNotEmpty) {
      selectedStateNames.add(startStateName!);
    }

    if (destinationStateName != null &&
        destinationStateName!.isNotEmpty) {
      selectedStateNames.add(destinationStateName!);
    }
  }
  void _clearStartLocation() {
    setState(() {
      startController.clear();

      startPoint = null;
      startStateName = null;

      routePoints.clear();
      routeDistanceKm = null;

      _updateSelectedStates();
    });

    _loadStatePolygons();
  }

  void _clearDestinationLocation() {
    setState(() {
      destinationController.clear();

      destinationPoint = null;
      destinationStateName = null;

      routePoints.clear();
      routeDistanceKm = null;

      _updateSelectedStates();
    });

    _loadStatePolygons();
  }

  Future<void> _selectStartLocation() async {
    try {
      setState(() {
        routePoints.clear();
        routeDistanceKm = null;
      });
      final String address =
      startController.text.trim();

      if (address.isEmpty) {
        return;
      }
      final List<Location> locations =
      await _geocoding.locationFromAddress(
        address,
      );

      if (locations.isEmpty) {
        print('Start address not found');
        return;
      }

      final Location location = locations.first;

      final List<Placemark> placemarks =
      await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        print('Start state not found');
        return;
      }

      final String stateName =
          placemarks.first.administrativeArea ?? '';

      print('===== START LOCATION =====');
      print('Address: $address');
      print('Latitude: ${location.latitude}');
      print('Longitude: ${location.longitude}');
      print('Detected State: $stateName');

      if (!mounted) return;

      setState(() {
        startPoint = LatLng(
          location.latitude,
          location.longitude,
        );

        startStateName = stateName;

        _updateSelectedStates();
      });

      await _loadStatePolygons();
      await _loadRoute();

    } catch (e) {
      print('===== START LOCATION ERROR =====');
      print(e);
    }
  }
  Future<void> _selectDestinationState() async {
    try {
      setState(() {
        routePoints.clear();
        routeDistanceKm = null;
      });

      final String address =
      destinationController.text.trim();

      if (address.isEmpty) {
        return;
      }

      final List<Location> locations =
      await _geocoding.locationFromAddress(
        address,
      );

      if (locations.isEmpty) {
        print('Address not found');
        return;
      }

      final Location location = locations.first;

      print('===== DESTINATION =====');
      print('Address: $address');
      print('Latitude: ${location.latitude}');
      print('Longitude: ${location.longitude}');

      final List<Placemark> placemarks =
      await _geocoding.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        print('State not found');
        return;
      }

      final Placemark place = placemarks.first;

      final String stateName =
          place.administrativeArea ?? '';

      print('Detected State: $stateName');

      if (!mounted) return;

      setState(() {
        destinationPoint = LatLng(
          location.latitude,
          location.longitude,
        );

        destinationStateName = stateName;

        _updateSelectedStates();
      });

      await _loadStatePolygons();
      await _loadRoute();

    } catch (e) {
      print('===== DESTINATION ERROR =====');
      print(e);
    }
  }

  Future<void> _loadRoute() async {
    if (startPoint == null || destinationPoint == null) {
      return;
    }

    try {
      final LatLng start = startPoint!;
      final LatLng destination = destinationPoint!;

      final Uri url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${destination.longitude},${destination.latitude}'
            '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('Route request failed');
        return;
      }

      final Map<String, dynamic> data =
      jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        print('Route not found');
        return;
      }

      final route = data['routes'][0];

      final List<dynamic> coordinates =
      route['geometry']['coordinates'];

      final List<LatLng> points = [];

      for (final coordinate in coordinates) {
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

      final double distanceKm =
          (route['distance'] as num).toDouble() / 1000;

      if (!mounted) return;

      setState(() {
        routePoints = points;
        routeDistanceKm = distanceKm;
      });

      print('===== ROUTE =====');
      print('Route points: ${routePoints.length}');
      print(
        'Distance: ${routeDistanceKm!.toStringAsFixed(2)} km',
      );

      // await _calculateFuelCost();
    } catch (e) {
      print('===== ROUTE ERROR =====');
      print(e);
    }
  }
  // Future<void> _calculateFuelCost() async {
  //   if (routeDistanceKm == null) {
  //     return;
  //   }
  //
  //   try {
  //
  //     final testData =
  //     await _repository.testFuelPriceTable();
  //
  //     print('===== FUEL TABLE TEST =====');
  //     print('Rows: ${testData.length}');
  //
  //     for (final row in testData) {
  //       print(row);
  //     }
  //
  //     final fuelData =
  //     await _repository.getLatestFuelPrice();
  //
  //     if (fuelData == null) {
  //       print('Fuel price not found');
  //       return;
  //     }
  //
  //     final double fuelPrice =
  //     (fuelData['ron95'] as num).toDouble();
  //
  //     const double averageFuelConsumption = 7.0;
  //
  //     final double fuelCost =
  //         (routeDistanceKm! / 100) *
  //             averageFuelConsumption *
  //             fuelPrice;
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       ron95Price = fuelPrice;
  //       estimatedFuelCost = fuelCost;
  //     });
  //
  //     print('===== FUEL COST =====');
  //     print(
  //       'Distance: ${routeDistanceKm!.toStringAsFixed(2)} km',
  //     );
  //     print(
  //       'RON95: RM${ron95Price!.toStringAsFixed(2)}/L',
  //     );
  //     print(
  //       'Estimated Fuel Cost: RM${estimatedFuelCost!.toStringAsFixed(2)}',
  //     );
  //   } catch (e) {
  //     print('===== FUEL COST ERROR =====');
  //     print(e);
  //   }
  // }

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
  void dispose() {
    startController.dispose();
    destinationController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
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

                  // First search bar
                  _buildSearchBar(
                    controller: startController,
                    onSearch: _selectStartLocation,
                    onClear: _clearStartLocation,
                  ),

                  const SizedBox(height: 8),

                  // Second search bar
                  _buildSearchBar(
                    controller: destinationController,
                    onSearch: _selectDestinationState,
                    onClear: _clearDestinationLocation,
                  ),
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
                    polylines: [
                      if (routePoints.isNotEmpty)
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4,
                          color: Colors.deepOrange,
                        ),
                    ],
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

                      // Destination
                      if (destinationPoint != null)
                        Marker(
                          point: destinationPoint!,
                          width: 130,
                          height: 95,
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              if (estimatedFuelCost != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (routeDistanceKm != null)
                                        Text(
                                          '${routeDistanceKm!.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                            fontSize: 11,
                                          ),
                                        ),

                                      Text(
                                        'RM ${estimatedFuelCost!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 2),

                              const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // =========================
      // Bottom Navigation
      // =========================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Map',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'List',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Graph',
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

  // ============================================================
  // Map Marker
  // ============================================================

  Widget _buildMarker({
    required String rating,
    required String name,
  }) {
    return Row(
      children: [

        const Icon(
          Icons.location_on,
          color: Colors.red,
          size: 25,
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 3,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(5),

            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
              ),
            ],
          ),

          child: Text(
            '$rating   $name',
            style: const TextStyle(
              fontSize: 8,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // Circle Map Button
  // ============================================================

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),

      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}