import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'saved_farms_screen.dart';
import 'settings_screen.dart';
import '../services/storage_service.dart';
import '../models/user.dart';
import 'login_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  AppUser? _user;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = StorageService().getUser();
    setState(() {
      _user = user;
      _rebuildScreens();
    });
  }

  void _rebuildScreens() {
    _screens.clear();
    _screens.addAll([
      DashboardScreen(user: _user),
      const MapScreen(),
      SavedFarmsScreen(user: _user, onFarmSelected: _onFarmSelected),
      SettingsScreen(user: _user, onLogout: _onLogout),
    ]);
  }

  void _onLogin(AppUser user) {
    StorageService().saveUser(user);
    setState(() {
      _user = user;
      _rebuildScreens();
    });
  }

  void _onLogout() {
    StorageService().clearUser();
    setState(() {
      _user = null;
      _rebuildScreens();
    });
  }

  void _onFarmSelected(double lat, double lng) {
    setState(() => _currentIndex = 1);
    // Map screen will handle the navigation via callback
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return LoginScreen(onLogin: _onLogin);
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF27272A), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Farms',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
