import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_filter_provider.dart';
import 'list_view/list_view_screen.dart';
import 'search_screen.dart';
import 'global/header.dart';
import 'global/navigation.dart';
import '../widgets/explore_panel.dart';
import '../pages/map_view/map_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapView(),
    ListViewScreen(),
    Center(child: Text('Graph View')),
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
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 20),
              child: Align(
                alignment: Alignment.topRight,
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