import 'package:flutter/painting.dart';

// Factor de oscurecimiento aplicado a los colores claros: el destello se
// multiplica por este valor para seguir siendo visible sobre fondos claros.
const double _darkenFactor = 0.85;

// Umbral de brillo (luminancia relativa) por encima del cual se considera que
// el color base es "claro" y el destello debe oscurecerse en lugar de aclararse.
const double _lightenMidpoint = 0.5;

/*
Calcula el color de destello (highlight) para el shimmer de las preview cards.

- Para colores claros (brightness > 0.5) el destello es una versión oscurecida
  del baseColor, de modo que siga siendo visible.
- Para colores oscuros el destello se aclara mezclando el baseColor hacia el
  blanco a la mitad.

El cálculo usa los componentes RGB en 0–255 extraidos de `Color.r/.g/.b`
(doubles 0.0–1.0) en lugar de los accessors `.red`/`.green`/`.blue` (deprecados).
*/
Color computeHighlightColor(Color baseColor) {
  // Componentes RGB en 0–255 (extraidos sin usar los accessors `.red`/`.green`/
  // `.blue`, deprecados en favor de `*.r * 255.0`).
  final r = (baseColor.r * 255.0).round().clamp(0, 255);
  final g = (baseColor.g * 255.0).round().clamp(0, 255);
  final b = (baseColor.b * 255.0).round().clamp(0, 255);

  final brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255;

  if (brightness > _lightenMidpoint) {
    return Color.fromARGB(
      255,
      (r * _darkenFactor).round(),
      (g * _darkenFactor).round(),
      (b * _darkenFactor).round(),
    );
  }

  return Color.fromARGB(
    255,
    (r + (255 - r) ~/ 2).clamp(0, 255),
    (g + (255 - g) ~/ 2).clamp(0, 255),
    (b + (255 - b) ~/ 2).clamp(0, 255),
  );
}
