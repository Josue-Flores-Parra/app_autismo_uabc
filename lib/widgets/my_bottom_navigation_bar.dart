import 'package:flutter/material.dart';
import '../colors/colors_app.dart';
import '../strings/strings_utils.dart';

class MyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MyBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book),
          label: AppStrings.modulos,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: AppStrings.progreso,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: AppStrings.configuracion,
        ),
      ],
      selectedItemColor: AppColors.seleccionado,
      unselectedItemColor: AppColors.noSeleccionado,
    );
  }
}
