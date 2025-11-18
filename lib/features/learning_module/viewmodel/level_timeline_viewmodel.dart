import 'package:flutter/material.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:appy/features/learning_module/viewmodel/learning_viewmodel.dart';

class LevelTimelineViewModel extends ChangeNotifier {
  final LearningViewModel _learningViewModel;
  final String _moduleId;

  List<LevelStepInfo> _steps = [];
  List<ModuleLevelInfo> _moduleLevels = []; // Guardar los niveles completos
  String _moduleTitle = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<LevelStepInfo> get steps => _steps;
  List<ModuleLevelInfo> get moduleLevels => _moduleLevels; // Getter para acceder a los niveles completos
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
      // Obtener título del módulo
      _moduleTitle = await _learningViewModel.getModuleTitle(moduleId);

      // Obtener niveles desde LearningViewModel
      final moduleLevels = await _learningViewModel.getModuleLevels(moduleId);
      _moduleLevels = moduleLevels; // Guardar los niveles completos

      if (moduleLevels.isEmpty) {
        _errorMessage = 'No se encontraron niveles para este módulo';
        _steps = [];
      } else {
        // Convertir ModuleLevelInfo a LevelStepInfo
        _steps = moduleLevels.asMap().entries.map((entry) {
          final level = entry.value;

          // Agregar "Paso X:" antes del título usando el campo 'orden'
          final stepNumber = level.orden;
          final titleWithPrefix = 'Paso $stepNumber: ${level.titulo}';

          return LevelStepInfo(
            previewTitle: titleWithPrefix,
            whatState: level.estado,
            stars: level.estrellas,
            posibleImagePreview: level.pictogramaUrl,
            minigameData: level.actividadData,
            actividadType: level.actividadType,
            levelId: level.id,
            moduleId: _moduleId,
          );
        }).toList();
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
}