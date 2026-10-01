import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:flutter_test/flutter_test.dart';

ModuleLevelInfo _level({
  String? pictograma,
  String? video,
  String? audio,
  String? puzzleImage,
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
    actividadData: actividadData,
  );
}

void main() {
  group('collectLevelAssetUrls', () {
    test('collects the level media fields', () {
      final urls = collectLevelAssetUrls([
        _level(
          pictograma: 'https://s.test/p.png',
          video: 'https://s.test/v.mp4',
          audio: 'https://s.test/a.mp3',
          puzzleImage: 'https://s.test/z.png',
        ),
      ]);

      expect(urls, {
        'https://s.test/p.png',
        'https://s.test/v.mp4',
        'https://s.test/a.mp3',
        'https://s.test/z.png',
      });
    });

    test('finds urls nested inside the activity data', () {
      final urls = collectLevelAssetUrls([
        _level(
          actividadData: {
            'minigamePool': [
              {'url': 'https://s.test/1.png', 'caption': 'Abrir la llave'},
              {'url': 'https://s.test/2.png', 'caption': 'Cerrar la llave'},
            ],
            'questions': {
              'q1': {
                'options': [
                  {'imagePath': 'https://s.test/3.png'},
                ],
              },
            },
            'maxAttempts': 3,
          },
        ),
      ]);

      expect(urls, {
        'https://s.test/1.png',
        'https://s.test/2.png',
        'https://s.test/3.png',
      });
    });

    test('ignores local assets, captions and empty values', () {
      final urls = collectLevelAssetUrls([
        _level(
          pictograma: '',
          video: 'assets/videos/dog.mp4',
          actividadData: {
            'minigamePool': [
              {'url': 'assets/images/salute.png', 'caption': 'visita http://x'},
            ],
          },
        ),
      ]);

      expect(urls, isEmpty);
    });

    test('repeated urls and surrounding spaces count once', () {
      final urls = collectLevelAssetUrls([
        _level(pictograma: ' https://s.test/p.png '),
        _level(
          pictograma: 'https://s.test/p.png',
          actividadData: {'pictogramaUrl': 'https://s.test/p.png'},
        ),
      ]);

      expect(urls, {'https://s.test/p.png'});
    });
  });
}
