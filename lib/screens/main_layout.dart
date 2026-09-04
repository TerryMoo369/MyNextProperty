import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_filter_provider.dart';
import 'search_screen.dart';
import 'global/header.dart';
import 'global/navigation.dart';
import '../widgets/explore_panel.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text('Map View Placeholder')),
    Center(child: Text('List View Placeholder')),
    Center(child: Text('Graph View Placeholder')),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Notify Provider to adapt filter stack rule
    final filterProvider = Provider.of<SearchFilterProvider>(context, listen: false);
    switch (index) {
      case 0:
        filterProvider.setAppView(AppView.map);
        break;
      case 1:
        filterProvider.setAppView(AppView.list);
        break;
      case 2:
        filterProvider.setAppView(AppView.graph);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: ExplorePanel(
                onSearchTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
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