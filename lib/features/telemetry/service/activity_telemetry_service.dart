import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../data/telemetry_repository.dart';
import '../model/activity_telemetry_session.dart';
import '../model/telemetry_enums.dart';
import '../model/telemetry_signals.dart';
import 'active_session_clock.dart';
import 'pending_session_store.dart';

/// Resultado de una operación de consentimiento opt-out.
class OptOutResult {
  const OptOutResult({
    required this.sessionClosed,
    this.error,
  });

  final bool sessionClosed;
  final TelemetryRepositoryException? error;
}

/// Servicio de telemetría de actividades.
///
/// Máquina de estados, consentimiento, UID, lifecycle, deduplicación terminal y
/// coordinación de persistencia. Es provisto por Provider y no expone Firebase
/// a las vistas. Las vistas emiten señales semánticas mediante
/// [ActivitySessionHandle].
class ActivityTelemetryService extends WidgetsBindingObserver {
  /// Referencia global para coordinación sin contexto (p.ej. logout desde
  /// servicios). Se asigna en el constructor y se limpia en [dispose].
  static ActivityTelemetryService? instance;

  ActivityTelemetryService({
    required TelemetryRepository repository,
    required PendingSessionStore pendingStore,
    required String? Function() uidProvider,
    ActiveSessionClock Function()? clockFactory,
    Uuid? uuid,
    DateTime Function()? now,
    this.inactivityWindow = const Duration(minutes: 15),
  })  : _repository = repository,
        _pendingStore = pendingStore,
        _uidProvider = uidProvider,
        _clockFactory = clockFactory ?? ActiveSessionClock.new,
        _uuid = uuid ?? const Uuid(),
        _now = now ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
    instance = this;
  }

  final TelemetryRepository _repository;
  final PendingSessionStore _pendingStore;
  final String? Function() _uidProvider;
  final ActiveSessionClock Function() _clockFactory;
  final Uuid _uuid;
  final DateTime Function() _now;
  final Duration inactivityWindow;

  bool _consentReady = false;
  bool _consentEnabled = false;

  // Sesiones activas (no terminales) por sessionId.
  final Map<String, _SessionRuntime> _sessions = {};

  // Última operación fallida sin PII (para diagnóstico/soporte).
  String? _lastError;
  String? get lastError => _lastError;
  int get activeSessionCount => _sessions.length;

  /// Coordina el consentimiento desde SettingsViewModel.
  ///
  /// Cuando el consentimiento se desactiva, intenta un único cierre best-effort
  /// de la sesión iniciada activa como `telemetry_opt_out`.
  Future<void> updateConsent({
    required bool ready,
    required bool enabled,
  }) async {
    final wasEnabled = _consentEnabled && _consentReady;
    _consentReady = ready;
    _consentEnabled = enabled;
    final nowEnabled = enabled && ready;

    if (wasEnabled && !nowEnabled) {
      await _optOutActiveSessions();
    }
  }

  bool get _consentActive => _consentReady && _consentEnabled;

  /// Solicita un contexto de sesión para una actividad. Devuelve un handle
  /// opaco o `null` si el consentimiento no está listo/activo o no hay UID.
  ///
  /// El consentimiento se captura en este instante; señales posteriores se
  /// ignoran si no se creó contexto.
  ActivitySessionHandle? requestLaunch({
    required String moduleId,
    required String levelId,
    required TelemetryActivityType activityType,
    String? difficulty,
    int? gridSize,
    required TelemetryClient client,
  }) {
    if (!_consentActive) return null;
    final actorId = _uidProvider();
    if (actorId == null || actorId.isEmpty) return null;
    if (moduleId.trim().isEmpty || levelId.trim().isEmpty) return null;

    final sessionId = _uuid.v4();
    final session = ActivityTelemetrySession.launchRequested(
      sessionId: sessionId,
      learnerId: actorId,
      actorId: actorId,
      activityType: activityType,
      moduleId: moduleId,
      levelId: levelId,
      difficulty: difficulty,
      gridSize: gridSize,
      client: client,
    );

    final runtime = _SessionRuntime(
      session: session,
      clock: _clockFactory(),
    );
    _sessions[sessionId] = runtime;
    runtime.chain = runtime.chain.then((_) async {
      try {
        await _repository.create(session);
        await _saveMarker(runtime);
      } on TelemetryRepositoryException catch (e) {
        _recordError(e);
      }
    });

    return _buildHandle(sessionId);
  }

  ActivitySessionHandle _buildHandle(String sessionId) {
    return ActivitySessionHandle(
      sessionId: sessionId,
      onActivityReady: () => activityReady(sessionId),
      onObjectiveMet: () => objectiveMet(sessionId),
      onRecordAttempts: (attempts) => recordAttempts(sessionId, attempts),
      onStartRetryRun: () => startRetryRun(sessionId),
      onRecordVideoReplay: () => recordVideoReplay(sessionId),
      onComplete: () => complete(sessionId),
      onFail: () => fail(sessionId),
      onAbandon: (reason) => abandon(sessionId, reason),
      onLaunchError: (reason) => launchError(sessionId, reason),
    );
  }

  _SessionRuntime? _runtime(String sessionId) => _sessions[sessionId];

  /// La actividad notificó que está lista. Marca `started` y arranca el reloj.
  void activityReady(String sessionId) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal) return;
    if (runtime.started) return;
    runtime.started = true;

    runtime.clock.startSegment();
    runtime.session = runtime.session.copyWith(
      outcome: runtime.session.outcome.copyWith(hasStarted: true),
      timing: runtime.session.timing.copyWith(activeSegmentCount: runtime.clock.segmentCount),
      lifecycle: runtime.session.lifecycle.copyWith(status: SessionState.started),
    );

    _enqueue(runtime, {
      'outcome.hasStarted': true,
      'lifecycle.status': SessionState.started.value,
      'timing.activeSegmentCount': runtime.clock.segmentCount,
      'timing.startedAt': ServerTimestamp.instance,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  /// Se alcanzó el objetivo pedagógico/umbral. Detiene el reloj.
  ///
  /// No terminaliza por sí sola: para interactivas la terminalización la decide
  /// el resultado del run (que también registra intentos); para media/video la
  /// sesión permanece no terminal hasta la decisión de producto.
  void objectiveMet(String sessionId) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal || !runtime.started) return;
    if (runtime.objectiveEmitted) return;
    runtime.objectiveEmitted = true;

    runtime.clock.stopSegment();
    runtime.session = runtime.session.copyWith(
      outcome: runtime.session.outcome.copyWith(objectiveReached: true),
      timing: runtime.session.timing.copyWith(
        activeDurationMs: runtime.clock.activeMs,
      ),
    );

    _enqueue(runtime, {
      'outcome.objectiveReached': true,
      'timing.objectiveMetAt': ServerTimestamp.instance,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  /// Acumula intentos de un run. Idempotente por run (se consume una vez).
  void recordAttempts(String sessionId, int attempts) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal || !runtime.started) return;
    if (runtime.runAttemptsCommitted) return;
    if (attempts <= 0) return;
    runtime.runAttemptsCommitted = true;

    final current = runtime.session.interaction.attempts ?? 0;
    runtime.session = runtime.session.copyWith(
      interaction: runtime.session.interaction.copyWith(
        attempts: current + attempts,
      ),
    );

    _enqueue(runtime, {
      'interaction.attempts': current + attempts,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  /// Aumenta `interaction.runCount` al reintentar (misma sesión y acumulados).
  void startRetryRun(String sessionId) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal || !runtime.started) return;

    runtime.runAttemptsCommitted = false;
    final nextRun = runtime.session.interaction.runCount + 1;
    runtime.session = runtime.session.copyWith(
      interaction: runtime.session.interaction.copyWith(runCount: nextRun),
    );

    _enqueue(runtime, {
      'interaction.runCount': nextRun,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  /// Taps explícitos de replay de video. Reanuda un segmento si la sesión sigue
  /// activa con objetivo alcanzado.
  void recordVideoReplay(String sessionId) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal || !runtime.started) return;

    final next = runtime.session.video.replayCount + 1;
    runtime.session = runtime.session.copyWith(
      video: runtime.session.video.copyWith(replayCount: next),
    );

    // Reanuda el reloj para la reproducción post-objetivo en video.
    if (runtime.session.outcome.objectiveReached && !runtime.clock.isRunning) {
      runtime.clock.startSegment();
    }

    _enqueue(runtime, {
      'video.replayCount': next,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  /// Terminaliza como completada.
  void complete(String sessionId) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal || !runtime.started) return;
    if (!runtime.session.outcome.objectiveReached) return;

    runtime.clock.stopSegment();
    _terminalize(
      runtime,
      status: SessionState.completed,
      reason: TerminalReason.objectiveCompleted,
    );
  }

  /// Terminaliza como fallida (reintentos agotados / fallo definitivo).
  void fail(String sessionId) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal || !runtime.started) return;
    runtime.clock.stopSegment();
    _terminalize(
      runtime,
      status: SessionState.failed,
      reason: TerminalReason.attemptsExhausted,
    );
  }

  /// Abandona la sesión iniciada con una razón controlada.
  void abandon(String sessionId, TerminalReason reason) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal) return;
    if (!runtime.started) return; // Salir antes de started es launch_error, no abandono.
    if (!TerminalReason.abandonedReasons.contains(reason)) return;
    runtime.clock.stopSegment();
    _terminalize(
      runtime,
      status: SessionState.abandoned,
      reason: reason,
    );
  }

  /// Cierra como `launch_error` una sesión que no llegó a `started`
  /// (actividad no disponible, invalid data, error de navegación/inicialización).
  void launchError(String sessionId, TerminalReason reason) {
    final runtime = _runtime(sessionId);
    if (runtime == null || runtime.terminal) return;
    if (runtime.started) return; // No hay launch_error después de started.
    if (!TerminalReason.launchErrorReasons.contains(reason)) return;

    runtime.terminal = true;
    runtime.session = runtime.session.copyWith(
      outcome: runtime.session.outcome.copyWith(terminalReason: reason),
      lifecycle: runtime.session.lifecycle.copyWith(
        status: SessionState.launchError,
      ),
    );

    _enqueue(
      runtime,
      {
        'lifecycle.status': SessionState.launchError.value,
        'outcome.isCompleted': false,
        'outcome.navigationSuccessful': false,
        'outcome.terminalReason': reason.value,
        'timing.terminalAt': ServerTimestamp.instance,
      },
      terminal: true,
    );
  }

  void _terminalize(
    _SessionRuntime runtime, {
    required SessionState status,
    required TerminalReason reason,
    Map<String, dynamic>? patch,
  }) {
    if (runtime.terminal) return;
    runtime.terminal = true;

    final outcome = runtime.session.outcome;
    runtime.session = runtime.session.copyWith(
      outcome: outcome.copyWith(
        isCompleted: status == SessionState.completed,
        navigationSuccessful:
            status == SessionState.completed && !runtime.session.lifecycle.wasInterrupted,
        terminalReason: reason,
      ),
      timing: runtime.session.timing.copyWith(
        activeDurationMs: runtime.clock.activeMs,
      ),
      lifecycle: runtime.session.lifecycle.copyWith(status: status),
    );

    final base = {
      'lifecycle.status': status.value,
      'outcome.isCompleted': status == SessionState.completed,
      'outcome.navigationSuccessful':
          status == SessionState.completed && !runtime.session.lifecycle.wasInterrupted,
      'outcome.terminalReason': reason.value,
      'timing.terminalAt': ServerTimestamp.instance,
      'timing.activeDurationMs': runtime.clock.activeMs,
      if (patch != null) ...patch,
    };

    _enqueue(runtime, base, terminal: true);
  }

  void _enqueue(
    _SessionRuntime runtime,
    Map<String, dynamic> patch, {
    bool terminal = false,
  }) {
    runtime.chain = runtime.chain.then((_) async {
      try {
        if (terminal) {
          await _repository.updateIfNotTerminal(runtime.session.sessionId, patch);
        } else {
          await _repository.update(runtime.session.sessionId, patch);
        }
        await _saveMarker(runtime);
        if (terminal) {
          await _pendingStore.clear(runtime.session.subject.actorId);
          _sessions.remove(runtime.session.sessionId);
        }
      } on TelemetryRepositoryException catch (e) {
        _recordError(e);
        if (terminal) {
          // Terminal best-effort: no reintentar; limpiar marcador.
          await _pendingStore.clear(runtime.session.subject.actorId);
          _sessions.remove(runtime.session.sessionId);
        }
      }
    });
  }

  Future<void> _saveMarker(_SessionRuntime runtime) async {
    final session = runtime.session;
    await _pendingStore.write(
      PendingSessionMarker(
        sessionId: runtime.session.sessionId,
        actorId: session.subject.actorId,
        moduleId: session.activity.moduleId,
        levelId: session.activity.levelId,
        activityType: session.activity.activityType,
        lastStatus: session.lifecycle.status,
        activeDurationMs: runtime.clock.activeMs,
        attempts: session.interaction.attempts ?? 0,
        runCount: session.interaction.runCount,
        replayCount: session.video.replayCount,
        wasInterrupted: session.lifecycle.wasInterrupted,
        interruptionCount: session.lifecycle.interruptionCount,
        objectiveReached: session.outcome.objectiveReached,
        lastLocalBackgroundAt: _now(),
      ),
    );
  }

  // ── Lifecycle global ───────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;

    for (final runtime in _sessions.values.toList()) {
      if (!runtime.started || runtime.terminal) continue;
      if (background && !runtime.inBackground) {
        runtime.inBackground = true;
        runtime.backgroundStartedAt = _now();
        runtime.clock.stopSegment();
        _onBackground(runtime);
      } else if (state == AppLifecycleState.resumed && runtime.inBackground) {
        runtime.inBackground = false;
        final elapsed = _now().difference(runtime.backgroundStartedAt ?? _now());
        if (elapsed >= inactivityWindow) {
          _onInactivityTimeout(runtime);
        } else {
          _onResumed(runtime);
        }
      }
    }
  }

  void _onBackground(_SessionRuntime runtime) {
    final session = runtime.session;
    final nextInterruption = session.lifecycle.interruptionCount + 1;
    runtime.session = session.copyWith(
      lifecycle: session.lifecycle.copyWith(
        wasInterrupted: true,
        interruptionCount: nextInterruption,
      ),
      timing: session.timing.copyWith(activeDurationMs: runtime.clock.activeMs),
    );
    _enqueue(runtime, {
      'lifecycle.wasInterrupted': true,
      'lifecycle.interruptionCount': nextInterruption,
      'lifecycle.lastBackgroundAt': ServerTimestamp.instance,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  void _onResumed(_SessionRuntime runtime) {
    if (runtime.terminal) return;
    // Reanudar segmento solo si el objetivo aún no se alcanzó (o en video se
    // reanuda manualmente al hacer replay).
    if (!runtime.session.outcome.objectiveReached) {
      runtime.clock.startSegment();
    }
    _enqueue(runtime, {
      'lifecycle.lastResumedAt': ServerTimestamp.instance,
      'timing.activeDurationMs': runtime.clock.activeMs,
    });
  }

  void _onInactivityTimeout(_SessionRuntime runtime) {
    _terminalize(
      runtime,
      status: SessionState.abandoned,
      reason: TerminalReason.inactivityTimeout,
    );
  }

  // ── Opt-out seguro ─────────────────────────────────────────────────────────

  Future<OptOutResult> _optOutActiveSessions() async {
    var closed = false;
    TelemetryRepositoryException? error;
    for (final runtime in _sessions.values.toList()) {
      if (runtime.terminal) {
        await _pendingStore.clear(runtime.session.subject.actorId);
        _sessions.remove(runtime.session.sessionId);
        continue;
      }
      runtime.clock.stopSegment();
      // Un único intento best-effort, serializado tras escrituras en vuelo.
      final task = runtime.chain.then((_) async {
        try {
          await _repository.updateIfNotTerminal(
            runtime.session.sessionId,
            {
              'lifecycle.status': SessionState.abandoned.value,
              'outcome.isCompleted': false,
              'outcome.navigationSuccessful': false,
              'outcome.terminalReason': TerminalReason.telemetryOptOut.value,
              'timing.terminalAt': ServerTimestamp.instance,
              'timing.activeDurationMs': runtime.clock.activeMs,
            },
          );
          closed = true;
        } on TelemetryRepositoryException catch (e) {
          error = e;
        }
        // Independientemente del resultado, descartar payload/marcador.
        await _pendingStore.clear(runtime.session.subject.actorId);
      });
      runtime.chain = task;
      await task;
      _sessions.remove(runtime.session.sessionId);
    }
    return OptOutResult(sessionClosed: closed, error: error);
  }

  /// Cierre best-effort de una sesión iniciada antes del logout.
  Future<void> closeActiveSessionForLogout() async {
    for (final runtime in _sessions.values.toList()) {
      if (runtime.terminal) continue;
      if (!runtime.started) continue;
      runtime.clock.stopSegment();
      final task = runtime.chain.then((_) async {
        try {
          await _repository.updateIfNotTerminal(
            runtime.session.sessionId,
            {
              'lifecycle.status': SessionState.abandoned.value,
              'outcome.terminalReason': TerminalReason.userExit.value,
              'timing.terminalAt': ServerTimestamp.instance,
              'timing.activeDurationMs': runtime.clock.activeMs,
            },
          );
        } catch (_) {}
        await _pendingStore.clear(runtime.session.subject.actorId);
      });
      runtime.chain = task;
      await task;
      _sessions.remove(runtime.session.sessionId);
    }
  }

  /// Reconciliación de arranque de marcador pendiente (proceso muerto).
  Future<void> reconcilePending({required bool consentEnabled}) async {
    final actorId = _uidProvider();
    if (actorId == null) return;
    final marker = _pendingStore.read(actorId);
    if (marker == null) return;

    // Sin opt-in: borrar marcador sin escribir remoto.
    if (!consentEnabled) {
      await _pendingStore.clear(actorId);
      return;
    }

    // UID distinto al actor del marcador: no escribir con otra identidad.
    if (marker.actorId != actorId) {
      await _pendingStore.clear(actorId);
      return;
    }

    // Sesión ya terminal en Firestore: limpiar marcador.
    try {
      final remote = await _repository.read(marker.sessionId);
      if (remote == null || remote.lifecycle.status.isTerminal) {
        await _pendingStore.clear(actorId);
        return;
      }
    } on TelemetryRepositoryException {
      // No reescribir ni decidir sobre error aquí; conservar marcador.
      return;
    }

    // Ausencia >= 15 min: terminalizar `stale_session` con duración acumulada.
    final elapsed = _now().difference(marker.lastLocalBackgroundAt);
    if (elapsed >= inactivityWindow) {
      try {
        await _repository.updateIfNotTerminal(
          marker.sessionId,
          {
            'lifecycle.status': SessionState.abandoned.value,
            'outcome.terminalReason': TerminalReason.staleSession.value,
            'timing.terminalAt': ServerTimestamp.instance,
            'timing.activeDurationMs': marker.activeDurationMs,
          },
        );
      } catch (_) {}
      await _pendingStore.clear(actorId);
      return;
    }

    // Ausencia < 15 min: no podemos garantizar el mismo contexto de ruta;
    // abandonar como stale_session para no dejar un documento abierto.
    try {
      await _repository.updateIfNotTerminal(
        marker.sessionId,
        {
          'lifecycle.status': SessionState.abandoned.value,
          'outcome.terminalReason': TerminalReason.staleSession.value,
          'timing.terminalAt': ServerTimestamp.instance,
          'timing.activeDurationMs': marker.activeDurationMs,
        },
      );
    } catch (_) {}
    await _pendingStore.clear(actorId);
  }

  /// Limpieza al desregistrar el observer (final de la app).
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (instance == this) {
      instance = null;
    }
  }

  void _recordError(TelemetryRepositoryException e) {
    _lastError = '${e.operation}:${e.kind}';
  }
}

/// Estado interno mutable de una sesión activa.
class _SessionRuntime {
  _SessionRuntime({required this.session, required this.clock});

  ActivityTelemetrySession session;
  final ActiveSessionClock clock;
  Future<void> chain = Future.value();
  bool started = false;
  bool terminal = false;
  bool objectiveEmitted = false;
  bool runAttemptsCommitted = false;
  bool inBackground = false;
  DateTime? backgroundStartedAt;
}