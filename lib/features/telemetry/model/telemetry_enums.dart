/// Enums controlados para telemetría de sesiones.
///
/// Evitan strings libres en las capas superiores y garantizan que los valores
/// escritos en Firestore pertenezcan a un conjunto cerrado y versionado.
library;

/// Estados válidos de una sesión de actividad.
///
/// El estado canónico se persiste en `lifecycle.status`.
enum SessionState {
  /// El usuario confirmó el launch y existe un contexto de sesión.
  launchRequested('launch_requested'),

  /// La actividad notificó que está lista (`outcome.hasStarted == true`).
  started('started'),

  /// Se alcanzó el criterio de finalización de producto.
  completed('completed'),

  /// El usuario salió explícitamente o venció la ventana de inactividad.
  abandoned('abandoned'),

  /// La actividad llegó a un fallo definitivo.
  failed('failed'),

  /// No se pudo llegar a una actividad lista (previa a `started`).
  launchError('launch_error');

  const SessionState(this.value);

  /// Valor persistido en Firestore.
  final String value;

  /// Devuelve el estado a partir de su valor persistido, o `null`.
  static SessionState? fromValue(String? value) {
    for (final state in SessionState.values) {
      if (state.value == value) return state;
    }
    return null;
  }

  bool get isTerminal => switch (this) {
        completed || abandoned || failed || launchError => true,
        launchRequested || started => false,
      };

  bool get isLaunched => this == launchRequested || this == started;

  bool get isStarted =>
      this == started ||
      this == completed ||
      this == abandoned ||
      this == failed;
}

/// Razones terminales controladas (valores cerrados, no mensajes libres).
enum TerminalReason {
  // Completado
  objectiveCompleted('objective_completed'),

  // Abandono
  userBack('user_back'),
  userExit('user_exit'),
  routeRemoved('route_removed'),
  inactivityTimeout('inactivity_timeout'),
  staleSession('stale_session'),
  telemetryOptOut('telemetry_opt_out'),

  // Fallo
  attemptsExhausted('attempts_exhausted'),
  definitiveActivityFailure('definitive_activity_failure'),

  // Error de launch
  activityUnavailable('activity_unavailable'),
  invalidActivityData('invalid_activity_data'),
  resourceInitializationFailed('resource_initialization_failed'),
  navigationFailed('navigation_failed'),
  launchCancelledBeforeNavigation('launch_cancelled_before_navigation');

  const TerminalReason(this.value);

  /// Valor persistido en Firestore.
  final String value;

  /// Devuelve la razón a partir de su valor persistido, o `null`.
  static TerminalReason? fromValue(String? value) {
    for (final reason in TerminalReason.values) {
      if (reason.value == value) return reason;
    }
    return null;
  }

  /// Razones válidas para cerrar un estado `completed`.
  static const Set<TerminalReason> completedReasons = {
    objectiveCompleted,
  };

  /// Razones válidas para cerrar un estado `abandoned`.
  static const Set<TerminalReason> abandonedReasons = {
    userBack,
    userExit,
    routeRemoved,
    inactivityTimeout,
    staleSession,
    telemetryOptOut,
  };

  /// Razones válidas para cerrar un estado `failed`.
  static const Set<TerminalReason> failedReasons = {
    attemptsExhausted,
    definitiveActivityFailure,
  };

  /// Razones válidas para cerrar un estado `launchError`.
  static const Set<TerminalReason> launchErrorReasons = {
    activityUnavailable,
    invalidActivityData,
    resourceInitializationFailed,
    navigationFailed,
    launchCancelledBeforeNavigation,
  };
}

/// Tipos de actividad normalizados para telemetría.
enum TelemetryActivityType {
  simpleSelection('simple_selection'),
  puzzle('puzzle'),
  video('video'),
  pictogram('pictogram'),
  audio('audio');

  const TelemetryActivityType(this.value);

  /// Valor persistido en Firestore.
  final String value;

  /// Devuelve el tipo a partir de su valor persistido, o `null`.
  static TelemetryActivityType? fromValue(String? value) {
    for (final type in TelemetryActivityType.values) {
      if (type.value == value) return type;
    }
    return null;
  }

  /// Las actividades interactivas acumulan intentos KPI.
  bool get attemptsApplicable =>
      this == simpleSelection || this == puzzle;

  /// Normaliza el valor de entrada (mayúsculas/espacios) a un tipo, o `null`.
  static TelemetryActivityType? normalize(String? raw) {
    if (raw == null) return null;
    return fromValue(raw.trim().toLowerCase());
  }
}

/// Modelo de identidad semántica. Fijo a `account_as_learner` en esta etapa.
enum IdentityModel {
  accountAsLearner('account_as_learner');

  const IdentityModel(this.value);

  /// Valor persistido en Firestore.
  final String value;
}