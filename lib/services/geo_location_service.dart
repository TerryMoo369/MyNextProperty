import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class GeoLocationService {
  static final GeoLocationService _instance = GeoLocationService._internal();

  factory GeoLocationService() => _instance;

  GeoLocationService._internal();

  List<dynamic>? _cachedGeoJsonFeatures;

  final Geocoding _geocoding = Geocoding();

  Future<List<dynamic>> getGeoJsonFeatures() async {
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

  Future<String?> findStateFromPoint(LatLng point) async {
    final List<dynamic> features = await getGeoJsonFeatures();

    for (final feature in features) {
      final String stateName = feature['properties']['state_name'];
      final List<dynamic> multiPolygon = feature['geometry']['coordinates'];

      for (final polygon in multiPolygon) {
        final List<dynamic> outerRing = polygon[0];

        if (isPointInsidePolygon(point, outerRing)) {
          return stateName;
        }
      }
    }
    return null;
  }

  bool isPointInsidePolygon(LatLng point, List<dynamic> polygon) {
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

  Future<String?> getStateFromAddress(String address) async {
    try {
      final List<Location> locations = await _geocoding.locationFromAddress(
        address,
      );
      if (locations.isEmpty) return null;

      final Location location = locations.first;
      final LatLng point = LatLng(location.latitude, location.longitude);

      return await findStateFromPoint(point);
    } catch (e) {
      return null;
    }
  }
}
