import 'package:flutter/material.dart';
import '../../activity/screens/activity_screen.dart';
import '../../assets/screens/assets_screen.dart';
import '../../liabilities/screens/liabilities_screen.dart';
import '../../overview/screens/overview_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Main navigation shell hosting the 5 primary application tabs:
/// 1. Overview
/// 2. Assets
/// 3. Liabilities
/// 4. Activity
/// 5. Settings
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const List<Widget> _screens = <Widget>[
    OverviewScreen(),
    AssetsScreen(),
    LiabilitiesScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_rounded),
            selectedIcon: Icon(Icons.trending_up_rounded),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card_rounded),
            label: 'Liabilities',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
