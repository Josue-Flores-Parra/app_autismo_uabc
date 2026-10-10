import 'package:appy/features/learning_module/view/preview_card_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeHighlightColor — ARGB exacto', () {
    test('color claro (blanco) se oscurece por el factor 0.85', () {
      const base = Color.fromARGB(255, 255, 255, 255);

      // 255 * 0.85 = 216.75 → round = 217
      expect(
        computeHighlightColor(base),
        const Color.fromARGB(255, 217, 217, 217),
      );
    });

    test('color claro arbitrario se oscurece componente a componente', () {
      // brightness = (255*0.299 + 200*0.587 + 100*0.114)/255 ≈ 0.804 (> 0.5)
      const base = Color.fromARGB(255, 255, 200, 100);

      expect(
        computeHighlightColor(base),
        const Color.fromARGB(
          255,
          217, // (255 * 0.85).round()
          170, // (200 * 0.85).round()
          85, // (100 * 0.85).round()
        ),
      );
    });

    test('color oscuro (negro) se aclara hacia el blanco a la mitad', () {
      const base = Color.fromARGB(255, 0, 0, 0);

      // (0 + (255 - 0) ~/ 2) = 127
      expect(
        computeHighlightColor(base),
        const Color.fromARGB(255, 127, 127, 127),
      );
    });

    test('color oscuro arbitrario se aclara componente a componente', () {
      // brightness = (200*0.299 + 100*0.587 + 50*0.114)/255 ≈ 0.487 (< 0.5)
      const base = Color.fromARGB(255, 200, 100, 50);

      expect(
        computeHighlightColor(base),
        const Color.fromARGB(
          255,
          227, // (200 + (255 - 200) ~/ 2) = 200 + 27
          177, // (100 + (255 - 100) ~/ 2) = 100 + 77
          152, // (50 + (255 - 50) ~/ 2) = 50 + 102
        ),
      );
    });

    test('umbral de brillos: justo por debajo y por encima de 0.5', () {
      // brightness = (r*0.299 + g*0.587 + b*0.114) / 255
      // 128,128,128 → brightness ≈ 0.5019 (> 0.5) → oscurece
      const midLight = Color.fromARGB(255, 128, 128, 128);
      expect(
        computeHighlightColor(midLight),
        const Color.fromARGB(255, 109, 109, 109), // (128 * 0.85).round() = 109
      );

      // 127,127,127 → brightness ≈ 0.498 (< 0.5) → aclara
      const midDark = Color.fromARGB(255, 127, 127, 127);
      expect(
        computeHighlightColor(midDark),
        const Color.fromARGB(
          255,
          191,
          191,
          191,
        ), // (127 + (255-127)~/2) = 127+64
      );
    });
  });
}
