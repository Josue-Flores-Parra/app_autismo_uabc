import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/telemetry_enums.dart';

/// Marcador local mínimo de una sesión pendiente.
///
/// Permite reconciliar una sesión iniciada si el proceso muere o pasa a
/// background. No guarda nombre, correo, URLs de contenido ni stack traces.
class PendingSessionMarker {
  const PendingSessionMarker({
    required this.sessionId,
    required this.actorId,
    required this.moduleId,
    required this.levelId,
    required this.activityType,
    required this.lastStatus,
    required this.activeDurationMs,
    required this.runCount,
    required this.replayCount,
    required this.wasInterrupted,
    required this.interruptionCount,
    required this.objectiveReached,
    this.attempts = 0,
    required this.lastLocalBackgroundAt,
  });

  final String sessionId;
  final String actorId;
  final String moduleId;
  final String levelId;
  final TelemetryActivityType activityType;
  final SessionState lastStatus;
  final int activeDurationMs;
  final int attempts;
  final int runCount;
  final int replayCount;
  final bool wasInterrupted;
  final int interruptionCount;
  final bool objectiveReached;

  /// Instante local de background/última persistencia para la ventana de 15 min.
  final DateTime lastLocalBackgroundAt;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'actorId': actorId,
        'moduleId': moduleId,
        'levelId': levelId,
        'activityType': activityType.value,
        'lastStatus': lastStatus.value,
        'activeDurationMs': activeDurationMs,
        'attempts': attempts,
        'runCount': runCount,
        'replayCount': replayCount,
        'wasInterrupted': wasInterrupted,
        'interruptionCount': interruptionCount,
        'objectiveReached': objectiveReached,
        'lastLocalBackgroundAt':
            lastLocalBackgroundAt.toIso8601String(),
      };

  static PendingSessionMarker? fromJson(Map<String, dynamic> json) {
    final sessionId = json['sessionId'] as String?;
    final actorId = json['actorId'] as String?;
    final moduleId = json['moduleId'] as String?;
    final levelId = json['levelId'] as String?;
    final activityType = TelemetryActivityType.fromValue(
      json['activityType'] as String?,
    );
    final lastStatus = SessionState.fromValue(json['lastStatus'] as String?);
    final background = DateTime.tryParse(
      json['lastLocalBackgroundAt'] as String? ?? '',
    );
    if (sessionId == null ||
        actorId == null ||
        moduleId == null ||
        levelId == null ||
        activityType == null ||
        lastStatus == null ||
        background == null) {
      return null;
    }
    return PendingSessionMarker(
      sessionId: sessionId,
      actorId: actorId,
      moduleId: moduleId,
      levelId: levelId,
      activityType: activityType,
      lastStatus: lastStatus,
      activeDurationMs: json['activeDurationMs'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      runCount: json['runCount'] as int? ?? 0,
      replayCount: json['replayCount'] as int? ?? 0,
      wasInterrupted: json['wasInterrupted'] as bool? ?? false,
      interruptionCount: json['interruptionCount'] as int? ?? 0,
      objectiveReached: json['objectiveReached'] as bool? ?? false,
      lastLocalBackgroundAt: background,
    );
  }
}

/// Almacén local de marcadores pendientes, namespaced por actor.
///
/// Persiste un único marcador por actor (el último iniciado) bajo una clave
/// derivada del UID. No expone PII ni URLs de contenido.
class PendingSessionStore {
  PendingSessionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'telemetry_pending_session_';

  String _key(String actorId) => '$_prefix$actorId';

  /// Devuelve el marcador pendiente del actor, o `null`.
  PendingSessionMarker? read(String actorId) {
    final raw = _prefs.getString(_key(actorId));
    if (raw == null) return null;
    try {
      return PendingSessionMarker.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Persiste un marcador para el actor.
  Future<void> write(PendingSessionMarker marker) async {
    await _prefs.setString(_key(marker.actorId), jsonEncode(marker.toJson()));
  }

  /// Elimina el marcador del actor.
  Future<void> clear(String actorId) async {
    await _prefs.remove(_key(actorId));
  }
}