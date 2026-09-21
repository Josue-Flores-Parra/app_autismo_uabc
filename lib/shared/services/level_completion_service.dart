import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/firestore_services.dart';
import '../../features/avatar/viewmodel/avatar_viewmodel.dart';
import '../../features/learning_module/model/levels_models.dart';
import '../../features/learning_module/viewmodel/learning_viewmodel.dart';

class LevelCompletionResult {
  final bool success;
  final int attempts;
  final int stars;
  final int coins;

  /// Cuanto subio/bajo felicidad y energia al registrar esta actividad, para
  /// mostrarlo junto a las monedas en el dialogo de resultado.
  final int felicidadDelta;
  final int energiaDelta;

  /// `true` si esta modalidad del nivel ya se habia completado antes (las
  /// monedas de un repaso son menores que la primera vez, no cero).
  final bool esRepaso;

  const LevelCompletionResult({
    required this.success,
    required this.attempts,
    required this.stars,
    required this.coins,
    this.felicidadDelta = 0,
    this.energiaDelta = 0,
    this.esRepaso = false,
  });
}

/// Centralizes progress persistence and rewards for level completion flows.
///
/// Cada modalidad de un nivel (pictograma, video y minijuego) se registra por
/// separado en `activities`; las estrellas del nivel son cuantas modalidades
/// distintas se completaron, con tope en [kLevelStarsToComplete].
class LevelCompletionService {
  /// Monedas de una actividad de observacion (pictograma o video).
  static const int _observationCoins = 10;

  /// Monedas de repasar una modalidad ya completada antes. Menos que la
  /// primera vez, pero nunca cero: repasar tiene que valer la pena o nadie
  /// vuelve a ver un video o a practicar un minijuego ya superado.
  static const int _repasoCoins = 5;

  /// Monedas de un minijuego segun los errores cometidos.
  ///
  /// [attempts] cuenta equivocaciones, no selecciones: acertar todo a la
  /// primera llega aqui como `0`.
  static int calculateCoins(int attempts) {
    if (attempts <= 0) return 30;
    if (attempts <= 2) return 20;
    return 10;
  }

  /// Colores fijos de los iconos de felicidad/energía en los diálogos de
  /// resultado. No salen de `context.appColors` a propósito: estos diálogos
  /// mantienen su paleta oscura fija (igual que "Monedas" en dorado), la
  /// misma que ya tenían antes de esta ronda de ajustes.
  static const Color felicidadColor = Color(0xFFFF6F91);
  static const Color energiaColor = Color(0xFF4FC3F7);

  /// Una fila por estadística que cambió (felicidad y/o energía), con el
  /// mismo peso visual que "Errores" y "Monedas": ícono + texto en negrita,
  /// no un subtítulo chico. Se usa igual en el diálogo de minijuego y en el
  /// de video para que ambos se vean consistentes.
  static List<Widget> buildStatRows(
    int felicidadDelta,
    int energiaDelta, {
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    String signed(int value) => value >= 0 ? '+$value' : '$value';
    final rows = <Widget>[];
    if (felicidadDelta != 0) {
      rows.add(
        Row(
          mainAxisAlignment: alignment,
          children: [
            const Icon(Icons.favorite_rounded, color: felicidadColor),
            const SizedBox(width: 8),
            Text(
              '${signed(felicidadDelta)} felicidad',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    if (energiaDelta != 0) {
      rows.add(
        Row(
          mainAxisAlignment: alignment,
          children: [
            const Icon(Icons.bolt_rounded, color: energiaColor),
            const SizedBox(width: 8),
            Text(
              '${signed(energiaDelta)} energía',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return rows;
  }

  static Future<LevelCompletionResult?> completeInteractiveLevel({
    required BuildContext context,
    required String? moduleId,
    required String? levelId,
    required String? actividadType,
    required bool success,
    required int attempts,
    int? totalActivities,
    FirestoreService? firestoreService,
  }) async {
    return _persistActivity(
      context: context,
      moduleId: moduleId,
      levelId: levelId,
      actividadType: actividadType,
      success: success,
      attempts: attempts,
      coinsIfFirstTime: calculateCoins(attempts),
      totalActivities: totalActivities,
      firestoreService: firestoreService,
    );
  }

  static Future<LevelCompletionResult?> completeObservationLevel({
    required BuildContext context,
    required String? moduleId,
    required String? levelId,
    required String? actividadType,
    int? totalActivities,
    FirestoreService? firestoreService,
  }) async {
    return _persistActivity(
      context: context,
      moduleId: moduleId,
      levelId: levelId,
      actividadType: actividadType,
      success: true,
      attempts: 0,
      coinsIfFirstTime: _observationCoins,
      isObservation: true,
      totalActivities: totalActivities,
      firestoreService: firestoreService,
    );
  }

  /// Guarda el progreso del nivel de video y muestra el diálogo de recompensas.
  ///
  /// Llama a [completeObservationLevel] para persistir el progreso y luego
  /// muestra un [AlertDialog] con las monedas ganadas. Reutilizable desde
  /// [VideoPlayerScreen] y [VideoPreviewCard] sin duplicar lógica de UI.
  static Future<void> showVideoCompletionDialog({
    required BuildContext context,
    required String? moduleId,
    required String? levelId,
  }) async {
    final result = await completeObservationLevel(
      context: context,
      moduleId: moduleId,
      levelId: levelId,
      actividadType: 'video',
    );
    if (!context.mounted) return;
    final coins = result?.coins ?? 0;
    final felicidadDelta = result?.felicidadDelta ?? 0;
    final energiaDelta = result?.energiaDelta ?? 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A3D52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF05E995), size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Nivel Completado!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡Excelente trabajo! Has completado el nivel con éxito.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FFFFFF), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFFFD700),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Monedas: +$coins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  for (final row in buildStatRows(
                    felicidadDelta,
                    energiaDelta,
                    alignment: MainAxisAlignment.center,
                  )) ...[
                    const SizedBox(height: 8),
                    row,
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05E995),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Continuar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Escribe la modalidad recien jugada y recalcula las estrellas del nivel.
  ///
  /// Solo la primera vez que se completa una modalidad otorga monedas, de modo
  /// que repetir una actividad ya terminada no vuelve a pagar.
  static Future<LevelCompletionResult?> _persistActivity({

    required BuildContext context,
    required String? moduleId,
    required String? levelId,
    required String? actividadType,
    required bool success,
    required int attempts,
    required int coinsIfFirstTime,
    int? totalActivities,
    bool isObservation = false,
    FirestoreService? firestoreService,
  }) async {
    if (moduleId == null || levelId == null) return null;

    final activityKey = actividadType?.toLowerCase().trim() ?? '';
    if (activityKey.isEmpty) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final service = firestoreService ?? FirestoreService();

    try {
      final nowIso = DateTime.now().toIso8601String();
      final previous = await service.getUserLevelProgress(
        user.uid,
        moduleId,
        levelId,
      );
      final completedActivities = parseCompletedActivities(previous);
      final alreadyRewarded = completedActivities.contains(activityKey);

      if (success) {
        completedActivities.add(activityKey);
      }

      // Un nivel puede ofrecer menos de tres modalidades. Exigir siempre tres
      // dejaría ese nivel imposible de terminar y bloquearía el siguiente, así
      // que la meta es cuántas modalidades tiene realmente, con tope de tres.
      final requeridas = (totalActivities ?? kLevelStarsToComplete).clamp(
        1,
        kLevelStarsToComplete,
      );
      final completadas = completedActivities.length;
      final isLevelComplete = completadas >= requeridas;

      // 3 estrellas significa siempre "nivel terminado", sin importar cuántas
      // modalidades tenía; por eso las parciales nunca llegan a 3.
      final stars = isLevelComplete
          ? kLevelStarsToComplete
          : (completadas > kLevelStarsToComplete - 1
                ? kLevelStarsToComplete - 1
                : completadas);
      // Repasar una modalidad ya completada da menos monedas que la primera
      // vez, pero nunca cero: repetir tiene que seguir valiendo la pena.
      final coins = !success
          ? 0
          : (alreadyRewarded ? _repasoCoins : coinsIfFirstTime);

      final progressData = <String, dynamic>{
        'status': isLevelComplete ? 'completed' : 'in_progress',
        'estrellas': stars,
        'attempts': attempts,
        'updatedAt': nowIso,
        if (isLevelComplete) 'completedAt': nowIso,
        if (isObservation) 'type': 'observation',
        if (success)
          'activities': {
            activityKey: {
              'completedAt': nowIso,
              'attempts': attempts,
              'rewarded': alreadyRewarded || coins > 0,
            },
          },
      };

      await service.updateUserLevelProgress(
        user.uid,
        moduleId,
        levelId,
        progressData,
      );

      var felicidadDelta = 0;
      var energiaDelta = 0;
      if (context.mounted) {
        try {
          final avatarViewModel = context.read<AvatarViewModel>();
          final delta = await avatarViewModel.registrarActividad(
            success: success,
            monedas: coins,
            esRepaso: success && alreadyRewarded,
          );
          felicidadDelta = delta.felicidad;
          energiaDelta = delta.energia;
        } catch (_) {}
      }

      if (context.mounted) {
        // Aislado del resultado: si esta relectura falla (ej. hipo de red), el
        // progreso ya quedó guardado arriba y el resultado no debe perderse
        // por un fallo del refresco de cache local.
        try {
          final learningViewModel = context.read<LearningViewModel>();
          await learningViewModel.getModuleLevels(
            moduleId,
            forceReload: true,
          );
          await learningViewModel.refreshModulesProgress();
        } catch (e) {
          debugPrint('LevelCompletionService: refresco de modulos falló: $e');
        }
      }

      return LevelCompletionResult(
        success: success,
        attempts: attempts,
        stars: stars,
        coins: coins,
        felicidadDelta: felicidadDelta,
        energiaDelta: energiaDelta,
        esRepaso: success && alreadyRewarded,
      );
    } catch (_) {
      return null;
    }
  }
}
