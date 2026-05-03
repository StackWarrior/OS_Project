import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shell_controller.dart';
import 'courses_list_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'my_courses_screen.dart';
import 'profile_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const _titles = [
    'Home',
    'Courses',
    'My courses',
    'Favorites',
    'Profile',
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomeScreen(),
      CoursesListScreen(),
      MyCoursesScreen(),
      FavoritesScreen(),
      ProfileScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShellController>().goToTab(widget.initialTab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<ShellController>();
    final idx = shell.index.clamp(0, _pages.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[idx]),
        actions: [
          IconButton(
            tooltip: 'Search in catalog',
            onPressed: () => shell.goToTab(1),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: IndexedStack(
        index: idx,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: shell.goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
