/// Contrato UI-servicio para telemetría.
///
/// Define las señales semánticas que emiten las vistas y el handle opaco que
/// se entrega a `LevelPlayScreen` para emitir señales sin exponer el servicio
/// ni construir mapas de Firestore.
library;

import 'telemetry_enums.dart';

/// Señal emitida cuando la actividad está lista para uso (idempotente).
typedef ActivityReadySignal = void Function();

/// Señal emitida cuando se alcanza el objetivo pedagógico/umbral (idempotente).
typedef ObjectiveMetSignal = void Function();

/// Handle opaco de sesión.
///
/// Las vistas usan únicamente este objeto para emitir señales; nunca reciben el
/// `ActivityTelemetryService` directamente ni construyen mapas de Firestore.
/// Toda la experiencia debe funcionar igual cuando este handle es `null`.
class ActivitySessionHandle {
  ActivitySessionHandle({
    required this.sessionId,
    required this.onActivityReady,
    required this.onObjectiveMet,
    required this.onRecordAttempts,
    required this.onStartRetryRun,
    required this.onRecordVideoReplay,
    required this.onComplete,
    required this.onFail,
    required this.onAbandon,
    required this.onLaunchError,
  });

  /// Identificador único de la sesión (UUID v4).
  final String sessionId;

  final VoidSignal onActivityReady;
  final VoidSignal onObjectiveMet;
  final AttemptsSignal onRecordAttempts;
  final VoidSignal onStartRetryRun;
  final VoidSignal onRecordVideoReplay;
  final CompleteSignal onComplete;
  final VoidSignal onFail;
  final AbandonSignal onAbandon;
  final AbandonSignal onLaunchError;
}

/// Señal sin argumentos.
typedef VoidSignal = void Function();

/// Registra intentos de un run.
typedef AttemptsSignal = void Function(int attempts);

/// Cierra la sesión como completada.
typedef CompleteSignal = void Function();

/// Abandona la sesión con una razón controlada.
typedef AbandonSignal = void Function(TerminalReason reason);