import 'package:flutter/material.dart';
import 'tarim_screen.dart';
import 'hayvancilik_screen.dart';
import 'dashboard_screen.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 1});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.instance.maybeShowStartupRewardedAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const TarimScreen(),
      DashboardScreen(
        onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const HayvancilikScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: 'Tarım',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Hayvancılık',
          ),
        ],
      ),
    );
  }
}
