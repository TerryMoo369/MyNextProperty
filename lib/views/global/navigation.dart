import 'dart:ui';

import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  bool _isDragging = false;
  late double _dragPosition;

  final double _tabWidth = 75.0;
  final double _tabHeight = 50.0;
  final double _padding = 6.0;

  @override
  void initState() {
    super.initState();
    _dragPosition = widget.currentIndex * _tabWidth;
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.currentIndex != widget.currentIndex) {
      _dragPosition = widget.currentIndex * _tabWidth;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, _tabWidth * 2);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      int closestIndex = (_dragPosition / _tabWidth).round();

      _dragPosition = closestIndex * _tabWidth;

      // Trigger the page change if it's a new tab
      if (closestIndex != widget.currentIndex) {
        widget.onTabSelected(closestIndex);
      }
    });
  }

  void _handleTap(int index) {
    setState(() {
      _isDragging = false;
      _dragPosition = index * _tabWidth;
      widget.onTabSelected(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: EdgeInsets.all(_padding),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withOpacity(0.65)
                  : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: SizedBox(
              width: _tabWidth * 3,
              height: _tabHeight,
              child: GestureDetector(
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: Stack(
                  children: [
                    // Sliding
                    AnimatedPositioned(
                      duration: _isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      left: _dragPosition,
                      top: 0,
                      bottom: 0,
                      width: _tabWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.2),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        _buildNavItem(0, Icons.map_outlined, 'Map'),
                        _buildNavItem(1, Icons.format_list_bulleted, 'List'),
                        _buildNavItem(2, Icons.bar_chart_outlined, 'Graph'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = widget.currentIndex == index;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _tabWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              size: 24, // icon
            ),
            const SizedBox(height: 2), // spacing
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
