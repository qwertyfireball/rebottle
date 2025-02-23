import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Import your page files here
import 'scanner_page.dart';
import 'leaderboard_page.dart';
import 'map_page.dart';
import 'account_page.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final user = FirebaseAuth.instance.currentUser!;
  int _selectedIndex = 0;

  // Create a list of widget pages
  final List<Widget> _pages = [
    const HomePage(),
    const LeaderboardPage(),
    const MapPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      // Replace the Center widget with the selected page
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: Colors.blue[100],
        ),
        child: NavigationBar(
          backgroundColor: Colors.grey[200],
          animationDuration: const Duration(seconds: 1),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: _navBarItems,
        ),
      ),
    );
  }
}

const _navBarItems = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home_rounded),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.leaderboard_outlined),
    selectedIcon: Icon(Icons.leaderboard_rounded),
    label: 'Leaderboard',
  ),
  NavigationDestination(
    icon: Icon(Icons.map_outlined),
    selectedIcon: Icon(Icons.map_rounded),
    label: 'Map',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline_rounded),
    selectedIcon: Icon(Icons.person_rounded),
    label: 'Account',
  ),
];
