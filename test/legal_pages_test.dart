import 'dart:io';

import 'package:appy/features/legal/data/legal_documents.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/legal_pages.dart';

void main() {
  test('renders headings, paragraphs, grouped bullets and notes', () {
    const document = LegalDocument(
      title: 'Prueba <1>',
      shortTitle: 'Prueba',
      lastUpdated: 'hoy',
      blocks: [
        LegalBlock.heading('Uno'),
        LegalBlock.paragraph('Texto & más'),
        LegalBlock.bullet('a'),
        LegalBlock.bullet('b'),
        LegalBlock.note('Aviso'),
        LegalBlock.bullet('c'),
      ],
    );

    final html = renderLegalPage(document, lang: 'es', otherPage: 'otra.html');

    expect(html, contains('<html lang="es">'));
    expect(html, contains('<title>Prueba &lt;1&gt; | Appy</title>'));
    expect(html, contains('<h2>Uno</h2>'));
    expect(html, contains('<p>Texto &amp; más</p>'));
    expect(html, contains('<p class="note">Aviso</p>'));
    expect(html, contains('href="otra.html"'));
    expect(RegExp('<ul>').allMatches(html).length, 2);
    expect(RegExp('<li>').allMatches(html).length, 3);
    expect(html, isNot(contains('<1>')));
  });

  test('publishes the four documents and an index', () {
    final names = buildLegalPages().map((page) => page.fileName).toSet();

    expect(names, {
      'index.html',
      'terms-es.html',
      'terms-en.html',
      'privacy-es.html',
      'privacy-en.html',
    });
  });

  test('docs/legal is up to date with the texts of the app', () {
    for (final page in buildLegalPages()) {
      final file = File('docs/legal/${page.fileName}');
      expect(file.existsSync(), isTrue, reason: '${page.fileName} falta');
      expect(
        file.readAsStringSync().replaceAll('\r\n', '\n'),
        page.html,
        reason:
            '${page.fileName} esta viejo: corre '
            '"dart run tool/generate_legal_pages.dart"',
      );
    }
  });

  test('the public address is empty or an https address', () {
    expect(
      kLegalPublicBaseUrl.isEmpty || kLegalPublicBaseUrl.startsWith('https://'),
      isTrue,
    );
  });
}
