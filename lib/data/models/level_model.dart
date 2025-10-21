/// LevelModel: clase de datos pura para representar un nivel de aprendizaje.
/// - Sin dependencias de Firestore/Flutter (solo Dart).
/// - Serializa fechas en ISO 8601 (string) para mantener independencia de infraestructura.
class LevelModel {
  final String id;
  final String title;
  final String description;
  final int order;
  final String difficulty;
  final String? pictogramUrl;
  final String? videoUrl;
  final Map<String, dynamic>? minigameData;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LevelModel({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    this.difficulty = 'easy',
    this.pictogramUrl,
    this.videoUrl,
    this.minigameData,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  LevelModel copyWith({
    String? id,
    String? title,
    String? description,
    int? order,
    String? difficulty,
    String? pictogramUrl,
    String? videoUrl,
    Map<String, dynamic>? minigameData,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LevelModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      difficulty: difficulty ?? this.difficulty,
      pictogramUrl: pictogramUrl ?? this.pictogramUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      minigameData: minigameData ?? this.minigameData,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      order: _toInt(json['order']),
      difficulty: (json['difficulty'] ?? 'easy').toString(),
      pictogramUrl: json['pictogramUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      minigameData: json['minigameData'] as Map<String, dynamic>?,
      isActive: _toBool(json['isActive']),
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'order': order,
      'difficulty': difficulty,
      'pictogramUrl': pictogramUrl,
      'videoUrl': videoUrl,
      'minigameData': minigameData,
      'isActive': isActive,
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

  static bool _toBool(dynamic v) {
    if (v == null) return true;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is int) return v != 0;
    return true;
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