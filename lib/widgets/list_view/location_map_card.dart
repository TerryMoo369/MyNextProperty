import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/list_view/list_view_helpers.dart';

class LocationMapCard extends StatefulWidget {
  final bool isDark;
  final List<String> locations;
  final Map<String, double> overallScores;
  final String? selectedLocation;

  const LocationMapCard({
    super.key,
    required this.isDark,
    required this.locations,
    required this.overallScores,
    required this.selectedLocation,
  });

  @override
  State<LocationMapCard> createState() => _LocationMapCardState();
}

class _LocationMapCardState extends State<LocationMapCard> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  @override
  void didUpdateWidget(LocationMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-center the map if the list of locations actually changed
    if (oldWidget.locations != widget.locations || oldWidget.overallScores != widget.overallScores) {
      _boundMap();
    }
  }

  void _boundMap() {
    if (!_isMapReady || widget.locations.isEmpty) return;

    if (widget.locations.length == 1) {
      _mapController.move(ListViewHelpers.getCoordinate(widget.locations.first), 8.0);
      return;
    }

    final points = widget.locations.map((loc) => ListViewHelpers.getCoordinate(loc)).toList();
    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locations.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 60, color: Color(0xFF0A84FF)),
            const SizedBox(height: 16),
            Text(
              'Your location scores will be displayed here.',
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Start by adding one location.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: ListViewHelpers.getCoordinate(widget.locations.first),
            initialZoom: 6.0,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            onMapReady: () {
              _isMapReady = true;
              _boundMap();
            },
          ),
          children: [
            TileLayer(
              // Reverted to colorful OpenStreetMap
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mynextproperty',
            ),
            MarkerLayer(
              markers: widget.locations.asMap().entries.map((entry) {
                int index = entry.key;
                String loc = entry.value;
                bool isSelected = loc == widget.selectedLocation;
                double score = widget.overallScores[loc] ?? 0.0;

                return Marker(
                  point: ListViewHelpers.getCoordinate(loc),
                  width: isSelected ? 80 : 30, // Make unselected markers smaller
                  height: isSelected ? 36 : 30,
                  child: isSelected
                      ? _buildMapPill(index, score)
                      : _buildMinimalMarker(index),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // The full label for the selected location
  Widget _buildMapPill(int index, double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListViewHelpers.getShapeIndicator(index),
          const SizedBox(width: 4),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // A small clean dot for the unselected locations
  Widget _buildMinimalMarker(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
          )
        ],
      ),
      child: Center(
        child: ListViewHelpers.getShapeIndicator(index),
      ),
    );
  }
}