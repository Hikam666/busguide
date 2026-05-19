import 'package:flutter/material.dart';
import 'package:busguide/core/theme/app_theme.dart';
import 'package:busguide/user/screens/home.dart';
import 'package:busguide/user/screens/halte.dart';
import 'package:busguide/user/screens/navigasi.dart';
import 'package:busguide/user/screens/rekomendasi.dart';
import 'package:busguide/user/screens/profil.dart';
import 'package:busguide/user/templates/bottom_navbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusGuide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    const Scaffold(body: Center(child: Text('Halte'))),
    const Scaffold(body: Center(child: Text('Navigasi'))),
    const Scaffold(body: Center(child: Text('Rekomendasi'))),
    const Scaffold(body: Center(child: Text('Profil'))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}