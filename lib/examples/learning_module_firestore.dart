import 'package:flutter/material.dart';
import '../features/learning_module/view/level_content_screen.dart';
import '../features/learning_module/model/content_card_model.dart';
import '../features/learning_module/viewmodel/module_list_viewmodel.dart';
import '../features/learning_module/model/levels_models.dart';

/*
EJEMPLO DE CÓMO CARGAR DATOS DESDE FIRESTORE

Este archivo demuestra cómo usar los datos de Firestore para mostrar niveles.
NO usa datos hardcoded - todo viene de la base de datos.
*/

class DynamicLevelContentScreen extends StatefulWidget {
  final String moduleId;
  final String levelId;

  const DynamicLevelContentScreen({
    super.key,
    required this.moduleId,
    required this.levelId,
  });

  @override
  State<DynamicLevelContentScreen> createState() =>
      _DynamicLevelContentScreenState();
}

class _DynamicLevelContentScreenState extends State<DynamicLevelContentScreen> {
  late ModuleListViewModel _viewModel;
  ModuleLevelInfo? _levelInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewModel = ModuleListViewModel();
    _loadLevelData();
  }

  Future<void> _loadLevelData() async {
    try {
      // Cargar todos los niveles del módulo desde Firestore
      final niveles = await _viewModel.obtenerNivelesModulo(widget.moduleId);

      // Encontrar el nivel específico
      final level = niveles.firstWhere(
        (nivel) => nivel.id == widget.levelId,
        orElse: () => throw Exception('Nivel no encontrado'),
      );

      setState(() {
        _levelInfo = level;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar nivel: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    // Construir las tarjetas de contenido basadas en los datos de Firestore
    final contents = _buildContentFromFirestore(_levelInfo!);

    return LevelContentPreviewScreen(
      levelName: _levelInfo!.titulo,
      bgLevelImg: _levelInfo!.pictogramaUrl,
      contents: contents,
    );
  }

  /*
  Convierte los datos de Firestore en ContentCardData
  Aquí defines cómo interpretar actividadData desde Firestore
  */
  List<ContentCardData> _buildContentFromFirestore(ModuleLevelInfo level) {
    final List<ContentCardData> contents = [];

    // Si hay pictograma, agregar tarjeta de pictograma
    if (level.pictogramaUrl != null && level.pictogramaUrl!.isNotEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.pictogram,
          title: level.titulo,
          description: 'Pictograma del nivel',
          imagePath: level.pictogramaUrl!,
        ),
      );
    }

    // Si hay video, agregar tarjeta de video
    if (level.videoUrl != null && level.videoUrl!.isNotEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.video,
          title: 'Video: ${level.titulo}',
          description: 'Video educativo',
          imagePath: level.pictogramaUrl ?? '',
          videoPath: level.videoUrl,
        ),
      );
    }

    // Si hay actividad configurada, agregar minijuego
    if (level.actividadData != null &&
        level.actividadData!['enabled'] == true) {
      contents.add(
        ContentCardData(
          type: ContentType.miniGame,
          title: 'Actividad: ${level.titulo}',
          description: 'Práctica interactiva',
          imagePath: level.pictogramaUrl ?? '',
        ),
      );
    }

    // Si no hay contenido, mostrar mensaje
    if (contents.isEmpty) {
      contents.add(
        ContentCardData(
          type: ContentType.pictogram,
          title: level.titulo,
          description: 'Contenido pendiente de agregar',
          imagePath: '',
        ),
      );
    }

    return contents;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}

/*
EJEMPLO DE USO:

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DynamicLevelContentScreen(
      moduleId: 'alimentacion_01',
      levelId: 'level_identificar_frutas',
    ),
  ),
);
*/
