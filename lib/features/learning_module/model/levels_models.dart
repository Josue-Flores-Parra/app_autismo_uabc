/*
  Se renombra el enum a 'StateOfStep' para evitar conflictos con la librería
  interna de Flutter que también tiene un 'StepState'.
*/
enum StateOfStep { completed, blocked, inProgress }

class LevelStepInfo {
  LevelStepInfo({
    required this.previewTitle,
    required this.whatState,
    this.posibleImagePreview,
    this.stars,
    this.minigameData,
  });

  final String previewTitle;
  final StateOfStep? whatState;
  final String? posibleImagePreview;
  final int? stars;
  final Map<String, dynamic>? minigameData;
}
