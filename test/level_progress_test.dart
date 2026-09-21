import 'dart:math';

import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:appy/features/minigames/simple_selection_questions.dart';
import 'package:appy/shared/services/level_completion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isCompletedProgress', () {
    test('requires the three modalities of the level', () {
      final unaModalidad = {
        'status': 'in_progress',
        'estrellas': 1,
        'activities': {'video': <String, dynamic>{}},
      };
      final tresModalidades = {
        'status': 'completed',
        'estrellas': 3,
        'activities': {
          'video': <String, dynamic>{},
          'pictogram': <String, dynamic>{},
          'simple_selection': <String, dynamic>{},
        },
      };

      expect(isCompletedProgress(unaModalidad), isFalse);
      expect(isCompletedProgress(tresModalidades), isTrue);
    });

    test('keeps levels unlocked by documents written before activities', () {
      final legacy = {'status': 'completed', 'estrellas': 1};
      expect(isCompletedProgress(legacy), isTrue);
    });

    test('does not complete a level with no progress', () {
      expect(isCompletedProgress(null), isFalse);
      expect(isCompletedProgress({'status': 'in_progress'}), isFalse);
    });
  });

  test('parseCompletedActivities reads the modality keys', () {
    final progress = {
      'activities': {
        'video': {'attempts': 0},
        'puzzle': {'attempts': 2},
      },
    };
    expect(parseCompletedActivities(progress), {'video', 'puzzle'});
    expect(parseCompletedActivities({}), isEmpty);
  });

  test('moduleStarsForCompletedLevels follows the 3 / 6 / all thresholds', () {
    expect(moduleStarsForCompletedLevels(2, 10), 0);
    expect(moduleStarsForCompletedLevels(3, 10), 1);
    expect(moduleStarsForCompletedLevels(5, 10), 1);
    expect(moduleStarsForCompletedLevels(6, 10), 2);
    expect(moduleStarsForCompletedLevels(9, 10), 2);
    expect(moduleStarsForCompletedLevels(10, 10), 3);
    // Un módulo más corto llega a 3 estrellas al terminarlo completo.
    expect(moduleStarsForCompletedLevels(8, 8), 3);
  });

  test('countCompletedLevels only counts levels with their three stars', () {
    final progressByLevel = <String, Map<String, dynamic>>{
      'l1': {
        'estrellas': 3,
        'activities': {'a': 1, 'b': 2, 'c': 3},
      },
      'l2': {
        'estrellas': 1,
        'activities': {'a': 1},
      },
    };
    expect(countCompletedLevels(progressByLevel), 1);
  });

  test('calculateCoins decreases with the number of mistakes', () {
    expect(LevelCompletionService.calculateCoins(0), 30);
    expect(LevelCompletionService.calculateCoins(1), 20);
    expect(LevelCompletionService.calculateCoins(2), 20);
    expect(LevelCompletionService.calculateCoins(3), 10);
    expect(LevelCompletionService.calculateCoins(9), 10);
  });

  test('simple selection never repeats an image between options', () {
    // Dos pasos distintos que comparten imagen: no pueden convivir como
    // opciones porque el niño no podría distinguirlas.
    final data = {
      'steps': [
        {'url': 'a.png', 'caption': 'Abrir la llave'},
        {'url': 'a.png', 'caption': 'Cerrar la llave'},
        {'url': 'b.png', 'caption': 'Enjabonarse'},
        {'url': 'c.png', 'caption': 'Secarse'},
      ],
    };

    final questions = buildQuestionsFromData(data, random: Random(7));

    expect(questions, isNotEmpty);
    for (final question in questions) {
      final imagenes = question.options.map((o) => o.imagePath).toList();
      expect(imagenes.toSet().length, imagenes.length);
      expect(question.correctIndex, inInclusiveRange(0, imagenes.length - 1));
    }
  });
}
