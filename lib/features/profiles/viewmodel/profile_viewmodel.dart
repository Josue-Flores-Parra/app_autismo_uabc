import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/services/settings_access_guard.dart';
import '../data/profile_repository.dart';
import '../model/learner_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ProfileRepository? repository})
    : _providedRepository = repository;

  final ProfileRepository? _providedRepository;
  late final ProfileRepository _repository =
      _providedRepository ?? ProfileRepository();

  /// UID Auth de la cuenta adulta; los IDs infantiles nunca son usuarios Auth.
  String? _parentUid;
  List<LearnerProfile> _learners = [];
  LearnerProfile? _selectedLearner;
  AppProfileMode? _mode;
  bool _loading = false;
  String? _error;
  bool _needsInitialLearner = false;
  bool _didMigrateLegacy = false;

  List<LearnerProfile> get learners => List.unmodifiable(_learners);
  LearnerProfile? get selectedLearner => _selectedLearner;
  String? get learnerUid =>
      _mode == AppProfileMode.learner ? _selectedLearner?.id : null;
  AppProfileMode? get mode => _mode;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get needsInitialLearner => _needsInitialLearner;
  bool get didMigrateLegacy => _didMigrateLegacy;
  bool get isReady => !_loading && _parentUid != null;

  /// Si las acciones de gestión (Editar, Agregar, ajustes de cuenta) están
  /// desbloqueadas en esta sesión parent. La pantalla del hub siempre es la
  /// misma; esta bandera solo decide si esas acciones corren directo o piden
  /// el PIN primero. Se reinicia con cada carga fresca y al cerrar sesión.
  bool _parentUnlocked = false;
  bool get parentUnlocked => _parentUnlocked;

  Future<void> loadForParent(String parentUid) async {
    if (_parentUid == parentUid && isReady) {
      // Cada regreso fresco desde auth arranca en el hub bloqueado, aunque la
      // misma cuenta se hubiera seleccionado antes en este proceso.
      _mode = null;
      _parentUnlocked = false;
      notifyListeners();
      return;
    }
    _parentUid = parentUid;
    _loading = true;
    _error = null;
    _mode = null;
    _selectedLearner = null;
    _parentUnlocked = false;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final initialized = await _repository.isInitialized(parentUid);
      if (!initialized) {
        // Conserva las decisiones previas del dispositivo en su perfil migrado.
        final migrated = await _repository.migrateLegacyLearner(
          parentUid,
          initialSettings: _deviceLearnerSettings(prefs),
        );
        final legacyLimit = prefs.getInt('parentalAllowedModules');
        if (legacyLimit != null) {
          await _repository.setAllowedModules(parentUid, migrated, legacyLimit);
          await prefs.remove('parentalAllowedModules');
        }
      } else {
        await _repository.ensureParent(parentUid);
        await prefs.remove('parentalAllowedModules');
      }
      _learners = await _repository.listLearners(parentUid);
      _needsInitialLearner = _learners.isEmpty;
      _didMigrateLegacy = _learners.any(
        (learner) => learner.needsNameConfirmation,
      );
      final selectedId = prefs.getString('selectedLearner_$parentUid');
      _selectedLearner = _findLearner(selectedId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retryLoad() async {
    final uid = _parentUid;
    if (uid == null) return;
    _parentUid = null;
    await loadForParent(uid);
  }

  /// Copia las preferencias de aprendizaje del dispositivo al perfil
  /// migrado para que el primer perfil conserve su comportamiento previo.
  /// Las decisiones globales (tema, idioma) quedan en la cuenta.
  LearnerSettings _deviceLearnerSettings(SharedPreferences prefs) {
    String time = '18:00';
    final storedTime = prefs.getString('reminderTime');
    if (storedTime != null && storedTime.contains(':')) {
      time = storedTime;
    }
    return LearnerSettings(
      fontScale: prefs.getString('fontScale') ?? 'medium',
      highContrast: prefs.getBool('highContrast') ?? false,
      reduceAnimations: prefs.getBool('reduceAnimations') ?? false,
      audioFeedback: prefs.getBool('audioFeedback') ?? true,
      hapticFeedback: prefs.getBool('hapticFeedback') ?? true,
      remindersEnabled: prefs.getBool('remindersEnabled') ?? false,
      reminderTime: time,
    );
  }

  LearnerProfile? _findLearner(String? id) {
    if (id == null) return null;
    for (final learner in _learners) {
      if (learner.id == id) return learner;
    }
    return null;
  }

  Future<LearnerProfile> addLearner(String name) async {
    final parentUid = _requireParent();
    final learner = await _repository.addLearner(parentUid, name);
    _learners = [..._learners, learner];
    _needsInitialLearner = false;
    _didMigrateLegacy = false;
    notifyListeners();
    return learner;
  }

  Future<void> renameLearner(LearnerProfile learner, String name) async {
    final parentUid = _requireParent();
    await _repository.renameLearner(parentUid, learner, name);
    _learners = [
      for (final item in _learners)
        if (item.id == learner.id)
          LearnerProfile(
            id: item.id,
            name: name.trim(),
            parentUid: parentUid,
            allowedModules: item.allowedModules,
            needsNameConfirmation: false,
            settings: item.settings,
          )
        else
          item,
    ];
    if (_selectedLearner?.id == learner.id) {
      _selectedLearner = _findLearner(learner.id);
    }
    notifyListeners();
  }

  Future<void> setLearnerAllowedModules(
    LearnerProfile learner,
    int count,
  ) async {
    await _repository.setAllowedModules(_requireParent(), learner, count);
    _learners = [
      for (final item in _learners)
        if (item.id == learner.id)
          LearnerProfile(
            id: item.id,
            name: item.name,
            parentUid: item.parentUid,
            allowedModules: count.clamp(0, 10),
            settings: item.settings,
          )
        else
          item,
    ];
    if (_selectedLearner?.id == learner.id) {
      _selectedLearner = _findLearner(learner.id);
    }
    notifyListeners();
  }

  /// Guarda las preferencias de aprendizaje y accesibilidad por perfil.
  Future<void> updateLearnerSettings(
    LearnerProfile learner,
    LearnerSettings settings,
  ) async {
    await _repository.updateLearnerSettings(
      _requireParent(),
      learner.id,
      settings,
    );
    _learners = [
      for (final item in _learners)
        if (item.id == learner.id)
          LearnerProfile(
            id: item.id,
            name: item.name,
            parentUid: item.parentUid,
            allowedModules: item.allowedModules,
            migrationComplete: item.migrationComplete,
            needsNameConfirmation: item.needsNameConfirmation,
            settings: settings,
          )
        else
          item,
    ];
    if (_selectedLearner?.id == learner.id) {
      _selectedLearner = _findLearner(learner.id);
    }
    notifyListeners();
  }

  Future<void> clearLearnerProgress(LearnerProfile learner) async {
    await _repository.clearLearnerProgress(learner.id);
  }

  /// Borra para siempre un perfil infantil y todos sus datos de Firestore
  /// (progreso, avatar, ajustes). Si era el perfil seleccionado, limpia la
  /// selección con su preferencia vieja para que el hub nunca apunte a un
  /// documento que ya no existe.
  Future<void> deleteLearner(LearnerProfile learner) async {
    final parentUid = _requireParent();
    await _repository.deleteLearner(parentUid, learner.id);
    _learners = [
      for (final item in _learners)
        if (item.id != learner.id) item,
    ];
    if (_selectedLearner?.id == learner.id) {
      _selectedLearner = null;
      _mode = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selectedLearner_$parentUid');
    }
    _needsInitialLearner = _learners.isEmpty;
    _didMigrateLegacy = _learners.any((item) => item.needsNameConfirmation);
    notifyListeners();
  }

  Future<void> selectLearner(LearnerProfile learner) async {
    final parentUid = _requireParent();
    // Recuerda el último perfil por comodidad entre arranques, pero muestra
    // igual el selector al iniciar sesión para nunca inferir la entrada
    // parent desde ese caché.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLearner_$parentUid', learner.id);
    _selectedLearner = learner;
    _mode = AppProfileMode.learner;
    notifyListeners();
  }

  /// Desbloquea las acciones de gestión en esta sesión parent y vuelve al
  /// hub. El engrane de módulos siempre pide el PIN primero, así que llegar
  /// aquí significa que el parent se verificó; las acciones del hub ya no
  /// vuelven a pedirlo hasta cerrar sesión o cambiar de cuenta.
  void unlockParent() {
    if (_parentUid == null) return;
    _parentUnlocked = true;
    _mode = null;
    notifyListeners();
  }

  /// Asegura que las acciones de gestión puedan correr, pidiendo el PIN si la
  /// sesión sigue bloqueada. Devuelve `false` cuando la acción no debe
  /// continuar. Se sobrescribe en tests para evitar el gate con Firebase.
  Future<bool> ensureParentUnlocked(BuildContext context) async {
    if (parentUnlocked) return true;
    final verified = await SettingsAccessGuard.ensureAccess(context);
    if (!verified || !context.mounted) return false;
    unlockParent();
    return true;
  }

  void confirmLegacyName() {
    _didMigrateLegacy = _learners.any(
      (learner) => learner.needsNameConfirmation,
    );
    notifyListeners();
  }

  void reset() {
    if (_parentUid == null &&
        _mode == null &&
        _learners.isEmpty &&
        !_parentUnlocked) {
      return;
    }
    _parentUid = null;
    _learners = [];
    _selectedLearner = null;
    _mode = null;
    _parentUnlocked = false;
    _loading = false;
    _error = null;
    _needsInitialLearner = false;
    notifyListeners();
  }

  String _requireParent() =>
      _parentUid ?? (throw StateError('No authenticated parent account'));
}
