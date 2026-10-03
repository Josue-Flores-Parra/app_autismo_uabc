import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appy/l10n/gen/app_localizations.dart';

import '../../data/services/firestore_services.dart';
import '../../features/avatar/viewmodel/avatar_viewmodel.dart';
import '../../features/learning_module/data/completion_sync_service.dart';
import '../../features/learning_module/model/levels_models.dart';
import '../../features/learning_module/viewmodel/learning_viewmodel.dart';
import '../../features/profiles/viewmodel/profile_viewmodel.dart';

class LevelCompletionResult {
  final bool success;
  final int attempts;
  final int stars;
  final int coins;
  final CompletionSyncState syncState;
  final CompletionSyncService? syncService;
  final String? completionId;
  final bool rewardsKnown;

  /// Cuanto subio/bajo felicidad y energia al registrar esta actividad, para
  /// mostrarlo junto a las monedas en el dialogo de resultado.
  final int felicidadDelta;
  final int energiaDelta;

  /// `true` si la energia del avatar quedo en cero tras esta actividad.
  final bool sinEnergia;

  /// `true` si esta modalidad del nivel ya se habia completado antes (las
  /// monedas de un repaso son menores que la primera vez, no cero).
  final bool esRepaso;

  const LevelCompletionResult({
    required this.success,
    required this.attempts,
    required this.stars,
    required this.coins,
    this.syncState = CompletionSyncState.confirmed,
    this.syncService,
    this.completionId,
    this.rewardsKnown = true,
    this.felicidadDelta = 0,
    this.energiaDelta = 0,
    this.sinEnergia = false,
    this.esRepaso = false,
  });

  /// Muestra pendientes solo sin red; los errores y recibos antiguos conservan su aviso.
  bool get showsSyncNotice => syncState == CompletionSyncState.pending
      ? (syncService?.isOffline ?? false)
      : syncState == CompletionSyncState.failed || !rewardsKnown;

  /// Sustituye el resultado provisional solo al recibir el recibo de este evento.
  LevelCompletionResult resolve() {
    final confirmation = completionId == null
        ? null
        : syncService?.confirmationOf(completionId!);
    if (syncState != CompletionSyncState.pending || confirmation == null) {
      return this;
    }
    final reward = confirmation.reward;
    return LevelCompletionResult(
      success: success,
      attempts: attempts,
      stars: reward?.stars ?? stars,
      coins: reward?.coins ?? 0,
      syncState: CompletionSyncState.confirmed,
      rewardsKnown: reward != null,
      felicidadDelta: reward?.happiness ?? 0,
      energiaDelta: reward?.energy ?? 0,
      sinEnergia: reward?.noEnergy ?? false,
      esRepaso: reward?.replay ?? false,
    );
  }
}

/// Centralizes progress persistence and rewards for level completion flows.
///
/// Cada modalidad de un nivel (pictograma, video y minijuego) se registra por
/// separado en `activities`; las estrellas del nivel son cuantas modalidades
/// distintas se completaron, con tope en [kLevelStarsToComplete].
class LevelCompletionService {
  /// Reconstruye el diálogo al confirmar la recompensa sin retrasar su apertura.
  static Widget watchResult(
    LevelCompletionResult? result,
    Widget Function(LevelCompletionResult?) builder,
  ) {
    final queue = result?.syncService;
    if (queue == null) return builder(result);
    return AnimatedBuilder(
      animation: queue,
      builder: (_, _) => builder(result?.resolve()),
    );
  }

  /// Monedas de una actividad de observacion (pictograma, video o audio).
  static const int _observationCoins = 10;

  /// Solo las actividades interactivas tienen intentos y pueden fallar. El
  /// resto (pictograma, video y audio) es de observacion.
  static bool isInteractiveType(String? actividadType) {
    final tipo = actividadType?.toLowerCase().trim();
    return tipo == 'simple_selection' || tipo == 'puzzle';
  }

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
            Flexible(
              child: Text(
                '${signed(felicidadDelta)} felicidad',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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
            Flexible(
              child: Text(
                '${signed(energiaDelta)} energía',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return rows;
  }

  /// Aviso amable cuando el avatar se queda sin energia. No bloquea nada: dice
  /// como recuperarla y cuanto tarda.
  static Widget buildEnergyNotice({
    TextAlign textAlign = TextAlign.start,
    MainAxisAlignment alignment = MainAxisAlignment.start,
  }) {
    return Row(
      mainAxisAlignment: alignment,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.bolt_rounded, color: energiaColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Appy se quedó sin energía. Repasa una actividad o espera: '
            'se recarga 1 punto cada '
            '${AvatarViewModel.minutosPorPuntoDeEnergia} minutos.',
            textAlign: textAlign,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ),
      ],
    );
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

  /// Explica recompensas pendientes o errores sin bloquear la salida.
  static Widget buildSyncNotice(
    BuildContext context,
    LevelCompletionResult? result,
  ) {
    if (result?.showsSyncNotice == false) return const SizedBox.shrink();
    final state = result?.syncState ?? CompletionSyncState.failed;
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return Text(
      state == CompletionSyncState.confirmed
          ? (l10n?.completionRewardsConfirmed ?? 'Recompensas sincronizadas.')
          : state == CompletionSyncState.pending
          ? (l10n?.completionRewardsPending ??
                'Recompensas pendientes de sincronización.')
          : (l10n?.completionSaveFailed ??
                'No se pudo guardar el resultado. Puedes volver e intentarlo de nuevo.'),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, color: Colors.white70),
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
    Future<LevelCompletionResult?> Function()? completionRecorder,
  }) async {
    final result =
        await (completionRecorder?.call() ??
            completeObservationLevel(
              context: context,
              moduleId: moduleId,
              levelId: levelId,
              actividadType: 'video',
            ));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => watchResult(result, (result) {
        final coins = result?.coins ?? 0;
        final felicidadDelta = result?.felicidadDelta ?? 0;
        final energiaDelta = result?.energiaDelta ?? 0;
        final sinEnergia = result?.sinEnergia ?? false;
        return AlertDialog(
          scrollable: true,
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
              if ((result?.showsSyncNotice ?? true) ||
                  result?.syncState == CompletionSyncState.confirmed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (result?.showsSyncNotice ?? true)
                        buildSyncNotice(context, result),
                      if (result?.syncState == CompletionSyncState.confirmed &&
                          result?.rewardsKnown == true)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Monedas: +$coins',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (result?.syncState == CompletionSyncState.confirmed &&
                          result?.rewardsKnown == true)
                        for (final row in buildStatRows(
                          felicidadDelta,
                          energiaDelta,
                          alignment: MainAxisAlignment.center,
                        )) ...[const SizedBox(height: 8), row],
                      if (sinEnergia) ...[
                        const SizedBox(height: 8),
                        buildEnergyNotice(
                          textAlign: TextAlign.center,
                          alignment: MainAxisAlignment.center,
                        ),
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
        );
      }),
    );
  }

  /// Registra la modalidad recien jugada y recalcula las estrellas si el nivel
  /// aun no estaba terminado.
  ///
  /// Repasar una modalidad ya completada da [_repasoCoins], menos que la
  /// primera vez pero nunca cero. Si el documento ya tiene
  /// [kLevelStarsToComplete] estrellas, no se vuelve a escribir: el progreso
  /// queda congelado aunque se repita (o se falle) una actividad.
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
    // The signed-in UID is the parent; progress and rewards belong to the
    // selected learner's users/{learnerUid} document.
    final learnerUid = context.read<ProfileViewModel>().learnerUid;
    if (learnerUid == null) return null;

    final queue = CompletionSyncService.instance;
    if (queue == null) return null;
    try {
      // Solo se consulta caché: ninguna confirmación remota bloquea el resultado.
      final previous = await (firestoreService ?? FirestoreService())
          .getCachedUserLevelProgress(learnerUid, moduleId, levelId);
      final event = CompletionEvent(
        id: CompletionSyncService.newId(),
        actorId: user.uid,
        learnerId: learnerUid,
        moduleId: moduleId,
        levelId: levelId,
        activity: activityKey,
        success: success,
        attempts: attempts,
        firstCoins: coinsIfFirstTime,
        totalActivities: totalActivities ?? kLevelStarsToComplete,
        completedAt: DateTime.now(),
        baseline: previous ?? {},
      );
      // Capturar la proyección antes de que una confirmación rápida retire el evento.
      final projected = completionProgress(
        queue.overlay(learnerUid, moduleId, {levelId: ?previous})[levelId] ??
            {},
        event,
      );
      await queue.enqueue(event);
      if (context.mounted) {
        context.read<LearningViewModel>().applyPendingProgress(moduleId);
      }
      return LevelCompletionResult(
        success: success,
        attempts: attempts,
        stars: parseProgressEstrellas(projected),
        coins: 0,
        syncState: CompletionSyncState.pending,
        syncService: queue,
        completionId: event.id,
      );
    } catch (e) {
      debugPrint('LevelCompletionService: no se pudo registrar: $e');
      return LevelCompletionResult(
        success: success,
        attempts: attempts,
        stars: 0,
        coins: 0,
        syncState: CompletionSyncState.failed,
      );
    }
  }
}
