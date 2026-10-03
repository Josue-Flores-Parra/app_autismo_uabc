import 'package:appy/features/avatar/viewmodel/avatar_viewmodel.dart';
import 'package:appy/shared/services/level_completion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('energia del avatar', () {
    test('recupera un punto por cada periodo de descanso', () {
      final minutos = AvatarViewModel.minutosPorPuntoDeEnergia;

      expect(
        AvatarViewModel.energiaConDescanso(0, Duration(minutes: minutos - 1)),
        0,
      );
      expect(
        AvatarViewModel.energiaConDescanso(0, Duration(minutes: minutos)),
        1,
      );
      expect(
        AvatarViewModel.energiaConDescanso(0, Duration(minutes: minutos * 5)),
        5,
      );
    });

    test('nunca pasa de 100 al descansar', () {
      expect(
        AvatarViewModel.energiaConDescanso(98, const Duration(hours: 5)),
        100,
      );
    });

    test('una actividad nueva no deja la energia en negativo', () {
      expect(AvatarViewModel.aplicarEnergia(100, -4), 96);
      expect(AvatarViewModel.aplicarEnergia(3, -4), 0);
      expect(AvatarViewModel.aplicarEnergia(0, -4), 0);
    });

    test('repasar devuelve energia incluso desde cero', () {
      expect(AvatarViewModel.aplicarEnergia(0, 3), 3);
      expect(AvatarViewModel.aplicarEnergia(99, 3), 100);
    });
  });

  testWidgets('el aviso sin energia explica como recuperarla', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LevelCompletionService.buildEnergyNotice()),
      ),
    );

    final minutos = AvatarViewModel.minutosPorPuntoDeEnergia;
    expect(find.textContaining('sin energía'), findsOneWidget);
    expect(find.textContaining('Repasa una actividad'), findsOneWidget);
    expect(find.textContaining('cada $minutos minutos'), findsOneWidget);
  });
}
