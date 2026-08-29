import 'package:flutter/material.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:appy/features/learning_module/viewmodel/learning_viewmodel.dart';

class LevelTimelineViewModel extends ChangeNotifier {
  final LearningViewModel _learningViewModel;
  final String _moduleId;

  List<LevelStepInfo> _steps = [];
  List<ModuleLevelInfo> _moduleLevels = [];
  String _moduleTitle = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<LevelStepInfo> get steps => _steps;
  List<ModuleLevelInfo> get moduleLevels => _moduleLevels;
  String get moduleTitle => _moduleTitle;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /*
    Lógica de Presentación
  */
  List<Offset> _nodePositions = [];
  List<Offset> get nodePositions => _nodePositions;

  /*
    Lógica de Estado de la UI
  */
  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;

  LevelTimelineViewModel(this._learningViewModel, this._moduleId) {
    _loadModuleData(_moduleId);
  }

  /// Recarga los datos del módulo (útil después de completar un nivel)
  Future<void> reloadModuleData() async {
    await _loadModuleData(_moduleId);
  }

  Future<void> _loadModuleData(String moduleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtener título y niveles en paralelo para reducir latencia
      final results = await Future.wait([
        _learningViewModel.getModuleTitle(moduleId),
        _learningViewModel.getModuleLevels(moduleId),
      ]);

      _moduleTitle = results[0] as String;
      final moduleLevels = results[1] as List<ModuleLevelInfo>;
      _moduleLevels = moduleLevels;

      if (moduleLevels.isEmpty) {
        _errorMessage = 'No se encontraron niveles para este módulo';
        _steps = [];
      } else {
        // Convertir ModuleLevelInfo a LevelStepInfo
        _steps = moduleLevels.asMap().entries.map((entry) {
          final level = entry.value;
          final stepNumber = level.orden;
          final titleWithPrefix = 'Paso $stepNumber: ${level.titulo}';

          return LevelStepInfo(
            previewTitle: titleWithPrefix,
            whatState: level.estado,
            stars: level.estrellas,
            posibleImagePreview:
                (level.actividadData?['pictogramaUrl'] as String?)
                        ?.isNotEmpty ==
                    true
                ? level.actividadData!['pictogramaUrl'] as String
                : level.pictogramaUrl,
            minigameData: _mergeMinigameData(level),
            actividadType: level.actividadType,
            levelId: level.id,
            moduleId: _moduleId,
          );
        }).toList();

        // Las imágenes ya están fijadas en el ImageCache por LearningViewModel
        // (_pinLevelImages) desde el momento en que se cargaron los niveles,
        // por lo que no es necesario hacer warmup adicional aquí.
      }
    } catch (e) {
      _errorMessage = 'Error al cargar los niveles: $e';
      _steps = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void calculateNodePositions(Size screenSize, double itemHeight) {
    final List<Offset> positions = [];
    for (int i = 0; i < _steps.length; i++) {
      final isLeft = i % 2 == 0;
      final centerX = screenSize.width / 2;
      final offset = screenSize.width * 0.15;
      final xPos = isLeft ? centerX - offset : centerX + offset;
      final yPos = (itemHeight * i) + 55;
      positions.add(Offset(xPos, yPos));
    }
    _nodePositions = positions;
    /*
      Se notifica a los listeners para que la vista se actualice una vez que
      las posiciones han sido calculadas.
    */
    notifyListeners();
  }

  void handleTap(int index) {
    if (_steps[index].whatState == StateOfStep.blocked) {
      return;
    }

    if (_selectedIndex == index) {
      _selectedIndex = null; // Si se toca el mismo, se deselecciona.
    } else {
      _selectedIndex = index; // Se selecciona uno nuevo.
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIndex = null;
    notifyListeners();
  }

  Map<String, dynamic>? _mergeMinigameData(ModuleLevelInfo level) {
    final base = Map<String, dynamic>.from(level.actividadData ?? const {});
    base.putIfAbsent('puzzleImageUrl', () => level.puzzleImageUrl);
    base.putIfAbsent('pictogramaUrl', () => level.pictogramaUrl);
    base.putIfAbsent('videoUrl', () => level.videoUrl);
    base.removeWhere((_, value) => value == null);
    return base.isEmpty ? null : base;
  }
}
