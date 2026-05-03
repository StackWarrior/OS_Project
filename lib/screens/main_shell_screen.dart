import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
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

  static const _titlesAr = [
    'الرئيسية',
    'الدورات',
    'دوراتي',
    'المفضلة',
    'الملف الشخصي',
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
    final isEn = context.watch<AppState>().locale.languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEn ? _titles[idx] : _titlesAr[idx]),
        actions: [
          IconButton(
            tooltip: isEn ? 'Switch Language' : 'تغيير اللغة',
            onPressed: () => context.read<AppState>().toggleLanguage(),
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: isEn ? 'Search' : 'بحث',
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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: isEn ? 'Home' : 'الرئيسية',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: isEn ? 'Courses' : 'الدورات',
          ),
          NavigationDestination(
            icon: const Icon(Icons.play_circle_outline),
            selectedIcon: const Icon(Icons.play_circle),
            label: isEn ? 'Learn' : 'تعلم',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline),
            selectedIcon: const Icon(Icons.favorite),
            label: isEn ? 'Saved' : 'المفضلة',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: isEn ? 'Profile' : 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}
