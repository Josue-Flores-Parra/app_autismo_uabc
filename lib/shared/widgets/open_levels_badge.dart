import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../features/profiles/viewmodel/profile_viewmodel.dart';
import '../../l10n/gen/app_localizations.dart';
import 'glass_pill.dart';

/// Indicador del modo libre. Solo se muestra cuando el perfil activo tiene
/// abiertos todos los niveles, para que se note que el avance no es el normal.
class OpenLevelsBadge extends StatelessWidget {
  const OpenLevelsBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.select<ProfileViewModel, bool>(
      (profiles) => profiles.selectedLearner?.settings.openAllLevels ?? false,
    );
    if (!active) return const SizedBox.shrink();

    final colors = context.appColors;
    return GlassPill(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_open_rounded, color: colors.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).openLevelsActive,
            style: TextStyle(
              color: colors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
