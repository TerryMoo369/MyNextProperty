import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mynextproperty/Data/repository.dart';
import 'package:mynextproperty/services/dataSync_service.dart';
import 'package:mynextproperty/Data/Dataset.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<LatLng> kedahTestPoints = [];

  final DataSyncService _syncService = DataSyncService();
  final DataRepository _repository = DataRepository();
  final TextEditingController startController =
  TextEditingController(text: 'Kepong');

  final TextEditingController destinationController =
  TextEditingController(text: 'Batu Pahat');


  @override
  void initState() {
    super.initState();

    _testGeoJson();
  }

  Future<void> _testGeoJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/geo/malaysia_states.geojson',
      );

      final Map<String, dynamic> geoJson =
      jsonDecode(jsonString);

      final List<dynamic> features =
      geoJson['features'];

      print('===== GEOJSON TEST =====');
      print('Total features: ${features.length}');

      final geometryTypes = features
          .map((feature) => feature['geometry']['type'])
          .toSet();

      print('Geometry types: $geometryTypes');

      final firstFeature = features.first;

      final String stateName =
      firstFeature['properties']['state_name'];

      final List<dynamic> multiPolygon =
      firstFeature['geometry']['coordinates'];

      print('State: $stateName');
      print('Polygon count: ${multiPolygon.length}');

      // =========================
      // 加在这里
      // =========================
      final List<LatLng> firstPolygonPoints = [];

      final firstPolygon = multiPolygon.first;

      final outerRing = firstPolygon[0];

      for (final coordinate in outerRing) {
        final double longitude =
        coordinate[0].toDouble();

        final double latitude =
        coordinate[1].toDouble();

        firstPolygonPoints.add(
          LatLng(
            latitude,
            longitude,
          ),
        );
        setState(() {
          kedahTestPoints = firstPolygonPoints;
        });
      }

      print(
        'First polygon point count: ${firstPolygonPoints.length}',
      );

      print(
        'First point: ${firstPolygonPoints.first}',
      );

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
                  ),

                  const SizedBox(height: 8),

                  // Second search bar
                  _buildSearchBar(
                    controller: destinationController,
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
                  initialCenter: LatLng(4.2105, 108.9758),
                  initialZoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.myapp',
                  ),
                  PolygonLayer(
                    polygons: [
                      if (kedahTestPoints.isNotEmpty)
                        Polygon(
                          points: kedahTestPoints,
                          color: Colors.cyan.withValues(alpha: 0.4),
                          borderColor: Colors.black,
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                  MarkerLayer(
                      markers:[
                        Marker(
                            point: LatLng(3.1390, 101.9758),
                            width:40,
                            height: 40,
                            child:  const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                        ),
                      ]
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
  }) {
    return SizedBox(
      height: 42,

      child: TextField(
        controller: controller,

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
              controller.clear();
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