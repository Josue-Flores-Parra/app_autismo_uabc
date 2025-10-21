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
  Widget? activeScreen;
  int _selectedIndex = 0;
  final List<Widget> screen = [Placeholder(), Placeholder(), Placeholder()];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      activeScreen = screen[_selectedIndex];
    });
  }

  @override
  Widget build(ctx) {
    return Scaffold(
      body: Container(child: activeScreen),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
