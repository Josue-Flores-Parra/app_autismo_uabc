import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../model/levels_models.dart';

/// Resultado de persistencia independiente del resultado de la actividad.
enum CompletionSyncState { pending, confirmed, failed }

/// Evento durable: la identidad se captura antes de cualquier espera.
class CompletionEvent {
  CompletionEvent({
    required this.id,
    required this.actorId,
    required this.learnerId,
    required this.moduleId,
    required this.levelId,
    required this.activity,
    required this.success,
    required this.attempts,
    required this.firstCoins,
    required this.totalActivities,
    required this.completedAt,
    this.baseline = const {},
  });

  final String id, actorId, learnerId, moduleId, levelId, activity;
  final bool success;
  final int attempts, firstCoins, totalActivities;
  final DateTime completedAt;
  final Map<String, dynamic> baseline;

  Map<String, dynamic> toJson() => {
    'id': id,
    'actorId': actorId,
    'learnerId': learnerId,
    'moduleId': moduleId,
    'levelId': levelId,
    'activity': activity,
    'success': success,
    'attempts': attempts,
    'firstCoins': firstCoins,
    'totalActivities': totalActivities,
    'completedAt': completedAt.toIso8601String(),
    'baseline': baseline,
  };

  factory CompletionEvent.fromJson(Map<String, dynamic> json) =>
      CompletionEvent(
        id: json['id'] as String,
        actorId: json['actorId'] as String,
        learnerId: json['learnerId'] as String,
        moduleId: json['moduleId'] as String,
        levelId: json['levelId'] as String,
        activity: json['activity'] as String,
        success: json['success'] as bool,
        attempts: json['attempts'] as int,
        firstCoins: json['firstCoins'] as int,
        totalActivities: json['totalActivities'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
        baseline: Map<String, dynamic>.from(json['baseline'] as Map),
      );
}

/// Calcula progreso sin marcar recompensas provisionales como pagadas.
Map<String, dynamic> completionProgress(
  Map<String, dynamic> previous,
  CompletionEvent event,
) {
  if (isCompletedProgress(previous)) return Map.of(previous);
  final activities = Map<String, dynamic>.from(
    previous['activities'] as Map? ?? {},
  );
  if (event.success) {
    activities[event.activity] = {
      'completedAt': event.completedAt.toIso8601String(),
      'attempts': event.attempts,
    };
  }
  final complete = activities.length >= event.totalActivities.clamp(1, 3);
  return {
    ...previous,
    'activities': activities,
    'estrellas': complete ? 3 : activities.length.clamp(0, 2),
    'status': complete ? 'completed' : 'in_progress',
    'attempts': event.attempts,
    'updatedAt': event.completedAt.toIso8601String(),
    if (complete) 'completedAt': event.completedAt.toIso8601String(),
  };
}

/// Aplica las reglas actuales de monedas, descanso y felicidad sobre datos remotos.
Map<String, dynamic> completionAvatar(
  Map<String, dynamic> avatar,
  Map<String, dynamic> previous,
  CompletionEvent event,
  DateTime now,
) {
  final replay =
      event.success &&
      (isCompletedProgress(previous) ||
          parseCompletedActivities(previous).contains(event.activity));
  final coins = event.success ? (replay ? 5 : event.firstCoins) : 0;
  final since = DateTime.tryParse(
    avatar['energiaActualizadaEn'] as String? ?? '',
  );
  final elapsed = since == null
      ? 0
      : now.difference(since).inMinutes.clamp(0, 1000000) ~/ 6;
  final energy = ((avatar['energia'] as num?)?.toInt() ?? 100);
  final happiness = ((avatar['felicidad'] as num?)?.toInt() ?? 100);
  final rested = (energy + elapsed).clamp(0, 100);
  final decayed = happiness <= 30
      ? happiness
      : (happiness - elapsed).clamp(30, 100);
  return {
    ...avatar,
    'monedas': ((avatar['monedas'] as num?)?.toInt() ?? 0) + coins,
    'energia': (rested + (replay ? 3 : -4)).clamp(0, 100),
    'felicidad': (decayed + (replay ? 1 : (event.success ? 5 : 1))).clamp(
      0,
      100,
    ),
    'energiaActualizadaEn': now.toIso8601String(),
  };
}

/// Confirma progreso y recompensa en una sola transacción con recibo idempotente.
class CompletionRepository {
  CompletionRepository(this.db);
  final FirebaseFirestore db;

  Future<void> confirm(CompletionEvent event) async {
    final user = db.collection('users').doc(event.learnerId);
    // El módulo reservado usa las reglas de propiedad existentes de progreso.
    // Sus recibos no se incluyen en el catálogo ni en los badges de módulos.
    final receipt = user
        .collection('progress')
        .doc('_completion_receipts')
        .collection('levels')
        .doc(event.id);
    final progress = user
        .collection('progress')
        .doc(event.moduleId)
        .collection('levels')
        .doc(event.levelId);
    await db.runTransaction((tx) async {
      final existing = await tx.get(receipt);
      if (existing.exists) return;
      final saved = await tx.get(progress);
      final account = await tx.get(user);
      if (!account.exists) throw StateError('El perfil ya no existe.');
      final previous = saved.data() ?? <String, dynamic>{};
      final avatar = Map<String, dynamic>.from(
        account.data()?['avatarConfig'] as Map? ?? {},
      );
      final next = completionProgress(previous, event);
      if (!isCompletedProgress(previous)) {
        final activities = Map<String, dynamic>.from(
          next['activities'] as Map? ?? {},
        );
        if (event.success) {
          activities[event.activity] = {
            ...activities[event.activity] as Map,
            'rewarded': true,
          };
        }
        tx.set(progress, {
          ...next,
          'activities': activities,
        }, SetOptions(merge: true));
      }
      tx.set(user, {
        'avatarConfig': completionAvatar(
          avatar,
          previous,
          event,
          DateTime.now(),
        ),
      }, SetOptions(merge: true));
      tx.set(receipt, {
        'completionId': event.id,
        'actorId': event.actorId,
        'moduleId': event.moduleId,
        'levelId': event.levelId,
        'confirmedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

/// Cola local serializada que conserva eventos hasta recibir confirmación real.
class CompletionSyncService extends ChangeNotifier with WidgetsBindingObserver {
  CompletionSyncService({
    required SharedPreferences prefs,
    required Future<void> Function(CompletionEvent) confirm,
    required String? Function() actorProvider,
  }) : _prefs = prefs,
       _confirm = confirm,
       _actorProvider = actorProvider {
    final stored = _prefs.getString(_key);
    if (stored != null) {
      for (final raw in jsonDecode(stored) as List) {
        _events.add(
          CompletionEvent.fromJson(Map<String, dynamic>.from(raw as Map)),
        );
      }
    }
  }

  static CompletionSyncService? instance;
  static const _key = 'activity_completion_outbox_v1';
  final SharedPreferences _prefs;
  final Future<void> Function(CompletionEvent) _confirm;
  final String? Function() _actorProvider;
  final List<CompletionEvent> _events = [];
  Future<void> _storageChain = Future.value();
  Future<void>? _flush;
  Timer? _retry;
  StreamSubscription<User?>? _auth;
  bool _disposed = false;
  String? lastConfirmedLearner;

  List<CompletionEvent> get pending => List.unmodifiable(_events);

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _retry = Timer.periodic(const Duration(seconds: 30), (_) => flush());
    _auth = FirebaseAuth.instance.authStateChanges().listen((_) => flush());
    unawaited(flush());
  }

  Future<void> enqueue(CompletionEvent event) async {
    await _store(() {
      if (!_events.any((item) => item.id == event.id)) _events.add(event);
    });
    lastConfirmedLearner = null;
    if (!_disposed) notifyListeners();
    unawaited(flush());
  }

  /// Mezcla eventos de este actor/learner sin alterar monedas ni estado remoto.
  Map<String, Map<String, dynamic>> overlay(
    String learnerId,
    String moduleId,
    Map<String, Map<String, dynamic>> saved,
  ) {
    final result = {...saved};
    for (final event in _events) {
      if (event.actorId != _actorProvider() ||
          event.learnerId != learnerId ||
          event.moduleId != moduleId) {
        continue;
      }
      result[event.levelId] = completionProgress(
        result[event.levelId] ?? event.baseline,
        event,
      );
    }
    return result;
  }

  Future<void> _store(void Function() change) {
    final operation = _storageChain.then((_) async {
      final before = List<CompletionEvent>.of(_events);
      change();
      try {
        if (!await _prefs.setString(
          _key,
          jsonEncode(
            _events.map((e) => e.toJson()).toList(),
            toEncodable: (value) {
              if (value is Timestamp) return value.toDate().toIso8601String();
              if (value is DateTime) return value.toIso8601String();
              throw FormatException(
                'Valor de progreso no serializable: ${value.runtimeType}',
              );
            },
          ),
        )) {
          throw StateError('No se pudo guardar el progreso local.');
        }
      } catch (_) {
        _events
          ..clear()
          ..addAll(before);
        rethrow;
      }
    });
    _storageChain = operation.then(
      (_) {},
      onError: (Object _, StackTrace stack) {},
    );
    return operation;
  }

  Future<void> flush() => _flush ??= _drain().whenComplete(() => _flush = null);

  Future<void> _drain() async {
    final actor = _actorProvider();
    final blocked = <String>{};
    for (final event in List<CompletionEvent>.of(_events)) {
      if (_disposed || actor != _actorProvider()) break;
      if (event.actorId != actor || blocked.contains(event.learnerId)) continue;
      try {
        await _confirm(event).timeout(const Duration(seconds: 10));
        await _store(() => _events.removeWhere((item) => item.id == event.id));
        lastConfirmedLearner = event.learnerId;
        if (!_disposed) notifyListeners();
      } catch (e) {
        // La transacción puede confirmar después del timeout: el recibo evita duplicados.
        blocked.add(event.learnerId);
        debugPrint('CompletionSyncService: confirmación pendiente: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(flush());
  }

  static String newId() => const Uuid().v4();

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
