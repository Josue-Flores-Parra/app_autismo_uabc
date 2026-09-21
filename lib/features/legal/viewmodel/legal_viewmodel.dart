import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../data/services/firestore_services.dart';
import '../data/legal_documents.dart';

enum LegalStatus {
  /// Todavía no se consulta la cuenta.
  desconocido,

  /// Consultando la versión aceptada en Firestore.
  cargando,

  /// La cuenta no ha aceptado la versión vigente.
  requiereAceptacion,

  /// La cuenta está al corriente.
  aceptado,
}

/// Controla si la cuenta actual ya aceptó la versión vigente de los términos
/// y del aviso de privacidad.
///
/// Se resuelve por cuenta y no por dispositivo: la constancia vive en
/// `users/{uid}.legal`, así que reinstalar la app o cambiar de teléfono no
/// vuelve a pedir la aceptación, y subir [kLegalVersion] sí la pide de nuevo.
class LegalViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  LegalStatus _status = LegalStatus.desconocido;
  String? _checkedUid;
  bool _isChecking = false;

  LegalStatus get status => _status;

  /// Consulta la versión aceptada, si aún no se ha hecho para esta cuenta.
  Future<void> ensureChecked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _isChecking) return;
    if (_checkedUid == uid && _status != LegalStatus.desconocido) return;

    _isChecking = true;
    _status = LegalStatus.cargando;
    notifyListeners();

    try {
      final aceptada = await _firestoreService.getAcceptedLegalVersion(uid);
      _checkedUid = uid;
      _status = (aceptada != null && aceptada >= kLegalVersion)
          ? LegalStatus.aceptado
          : LegalStatus.requiereAceptacion;
    } catch (_) {
      // Sin lectura confiable no se puede afirmar que aceptó: se vuelve a
      // preguntar antes que dar por bueno un consentimiento que no consta.
      _checkedUid = null;
      _status = LegalStatus.requiereAceptacion;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Guarda la aceptación de la versión vigente. Devuelve `false` si no se
  /// pudo dejar constancia, para no dejar pasar al usuario sin registro.
  Future<bool> accept() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      await _firestoreService.setAcceptedLegalVersion(uid, kLegalVersion);
      _checkedUid = uid;
      _status = LegalStatus.aceptado;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Limpia el estado al cerrar sesión, para que la siguiente cuenta se
  /// consulte desde cero.
  void reset() {
    if (_status == LegalStatus.desconocido && _checkedUid == null) return;
    _checkedUid = null;
    _status = LegalStatus.desconocido;
    // Se difiere porque quien llama es el `update` del provider, que corre
    // durante el build: notificar ahí mismo dispara un error de framework.
    Future.microtask(notifyListeners);
  }
}
