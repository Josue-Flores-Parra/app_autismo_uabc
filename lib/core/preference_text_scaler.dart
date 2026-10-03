import 'package:flutter/painting.dart';

/// Conserva el escalado del sistema y aplica la preferencia adicional de la app.
class PreferenceTextScaler extends TextScaler {
  const PreferenceTextScaler(this.system, this.factor);

  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is PreferenceTextScaler &&
      other.system == system &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}
