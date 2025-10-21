import 'package:flutter/material.dart';
import 'package:app_autismo_uabc/shared/widgets/custom_bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() {
    return _MainShellState();
  }
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late Widget activeScreen;

  final List<Widget> screen = [
    const Placeholder(),
    const Placeholder(),
    const Placeholder(),
  ];

  @override
  void initState() {
    super.initState();
    activeScreen = screen[_selectedIndex];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      activeScreen = screen[_selectedIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: activeScreen,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}