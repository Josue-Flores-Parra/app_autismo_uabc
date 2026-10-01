import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:appy/features/profiles/model/learner_profile.dart';
import 'package:flutter_test/flutter_test.dart';

ModuleLevelInfo _level({
  StateOfStep estado = StateOfStep.blocked,
  String? pictograma,
  String? video,
  String? audio,
  String? puzzleImage,
  String? actividadType,
  Map<String, dynamic>? actividadData,
}) {
  return ModuleLevelInfo(
    id: 'nivel',
    titulo: 'Nivel',
    orden: 1,
    pictogramaUrl: pictograma,
    videoUrl: video,
    audioUrl: audio,
    puzzleImageUrl: puzzleImage,
    actividadType: actividadType,
    actividadData: actividadData,
    estado: estado,
  );
}

void main() {
  group('levelOffersContent', () {
    test('without any modality the level has no content', () {
      expect(levelOffersContent(_level()), isFalse);
      expect(levelOffersContent(_level(pictograma: '')), isFalse);
    });

    test('pictogram, video and audio count as content', () {
      expect(levelOffersContent(_level(pictograma: 'p.png')), isTrue);
      expect(levelOffersContent(_level(video: 'v.mp4')), isTrue);
      expect(levelOffersContent(_level(audio: 'a.mp3')), isTrue);
    });

    test('simple selection counts when it is enabled', () {
      expect(
        levelOffersContent(
          _level(actividadData: {'isSimpleSelectionEnabled': true}),
        ),
        isTrue,
      );
      expect(
        levelOffersContent(
          _level(actividadData: {'isSimpleSelectionEnabled': false}),
        ),
        isFalse,
      );
    });

    test('puzzle needs an image to count', () {
      expect(levelOffersContent(_level(actividadType: 'puzzle')), isFalse);
      expect(
        levelOffersContent(
          _level(actividadType: 'puzzle', puzzleImage: 'img.png'),
        ),
        isTrue,
      );
    });
  });

  group('levelStateForDisplay', () {
    test('keeps the saved state when the free mode is off', () {
      final level = _level(video: 'v.mp4');
      expect(
        levelStateForDisplay(level, openAllLevels: false),
        StateOfStep.blocked,
      );
    });

    test('opens blocked levels that have content in free mode', () {
      final level = _level(video: 'v.mp4');
      expect(
        levelStateForDisplay(level, openAllLevels: true),
        StateOfStep.inProgress,
      );
    });

    test('never opens a level without content', () {
      expect(
        levelStateForDisplay(_level(), openAllLevels: true),
        StateOfStep.blocked,
      );
    });

    test('does not change completed or in progress levels', () {
      for (final estado in [StateOfStep.completed, StateOfStep.inProgress]) {
        final level = _level(estado: estado, video: 'v.mp4');
        expect(levelStateForDisplay(level, openAllLevels: true), estado);
      }
    });
  });

  group('LearnerSettings.openAllLevels', () {
    test('is off by default and for profiles saved before the option', () {
      expect(LearnerSettings.defaults.openAllLevels, isFalse);
      expect(LearnerSettings.fromMap(null).openAllLevels, isFalse);
      expect(
        LearnerSettings.fromMap({'fontScale': 'large'}).openAllLevels,
        isFalse,
      );
    });

    test('is saved and read back', () {
      final settings = LearnerSettings.defaults.copyWith(openAllLevels: true);
      expect(settings.toMap()['openAllLevels'], isTrue);
      expect(LearnerSettings.fromMap(settings.toMap()).openAllLevels, isTrue);
      expect(settings == LearnerSettings.defaults, isFalse);
    });

    test('ignores values that are not booleans', () {
      expect(
        LearnerSettings.fromMap({'openAllLevels': 'si'}).openAllLevels,
        isFalse,
      );
    });
  });
}
