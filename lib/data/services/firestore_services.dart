import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tiempo que se espera la confirmación del servidor antes de seguir.
  static const Duration _offlineWriteGrace = Duration(seconds: 3);

  /*
  Sin conexión, el Future de una escritura de Firestore no termina hasta que
  el servidor confirma, aunque el dato ya esté en la cola local. Esperarlo sin
  límite dejaría la pantalla colgada (por ejemplo, el resultado de una
  actividad). Aquí se espera un plazo corto: si el servidor responde, los
  errores se propagan como antes; si no, la escritura sigue en cola y se envía
  sola al volver la red.
  */
  Future<void> _queuedWrite(Future<void> write) {
    final completer = Completer<void>();
    write.then(
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        } else {
          debugPrint('FirestoreService: escritura en cola falló: $error');
        }
      },
    );
    Timer(_offlineWriteGrace, () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _readDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      return await reference.get().timeout(const Duration(seconds: 2));
    } catch (_) {
      return reference.get(const GetOptions(source: Source.cache));
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _readQuery(
    Query<Map<String, dynamic>> query,
  ) async {
    try {
      return await query.get().timeout(const Duration(seconds: 2));
    } catch (_) {
      return query.get(const GetOptions(source: Source.cache));
    }
  }

  // Escribir datos de usuario
  Future<void> setUserData(String uid, Map<String, dynamic> data) async {
    await _queuedWrite(
      _db.collection('users').doc(uid).set(data, SetOptions(merge: true)),
    );
  }

  // Leer datos de usuario
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _readDocument(_db.collection('users').doc(uid));
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
    await setUserData(uid, {'legal': legalAcceptance(version)});
  }

  /// Campos de `users.legal` que registran una aceptación de [version].
  ///
  /// `confirmationPending` marca que falta el correo de confirmación del
  /// consentimiento (método "email plus"); la función programada
  /// `sendConsentConfirmations` lo envía y apaga la marca. `acceptedAtServer`
  /// le da una hora confiable para esperar 24 horas antes de enviarlo.
  static Map<String, dynamic> legalAcceptance(int version) => {
    'version': version,
    'acceptedAt': DateTime.now().toIso8601String(),
    'acceptedAtServer': FieldValue.serverTimestamp(),
    'consentMethod': 'email_plus',
    'confirmationPending': true,
  };

  // =======================================
  // Métodos para Módulos de Aprendizaje
  // =======================================

  /*
  Obtiene los datos de un módulo específico desde Firestore
  */
  Future<Map<String, dynamic>?> getModuleData(String moduleId) async {
    try {
      final doc = await _readDocument(_db.collection('modules').doc(moduleId));

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
      final snapshot = await _readQuery(_db.collection('modules'));
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
      final snapshot = await _readQuery(
        _db
            .collection('modules')
            .doc(moduleId)
            .collection('levels')
            .orderBy('orden'),
      );

      final levels = snapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to the data map
        data['id'] = doc.id;
        return data;
      }).toList();

      return levels;
    } catch (e) {
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
      await _queuedWrite(
        _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(moduleId)
            .collection('levels')
            .doc(levelId)
            .set(progressData, SetOptions(merge: true)),
      );
    } catch (e) {
      // Silent fail - error handling can be added at higher level if needed
    }
  }

  /*
  Limpia todo el progreso de todos los módulos para un usuario
  */
  Future<void> clearUserProgress(String uid) async {
    try {
      final progressRef = _db
          .collection('users')
          .doc(uid)
          .collection('progress');
      final modulesSnapshot = await progressRef.get().timeout(
        const Duration(seconds: 2),
      );
      for (final moduleDoc in modulesSnapshot.docs) {
        final levelsSnapshot = await moduleDoc.reference
            .collection('levels')
            .get()
            .timeout(const Duration(seconds: 2));
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
      final doc = await _readDocument(
        _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(moduleId)
            .collection('levels')
            .doc(levelId),
      );
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  /// Lee únicamente el progreso disponible en disco, incluso al arrancar sin red.
  Future<Map<String, dynamic>?> getCachedUserLevelProgress(
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
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(milliseconds: 500));
      return doc.data();
    } catch (_) {
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
      final snapshot = await _readQuery(
        _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(moduleId)
            .collection('levels'),
      );

      final progressMap = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        progressMap[doc.id] = doc.data();
      }
      return progressMap;
    } catch (e) {
      try {
        final cached = await _db
            .collection('users')
            .doc(uid)
            .collection('progress')
            .doc(moduleId)
            .collection('levels')
            .get(const GetOptions(source: Source.cache));
        return {for (final doc in cached.docs) doc.id: doc.data()};
      } catch (_) {
        return {};
      }
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
