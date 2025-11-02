import 'package:flutter/material.dart';
import '../features/learning_module/view/level_content_screen.dart';
import '../features/learning_module/model/content_card_model.dart';

class ExampleLearningModuleScreen extends StatelessWidget {
  const ExampleLearningModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ContentCardData> contents = [
      ContentCardData(
        type: ContentType.pictogram,
        title: 'Saludar',
        description: 'Aprende a saludar correctamente',
        imagePath: 'assets/images/saludar.png',
      ),

      ContentCardData(
        type: ContentType.video,
        title: 'Cómo Comunicarse',
        description: 'Video educativo sobre comunicación',
        imagePath: 'assets/images/video_preview.png',
        videoPath: 'assets/videos/comunicacion.mp4',
      ),

      ContentCardData(
        type: ContentType.miniGame,
        title: 'Encuentra las Emociones',
        description: 'Identifica las diferentes emociones',
        imagePath: 'assets/images/game_emotions.png',
      ),

      ContentCardData(
        type: ContentType.pictogram,
        title: 'Lavarse las Manos',
        description: 'Pasos para una correcta higiene',
        imagePath: 'assets/images/lavarse_manos.png',
      ),

      ContentCardData(
        type: ContentType.video,
        title: 'Rutinas Diarias',
        description: 'Aprende sobre las rutinas del día',
        imagePath: 'assets/images/video_preview2.png',
        videoPath: 'assets/videos/rutinas.mp4',
      ),

      ContentCardData(
        type: ContentType.miniGame,
        title: 'Ordena la Secuencia',
        description: 'Ordena los pasos correctamente',
        imagePath: 'assets/images/game_sequence.png',
      ),
    ];

    return LevelContentPreviewScreen(
      levelName: 'Nivel 1: Comunicación',
      bgLevelImg: null,
      contents: contents,
    );
  }
}

class DynamicLearningModuleScreen extends StatelessWidget {
  final String moduleName;
  final List<Map<String, dynamic>> dynamicData;

  const DynamicLearningModuleScreen({
    super.key,
    required this.moduleName,
    required this.dynamicData,
  });

  @override
  Widget build(BuildContext context) {
    final contents = dynamicData.map((data) {
      ContentType type;
      switch (data['type']) {
        case 'video':
          type = ContentType.video;
          break;
        case 'game':
          type = ContentType.miniGame;
          break;
        default:
          type = ContentType.pictogram;
      }

      return ContentCardData(
        type: type,
        title: data['title'] ?? '',
        description: data['description'],
        imagePath: data['imagePath'] ?? '',
        videoPath: data['videoPath'],
      );
    }).toList();

    return LevelContentPreviewScreen(levelName: moduleName, contents: contents);
  }
}
