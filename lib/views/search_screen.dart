import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository.dart';
import '../providers/search_filter_provider.dart';
import '../services/geo_location_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final DataRepository _repository = DataRepository();
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _isResolvingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecentSearch(String location) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(location);
    _recentSearches.insert(0, location);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  void _onSearchChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _suggestions = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _repository.searchLocations(value);

    if (mounted) {
      setState(() {
        _suggestions = results;
      });
    }
  }

  Future<void> _selectLocation(String location) async {
    // 1. Immediately lock the UI to block rapid double-taps
    if (_isResolvingLocation) return;
    setState(() => _isResolvingLocation = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = Provider.of<SearchFilterProvider>(context, listen: false);

    String finalLocationName = location;

    // Only geocode if it's a typed query not directly chosen from database suggestions
    if (!_suggestions.contains(location)) {
      final stateName = await GeoLocationService().getStateFromAddress(
        location,
      );

      // Validation check: Location must resolve within Malaysia's GeoJSON boundaries
      if (stateName == null) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid location or outside Malaysia. Please select a valid state or district.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isResolvingLocation = false); // unlock UI
        }
        return;
      }

      if (!location.toLowerCase().contains(stateName.toLowerCase())) {
        finalLocationName = '$location, $stateName';
      }
    }

    // 2. Ensure widget hasn't been closed during the async resolution
    if (!mounted) return;

    if (provider.selectedLocations.contains(finalLocationName)) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('$finalLocationName is already selected.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isResolvingLocation = false); // unlock
      return;
    }

    if (provider.selectedLocations.length >= 4) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('You can only compare up to 4 locations at a time.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isResolvingLocation = false); // unlock
      return;
    }

    _saveRecentSearch(finalLocationName);
    provider.addLocation(finalLocationName);

    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filterProvider = Provider.of<SearchFilterProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                enabled: !_isResolvingLocation,
                // Disable input while geocoding
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  final location = value.trim();
                  if (location.isNotEmpty && !_isResolvingLocation) {
                    _selectLocation(location);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _isResolvingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isSearching
                      ? IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            _controller.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Selected Locations Chips
              if (filterProvider.selectedLocations.isNotEmpty) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: filterProvider.selectedLocations.map((location) {
                    return InputChip(
                      label: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      deleteIcon: const Icon(
                        Icons.cancel,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onDeleted: () {
                        filterProvider.removeLocation(location);
                      },
                      backgroundColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Dynamic Content List (Suggestions or Recent)
              Expanded(
                child: _isSearching
                    ? _buildSuggestionsList(isDark)
                    : _buildRecentSearchesList(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(bool isDark) {
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(
          'No locations found.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
      itemBuilder: (context, index) {
        final item = _suggestions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF0A84FF),
              size: 20,
            ),
          ),
          title: Text(
            item,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onTap: () => _selectLocation(item),
        );
      },
    );
  }

  Widget _buildRecentSearchesList(bool isDark) {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Searches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final item = _recentSearches[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(
                  item,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _recentSearches.remove(item);
                      _saveRecentSearch(item);
                    });
                  },
                ),
                onTap: () => _selectLocation(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
