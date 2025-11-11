import 'package:flutter/material.dart';
import 'package:appy/features/learning_module/data/level_repository.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';

class LevelTimelineViewModel extends ChangeNotifier {
  final LevelRepository _levelRepository = LevelRepository();

  List<LevelStepInfo> _steps = [];
  String _moduleTitle = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<LevelStepInfo> get steps => _steps;
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

  LevelTimelineViewModel(String moduleId) {
    _loadModuleData(moduleId);
  }

  Future<void> _loadModuleData(String moduleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _steps = await _levelRepository.getStepsForModule(moduleId);

      if (moduleId.contains('Higiene') || moduleId.contains('higiene')) {
        _moduleTitle = 'Módulo de Higiene';
      } else if (moduleId.contains('alimentacion')) {
        _moduleTitle = 'Módulo de Alimentación';
      } else {
        _moduleTitle = 'Módulo de Aprendizaje';
      }

      if (_steps.isEmpty) {
        _errorMessage = 'No se encontraron niveles para este módulo';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar los niveles: $e';
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
