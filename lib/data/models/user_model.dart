/// UserModel: clase de datos pura para representar a un usuario.
/// - Sin dependencias de Firestore/Flutter (solo Dart).
/// - Serializa fechas en ISO 8601 (string) para mantener independencia de infraestructura.
class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final int monedas;
  final String role;
  final Map<String, dynamic>? avatarConfig;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.monedas = 0,
    this.role = 'patient',
    this.avatarConfig,
    this.createdAt,
    this.updatedAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    int? monedas,
    String? role,
    Map<String, dynamic>? avatarConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      monedas: monedas ?? this.monedas,
      role: role ?? this.role,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      displayName: json['displayName'] as String?,
      monedas: _toInt(json['monedas']),
      role: (json['role'] ?? 'patient').toString(),
      avatarConfig: json['avatarConfig'] as Map<String, dynamic>?,
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'email': email,
      'displayName': displayName,
      'monedas': monedas,
      'role': role,
      'avatarConfig': avatarConfig,
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
