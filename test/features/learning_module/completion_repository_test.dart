import 'package:appy/features/learning_module/data/completion_sync_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _Database extends Fake implements FirebaseFirestore {
  final docs = <String, Map<String, dynamic>>{};
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = _Transaction(this);
    final result = await handler(transaction);
    docs.addAll(transaction.writes);
    return result;
  }
}

// Firestore permite dobles de prueba; no son subtipos usados en producción.
// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.db, this.path);
  final _Database db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(db, '${this.path}/$path');
}

// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.db, this.path);
  final _Database db;
  @override
  final String path;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Collection(db, '$path/$name');
}

// ignore: subtype_of_sealed_class
class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.value);
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
}

class _Transaction extends Fake implements Transaction {
  _Transaction(this.db);
  final _Database db;
  final writes = <String, Map<String, dynamic>>{};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async {
    expect(
      writes,
      isEmpty,
      reason: 'Todas las lecturas deben preceder las escrituras.',
    );
    return _Snapshot(db.docs[reference.path]) as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    writes[reference.path] = {
      ...?db.docs[reference.path],
      ...data as Map<String, dynamic>,
    };
    return this;
  }
}

void main() {
  test('transaction retries cannot pay the same completion twice', () async {
    final db = _Database();
    db.docs['users/child'] = {
      'avatarConfig': {'monedas': 0, 'energia': 100, 'felicidad': 100},
    };
    final event = CompletionEvent(
      id: 'unique',
      actorId: 'parent',
      learnerId: 'child',
      moduleId: 'module',
      levelId: 'level',
      activity: 'puzzle',
      success: true,
      attempts: 0,
      firstCoins: 30,
      totalActivities: 3,
      completedAt: DateTime(2026),
    );
    final repository = CompletionRepository(db);
    final reward = await repository.confirm(event);
    final duplicate = await repository.confirm(event);
    expect(reward!.coins, 30);
    expect(reward.stars, 1);
    expect(reward.energy, -4);
    expect(duplicate!.toJson(), reward.toJson());
    expect((db.docs['users/child']!['avatarConfig'] as Map)['monedas'], 30);
    expect(
      db.docs['users/child/progress/module/levels/level']!['estrellas'],
      1,
    );
    expect(
      db.docs.containsKey(
        'users/child/progress/_completion_receipts/levels/unique',
      ),
      isTrue,
    );
  });
  test(
    'deleted learner cannot receive progress, receipt or reward writes',
    () async {
      final db = _Database();
      final event = CompletionEvent(
        id: 'unique',
        actorId: 'parent',
        learnerId: 'deleted',
        moduleId: 'module',
        levelId: 'level',
        activity: 'video',
        success: true,
        attempts: 0,
        firstCoins: 10,
        totalActivities: 3,
        completedAt: DateTime(2026),
      );
      await expectLater(
        CompletionRepository(db).confirm(event),
        throwsStateError,
      );
      expect(db.docs, isEmpty);
    },
  );
}
