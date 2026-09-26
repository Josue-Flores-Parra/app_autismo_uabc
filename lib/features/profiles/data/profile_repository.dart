import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/learner_profile.dart';

class ProfileRepository {
  ProfileRepository([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _learners(String parentUid) =>
      _user(parentUid).collection('learners');

  /// `profilesInitialized` distinguishes new accounts (first child is created
  /// on demand) from older accounts that still own avatar/progress at their
  /// Auth UID and must be migrated once.
  Future<bool> isInitialized(String parentUid) async {
    final snapshot = await _user(parentUid).get();
    return snapshot.data()?['profilesInitialized'] == true;
  }

  Future<void> ensureParent(String parentUid) async {
    final ref = _user(parentUid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data() ?? <String, dynamic>{};
      if (data['role'] == 'parent' && data['profilesInitialized'] == true) {
        return;
      }
      // Merge so legal acceptance, email, display name and old avatar data are
      // preserved on pre-profile accounts.
      transaction.set(ref, {'role': 'parent'}, SetOptions(merge: true));
    });
  }

  Future<List<LearnerProfile>> listLearners(String parentUid) async {
    final snapshot = await _learners(parentUid).orderBy('createdAt').get();
    return snapshot.docs
        .map((doc) => LearnerProfile.fromMap(doc.id, doc.data()))
        // A partially copied legacy child must never look ready/selectable.
        .where((profile) => profile.migrationComplete)
        .toList();
  }

  Future<LearnerProfile> addLearner(
    String parentUid,
    String name, {
    LearnerSettings settings = LearnerSettings.defaults,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Learner name is required');
    final learnerRef = _db.collection('users').doc();
    final learnerId = learnerRef.id;
    final profileRef = _learners(parentUid).doc(learnerId);
    // Both indexes commit together so neither a dangling profile link nor an
    // unindexed `users/{learnerId}` child can be exposed after a partial write.
    final batch = _db.batch();
    final createdAt = DateTime.now().toIso8601String();
    batch.set(profileRef, {
      'name': cleanName,
      'parentUid': parentUid,
      'allowedModules': 0,
      'migrationStatus': 'complete',
      'nameConfirmed': true,
      'settings': settings.toMap(),
      'createdAt': createdAt,
    });
    batch.set(learnerRef, {
      'role': 'learner',
      'parentUid': parentUid,
      'name': cleanName,
      'createdAt': createdAt,
      'avatarConfig': {'nombre': cleanName},
    });
    await batch.commit();
    return LearnerProfile(
      id: learnerId,
      name: cleanName,
      parentUid: parentUid,
      settings: settings,
    );
  }

  Future<void> renameLearner(
    String parentUid,
    LearnerProfile learner,
    String name,
  ) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Learner name is required');
    // Keep the selector label and AvatarViewModel's fallback name in sync.
    final batch = _db.batch();
    batch.set(_learners(parentUid).doc(learner.id), {
      'name': cleanName,
      'nameConfirmed': true,
    }, SetOptions(merge: true));
    batch.set(_user(learner.id), {
      'name': cleanName,
      'avatarConfig': {'nombre': cleanName},
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> setAllowedModules(
    String parentUid,
    LearnerProfile learner,
    int count,
  ) async {
    await _learners(
      parentUid,
    ).doc(learner.id).update({'allowedModules': count.clamp(0, 10)});
  }

  /// Persists per-child learning and accessibility preferences.
  ///
  /// The module limit keeps its top-level field and is managed separately.
  Future<void> updateLearnerSettings(
    String parentUid,
    String learnerId,
    LearnerSettings settings,
  ) async {
    // Replace only the nested settings map; profile identity and module limit
    // remain in their own fields.
    await _learners(
      parentUid,
    ).doc(learnerId).update({'settings': settings.toMap()});
  }

  /// Parent-wide preferences shared by every profile on the account.
  ///
  /// Only theme and language live here; everything learning- or
  /// accessibility-related belongs to each learner profile instead.
  Future<Map<String, dynamic>?> getParentSettings(String parentUid) async {
    final snapshot = await _user(parentUid).get();
    final data = snapshot.data();
    if (data == null) return null;
    final settings = data['parentSettings'];
    if (settings is Map<String, dynamic>) return settings;
    if (settings is Map) return Map<String, dynamic>.from(settings);
    return null;
  }

  Future<void> setParentSettings(
    String parentUid,
    Map<String, dynamic> settings,
  ) async {
    // These settings apply before a learner is selected and are shared by all
    // profiles on this parent's account.
    await _user(
      parentUid,
    ).set({'parentSettings': settings}, SetOptions(merge: true));
  }

  Future<void> clearLearnerProgress(String learnerUid) async {
    final modules = await _user(learnerUid).collection('progress').get();
    for (final module in modules.docs) {
      final levels = await module.reference.collection('levels').get();
      await _deleteRefs(levels.docs.map((doc) => doc.reference).toList());
    }
    await _deleteRefs(modules.docs.map((doc) => doc.reference).toList());
  }

  /// Migrates the existing account-owned data into a new learner ID.
  ///
  /// The profile document is first marked `copying`; AuthGate does not expose
  /// it until all copied progress batches have committed. Re-running this
  /// method uses the same ID and merge writes, so a partial migration is safe
  /// to retry. The original account data is deliberately retained.
  Future<LearnerProfile> migrateLegacyLearner(
    String parentUid, {
    LearnerSettings initialSettings = LearnerSettings.defaults,
  }) async {
    final parentRef = _user(parentUid);
    // Claim the parent role first, without touching existing profile data.
    // The account is only marked initialized after the copy below commits.
    await parentRef.set({'role': 'parent'}, SetOptions(merge: true));

    final parent = await parentRef.get();
    final parentData = parent.data() ?? <String, dynamic>{};
    final learnersRef = _learners(parentUid);
    final existingProfiles = await learnersRef.get();
    final existing = existingProfiles.docs.where(
      (doc) => doc.data()['legacySourceUid'] == parentUid,
    );
    // Reuse the migration ID across retries; creating a fresh ID after a
    // network interruption would strand half-copied data and duplicate rows.
    final profileRef = existing.isNotEmpty
        ? existing.first.reference
        : learnersRef.doc();
    final learnerId = profileRef.id;
    final legacyName = _legacyName(parentData);

    // Reuse the in-progress profile link when retrying, normalizing its
    // creation date to the ISO-8601 strings used everywhere else.
    String? profileCreatedAt;
    if (existing.isNotEmpty) {
      profileCreatedAt = _isoCreatedAt(existing.first.data()['createdAt']);
    }
    profileCreatedAt ??= DateTime.now().toIso8601String();

    await profileRef.set({
      'name': legacyName,
      'parentUid': parentUid,
      'legacySourceUid': parentUid,
      'allowedModules': 0,
      'migrationStatus': 'copying',
      'nameConfirmed': false,
      'settings': initialSettings.toMap(),
      'createdAt': profileCreatedAt,
    }, SetOptions(merge: true));

    // Create the learner document before reading it: reads are authorized by
    // the stored parentUid, which cannot exist until this write commits.
    final childRef = _user(learnerId);
    await childRef.set({
      'role': 'learner',
      'parentUid': parentUid,
    }, SetOptions(merge: true));
    final childSnapshot = await childRef.get();
    final childData = childSnapshot.data() ?? <String, dynamic>{};
    await childRef.set({
      'role': 'learner',
      'parentUid': parentUid,
      'name': legacyName,
      'createdAt':
          _isoCreatedAt(childData['createdAt']) ??
          DateTime.now().toIso8601String(),
      if (parentData['nivel'] != null && childData['nivel'] == null)
        'nivel': parentData['nivel'],
      if (parentData['avatarConfig'] != null &&
          childData['avatarConfig'] == null)
        'avatarConfig': parentData['avatarConfig'],
    }, SetOptions(merge: true));

    // Set completion markers last. If a copy batch fails, login can retry this
    // same source-to-learner mapping rather than exposing partial progress.
    await _copyLegacyProgress(parentUid, learnerId);
    await profileRef.update({'migrationStatus': 'complete'});
    await parentRef.set({
      'role': 'parent',
      'profilesInitialized': true,
      'legacyMigrationLearnerId': learnerId,
    }, SetOptions(merge: true));
    return LearnerProfile(
      id: learnerId,
      name: legacyName,
      parentUid: parentUid,
      settings: initialSettings,
    );
  }

  /// Normalizes a stored creation date to ISO-8601, preserving the instant
  /// of feature-created Firestore Timestamps. Returns null when absent.
  String? _isoCreatedAt(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    return null;
  }

  String _legacyName(Map<String, dynamic> parentData) {
    final avatar = parentData['avatarConfig'];
    final avatarName = avatar is Map ? avatar['nombre'] : null;
    for (final value in [avatarName, parentData['name']]) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return 'Learner';
  }

  Future<void> _copyLegacyProgress(String sourceUid, String learnerUid) async {
    // Level writes never create their intermediate progress/{moduleId}
    // document, so listing that collection can miss modules entirely. Read
    // each catalog module's levels directly, plus any intermediate documents
    // that do exist.
    final moduleIds = <String>{};
    try {
      final catalog = await _db.collection('modules').get();
      for (final module in catalog.docs) {
        moduleIds.add(module.id);
      }
    } catch (_) {
      // Offline or denied catalog: fall back to whatever parents exist.
    }
    final existingParents = await _user(sourceUid).collection('progress').get();
    for (final module in existingParents.docs) {
      moduleIds.add(module.id);
    }
    for (final moduleId in moduleIds) {
      final levels = await _user(
        sourceUid,
      ).collection('progress').doc(moduleId).collection('levels').get();
      // Each batch remains bounded; levels can exceed Firestore's 500-write
      // batch limit in accounts with unusually large histories.
      for (var start = 0; start < levels.docs.length; start += 400) {
        final batch = _db.batch();
        final end = (start + 400).clamp(0, levels.docs.length);
        for (final level in levels.docs.sublist(start, end)) {
          batch.set(
            _user(learnerUid)
                .collection('progress')
                .doc(moduleId)
                .collection('levels')
                .doc(level.id),
            level.data(),
            SetOptions(merge: true),
          );
        }
        await batch.commit();
      }
    }
  }

  /// Removes learner data and profile links before deleting the parent Auth
  /// account. Telemetry is deliberately retained as aggregate history.
  Future<void> deleteFamily(String parentUid) async {
    final profiles = await _learners(parentUid).get();
    final learnerIds = <String>{
      parentUid,
      ...profiles.docs.map((doc) => doc.id),
    };
    for (final learnerId in learnerIds) {
      await clearLearnerProgress(learnerId);
    }
    final childRefs = learnerIds
        .where((id) => id != parentUid)
        .map((id) => _user(id))
        .toList();
    await _deleteRefs(childRefs);
    await _deleteRefs(profiles.docs.map((doc) => doc.reference).toList());
    await _user(parentUid).delete();
  }

  Future<void> _deleteRefs(
    List<DocumentReference<Map<String, dynamic>>> refs,
  ) async {
    for (var start = 0; start < refs.length; start += 400) {
      final batch = _db.batch();
      final end = (start + 400).clamp(0, refs.length);
      for (final ref in refs.sublist(start, end)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
