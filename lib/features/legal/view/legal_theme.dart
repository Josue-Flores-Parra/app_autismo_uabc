import 'package:flutter/material.dart';

/// Paleta de las pantallas legales.
///
/// Se aparta del degradado azul oscuro del resto de la app a propósito: un
/// contrato se lee como documento, sobre papel blanco y con tinta negra. Los
/// acentos sí provienen del tema de la app (`AppTheme`), para que no parezca
/// una pantalla de otro producto.
class LegalPalette {
  /// Superficie del documento.
  static const Color paper = Color(0xFFFFFFFF);

  /// Fondo detrás del documento.
  static const Color surface = Color(0xFFF4F5F7);

  /// Texto principal.
  static const Color ink = Color(0xFF16181D);

  /// Texto secundario y notas al pie.
  static const Color inkSoft = Color(0xFF5A626E);

  /// Líneas divisorias.
  static const Color rule = Color(0xFFE2E5EA);

  /// Azul profundo del encabezado de la app.
  static const Color brand = Color(0xFF1A3D52);

  /// Azul de acción, el mismo seed de `AppTheme`.
  static const Color action = Color(0xFF4A90E2);
}
