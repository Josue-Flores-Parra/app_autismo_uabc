/*
  Se renombra el enum a 'StateOfStep' para evitar conflictos con la librería
  interna de Flutter que también tiene un 'StepState'.
*/
enum StateOfStep { completed, blocked, inProgress }

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
  final String? audioUrl;
  final String actividadType;
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
    this.audioUrl,
    required this.actividadType,
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
      audioUrl: data['audioUrl']?.toString(),
      actividadType: data['actividadType']?.toString() ?? 'simple_selection',
      actividadData: actividadDataValue,
      estrellas: estrellasValue,
      estado: _parseEstado(data['estado']?.toString()),
    );

    return nivel;
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
      'audioUrl': audioUrl,
      'actividadType': actividadType,
      'actividadData': actividadData,
      'estrellas': estrellas,
      'estado': estado.toString().split('.').last,
    };
  }
}
