/// ProgressLogModel: clase de datos pura para representar el progreso del usuario.
/// - Sin dependencias de Firestore/Flutter (solo Dart).
/// - Serializa fechas en ISO 8601 (string) para mantener independencia de infraestructura.
class ProgressLogModel {
  final String id;
  final String userId;
  final String levelId;
  final String status;
  final int score;
  final int attempts;
  final int timeSpentSeconds;
  final Map<String, dynamic>? sessionData;
  final List<String>? achievements;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProgressLogModel({
    required this.id,
    required this.userId,
    required this.levelId,
    this.status = 'in_progress',
    this.score = 0,
    this.attempts = 0,
    this.timeSpentSeconds = 0,
    this.sessionData,
    this.achievements,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  ProgressLogModel copyWith({
    String? id,
    String? userId,
    String? levelId,
    String? status,
    int? score,
    int? attempts,
    int? timeSpentSeconds,
    Map<String, dynamic>? sessionData,
    List<String>? achievements,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      levelId: levelId ?? this.levelId,
      status: status ?? this.status,
      score: score ?? this.score,
      attempts: attempts ?? this.attempts,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      sessionData: sessionData ?? this.sessionData,
      achievements: achievements ?? this.achievements,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProgressLogModel.fromJson(Map<String, dynamic> json) {
    return ProgressLogModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      levelId: (json['levelId'] ?? '').toString(),
      status: (json['status'] ?? 'in_progress').toString(),
      score: _toInt(json['score']),
      attempts: _toInt(json['attempts']),
      timeSpentSeconds: _toInt(json['timeSpentSeconds']),
      sessionData: json['sessionData'] as Map<String, dynamic>?,
      achievements: _toStringList(json['achievements']),
      startedAt: _toDateTime(json['startedAt']),
      completedAt: _toDateTime(json['completedAt']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'levelId': levelId,
      'status': status,
      'score': score,
      'attempts': attempts,
      'timeSpentSeconds': timeSpentSeconds,
      'sessionData': sessionData,
      'achievements': achievements,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
    map.removeWhere((_, v) => v == null);
    return map;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static List<String>? _toStringList(dynamic v) {
    if (v == null) return null;
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return null;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    // Compatibilidad básica con objetos serializados tipo Timestamp sin importar paquete:
    if (v is Map) {
      final seconds = v['seconds'] ?? v['_seconds'];
      final nanos = v['nanoseconds'] ?? v['_nanoseconds'];
      if (seconds is int) {
        final ms = seconds * 1000 + (nanos is int ? nanos ~/ 1000000 : 0);
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
    return null;
  }
}