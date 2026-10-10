import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appy/features/minigames/view/types/puzzle_minigame.dart';

void main() {
  testWidgets('PuzzleMinigame renders tray and instruction', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleMinigame(
          onComplete: (_, __) {},
          minigameData: const {
            'maxAttempts': 999,
            'imagePath': 'assets/images/DORMIR.jpg',
          },
        ),
      ),
    );

    expect(find.text('Rompecabezas'), findsOneWidget);
    expect(
      find.text('Arrastra las piezas para completar la imagen.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

    // LoadingScreen escalona sus puntos con Future.delayed; se dejan correr
    // para que no queden timers pendientes al desmontar el arbol.
    await tester.pump(const Duration(seconds: 1));
  });
}
