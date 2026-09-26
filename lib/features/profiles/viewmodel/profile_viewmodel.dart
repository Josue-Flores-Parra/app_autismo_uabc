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

  /// Auth UID for the adult account; child profile IDs are never Auth users.
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

  /// Whether management actions (Edit, Add, account settings) are unlocked
  /// for this parent session. The hub screen is always the same; this flag
  /// only decides if those actions run directly or ask for the PIN first.
  /// It resets on every fresh account load and on logout.
  bool _parentUnlocked = false;
  bool get parentUnlocked => _parentUnlocked;

  Future<void> loadForParent(String parentUid) async {
    if (_parentUid == parentUid && isReady) {
      // Every fresh return from auth starts at the locked hub, even if the
      // same account was selected earlier in this process.
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
        // Preserve the old device-only learner choices on its migrated child.
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

  /// Copies the device-level learning preferences into the migrated
  /// profile so the first child keeps its previous behaviour. Parent-wide
  /// choices (theme, language) stay on the account instead.
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

  /// Persists per-child learning and accessibility preferences.
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

  Future<void> selectLearner(LearnerProfile learner) async {
    final parentUid = _requireParent();
    // Remember the last child for cross-launch convenience, but still show the
    // selector at login so parent entry is never inferred from that cache.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLearner_$parentUid', learner.id);
    _selectedLearner = learner;
    _mode = AppProfileMode.learner;
    notifyListeners();
  }

  /// Unlocks management actions for this parent session and returns to the
  /// hub. The module gear always asks for the PIN first, so reaching here
  /// means the parent was verified; the hub actions then run without asking
  /// again until logout or account change.
  void unlockParent() {
    if (_parentUid == null) return;
    _parentUnlocked = true;
    _mode = null;
    notifyListeners();
  }

  /// Ensures management actions may run, asking for the PIN when the session
  /// is still locked. Returns `false` when the action must not continue.
  /// Override in tests to avoid the Firebase-backed PIN gate.
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
