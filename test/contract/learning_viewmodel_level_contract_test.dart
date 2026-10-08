import 'package:appy/features/learning_module/model/levels_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isCompletedProgress', () {
    test('null no es completado', () {
      expect(isCompletedProgress(null), isFalse);
    });

    test("status 'completed' sin activities es completado (legado)", () {
      expect(
        isCompletedProgress({'status': 'completed', 'estrellas': 0}),
        isTrue,
      );
    });

    test("status 'completed' con activities necesita las tres estrellas", () {
      expect(
        isCompletedProgress({
          'status': 'completed',
          'estrellas': 1,
          'activities': {'video': true},
        }),
        isFalse,
      );
    });

    test('status COMPLETED (mayúsculas) es completado', () {
      expect(isCompletedProgress({'status': 'COMPLETED'}), isTrue);
    });

    test('tres estrellas es completado aunque status no sea completed', () {
      expect(
        isCompletedProgress({'status': 'in_progress', 'estrellas': 3}),
        isTrue,
      );
    });

    test('una o dos estrellas aun no completan el nivel', () {
      expect(
        isCompletedProgress({'status': 'in_progress', 'estrellas': 2}),
        isFalse,
      );
      expect(isCompletedProgress({'estrellas': 1}), isFalse);
    });

    test('estrellas como String usan la misma regla de tres', () {
      // parseProgressEstrellas acepta String (igual que _createModuleLevelInfoWithProgress)
      expect(isCompletedProgress({'estrellas': '3'}), isTrue);
      expect(isCompletedProgress({'estrellas': '2'}), isFalse);
      expect(isCompletedProgress({'estrellas': '0'}), isFalse);
    });

    test('status distinto y estrellas 0 no es completado', () {
      expect(
        isCompletedProgress({'status': 'in_progress', 'estrellas': 0}),
        isFalse,
      );
      expect(isCompletedProgress({'status': 'blocked'}), isFalse);
      expect(isCompletedProgress(<String, dynamic>{}), isFalse);
    });
  });

  group('countCompletedLevels', () {
    test('cuenta solo los niveles completados', () {
      final progress = <String, Map<String, dynamic>>{
        'lvl1': {'status': 'completed', 'estrellas': 3},
        'lvl2': {'status': 'in_progress', 'estrellas': 3}, // tres modalidades
        'lvl3': {'status': 'in_progress', 'estrellas': 2}, // le falta una
        'lvl4': {'status': 'blocked'}, // no completado
      };

      expect(countCompletedLevels(progress), 2);
    });

    test('mapa vacío → 0', () {
      expect(countCompletedLevels(<String, Map<String, dynamic>>{}), 0);
    });

    test('todos completados', () {
      final progress = <String, Map<String, dynamic>>{
        'a': {'status': 'completed'},
        'b': {'estrellas': 3},
      };

      expect(countCompletedLevels(progress), 2);
    });
  });
}
