import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'customer_scanner.dart';
import 'leaderboard_page.dart';
import 'cafe_page.dart';
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
    const CafePage(),
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
    label: 'Ranks',
  ),
  NavigationDestination(
    icon: Icon(Icons.coffee_outlined),
    selectedIcon: Icon(Icons.coffee_rounded),
    label: 'Cafes',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline_rounded),
    selectedIcon: Icon(Icons.person_rounded),
    label: 'Account',
  ),
];
