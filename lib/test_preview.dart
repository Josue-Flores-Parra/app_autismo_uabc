import 'package:flutter/material.dart';
import 'features/learning_module/view/level_content_screen.dart';
import 'features/learning_module/model/content_card_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learning Module Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A97B8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TestPreviewScreen(),
    );
  }
}

class TestPreviewScreen extends StatelessWidget {
  const TestPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo usando los assets reales
    final List<ContentCardData> contents = [
      ContentCardData(
        type: ContentType.pictogram,
        title: 'Aprender Colores',
        description: 'Identifica y aprende los diferentes colores',
        imagePath: 'assets/imgs/pictogramjpg.jpg',
      ),
      ContentCardData(
        type: ContentType.video,
        title: 'Video: Perrito Feliz',
        description: 'Aprende sobre los animales',
        imagePath: 'assets/imgs/bgdog.jpg',
        videoPath: 'assets/videos/dog.mp4',
      ),
      ContentCardData(
        type: ContentType.miniGame,
        title: 'Juego de Memoria',
        description: 'Encuentra las parejas correctas',
        imagePath: 'assets/imgs/game.jpg',
      ),
      ContentCardData(
        type: ContentType.pictogram,
        title: 'Emociones',
        description: 'Reconoce las diferentes emociones',
        imagePath: 'assets/imgs/pictogramjpg.jpg',
      ),
    ];

    return LevelContentPreviewScreen(
      levelName: 'Nivel 1: Aprendizaje Básico',
      bgLevelImg: 'assets/imgs/bgdog.jpg',
      contents: contents,
    );
  }
}
