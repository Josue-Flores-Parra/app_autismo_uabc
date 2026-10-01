import 'dart:io';

import 'legal_pages.dart';

/// Genera las páginas legales en `docs/legal/`.
///
///     dart run tool/generate_legal_pages.dart
///
/// Hay que volver a correrlo cada vez que cambie `legal_documents.dart`; la
/// prueba `test/legal_pages_test.dart` avisa si las páginas quedaron viejas.
void main() {
  final directory = Directory('docs/legal')..createSync(recursive: true);
  for (final page in buildLegalPages()) {
    File('${directory.path}/${page.fileName}').writeAsStringSync(page.html);
    stdout.writeln('docs/legal/${page.fileName}');
  }
}
