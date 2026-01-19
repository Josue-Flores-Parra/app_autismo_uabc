import 'package:flutter/material.dart';
import 'package:appy/l10n/gen/app_localizations.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: l10n?.navModules ?? 'Módulos',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n?.navAvatar ?? 'Avatar',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: l10n?.navSettings ?? 'Ajustes',
        ),
      ],
    );
  }
}
