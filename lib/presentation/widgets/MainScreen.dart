import 'package:flutter/material.dart';
import '../screens/GameHubScreen.dart';
import '../screens/HiveScreen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/futuristic_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentNavIndex = 0;

  /// System Navigation Mapping (Matches FuturisticNavBar):
  /// 0: CORE -> HomeScreen
  /// 1: VAULT -> HistoryScreen
  /// 2: HUB -> GameHubScreen
  /// 3: DOSSIER -> ProfileScreen
  /// 4: SQUAD -> HiveScreen
  final List<Widget> _pages = [
    const HomeScreen(), // Index 0
    const HistoryScreen(), // Index 1
    const GameHubScreen(), // Index 2
    const ProfileScreen(), // Index 3 (Mapped to DOSSIER in NavBar)
    const HiveScreen(), // Index 4 (Mapped to SQUAD in NavBar)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      extendBody: true,
      body: IndexedStack(index: _currentNavIndex, children: _pages),
      bottomNavigationBar: FuturisticNavBar(
        selectedIndex: _currentNavIndex,
        onItemSelected: (index) {
          if (index >= 0 && index < _pages.length) {
            setState(() {
              _currentNavIndex = index;
            });
          }
        },
      ),
    );
  }
}
