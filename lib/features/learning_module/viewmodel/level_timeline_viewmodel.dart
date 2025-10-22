import 'package:flutter/material.dart';
import 'package:appy/features/learning_module/data/level_repository.dart';
import 'package:appy/features/learning_module/model/levels_models.dart';

class LevelTimelineViewModel
    extends ChangeNotifier {
  List<LevelStepInfo> _steps = [];
  String _moduleTitle = '';
  List<LevelStepInfo> get steps =>
      _steps;
  String get moduleTitle =>
      _moduleTitle;

  /*
    Lógica de Presentación
  */
  List<Offset> _nodePositions = [];
  List<Offset> get nodePositions =>
      _nodePositions;

  /*
    Lógica de Estado de la UI
  */
  int? _selectedIndex;
  int? get selectedIndex =>
      _selectedIndex;

  LevelTimelineViewModel(
    String moduleId,
  ) {
    _loadModuleData(moduleId);
  }

  void _loadModuleData(
    String moduleId,
  ) {
    _steps =
        LevelRepository.getStepsForModule(
          moduleId,
        );
    if (moduleId.contains('Higiene')) {
      _moduleTitle =
          'Módulo de Higiene';
    } else {
      _moduleTitle =
          'Módulo de Aprendizaje';
    }
  }

  void calculateNodePositions(
    Size screenSize,
    double itemHeight,
  ) {
    final List<Offset> positions = [];
    for (
      int i = 0;
      i < _steps.length;
      i++
    ) {
      final isLeft = i % 2 == 0;
      final centerX =
          screenSize.width / 2;
      final offset =
          screenSize.width * 0.15;
      final xPos = isLeft
          ? centerX - offset
          : centerX + offset;
      final yPos =
          (itemHeight * i) + 55;
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
    if (_steps[index].whatState ==
        StateOfStep.blocked) {
      return;
    }

    if (_selectedIndex == index) {
      _selectedIndex =
          null; // Si se toca el mismo, se deselecciona.
    } else {
      _selectedIndex =
          index; // Se selecciona uno nuevo.
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIndex = null;
    notifyListeners();
  }
}
