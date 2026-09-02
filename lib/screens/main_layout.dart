import 'package:flutter/material.dart';
import 'global/theme_toggle.dart';
import 'global/navigation.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; // Default to Map view

  // The 3 main view
  final List<Widget> _screens = [
    const Center(child: Text('Map View')),
    const Center(child: Text('List View')),
    const Center(child: Text('Graph View')),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ThemeToggle(), // Header
      body: Stack(
        children: [
          // content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Footer
          Positioned(
            bottom: 30,
            left: 40,
            right: 40,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}