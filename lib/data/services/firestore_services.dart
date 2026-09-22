import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Escribir datos de usuario
  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  // Leer datos de usuario
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /*
  Versión de los documentos legales que la cuenta aceptó.
  Devuelve null si nunca aceptó ninguna, que es el caso de las cuentas creadas
  antes de que existiera la pantalla de consentimiento.
  */
  Future<int?> getAcceptedLegalVersion(String uid) async {
    final data = await getUserData(uid);
    final legal = data?['legal'];
    if (legal is! Map) return null;
    final version = legal['version'];
    if (version is int) return version;
    if (version is String) return int.tryParse(version);
    return null;
  }

  /*
  Deja constancia de qué versión aceptó la cuenta y cuándo. Es el registro que
  respalda el consentimiento expreso del padre o tutor.
  */
  Future<void> setAcceptedLegalVersion(String uid, int version) async {
    await setUserData(uid, {
      'legal': {
        'version': version,
        'acceptedAt': DateTime.now().toIso8601String(),
      },
    });
  }

  // =======================================
  // Métodos para Módulos de Aprendizaje
  // =======================================

  /*
  Obtiene los datos de un módulo específico desde Firestore
  */
  Future<Map<String, dynamic>?> getModuleData(String moduleId) async {
    try {
      final doc = await _db.collection('modules').doc(moduleId).get();

      if (doc.exists) {
        final data = doc.data()!;
        // Add the document ID to the data map
        data['id'] = doc.id;
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /*
  Obtiene todos los módulos disponibles
  */
  Future<List<Map<String, dynamic>>> getAllModules() async {
    try {
      final snapshot = await _db.collection('modules').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to the data map
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /*
  Obtiene todos los niveles de un módulo específico ordenados por 'orden'
  */
  Future<List<Map<String, dynamic>>> getModuleLevels(String moduleId) async {
    // Validar que moduleId no esté vacío
    if (moduleId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _db
          .collection('modules')
          .doc(moduleId)
          .collection('levels')
          .orderBy('orden')
          .get();

      final levels = snapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to the data map
        data['id'] = doc.id;
        return data;
      }).toList();

      return levels;
    } catch (e, stackTrace) {
      return [];
    }
  }

  /*
  Actualiza el progreso de un usuario en un nivel específico
  */
  Future<void> updateUserLevelProgress(
    String uid,
    String moduleId,
    String levelId,
    Map<String, dynamic> progressData,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(moduleId)
          .collection('levels')
          .doc(levelId)
          .set(progressData, SetOptions(merge: true));
    } catch (e) {
      // Silent fail - error handling can be added at higher level if needed
    }
  }

  /*
  Limpia todo el progreso de todos los módulos para un usuario
  */
  Future<void> clearUserProgress(String uid) async {
    try {
      final progressRef = _db.collection('users').doc(uid).collection('progress');
      final modulesSnapshot = await progressRef.get();
      for (final moduleDoc in modulesSnapshot.docs) {
        final levelsSnapshot = await moduleDoc.reference.collection('levels').get();
        for (final levelDoc in levelsSnapshot.docs) {
          await levelDoc.reference.delete();
        }
        await moduleDoc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error al limpiar el progreso: $e');
    }
  }

  /*
  Obtiene el progreso de un único nivel. Se usa antes de escribir para saber
  qué modalidades ya estaban completadas y cuáles ya pagaron monedas.
  */
  Future<Map<String, dynamic>?> getUserLevelProgress(
    String uid,
    String moduleId,
    String levelId,
  ) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(moduleId)
          .collection('levels')
          .doc(levelId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  /*
  Obtiene el progreso de todos los niveles de un módulo para un usuario específico
  Retorna un Map donde la clave es el levelId y el valor es el progreso
  */
  Future<Map<String, Map<String, dynamic>>> getUserLevelsProgress(
    String uid,
    String moduleId,
  ) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc(moduleId)
          .collection('levels')
          .get();

      final progressMap = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        progressMap[doc.id] = doc.data();
      }
      return progressMap;
    } catch (e) {
      return {};
    }
  }

  /*
  Obtiene el nivel del usuario desde Firestore
  Retorna el nivel del usuario o 1 por defecto si no existe
  */
  Future<int> getUserLevel(String uid) async {
    try {
      final userData = await getUserData(uid);
      if (userData != null && userData['nivel'] != null) {
        if (userData['nivel'] is int) {
          return userData['nivel'] as int;
        } else if (userData['nivel'] is String) {
          return int.tryParse(userData['nivel']) ?? 1;
        }
      }
      return 1; // Nivel por defecto
    } catch (e) {
      return 1; // Nivel por defecto en caso de error
    }
  }
}
