import 'package:flutter/material.dart';
import 'package:mynextproperty/Data/repository.dart';
import 'package:mynextproperty/Services/dataSync_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  final TextEditingController startController =
  TextEditingController(text: 'Kepong');

  final TextEditingController destinationController =
  TextEditingController(text: 'Batu Pahat');

  String _apiTestData = "Fetching API data... please wait.";
  final DataRepository _repository = DataRepository();
  final DataSyncService _syncService = DataSyncService();

  @override
  void initState() {
    super.initState();
    _testFetchData();
  }

  Future<void> _testFetchData() async {
    try {
      // Trigger the sync
      await _syncService.syncDataset('cpi_state');

      // Fetch the data from SQLite
      final data = await _repository.getLatestEconomicData();

      // Display result
      if (mounted) {
        setState(() {
          _apiTestData = "SUCCESS! Fetched ${data.length} records.\n\nSample:\n${data.isNotEmpty ? data.first.toString() : 'No data'}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiTestData = "ERROR:\n$e";
        });
      }
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
              child: Stack(
                children: [

                  // Temporary map
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade300,

                    child: const Center(
                      child: Text(
                        'MAP AREA',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Add Floating text box for api test
                  Positioned(
                    top: 50,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _apiTestData,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Example restaurant marker
                  Positioned(
                    left: 110,
                    top: 120,
                    child: _buildMarker(
                      rating: '3.5',
                      name: 'Omer Yusel',
                    ),
                  ),

                  Positioned(
                    left: 100,
                    top: 155,
                    child: _buildMarker(
                      rating: '3.6',
                      name: 'La Bonne',
                    ),
                  ),

                  Positioned(
                    left: 130,
                    bottom: 130,
                    child: _buildMarker(
                      rating: '4.3',
                      name: 'Pizzeria Capricciosa',
                    ),
                  ),

                  // Layer button
                  Positioned(
                    right: 15,
                    top: 15,

                    child: _buildCircleButton(
                      icon: Icons.layers_outlined,
                      onPressed: () {},
                    ),
                  ),

                  // Current location button
                  Positioned(
                    right: 15,
                    bottom: 15,

                    child: _buildCircleButton(
                      icon: Icons.navigation,
                      onPressed: () {},
                    ),
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