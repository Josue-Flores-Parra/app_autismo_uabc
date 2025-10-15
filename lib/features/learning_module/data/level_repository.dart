import 'package:app_autismo_uabc/features/learning_module/model/levels_models.dart';

class LevelRepository {
  /*
    Método estático que proporciona la lista de niveles para un módulo.
    Los datos están fijos para fines de prueba.
  */
  static List<LevelStepInfo>
  getStepsForModule(String moduleId) {
    return [
      LevelStepInfo(
        previewTitle:
            'Paso 1: Lavado de manos',
        whatState: StateOfStep.blocked,
        stars: 5,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/LavadoDeManos.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 2: Cepillado de dientes',
        whatState:
            StateOfStep.inProgress,
        stars: 4,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/CepilladoDeDientes.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 3: Baño e Higiene Corporal',
        whatState:
            StateOfStep.completed,
        stars: 5,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/BanoCorporal.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 4: Cuidado del cabello',
        whatState: StateOfStep.blocked,
        stars: 3,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/CuidadoCabello.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 5: Uso del inodoro',
        whatState:
            StateOfStep.completed,
        stars: 5,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/UsodelInodoro.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 6: Cambio de ropa',
        whatState:
            StateOfStep.completed,
        stars: 4,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/CambioDeRopa.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 7: Corte de uñas',
        whatState:
            StateOfStep.completed,
        stars: 3,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/CorteDeUnas.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 8: Uso de desodorante',
        whatState:
            StateOfStep.completed,
        stars: 5,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/UsoDesodorante.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 9: Cuidado de los Zapatos',
        whatState:
            StateOfStep.completed,
        stars: 4,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/CuidadoZapatos.jpg',
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 10: Rutina matutina y nocturna',
        whatState:
            StateOfStep.inProgress,
        stars: 0,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/RUTINADIARIA.jpg',
      ),
    ];
  }
}
