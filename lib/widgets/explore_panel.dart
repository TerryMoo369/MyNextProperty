import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_filter_provider.dart';
import 'filter_bottom_sheet.dart';

class ExplorePanel extends StatefulWidget {
  final VoidCallback onSearchTap;

  const ExplorePanel({
    super.key,
    required this.onSearchTap,
  });

  @override
  State<ExplorePanel> createState() => _ExplorePanelState();
}

class _ExplorePanelState extends State<ExplorePanel> {
  bool _isExpanded = true;

  Widget _getShapeIndicator(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.circle, color: Color(0xFF0A84FF), size: 16);
      case 1:
        return const Icon(Icons.square, color: Color(0xFFFF9F0A), size: 16);
      case 2:
        return const Icon(Icons.change_history, color: Color(0xFF30D158), size: 18);
      case 3:
        return const Icon(Icons.star, color: Color(0xFFBF5AF2), size: 18);
      default:
        return const Icon(Icons.location_on, color: Colors.grey, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final filterProvider = Provider.of<SearchFilterProvider>(context);
    final locations = filterProvider.selectedLocations;

    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
      alignment: Alignment.topRight, // CRITICAL: Forces it to shrink/grow towards the top right
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        // Use a simple Fade instead of the old SlideTransition to prevent weird moving
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isExpanded
            ? SizedBox(
          key: const ValueKey('expanded_state'), // Keys are required for AnimatedSwitcher
          width: double.infinity,
          child: _buildExpandedState(isDark, filterProvider, locations),
        )
            : Align(
          key: const ValueKey('collapsed_state'),
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 20),
            child: _buildCollapsedState(isDark, locations),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedState(bool isDark, List<String> locations) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.9) : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, color: Color(0xFF0A84FF), size: 18),
            const SizedBox(width: 8),
            Text(
              locations.isEmpty ? 'Explore' : '${locations.length} Locations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedState(bool isDark, SearchFilterProvider filterProvider, List<String> locations) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.80) : Colors.white.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isExpanded = false),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.keyboard_arrow_up, size: 20, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (locations.isEmpty)
                GestureDetector(
                  onTap: widget.onSearchTap,
                  child: _buildEmptySearchBar(isDark),
                )
              else
                Column(
                  children: [
                    ...List.generate(locations.length, (index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141415).withOpacity(0.8) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                        ),
                        child: Row(
                          children: [
                            _getShapeIndicator(index),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                locations[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            // Quick remove button for convenience
                            GestureDetector(
                              onTap: () {
                                filterProvider.removeLocation(locations[index]);
                              },
                              child: const Icon(Icons.close, color: Colors.grey, size: 20),
                            ),
                          ],
                        ),
                      );
                    }),
                    // --- ONLY SHOW IF LESS THAN 4 LOCATIONS ---
                    if (locations.length < 4)
                      GestureDetector(
                        onTap: widget.onSearchTap,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0A1B3A) : const Color(0xFFE5F0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, color: Color(0xFF0A84FF), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'COMPARE LOCATIONS',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF0A84FF) : const Color(0xFF005ECB),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => FilterBottomSheet.show(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'All ${filterProvider.totalFiltersApplied} filters applied.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchBar(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E).withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(color: Color(0xFF0A84FF), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tap to search a location',
              style: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Start', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}