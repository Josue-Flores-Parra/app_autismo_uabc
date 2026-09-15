/*
  Se renombra el enum a 'StateOfStep' para evitar conflictos con la librería
  interna de Flutter que también tiene un 'StepState'.
*/
enum StateOfStep { completed, blocked, inProgress }

/*
Predicado que determina si un documento de progreso representa un nivel
completado. Un nivel se considera completado cuando su `status` es
'completed' o cuando tiene estrellas (> 0).

Mantiene la misma regla usada por `LearningViewModel._determineLevelStates`,
de modo que el badge de nivel y el estado de los nodos del timeline nunca
diverjan. `estrellas` se parsea de forma robusta (int o String) igual que en
`_createModuleLevelInfoWithProgress`.
*/
bool isCompletedProgress(Map<String, dynamic>? progress) {
  if (progress == null) return false;
  final status = progress['status']?.toString().toLowerCase();
  final estrellas = parseProgressEstrellas(progress);
  return status == 'completed' || estrellas > 0;
}

/*
Parsea el campo `estrellas` de un documento de progreso como int, aceptando
int o String (igual que `_createModuleLevelInfoWithProgress`). Cualquier otro
tipo o valor ausente se trata como 0.
*/
int parseProgressEstrellas(Map<String, dynamic> progress) {
  final value = progress['estrellas'];
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/*
Cuenta cuántos niveles están completados a partir de un mapa de progreso
indexado por levelId (clave = levelId, valor = documento de progreso).
*/
int countCompletedLevels(Map<String, Map<String, dynamic>> progressByLevel) {
  int count = 0;
  progressByLevel.forEach((_, levelProgress) {
    if (isCompletedProgress(levelProgress)) count++;
  });
  return count;
}

class LevelStepInfo {
  LevelStepInfo({
    required this.previewTitle,
    required this.whatState,
    this.posibleImagePreview,
    this.stars,
    this.minigameData,
    this.actividadType,
    this.levelId,
    this.moduleId,
  });

  final String previewTitle;
  final StateOfStep? whatState;
  final String? posibleImagePreview;
  final int? stars;
  final Map<String, dynamic>? minigameData;
  final String? actividadType;
  final String? levelId;
  final String? moduleId;
}

/*
Modelo que representa un nivel específico dentro de un módulo.
Contiene información sobre el nivel individual cargada desde Firestore.
*/
class ModuleLevelInfo {
  final String id;
  final String titulo;
  final int orden;
  final String? pictogramaUrl;
  final String? videoUrl;
  final String? puzzleImageUrl;
  final String? audioUrl;
  final String?
  actividadType; // Nullable para detectar cuando no hay actividad interactiva
  final Map<String, dynamic>? actividadData;
  final int estrellas;
  final StateOfStep estado;

  // constructor default
  ModuleLevelInfo({
    required this.id,
    required this.titulo,
    required this.orden,
    this.pictogramaUrl,
    this.videoUrl,
    this.puzzleImageUrl,
    this.audioUrl,
    this.actividadType, // Ahora es nullable
    this.actividadData,
    this.estrellas = 0,
    this.estado = StateOfStep.blocked,
  });

  /*
  Factory constructor para crear ModuleLevelInfo desde datos de Firestore.
  Maneja campos faltantes y conversiones de tipo con valores por defecto seguros.
  */
  factory ModuleLevelInfo.fromFirestore(Map<String, dynamic> data) {
    // Convertir orden de manera segura (puede venir como string o número)
    int ordenValue;
    try {
      if (data['orden'] is int) {
        ordenValue = data['orden'];
      } else if (data['orden'] is String) {
        ordenValue = int.parse(data['orden']);
      } else if (data['orden'] == null) {
        ordenValue = 0;
      } else {
        ordenValue = 0;
      }
    } catch (e) {
      ordenValue = 0;
    }

    // Convertir estrellas de manera segura
    int estrellasValue;
    try {
      if (data['estrellas'] is int) {
        estrellasValue = data['estrellas'];
      } else if (data['estrellas'] is String) {
        estrellasValue = int.parse(data['estrellas']);
      } else {
        estrellasValue = 0;
      }
    } catch (e) {
      estrellasValue = 0;
    }

    // Parsear actividadData de manera segura
    Map<String, dynamic>? actividadDataValue;
    try {
      if (data['actividadData'] != null) {
        actividadDataValue = data['actividadData'] as Map<String, dynamic>;
      }
    } catch (e) {
      actividadDataValue = null;
    }

    final nivel = ModuleLevelInfo(
      id: data['id']?.toString() ?? '',
      titulo: data['titulo']?.toString() ?? '',
      orden: ordenValue,
      pictogramaUrl: data['pictogramaUrl']?.toString(),
      videoUrl: data['videoUrl']?.toString(),
      puzzleImageUrl: data['puzzleImageUrl']?.toString(),
      audioUrl: data['audioUrl']?.toString(),
      // Tratar null y cadenas vacías como null
      actividadType: _parseActividadType(data['actividadType']),
      actividadData: actividadDataValue,
      estrellas: estrellasValue,
      estado: _parseEstado(data['estado']?.toString()),
    );

    return nivel;
  }

  /*
  Helper para parsear actividadType desde Firestore.
  Trata null, cadenas vacías y la cadena "null" como null.
  */
  static String? _parseActividadType(dynamic actividadType) {
    if (actividadType == null) {
      return null;
    }

    final String str = actividadType.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null') {
      return null;
    }

    return str;
  }

  /*
  Helper para convertir string de estado a StateOfStep.
  Maneja valores null y strings inválidos de manera segura.
  */
  static StateOfStep _parseEstado(String? estado) {
    if (estado == null) {
      return StateOfStep.blocked;
    }

    switch (estado.toLowerCase()) {
      case 'completed':
        return StateOfStep.completed;
      case 'inprogress':
      case 'in_progress':
        return StateOfStep.inProgress;
      case 'blocked':
        return StateOfStep.blocked;
      default:
        return StateOfStep.blocked;
    }
  }

  /*
  Convierte ModuleLevelInfo a Map para Firestore
  */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'orden': orden,
      'pictogramaUrl': pictogramaUrl,
      'videoUrl': videoUrl,
      'puzzleImageUrl': puzzleImageUrl,
      'audioUrl': audioUrl,
      'actividadType': actividadType,
      'actividadData': actividadData,
      'estrellas': estrellas,
      'estado': estado.toString().split('.').last,
    };
  }
}
