import 'package:appy/features/legal/data/legal_documents.dart';

/// Páginas HTML estáticas de los documentos legales, para publicarlas en una
/// URL pública (por ejemplo la que pide Google Play). Salen de los mismos
/// textos que la app (`legal_documents.dart`), así no hay dos versiones.

/// Una página lista para guardar.
class LegalPage {
  const LegalPage(this.fileName, this.html);

  final String fileName;
  final String html;
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

const String _styles = '''
    :root { color-scheme: light dark; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      line-height: 1.6;
      color: #1b2430;
      background: #ffffff;
    }
    main { max-width: 46rem; margin: 0 auto; padding: 1.5rem 1.25rem 3rem; }
    h1 { font-size: 1.6rem; margin: 0 0 0.25rem; }
    h2 { font-size: 1.15rem; margin: 2rem 0 0.5rem; }
    .meta { color: #5b6672; font-size: 0.9rem; margin: 0 0 1.5rem; }
    ul { padding-left: 1.25rem; }
    .note {
      border-left: 3px solid #4a90e2;
      background: #f3f7fd;
      padding: 0.5rem 0.9rem;
      margin: 1rem 0;
    }
    nav { margin-top: 2rem; font-size: 0.95rem; }
    a { color: #2563b8; }
    @media (prefers-color-scheme: dark) {
      body { color: #e6ebf2; background: #121820; }
      .meta { color: #9aa6b4; }
      .note { background: #1b2635; }
      a { color: #7ab2f5; }
    }''';

/// Cuerpo del documento: títulos, párrafos, listas y notas.
String _renderBlocks(LegalDocument document) {
  final out = StringBuffer();
  var inList = false;
  void closeList() {
    if (inList) {
      out.writeln('    </ul>');
      inList = false;
    }
  }

  for (final block in document.blocks) {
    if (block.type == LegalBlockType.bullet) {
      if (!inList) {
        out.writeln('    <ul>');
        inList = true;
      }
      out.writeln('      <li>${_escape(block.text)}</li>');
      continue;
    }
    closeList();
    final text = _escape(block.text);
    switch (block.type) {
      case LegalBlockType.heading:
        out.writeln('    <h2>$text</h2>');
      case LegalBlockType.paragraph:
        out.writeln('    <p>$text</p>');
      case LegalBlockType.note:
        out.writeln('    <p class="note">$text</p>');
      case LegalBlockType.bullet:
        break;
    }
  }
  closeList();
  return out.toString();
}

/// Una página de [document] en el idioma [lang] (`es` o `en`). [otherPage] es
/// el archivo del mismo documento en el otro idioma.
String renderLegalPage(
  LegalDocument document, {
  required String lang,
  required String otherPage,
}) {
  final isSpanish = lang == 'es';
  final versionLabel = isSpanish ? 'Versión' : 'Version';
  final updatedLabel = isSpanish ? 'Última actualización' : 'Last updated';
  final otherLanguage = isSpanish ? 'English' : 'Español';
  final contactLabel = isSpanish ? 'Contacto' : 'Contact';
  return '''<!DOCTYPE html>
<html lang="$lang">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${_escape(document.title)} | Appy</title>
  <style>
$_styles
  </style>
</head>
<body>
  <main>
    <h1>${_escape(document.title)}</h1>
    <p class="meta">$versionLabel $kLegalVersion. $updatedLabel: ${_escape(document.lastUpdated)}.</p>
${_renderBlocks(document)}    <nav>
      <a href="$otherPage" hreflang="${isSpanish ? 'en' : 'es'}">$otherLanguage</a>
      | <a href="index.html">Appy</a>
      | $contactLabel: <a href="mailto:$kLegalContactEmail">$kLegalContactEmail</a>
    </nav>
  </main>
</body>
</html>
''';
}

/// Página de entrada con los cuatro documentos y el soporte.
///
/// `support.html` no se genera: se mantiene a mano en `docs/legal/` porque no
/// depende de los textos versionados de la app.
String renderLegalIndex() {
  return '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Appy TEApoya TEAcompaña | Información y soporte</title>
  <style>
$_styles
  </style>
</head>
<body>
  <main>
    <h1>Appy TEApoya TEAcompaña</h1>
    <p class="meta">Información legal y soporte / Legal information and support.</p>
    <h2>Español</h2>
    <ul>
      <li><a href="terms-es.html">${_escape(termsOfUse('es').title)}</a></li>
      <li><a href="privacy-es.html">${_escape(privacyNotice('es').title)}</a></li>
      <li><a href="support.html#es">Soporte y contacto</a></li>
    </ul>
    <h2>English</h2>
    <ul>
      <li><a href="terms-en.html">${_escape(termsOfUse('en').title)}</a></li>
      <li><a href="privacy-en.html">${_escape(privacyNotice('en').title)}</a></li>
      <li><a href="support.html#en">Support and contact</a></li>
    </ul>
    <p class="meta">© 2026 Universidad Autónoma de Baja California. Derechos sobre el software / Software copyright.</p>
  </main>
</body>
</html>
''';
}

/// Todas las páginas que se publican.
List<LegalPage> buildLegalPages() {
  return [
    LegalPage('index.html', renderLegalIndex()),
    for (final lang in ['es', 'en']) ...[
      LegalPage(
        'terms-$lang.html',
        renderLegalPage(
          termsOfUse(lang),
          lang: lang,
          otherPage: 'terms-${lang == 'es' ? 'en' : 'es'}.html',
        ),
      ),
      LegalPage(
        'privacy-$lang.html',
        renderLegalPage(
          privacyNotice(lang),
          lang: lang,
          otherPage: 'privacy-${lang == 'es' ? 'en' : 'es'}.html',
        ),
      ),
    ],
  ];
}
