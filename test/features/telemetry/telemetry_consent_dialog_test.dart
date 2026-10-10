import 'package:appy/features/telemetry/view/telemetry_consent_dialog.dart';
import 'package:appy/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _spanishBody =
    'Para generar indicadores del desempeño educativo, Appy puede recopilar '
    'metricas seudonimizadas sobre el uso de actividades. Estos datos se asocian '
    'a un identificador de cuenta y no incluyen nombres ni correos electronicos.\n'
    'Esta recopilación es opcional. Puedes rechazarla sin perder acceso a las '
    'actividades y cambiar tu eleccion en cualquier momento desde las configuraciones';

void main() {
  for (final language in ['es', 'en']) {
    for (final size in [
      const Size(320, 568),
      const Size(568, 320),
      const Size(390, 844),
    ]) {
      for (final scale in [1.0, 2.0, 2.3]) {
        for (final accept in [false, true]) {
          testWidgets(
            'Consentimiento $language en $size, escala $scale, acepta $accept',
            (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              bool? decision;
              late AppLocalizations l10n;
              await tester.pumpWidget(
                MaterialApp(
                  locale: Locale(language),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Builder(
                    builder: (context) {
                      l10n = AppLocalizations.of(context);
                      return Scaffold(
                        body: TextButton(
                          onPressed: () async {
                            decision = await showTelemetryConsentDialog(
                              context,
                            );
                          },
                          child: const Text('Abrir'),
                        ),
                      );
                    },
                  ),
                ),
              );
              await tester.tap(find.text('Abrir'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (language == 'es') {
                expect(l10n.telemetryConsentBody, _spanishBody);
              }
              final body = find.text(l10n.telemetryConsentBody);
              expect(body, findsOneWidget);
              final text = tester.widget<Text>(body);
              expect(text.maxLines, isNull);
              expect(text.overflow, isNot(TextOverflow.ellipsis));
              final paragraph = tester.renderObject<RenderParagraph>(body);
              expect(paragraph.didExceedMaxLines, isFalse);

              // Comprueba que el final del mensaje se pueda leer al desplazarlo.
              final scrollable = find.descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(Scrollable),
              );
              if (scrollable.evaluate().isNotEmpty) {
                final state = tester.state<ScrollableState>(scrollable.first);
                state.position.jumpTo(state.position.maxScrollExtent);
                await tester.pumpAndSettle();
                final viewport = tester.getRect(scrollable.first);
                final message = tester.getRect(body);
                expect(message.bottom, lessThanOrEqualTo(viewport.bottom + 1));
                expect(message.bottom, greaterThan(viewport.top));
              }
              final button = find.text(
                accept
                    ? l10n.telemetryConsentAccept
                    : l10n.telemetryConsentDecline,
              );
              expect(button.hitTestable(), findsOneWidget);
              await tester.tap(button);
              await tester.pumpAndSettle();
              expect(decision, accept);
              expect(find.byType(AlertDialog), findsNothing);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
