/// Auth still represents the parent; this mode only selects which app surface
/// the current device session shows.
enum AppProfileMode { parent, learner }

/// Per-child learning and accessibility preferences.
///
/// Stored in the learner profile document (`settings` map) so they follow the
/// account across devices. The module limit lives alongside them as the
/// top-level `allowedModules` field for backwards compatibility.
class LearnerSettings {
  const LearnerSettings({
    this.fontScale = 'medium',
    this.highContrast = false,
    this.reduceAnimations = false,
    this.audioFeedback = true,
    this.hapticFeedback = true,
    this.remindersEnabled = false,
    this.reminderTime = '18:00',
  });

  /// Explicit defaults for newly created profiles.
  static const LearnerSettings defaults = LearnerSettings();

  final String fontScale;
  final bool highContrast;
  final bool reduceAnimations;
  final bool audioFeedback;
  final bool hapticFeedback;
  final bool remindersEnabled;

  /// `HH:mm`, 24-hour clock. Actual notification scheduling is pending.
  final String reminderTime;

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
  };

  LearnerSettings copyWith({
    String? fontScale,
    bool? highContrast,
    bool? reduceAnimations,
    bool? audioFeedback,
    bool? hapticFeedback,
    bool? remindersEnabled,
    String? reminderTime,
  }) {
    return LearnerSettings(
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      audioFeedback: audioFeedback ?? this.audioFeedback,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
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
        other.reminderTime == reminderTime;
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
  );
}

/// A child profile has an independent data UID without creating another Auth
/// account. Its data lives in `users/{id}` and its link/settings under the
/// parent's `users/{parentUid}/learners/{id}` document.
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

  /// Zero means no module limit. Kept at the profile root for quick module
  /// gating and migration from the former device-wide setting.
  final int allowedModules;

  /// Incomplete legacy copies are hidden from the selector until copied.
  final bool migrationComplete;

  /// Existing-account names need explicit parent review after migration.
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
