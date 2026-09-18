import 'package:cloud_firestore/cloud_firestore.dart';
import 'telemetry_enums.dart';

/// Modelo inmutable del documento canónico `telemetryActivitySessions/{sessionId}`.
///
/// No contiene dependencias de widgets. La serialización es canónica según el
/// esquema v1 de `docs/telemetry-implementation.md`.
class ActivityTelemetrySession {
  const ActivityTelemetrySession({
    required this.schemaVersion,
    required this.sessionId,
    required this.subject,
    required this.activity,
    required this.outcome,
    required this.timing,
    required this.lifecycle,
    required this.interaction,
    required this.video,
    required this.client,
    this.createdAt,
    this.updatedAt,
  });

  /// Versión del esquema. Inicia en 1.
  final int schemaVersion;

  /// ID del documento (UUID v4).
  final String sessionId;

  final TelemetrySubject subject;
  final TelemetryActivity activity;
  final TelemetryOutcome outcome;
  final TelemetryTiming timing;
  final TelemetryLifecycle lifecycle;
  final TelemetryInteraction interaction;
  final TelemetryVideo video;
  final TelemetryClient client;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  static const int currentSchemaVersion = 1;

  /// Construye el documento inicial de una sesión en estado `launch_requested`.
  factory ActivityTelemetrySession.launchRequested({
    required String sessionId,
    required String learnerId,
    required String actorId,
    required TelemetryActivityType activityType,
    required String moduleId,
    required String levelId,
    String? difficulty,
    int? gridSize,
    required TelemetryClient client,
  }) {
    final activityId = '$moduleId:$levelId:${activityType.value}';
    return ActivityTelemetrySession(
      schemaVersion: currentSchemaVersion,
      sessionId: sessionId,
      subject: TelemetrySubject(
        learnerId: learnerId,
        actorId: actorId,
        identityModel: IdentityModel.accountAsLearner,
      ),
      activity: TelemetryActivity(
        activityId: activityId,
        moduleId: moduleId,
        levelId: levelId,
        activityType: activityType,
        difficulty: difficulty,
        gridSize: gridSize,
      ),
      outcome: const TelemetryOutcome(),
      timing: TelemetryTiming(launchRequestedAt: null),
      lifecycle: const TelemetryLifecycle(status: SessionState.launchRequested),
      interaction: TelemetryInteraction.from(activityType),
      video: TelemetryVideo.from(activityType),
      client: client,
    );
  }

  ActivityTelemetrySession copyWith({
    TelemetrySubject? subject,
    TelemetryActivity? activity,
    TelemetryOutcome? outcome,
    TelemetryTiming? timing,
    TelemetryLifecycle? lifecycle,
    TelemetryInteraction? interaction,
    TelemetryVideo? video,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ActivityTelemetrySession(
      schemaVersion: schemaVersion,
      sessionId: sessionId,
      subject: subject ?? this.subject,
      activity: activity ?? this.activity,
      outcome: outcome ?? this.outcome,
      timing: timing ?? this.timing,
      lifecycle: lifecycle ?? this.lifecycle,
      interaction: interaction ?? this.interaction,
      video: video ?? this.video,
      client: client,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialización canónica del esquema v1.
  ///
  /// Los timestamps de auditoría quedan tal cual; el repositorio aplica
  /// `FieldValue.serverTimestamp()` a los campos que correspondan al escribir.
  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'sessionId': sessionId,
      'subject': subject.toMap(),
      'activity': activity.toMap(),
      'outcome': outcome.toMap(),
      'timing': timing.toMap(),
      'lifecycle': lifecycle.toMap(),
      'interaction': interaction.toMap(),
      'video': video.toMap(),
      'client': client.toMap(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  /// Deserializa desde un snapshot de Firestore.
  static ActivityTelemetrySession? fromMap(
    Map<String, dynamic>? data, {
    required String sessionId,
  }) {
    if (data == null) return null;

    final subjectMap = data['subject'] as Map<String, dynamic>?;
    final activityMap = data['activity'] as Map<String, dynamic>?;
    final outcomeMap = data['outcome'] as Map<String, dynamic>?;
    final timingMap = data['timing'] as Map<String, dynamic>?;
    final lifecycleMap = data['lifecycle'] as Map<String, dynamic>?;
    final interactionMap = data['interaction'] as Map<String, dynamic>?;
    final videoMap = data['video'] as Map<String, dynamic>?;
    final clientMap = data['client'] as Map<String, dynamic>?;
    if (subjectMap == null ||
        activityMap == null ||
        outcomeMap == null ||
        timingMap == null ||
        lifecycleMap == null ||
        clientMap == null) {
      return null;
    }

    final subject = TelemetrySubject.fromMap(subjectMap);
    final activity = TelemetryActivity.fromMap(activityMap);
    final outcome = TelemetryOutcome.fromMap(outcomeMap);
    final timing = TelemetryTiming.fromMap(timingMap);
    final lifecycle = TelemetryLifecycle.fromMap(lifecycleMap);
    final interaction = TelemetryInteraction.fromMap(interactionMap);
    final video = TelemetryVideo.fromMap(videoMap);
    final client = TelemetryClient.fromMap(clientMap);
    if (subject == null ||
        activity == null ||
        outcome == null ||
        timing == null ||
        lifecycle == null ||
        client == null) {
      return null;
    }

    return ActivityTelemetrySession(
      schemaVersion: data['schemaVersion'] as int? ?? 0,
      sessionId: sessionId,
      subject: subject,
      activity: activity,
      outcome: outcome,
      timing: timing,
      lifecycle: lifecycle,
      interaction: interaction ?? const TelemetryInteraction(),
      video: video ?? const TelemetryVideo(),
      client: client,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}

/// Identidad semántica del sujeto sin PII.
class TelemetrySubject {
  const TelemetrySubject({
    required this.learnerId,
    required this.actorId,
    required this.identityModel,
  });

  final String learnerId;
  final String actorId;
  final IdentityModel identityModel;

  Map<String, dynamic> toMap() => {
        'learnerId': learnerId,
        'actorId': actorId,
        'identityModel': identityModel.value,
      };

  static TelemetrySubject? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final learnerId = data['learnerId'] as String?;
    final actorId = data['actorId'] as String?;
    if (learnerId == null || actorId == null) return null;
    return TelemetrySubject(
      learnerId: learnerId,
      actorId: actorId,
      identityModel:
          IdentityModel.accountAsLearner, // Fijo mientras rija este modelo.
    );
  }
}

/// Identidad y clasificación de la actividad.
class TelemetryActivity {
  const TelemetryActivity({
    required this.activityId,
    required this.moduleId,
    required this.levelId,
    required this.activityType,
    this.difficulty,
    this.gridSize,
  });

  final String activityId;
  final String moduleId;
  final String levelId;
  final TelemetryActivityType activityType;
  final String? difficulty;
  final int? gridSize;

  Map<String, dynamic> toMap() => {
        'activityId': activityId,
        'moduleId': moduleId,
        'levelId': levelId,
        'activityType': activityType.value,
        if (difficulty != null) 'difficulty': difficulty,
        if (gridSize != null) 'gridSize': gridSize,
      };

  static TelemetryActivity? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final moduleId = data['moduleId'] as String?;
    final levelId = data['levelId'] as String?;
    final type = TelemetryActivityType.fromValue(data['activityType'] as String?);
    if (moduleId == null || levelId == null || type == null) return null;
    return TelemetryActivity(
      activityId: data['activityId'] as String? ??
          '$moduleId:$levelId:${type.value}',
      moduleId: moduleId,
      levelId: levelId,
      activityType: type,
      difficulty: data['difficulty'] as String?,
      gridSize: data['gridSize'] as int?,
    );
  }
}

/// Flags derivados y resultado terminal.
class TelemetryOutcome {
  const TelemetryOutcome({
    this.hasStarted = false,
    this.objectiveReached = false,
    this.isCompleted = false,
    this.navigationSuccessful = false,
    this.terminalReason,
  });

  final bool hasStarted;
  final bool objectiveReached;
  final bool isCompleted;
  final bool navigationSuccessful;
  final TerminalReason? terminalReason;

  TelemetryOutcome copyWith({
    bool? hasStarted,
    bool? objectiveReached,
    bool? isCompleted,
    bool? navigationSuccessful,
    TerminalReason? terminalReason,
    bool clearTerminalReason = false,
  }) {
    return TelemetryOutcome(
      hasStarted: hasStarted ?? this.hasStarted,
      objectiveReached: objectiveReached ?? this.objectiveReached,
      isCompleted: isCompleted ?? this.isCompleted,
      navigationSuccessful: navigationSuccessful ?? this.navigationSuccessful,
      terminalReason: clearTerminalReason
          ? null
          : terminalReason ?? this.terminalReason,
    );
  }

  Map<String, dynamic> toMap() => {
        'hasStarted': hasStarted,
        'objectiveReached': objectiveReached,
        'isCompleted': isCompleted,
        'navigationSuccessful': navigationSuccessful,
        'terminalReason': terminalReason?.value,
      };

  static TelemetryOutcome? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return TelemetryOutcome(
      hasStarted: data['hasStarted'] as bool? ?? false,
      objectiveReached: data['objectiveReached'] as bool? ?? false,
      isCompleted: data['isCompleted'] as bool? ?? false,
      navigationSuccessful: data['navigationSuccessful'] as bool? ?? false,
      terminalReason: TerminalReason.fromValue(
        data['terminalReason'] as String?,
      ),
    );
  }
}

/// Duración monotónica y timestamps de auditoría.
class TelemetryTiming {
  const TelemetryTiming({
    this.activeDurationMs = 0,
    this.activeSegmentCount = 0,
    this.launchRequestedAt,
    this.startedAt,
    this.objectiveMetAt,
    this.terminalAt,
  });

  final int activeDurationMs;
  final int activeSegmentCount;
  final Timestamp? launchRequestedAt;
  final Timestamp? startedAt;
  final Timestamp? objectiveMetAt;
  final Timestamp? terminalAt;

  TelemetryTiming copyWith({
    int? activeDurationMs,
    int? activeSegmentCount,
    Timestamp? launchRequestedAt,
    Timestamp? startedAt,
    Timestamp? objectiveMetAt,
    Timestamp? terminalAt,
  }) {
    return TelemetryTiming(
      activeDurationMs: activeDurationMs ?? this.activeDurationMs,
      activeSegmentCount: activeSegmentCount ?? this.activeSegmentCount,
      launchRequestedAt: launchRequestedAt ?? this.launchRequestedAt,
      startedAt: startedAt ?? this.startedAt,
      objectiveMetAt: objectiveMetAt ?? this.objectiveMetAt,
      terminalAt: terminalAt ?? this.terminalAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'activeDurationMs': activeDurationMs,
        'activeSegmentCount': activeSegmentCount,
        if (launchRequestedAt != null) 'launchRequestedAt': launchRequestedAt,
        if (startedAt != null) 'startedAt': startedAt,
        if (objectiveMetAt != null) 'objectiveMetAt': objectiveMetAt,
        if (terminalAt != null) 'terminalAt': terminalAt,
      };

  static TelemetryTiming? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return TelemetryTiming(
      activeDurationMs: data['activeDurationMs'] as int? ?? 0,
      activeSegmentCount: data['activeSegmentCount'] as int? ?? 0,
      launchRequestedAt: data['launchRequestedAt'] as Timestamp?,
      startedAt: data['startedAt'] as Timestamp?,
      objectiveMetAt: data['objectiveMetAt'] as Timestamp?,
      terminalAt: data['terminalAt'] as Timestamp?,
    );
  }
}

/// Estado actual e interrupciones.
class TelemetryLifecycle {
  const TelemetryLifecycle({
    required this.status,
    this.wasInterrupted = false,
    this.interruptionCount = 0,
    this.lastBackgroundAt,
    this.lastResumedAt,
  });

  final SessionState status;
  final bool wasInterrupted;
  final int interruptionCount;
  final Timestamp? lastBackgroundAt;
  final Timestamp? lastResumedAt;

  TelemetryLifecycle copyWith({
    SessionState? status,
    bool? wasInterrupted,
    int? interruptionCount,
    Timestamp? lastBackgroundAt,
    Timestamp? lastResumedAt,
  }) {
    return TelemetryLifecycle(
      status: status ?? this.status,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      lastBackgroundAt: lastBackgroundAt ?? this.lastBackgroundAt,
      lastResumedAt: lastResumedAt ?? this.lastResumedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'wasInterrupted': wasInterrupted,
        'interruptionCount': interruptionCount,
        if (lastBackgroundAt != null) 'lastBackgroundAt': lastBackgroundAt,
        if (lastResumedAt != null) 'lastResumedAt': lastResumedAt,
      };

  static TelemetryLifecycle? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final status = SessionState.fromValue(data['status'] as String?);
    if (status == null) return null;
    return TelemetryLifecycle(
      status: status,
      wasInterrupted: data['wasInterrupted'] as bool? ?? false,
      interruptionCount: data['interruptionCount'] as int? ?? 0,
      lastBackgroundAt: data['lastBackgroundAt'] as Timestamp?,
      lastResumedAt: data['lastResumedAt'] as Timestamp?,
    );
  }
}

/// Métricas de actividades interactivas.
class TelemetryInteraction {
  const TelemetryInteraction({
    this.attemptsApplicable = false,
    this.attempts,
    this.runCount = 0,
  });

  final bool attemptsApplicable;
  final int? attempts;
  final int runCount;

  TelemetryInteraction copyWith({
    bool? attemptsApplicable,
    int? attempts,
    int? runCount,
  }) {
    return TelemetryInteraction(
      attemptsApplicable: attemptsApplicable ?? this.attemptsApplicable,
      attempts: attempts ?? this.attempts,
      runCount: runCount ?? this.runCount,
    );
  }

  /// Construye el valor por defecto según el tipo de actividad.
  factory TelemetryInteraction.from(TelemetryActivityType type) {
    if (!type.attemptsApplicable) {
      return const TelemetryInteraction();
    }
    return const TelemetryInteraction(
      attemptsApplicable: true,
      attempts: 0,
      runCount: 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'attemptsApplicable': attemptsApplicable,
        'attempts': attempts,
        'runCount': runCount,
      };

  static TelemetryInteraction? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return TelemetryInteraction(
      attemptsApplicable: data['attemptsApplicable'] as bool? ?? false,
      attempts: data['attempts'] as int?,
      runCount: data['runCount'] as int? ?? 0,
    );
  }
}

/// Métricas exclusivas de video, con defaults para esquema uniforme.
class TelemetryVideo {
  const TelemetryVideo({
    this.replayCount = 0,
    this.objectiveThreshold,
  });

  final int replayCount;
  final double? objectiveThreshold;

  TelemetryVideo copyWith({
    int? replayCount,
    double? objectiveThreshold,
  }) {
    return TelemetryVideo(
      replayCount: replayCount ?? this.replayCount,
      objectiveThreshold: objectiveThreshold ?? this.objectiveThreshold,
    );
  }

  /// Construye el valor por defecto según el tipo de actividad.
  factory TelemetryVideo.from(TelemetryActivityType type) {
    if (type == TelemetryActivityType.video) {
      return const TelemetryVideo(
        replayCount: 0,
        objectiveThreshold: 0.9,
      );
    }
    return const TelemetryVideo();
  }

  Map<String, dynamic> toMap() => {
        'replayCount': replayCount,
        'objectiveThreshold': objectiveThreshold,
      };

  static TelemetryVideo? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return TelemetryVideo(
      replayCount: data['replayCount'] as int? ?? 0,
      objectiveThreshold: data['objectiveThreshold'] as double?,
    );
  }
}

/// Contexto técnico no identificable.
class TelemetryClient {
  const TelemetryClient({
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.locale,
  });

  final String platform;
  final String appVersion;
  final String buildNumber;
  final String locale;

  Map<String, dynamic> toMap() => {
        'platform': platform,
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'locale': locale,
      };

  static TelemetryClient? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final platform = data['platform'] as String?;
    final appVersion = data['appVersion'] as String?;
    final buildNumber = data['buildNumber'] as String?;
    final locale = data['locale'] as String?;
    if (platform == null ||
        appVersion == null ||
        buildNumber == null ||
        locale == null) {
      return null;
    }
    return TelemetryClient(
      platform: platform,
      appVersion: appVersion,
      buildNumber: buildNumber,
      locale: locale,
    );
  }
}