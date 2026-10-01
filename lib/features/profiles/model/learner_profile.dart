/// Auth sigue representando al parent; este modo solo elige qué superficie de
/// la app muestra la sesión actual del dispositivo.
enum AppProfileMode { parent, learner }

/// Preferencias de aprendizaje y accesibilidad por perfil infantil.
///
/// Se guardan en el documento del perfil (`settings`) para seguir a la cuenta
/// entre dispositivos. El límite de módulos vive junto a ellas como campo
/// `allowedModules` de nivel superior por compatibilidad.
class LearnerSettings {
  const LearnerSettings({
    this.fontScale = 'medium',
    this.highContrast = false,
    this.reduceAnimations = false,
    this.audioFeedback = true,
    this.hapticFeedback = true,
    this.remindersEnabled = false,
    this.reminderTime = '18:00',
    this.openAllLevels = false,
  });

  /// Defaults explícitos para perfiles recién creados.
  static const LearnerSettings defaults = LearnerSettings();

  final String fontScale;
  final bool highContrast;
  final bool reduceAnimations;
  final bool audioFeedback;
  final bool hapticFeedback;
  final bool remindersEnabled;

  /// `HH:mm`, reloj de 24 horas. La programación real aún está pendiente.
  final String reminderTime;

  /// Modo libre: muestra abiertos todos los niveles con contenido de los
  /// módulos permitidos. Solo cambia lo que se ve; no escribe progreso ni
  /// otorga recompensas.
  final bool openAllLevels;

  static String _fontScaleFrom(dynamic value) {
    if (value == 'small' || value == 'medium' || value == 'large') {
      return value as String;
    }
    return 'medium';
  }

  static bool _boolFrom(dynamic value, bool fallback) {
    if (value is bool) return value;
    return fallback;
  }

  static String _timeFrom(dynamic value) {
    if (value is! String) return '18:00';
    final parts = value.split(':');
    if (parts.length != 2) return '18:00';
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return '18:00';
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return '18:00';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  factory LearnerSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return LearnerSettings.defaults;
    return LearnerSettings(
      fontScale: _fontScaleFrom(data['fontScale']),
      highContrast: _boolFrom(data['highContrast'], false),
      reduceAnimations: _boolFrom(data['reduceAnimations'], false),
      audioFeedback: _boolFrom(data['audioFeedback'], true),
      hapticFeedback: _boolFrom(data['hapticFeedback'], true),
      remindersEnabled: _boolFrom(data['remindersEnabled'], false),
      reminderTime: _timeFrom(data['reminderTime']),
      openAllLevels: _boolFrom(data['openAllLevels'], false),
    );
  }

  Map<String, dynamic> toMap() => {
    'fontScale': fontScale,
    'highContrast': highContrast,
    'reduceAnimations': reduceAnimations,
    'audioFeedback': audioFeedback,
    'hapticFeedback': hapticFeedback,
    'remindersEnabled': remindersEnabled,
    'reminderTime': reminderTime,
    'openAllLevels': openAllLevels,
  };

  LearnerSettings copyWith({
    String? fontScale,
    bool? highContrast,
    bool? reduceAnimations,
    bool? audioFeedback,
    bool? hapticFeedback,
    bool? remindersEnabled,
    String? reminderTime,
    bool? openAllLevels,
  }) {
    return LearnerSettings(
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      audioFeedback: audioFeedback ?? this.audioFeedback,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      openAllLevels: openAllLevels ?? this.openAllLevels,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LearnerSettings &&
        other.fontScale == fontScale &&
        other.highContrast == highContrast &&
        other.reduceAnimations == reduceAnimations &&
        other.audioFeedback == audioFeedback &&
        other.hapticFeedback == hapticFeedback &&
        other.remindersEnabled == remindersEnabled &&
        other.reminderTime == reminderTime &&
        other.openAllLevels == openAllLevels;
  }

  @override
  int get hashCode => Object.hash(
    fontScale,
    highContrast,
    reduceAnimations,
    audioFeedback,
    hapticFeedback,
    remindersEnabled,
    reminderTime,
    openAllLevels,
  );
}

/// Un perfil infantil tiene UID de datos propio sin crear otra cuenta Auth.
/// Sus datos viven en `users/{id}` y su enlace/ajustes bajo el documento
/// `users/{parentUid}/learners/{id}` del parent.
class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    this.parentUid,
    this.allowedModules = 0,
    this.migrationComplete = true,
    this.needsNameConfirmation = false,
    this.settings = LearnerSettings.defaults,
  });

  final String id;
  final String name;
  final String? parentUid;

  /// Cero significa sin límite de módulos. Se conserva en la raíz del perfil
  /// para el gating rápido de módulos y la migración del ajuste anterior.
  final int allowedModules;

  /// Las copias legacy incompletas se ocultan del selector hasta copiarse.
  final bool migrationComplete;

  /// Los nombres de cuentas existentes requieren revisión explícita del
  /// parent tras la migración.
  final bool needsNameConfirmation;
  final LearnerSettings settings;

  factory LearnerProfile.fromMap(String id, Map<String, dynamic> data) {
    final rawLimit = data['allowedModules'];
    final rawSettings = data['settings'];
    return LearnerProfile(
      id: id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Learner',
      parentUid: data['parentUid'] as String?,
      allowedModules: rawLimit is num ? rawLimit.toInt().clamp(0, 10) : 0,
      migrationComplete: data['migrationStatus'] != 'copying',
      needsNameConfirmation: data['nameConfirmed'] == false,
      settings: rawSettings is Map<String, dynamic>
          ? LearnerSettings.fromMap(rawSettings)
          : LearnerSettings.fromMap(
              rawSettings is Map
                  ? Map<String, dynamic>.from(rawSettings)
                  : null,
            ),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'parentUid': parentUid,
    'allowedModules': allowedModules,
    'migrationStatus': migrationComplete ? 'complete' : 'copying',
    'nameConfirmed': !needsNameConfirmation,
    'settings': settings.toMap(),
  };
}
