import 'package:appy/features/learning_module/model/levels_models.dart';

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
        whatState: StateOfStep.inProgress,
        stars: 5,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/LavadoDeManos.jpg',
        minigameData: {
          'questions': [
            {
              'question': '¿Qué necesitas para lavarte las manos?',
              'correctIndex': 0,
              'maxAttempts': 3,
              'options': [
                {
                  'imagePath': 'assets/images/HIGIENE.jpg',
                  'label': 'Jabón',
                },
                {
                  'imagePath': 'assets/images/ALIMENTACION.jpg',
                  'label': 'Comida',
                },
                {
                  'imagePath': 'assets/images/DORMIR.jpg',
                  'label': 'Cama',
                },
              ],
            },
            {
              'question': '¿Cuándo debes lavarte las manos?',
              'correctIndex': 1,
              'maxAttempts': 3,
              'options': [
                {
                  'imagePath': 'assets/images/DORMIR.jpg',
                  'label': 'Al dormir',
                },
                {
                  'imagePath': 'assets/images/ALIMENTACION.jpg',
                  'label': 'Antes de comer',
                },
                {
                  'imagePath': 'assets/images/SOCIALIZAR.jpg',
                  'label': 'Al jugar videojuegos',
                },
              ],
            },
            {
              'question': '¿Qué parte del cuerpo lavas con jabón?',
              'correctIndex': 2,
              'maxAttempts': 3,
              'options': [
                {
                  'imagePath': 'assets/images/DORMIR.jpg',
                  'label': 'Pies',
                },
                {
                  'imagePath': 'assets/images/SOCIALIZAR.jpg',
                  'label': 'Cabeza',
                },
                {
                  'imagePath': 'assets/images/HIGIENE.jpg',
                  'label': 'Manos',
                },
              ],
            },
          ],
        },
      ),
      LevelStepInfo(
        previewTitle:
            'Paso 2: Cepillado de dientes',
        whatState:
            StateOfStep.inProgress,
        stars: 4,
        posibleImagePreview:
            'assets/images/LevelBGs/Higiene/StepsBGs/CepilladoDeDientes.jpg',
        minigameData: {
          'question': 'Selecciona la imagen del cepillo de dientes',
          'correctIndex': 1,
          'maxAttempts': 3,
          'options': [
            {
              'imagePath': 'assets/images/icon-questionmark.png',
              'label': 'Opción A',
            },
            {
              'imagePath': 'assets/images/icon-salute-hidden.png',
              'label': 'Opción B',
            },
          ],
        },
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
        minigameData: {
          'questions': [
            {
              'question': '¿Qué haces por la mañana?',
              'correctIndex': 2,
              'maxAttempts': 4,
              'options': [
                {
                  'imagePath': 'assets/images/DORMIR.jpg',
                  'label': 'Dormir',
                },
                {
                  'imagePath': 'assets/images/SOCIALIZAR.jpg',
                  'label': 'Jugar',
                },
                {
                  'imagePath': 'assets/images/HIGIENE.jpg',
                  'label': 'Aseo personal',
                },
                {
                  'imagePath': 'assets/images/ALIMENTACION.jpg',
                  'label': 'Comer',
                },
              ],
            },
            {
              'question': '¿Qué haces antes de dormir?',
              'correctIndex': 1,
              'maxAttempts': 3,
              'options': [
                {
                  'imagePath': 'assets/images/SOCIALIZAR.jpg',
                  'label': 'Jugar afuera',
                },
                {
                  'imagePath': 'assets/images/HIGIENE.jpg',
                  'label': 'Cepillar dientes',
                },
                {
                  'imagePath': 'assets/images/ALIMENTACION.jpg',
                  'label': 'Comer dulces',
                },
              ],
            },
          ],
        },
      ),
    ];
  }
}
