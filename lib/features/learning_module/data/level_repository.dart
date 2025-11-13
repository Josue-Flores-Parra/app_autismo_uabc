import 'package:appy/data/services/firestore_services.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';

class LevelRepository {
  final FirestoreService _firestoreService = FirestoreService();

  /*
    Método que carga los niveles de un módulo desde Firestore y los convierte
    a objetos LevelStepInfo para compatibilidad con el código existente.
  */
  Future<List<LevelStepInfo>> getStepsForModule(String moduleId) async {
    try {
      // Obtener niveles desde Firestore
      final levelsData = await _firestoreService.getModuleLevels(moduleId);

      if (levelsData.isEmpty) {
        return [];
      }

      // Convertir datos de Firestore a ModuleLevelInfo
      final moduleLevels = levelsData
          .map((data) => ModuleLevelInfo.fromFirestore(data))
          .toList();

      // Convertir ModuleLevelInfo a LevelStepInfo
      final steps = moduleLevels.asMap().entries.map((entry) {
        final level = entry.value;

        // Agregar "Paso X:" antes del título usando el campo 'orden'
        final stepNumber = level.orden;
        final titleWithPrefix = 'Paso $stepNumber: ${level.titulo}';

        // El primer nivel (orden = 1) siempre debe estar en progreso
        final estado = level.orden == 1 ? StateOfStep.inProgress : level.estado;

        return LevelStepInfo(
          previewTitle: titleWithPrefix,
          whatState: estado,
          stars: level.estrellas,
          posibleImagePreview: level.pictogramaUrl,
          minigameData: level.actividadData,
          actividadType: level.actividadType,
          levelId: level.id,
          moduleId: moduleId,
        );
      }).toList();

      return steps;
    } catch (e, stackTrace) {
      return [];
    }
  }
}
