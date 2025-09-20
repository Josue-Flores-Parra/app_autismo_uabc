import 'package:flutter/material.dart';

class CustomBottomNavBar
    extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.dashboard,
            color: Color(0xFF5B8DB3),
          ),
          label: "Módulos",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.person,
            color: Color(0xFF92C5BC),
          ),
          label: "Avatar",
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.settings,
            color: Color(0xFF5B8DB3),
          ),
          label: "Ajustes",
        ),
      ],
    );
  }
}
