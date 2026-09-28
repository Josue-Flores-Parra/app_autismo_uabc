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

  /// `profilesInitialized` distingue cuentas nuevas (el primer perfil se crea
  /// bajo demanda) de cuentas anteriores que aún guardan avatar/progreso en
  /// su UID de Auth y deben migrarse una vez.
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
      // Merge para conservar aceptación legal, correo, nombre visible y datos
      // de avatar anteriores en cuentas previas a perfiles.
      transaction.set(ref, {'role': 'parent'}, SetOptions(merge: true));
    });
  }

  Future<List<LearnerProfile>> listLearners(String parentUid) async {
    final snapshot = await _learners(parentUid).orderBy('createdAt').get();
    return snapshot.docs
        .map((doc) => LearnerProfile.fromMap(doc.id, doc.data()))
        // Un perfil legacy copiado a medias nunca debe verse listo/elegible.
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
    // Ambos índices se confirman juntos para no exponer tras una escritura
    // parcial ni un enlace suelto ni un `users/{learnerId}` sin índice.
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
    // Mantiene sincronizados la etiqueta del selector y el nombre fallback de AvatarViewModel.
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

  /// Guarda las preferencias de aprendizaje y accesibilidad por perfil.
  ///
  /// El límite de módulos conserva su campo de nivel superior y se gestiona
  /// por separado.
  Future<void> updateLearnerSettings(
    String parentUid,
    String learnerId,
    LearnerSettings settings,
  ) async {
    // Reemplaza solo el mapa anidado de ajustes; la identidad del perfil y el
    // límite de módulos quedan en sus propios campos.
    await _learners(
      parentUid,
    ).doc(learnerId).update({'settings': settings.toMap()});
  }

  /// Preferencias globales de la cuenta, compartidas por todos sus perfiles.
  ///
  /// Solo viven aquí tema e idioma; todo lo de aprendizaje o accesibilidad
  /// pertenece a cada perfil infantil.
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
    // Estos ajustes aplican antes de elegir perfil y los comparten todos los
    // perfiles de la cuenta parent.
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

  /// Elimina para siempre un perfil infantil: su progreso de niveles, su
  /// enlace bajo el parent y su documento `users/{learnerId}` (avatar,
  /// nombre y ajustes incluidos). El historial de telemetría se conserva a
  /// propósito. El orden importa: las reglas de progreso y del documento
  /// resuelven propiedad vía `users/{learnerId}.parentUid`, así que el
  /// progreso va primero y el documento al final.
  Future<void> deleteLearner(String parentUid, String learnerId) async {
    await clearLearnerProgress(learnerId);
    await _learners(parentUid).doc(learnerId).delete();
    await _user(learnerId).delete();
  }

  /// Migra los datos actuales de la cuenta a un ID infantil nuevo.
  ///
  /// El documento del perfil primero se marca `copying`; AuthGate no lo
  /// expone hasta confirmar todos los lotes de progreso copiados. Reejecutar
  /// este método reusa el mismo ID con escrituras merge, así que reintentar
  /// una migración parcial es seguro. Los datos originales se conservan a
  /// propósito.
  Future<LearnerProfile> migrateLegacyLearner(
    String parentUid, {
    LearnerSettings initialSettings = LearnerSettings.defaults,
  }) async {
    final parentRef = _user(parentUid);
    // Reclama primero el rol parent, sin tocar los datos existentes del
    // perfil. La cuenta solo se marca inicializada tras confirmar la copia.
    await parentRef.set({'role': 'parent'}, SetOptions(merge: true));

    final parent = await parentRef.get();
    final parentData = parent.data() ?? <String, dynamic>{};
    final learnersRef = _learners(parentUid);
    final existingProfiles = await learnersRef.get();
    final existing = existingProfiles.docs.where(
      (doc) => doc.data()['legacySourceUid'] == parentUid,
    );
    // Reusa el ID de migración entre reintentos; crear uno nuevo tras un
    // corte de red dejaría datos a medias y filas duplicadas.
    final profileRef = existing.isNotEmpty
        ? existing.first.reference
        : learnersRef.doc();
    final learnerId = profileRef.id;
    final legacyName = _legacyName(parentData);

    // Reusa el enlace en curso al reintentar, normalizando su fecha de
    // creación a los strings ISO-8601 usados en el resto.
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

    // Crea el documento infantil antes de leerlo: las lecturas se autorizan
    // por el parentUid guardado, que no existe hasta confirmar esta escritura.
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

    // Marca completado al final. Si falla un lote, el login reintenta este
    // mismo mapeo origen→perfil en vez de exponer progreso parcial.
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

  /// Normaliza una fecha de creación guardada a ISO-8601, conservando el
  /// instante de los Timestamps de Firestore creados por la feature.
  /// Devuelve null si no hay valor.
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
    // Las escrituras de nivel nunca crean su documento intermedio
    // progress/{moduleId}, así que listar esa colección puede omitir módulos
    // por completo. Lee los niveles de cada módulo del catálogo directo,
    // más los documentos intermedios que sí existan.
    final moduleIds = <String>{};
    try {
      final catalog = await _db.collection('modules').get();
      for (final module in catalog.docs) {
        moduleIds.add(module.id);
      }
    } catch (_) {
      // Catálogo sin conexión o denegado: usa los padres que existan.
    }
    final existingParents = await _user(sourceUid).collection('progress').get();
    for (final module in existingParents.docs) {
      moduleIds.add(module.id);
    }
    for (final moduleId in moduleIds) {
      final levels = await _user(
        sourceUid,
      ).collection('progress').doc(moduleId).collection('levels').get();
      // Cada lote queda acotado; los niveles pueden superar el límite de
      // 500 escrituras por lote de Firestore en historiales muy grandes.
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

  /// Borra datos infantiles y enlaces de perfil antes de eliminar la cuenta
  /// Auth parent. La telemetría se conserva a propósito como historial.
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
