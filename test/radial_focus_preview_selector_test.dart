import 'package:appy/core/app_theme.dart';
import 'package:appy/features/learning_module/model/content_card_model.dart';
import 'package:appy/features/learning_module/view/radial_focus_preview_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<ContentCardData> _contents() => [
  ContentCardData(type: ContentType.pictogram, title: 'a', imagePath: 'x'),
  ContentCardData(type: ContentType.video, title: 'b', imagePath: 'x'),
  ContentCardData(
    type: ContentType.miniGame,
    title: 'c',
    imagePath: 'x',
    miniGameType: 'puzzle',
  ),
];

Widget _buildApp() {
  return MaterialApp(
    theme: AppTheme.light(fontScale: 1.0),
    home: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(width: double.infinity, height: 60),
            Expanded(child: RadialFocusPreviewSelector(contents: _contents())),
            const SizedBox(height: 120),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the type label under every orb', (tester) async {
    tester.view.physicalSize = const Size(720, 1100);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PICTOGRAMA'), findsOneWidget);
    expect(find.text('VIDEO'), findsOneWidget);
    expect(find.text('MINIJUEGO'), findsOneWidget);
  });

  testWidgets('keeps the orbs centered in the selector', (tester) async {
    tester.view.physicalSize = const Size(720, 1100);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildApp());
    await tester.pump(const Duration(milliseconds: 300));

    final selector = tester.getSize(find.byType(RadialFocusPreviewSelector));
    expect(selector.width, 360);
  });
}
