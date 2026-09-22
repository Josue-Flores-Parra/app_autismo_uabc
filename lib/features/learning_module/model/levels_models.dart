/*
  Se renombra el enum a 'StateOfStep' para evitar conflictos con la librería
  interna de Flutter que también tiene un 'StepState'.
*/
enum StateOfStep { completed, blocked, inProgress }

/*
Estrellas necesarias para dar un nivel por terminado y abrir el siguiente.
Cada modalidad del nivel (video, pictograma y minijuego) otorga una estrella,
así que exigir 3 equivale a completar las tres modalidades.
*/
const int kLevelStarsToComplete = 3;

/*
Predicado que determina si un documento de progreso representa un nivel
completado. Un nivel se considera completado cuando reune
`kLevelStarsToComplete` estrellas, es decir sus tres modalidades.

Mantiene la misma regla usada por `LearningViewModel._determineLevelStates`,
de modo que el badge de nivel y el estado de los nodos del timeline nunca
diverjan. `estrellas` se parsea de forma robusta (int o String) igual que en
`_createModuleLevelInfoWithProgress`.

Los documentos escritos antes de registrar `activities` no pueden recalcularse
por modalidad, así que conservan el desbloqueo que ya tenían.
*/
bool isCompletedProgress(Map<String, dynamic>? progress) {
  if (progress == null) return false;
  if (parseProgressEstrellas(progress) >= kLevelStarsToComplete) return true;
  if (progress['activities'] == null) {
    return progress['status']?.toString().toLowerCase() == 'completed';
  }
  return false;
}

/*
Modalidades ya completadas dentro de un nivel, leidas del mapa `activities`
del documento de progreso. La clave de cada entrada es el `actividadType`.
*/
Set<String> parseCompletedActivities(Map<String, dynamic>? progress) {
  final raw = progress?['activities'];
  if (raw is! Map) return <String>{};
  return raw.keys.map((key) => key.toString()).toSet();
}

/*
Estrellas del badge de modulo segun los niveles terminados:
3 niveles dan 1 estrella, 6 dan 2 y terminar el modulo completo da 3.
*/
int moduleStarsForCompletedLevels(int completedLevels, int totalLevels) {
  if (totalLevels > 0 && completedLevels >= totalLevels) return 3;
  if (completedLevels >= 6) return 2;
  if (completedLevels >= 3) return 1;
  return 0;
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
