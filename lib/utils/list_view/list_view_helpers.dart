import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class ListViewHelpers {
  static final Map<String, LatLng> stateCoordinates = {
    'Johor': const LatLng(1.9344, 103.3587),
    'Kedah': const LatLng(6.1184, 100.3685),
    'Kelantan': const LatLng(5.3104, 102.2501),
    'Melaka': const LatLng(2.1896, 102.2501),
    'Negeri Sembilan': const LatLng(2.7258, 101.9424),
    'Pahang': const LatLng(3.8126, 103.3256),
    'Perak': const LatLng(4.5921, 101.0901),
    'Perlis': const LatLng(6.4449, 100.2048),
    'Pulau Pinang': const LatLng(5.4141, 100.3288),
    'Sabah': const LatLng(5.9788, 116.0753),
    'Sarawak': const LatLng(1.5533, 110.3592),
    'Selangor': const LatLng(3.0738, 101.5183),
    'Terengganu': const LatLng(5.3117, 103.1324),
    'Kuala Lumpur': const LatLng(3.1390, 101.6869),
    'Labuan': const LatLng(5.2831, 115.2308),
    'Putrajaya': const LatLng(2.9264, 101.6964),
  };

  static LatLng getCoordinate(String loc) {
    if (loc.contains('Kuala Lumpur')) return stateCoordinates['Kuala Lumpur']!;
    if (loc.contains('Putrajaya')) return stateCoordinates['Putrajaya']!;
    if (loc.contains('Labuan')) return stateCoordinates['Labuan']!;
    if (loc.contains('Kelantan')) return stateCoordinates['Kelantan']!;
    if (loc.contains('Penang')) return stateCoordinates['Pulau Pinang']!;
    // Add a fallback center point for Semenanjung Malaysia
    if (loc.contains('Semenanjung Malaysia')) return const LatLng(4.2105, 101.9758);
    return stateCoordinates[loc.split(',').first] ?? const LatLng(4.2105, 101.9758);
  }

  static Widget getShapeIndicator(int index) {
    switch (index) {
      case 0: return const Icon(Icons.circle, color: Color(0xFF0A84FF), size: 14);
      case 1: return const Icon(Icons.square, color: Color(0xFFFF9F0A), size: 14);
      case 2: return const Icon(Icons.change_history, color: Color(0xFF30D158), size: 16);
      case 3: return const Icon(Icons.star, color: Color(0xFFBF5AF2), size: 16);
      default: return const Icon(Icons.location_on, color: Colors.grey, size: 14);
    }
  }

  static Color getColorForIndex(int index) {
    switch (index) {
      case 0: return const Color(0xFF0A84FF);
      case 1: return const Color(0xFFFF9F0A);
      case 2: return const Color(0xFF30D158);
      case 3: return const Color(0xFFBF5AF2);
      default: return Colors.grey;
    }
  }

  static IconData getIconForFilter(String filter) {
    switch (filter) {
      case 'Total Population': return Icons.groups;
      case 'Cost of Living (CPI)': return Icons.account_balance_wallet;
      case 'Mean Income': return Icons.attach_money;
      case 'Median Income': return Icons.money;
      case 'Expenditure': return Icons.shopping_cart;
      case 'Poverty Rate': return Icons.trending_down;
      case 'Income Inequality': return Icons.balance;
      case 'GDP': return Icons.auto_graph;
      case 'Labour Force': return Icons.engineering;
      case 'Workforce Participation': return Icons.work;
      case 'Unemployment Rate': return Icons.work_off;
      case 'General Crime': return Icons.local_police;
      case 'Drug Crime': return Icons.medication_liquid;
      case 'Hospital Beds': return Icons.bed;
      case 'Healthcare Staff': return Icons.health_and_safety;
      case 'Teachers': return Icons.school;
      case 'Literacy Rate': return Icons.menu_book;
      case 'Electricity Access': return Icons.bolt;
      case 'Water Access': return Icons.water_drop;
      case 'Sanitation': return Icons.cleaning_services;
      case 'Green Space': return Icons.park;
      default: return Icons.analytics;
    }
  }
}