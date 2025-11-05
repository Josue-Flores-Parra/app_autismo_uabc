/// ModuleModel: clase de datos para un módulo de aprendizaje.
/// Puede incluir niveles (Level) como lista interna.
class ModuleModel {
  final String id;
  final String name;
  final String? description;
  final List<ModuleLevel> levels;

  const ModuleModel({
    required this.id,
    required this.name,
    this.description,
    this.levels = const [],
  });

  ModuleModel copyWith({
    String? id,
    String? name,
    String? description,
    List<ModuleLevel>? levels,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      levels: levels ?? this.levels,
    );
  }

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'];
    final parsedLevels = (rawLevels is List)
        ? rawLevels
              .whereType<Map>()
              .map((e) => ModuleLevel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <ModuleLevel>[];

    return ModuleModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      levels: parsedLevels,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'levels': levels.map((e) => e.toJson()).toList(),
    };
    map.removeWhere((_, v) => v == null);
    return map;
  }
}

/// Nivel dentro de un módulo.
/// Mantiene estructura mínima y serialización simple.
class ModuleLevel {
  final String id;
  final String name;
  final int order; // Para ordenar niveles (0..n)
  final String? description;
  final int? requiredMonedas; // Opcional: costo/desbloqueo

  const ModuleLevel({
    required this.id,
    required this.name,
    required this.order,
    this.description,
    this.requiredMonedas,
  });

  ModuleLevel copyWith({
    String? id,
    String? name,
    int? order,
    String? description,
    int? requiredMonedas,
  }) {
    return ModuleLevel(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      description: description ?? this.description,
      requiredMonedas: requiredMonedas ?? this.requiredMonedas,
    );
  }

  factory ModuleLevel.fromJson(Map<String, dynamic> json) {
    return ModuleLevel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      order: _toInt(json['order']),
      description: json['description'] as String?,
      requiredMonedas: _toNullableInt(json['requiredMonedas']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'order': order,
      'description': description,
      'requiredMonedas': requiredMonedas,
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

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
