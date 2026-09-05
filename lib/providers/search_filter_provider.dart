import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppView { map, list, graph }

class SearchFilterProvider extends ChangeNotifier {
  static const String _prefLocationsKey = 'saved_selected_locations';
  static const String _prefFiltersKey = 'saved_active_filters';

  static const List<String> availableFilters = [
    'Total Population',
    'Cost of Living (CPI)',
    'Mean Income',
    'Median Income',
    'Expenditure',
    'Poverty Rate',
    'Income Inequality',
    'GDP',
    'Labour Force',
    'Workforce Participation',
    'Unemployment Rate',
    'General Crime',
    'Drug Crime',
    'Hospital Beds',
    'Healthcare Staff',
    'Teachers',
    'Literacy Rate',
    'Electricity Access',
    'Water Access',
    'Sanitation',
    'Green Space',
  ];

  AppView _currentView = AppView.map;
  List<String> _selectedLocations = [];
  List<String> _activeFilters = ['Mean Income'];
  SearchFilterProvider() {
    _loadSavedPreferences();
  }

  AppView get currentView => _currentView;

  List<String> get selectedLocations => List.unmodifiable(_selectedLocations);

  List<String> get activeFilters => List.unmodifiable(_activeFilters);

  int get totalFiltersApplied => _activeFilters.length;

  bool get isMapView => _currentView == AppView.map;

  /// Changes the active app view tab and enforces single vs. multi-filter rules.
  void setAppView(AppView view) {
    if (_currentView == view) return;
    _currentView = view;

    // Switch to Map View -> Retain only the FIRST filter in the stack
    if (_currentView == AppView.map && _activeFilters.length > 1) {
      _activeFilters = [_activeFilters.first];
      _saveFilters();
    }
    notifyListeners();
  }

  /// Toggles or replaces filter selection based on current view constraints.
  void toggleFilter(String filter) {
    if (!availableFilters.contains(filter)) return;

    if (isMapView) {
      // Map View constraint: Single-selection only
      _activeFilters = [filter];
    } else {
      // List & Graph Views constraint: Multi-selection allowed
      if (_activeFilters.contains(filter)) {
        // Keep at least 1 filter selected
        if (_activeFilters.length > 1) {
          _activeFilters.remove(filter);
        }
      } else {
        _activeFilters.add(filter);
      }
    }

    _saveFilters();
    notifyListeners();
  }

  /// Selects a single indicator directly
  void setSingleFilter(String filter) {
    if (!availableFilters.contains(filter)) return;
    _activeFilters = [filter];
    _saveFilters();
    notifyListeners();
  }

  /// Reset to default filters
  void resetFilters() {
    _activeFilters = ['Mean Income'];
    _saveFilters();
    notifyListeners();
  }

  // Location Management
  void addLocation(String location) {
    if (!_selectedLocations.contains(location) &&
        _selectedLocations.length < 4) {
      _selectedLocations.add(location);
      _saveLocations();
      notifyListeners();
    }
  }

  void removeLocation(String location) {
    if (_selectedLocations.remove(location)) {
      _saveLocations();
      notifyListeners();
    }
  }

  void clearLocations() {
    _selectedLocations.clear();
    _saveLocations();
    notifyListeners();
  }

  void selectAllFilters() {
    if (isMapView) return;
    _activeFilters = List.from(availableFilters);
    _saveFilters();
    notifyListeners();
  }

  // Persistence methods
  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedLocations = prefs.getStringList(_prefLocationsKey) ?? [];
    final savedFilters = prefs.getStringList(_prefFiltersKey);
    if (savedFilters != null && savedFilters.isNotEmpty) {
      _activeFilters = savedFilters
          .where((f) => availableFilters.contains(f))
          .toList();
      if (_activeFilters.isEmpty) _activeFilters = ['Mean Income'];
    }
    // Enforce map view rule if initial view is map
    if (isMapView && _activeFilters.length > 1) {
      _activeFilters = [_activeFilters.first];
    }
    notifyListeners();
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefLocationsKey, _selectedLocations);
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefFiltersKey, _activeFilters);
  }
}
