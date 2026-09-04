import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/activity_telemetry_session.dart';
import '../model/telemetry_enums.dart';

/// Sentinela que el servicio usa para indicar "timestamp de servidor" en un
/// update. El repositorio lo convierte a `FieldValue.serverTimestamp()`.
class ServerTimestamp {
  const ServerTimestamp();
  static const instance = ServerTimestamp();
}

/// Tipo de error de repositorio (clasificación sin PII).
enum TelemetryErrorKind {
  /// Recuperable: offline/timeout. Puede reintentarse con backoff acotado.
  recoverable,

  /// Permanente: permission-denied, invalid-argument, not-found, etc.
  permanent,
}

/// Excepción tipada del repositorio con contexto de operación (sin PII).
class TelemetryRepositoryException implements Exception {
  const TelemetryRepositoryException({
    required this.kind,
    required this.operation,
    this.sessionId,
    this.message,
  });

  final TelemetryErrorKind kind;
  final String operation;
  final String? sessionId;
  final String? message;

  @override
  String toString() =>
      'TelemetryRepositoryException(kind: $kind, operation: $operation, '
      'sessionId: $sessionId, message: $message)';
}

/// Repositorio de telemetría sobre Cloud Firestore.
///
/// Recibe `FirebaseFirestore` por constructor para poder usar emulator/fakes.
/// Crea/actualiza `telemetryActivitySessions/{sessionId}`, aplica timestamps de
/// servidor y propaga errores tipados. No reutiliza `FirestoreService`.
class TelemetryRepository {
  TelemetryRepository([FirebaseFirestore? db]) : _db = db;

  final FirebaseFirestore? _db;
  static const _collection = 'telemetryActivitySessions';

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(_collection);

  /// Crea idempotente del documento con ID conocido (`sessionId`).
  ///
  /// Usa `set` sin merge para no sobreescribir un documento terminal existente
  /// con el mismo UUID. Aplica timestamps de servidor a `launchRequestedAt`,
  /// `createdAt` y `updatedAt`.
  Future<void> create(ActivityTelemetrySession session) async {
    final map = session.toMap();
    (map['timing'] as Map<String, dynamic>)['launchRequestedAt'] =
        FieldValue.serverTimestamp();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();
    try {
      await _sessions.doc(session.sessionId).set(map);
    } catch (e) {
      throw _classify(e, 'create', session.sessionId);
    }
  }

  /// Aplica un parche tipado con dot-paths.
  ///
  /// Los valores `ServerTimestamp.instance` se convierten a
  /// `FieldValue.serverTimestamp()`. Siempre actualiza `updatedAt`.
  Future<void> update(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _sessions.doc(sessionId).update(
            _applyServerTimestamps(updates, includeUpdatedAt: true),
          );
    } catch (e) {
      throw _classify(e, 'update', sessionId);
    }
  }

  /// Update terminal protegido: no sobreescribe un documento ya terminal.
  ///
  /// Usa una transacción para leer el estado remoto y verificar terminalidad
  /// antes de escribir. Es el respaldo remoto de la guarda local del servicio.
  Future<void> updateIfNotTerminal(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.runTransaction((tx) async {
        final ref = _sessions.doc(sessionId);
        final snap = await tx.get(ref);
        if (snap.exists) {
          final status = (snap.data()?['lifecycle']
              as Map<String, dynamic>?)?['status'] as String?;
          final state = SessionState.fromValue(status);
          if (state != null && state.isTerminal) return;
        }
        tx.update(ref, _applyServerTimestamps(updates, includeUpdatedAt: true));
      });
    } catch (e) {
      throw _classify(e, 'updateIfNotTerminal', sessionId);
    }
  }

  /// Lectura puntual para reconciliación.
  Future<ActivityTelemetrySession?> read(String sessionId) async {
    try {
      final doc = await _sessions.doc(sessionId).get();
      if (!doc.exists) return null;
      return ActivityTelemetrySession.fromMap(
        doc.data(),
        sessionId: doc.id,
      );
    } catch (e) {
      throw _classify(e, 'read', sessionId);
    }
  }

  Map<String, dynamic> _applyServerTimestamps(
    Map<String, dynamic> updates, {
    bool includeUpdatedAt = false,
  }) {
    final converted = <String, dynamic>{
      for (final entry in updates.entries)
        entry.key: entry.value is ServerTimestamp
            ? FieldValue.serverTimestamp()
            : entry.value,
    };
    if (includeUpdatedAt) {
      converted['updatedAt'] = FieldValue.serverTimestamp();
    }
    return converted;
  }

  TelemetryRepositoryException _classify(
    Object error,
    String operation,
    String? sessionId,
  ) {
    final kind = _isRecoverable(error)
        ? TelemetryErrorKind.recoverable
        : TelemetryErrorKind.permanent;
    return TelemetryRepositoryException(
      kind: kind,
      operation: operation,
      sessionId: sessionId,
      message: _sanitizeMessage(error),
    );
  }

  bool _isRecoverable(Object error) {
    if (error is FirebaseException) {
      final code = error.code;
      if (code == 'unavailable' ||
          code == 'deadline-exceeded' ||
          code == 'aborted' ||
          code == 'network-request-failed') {
        return true;
      }
    }
    return false;
  }

  /// Mensaje sanitizado: no debe incluir datos sensibles ni stack traces.
  String? _sanitizeMessage(Object error) {
    if (error is FirebaseException) {
      // Solo el código es estable y no sensible.
      return error.code;
    }
    return null;
  }
}