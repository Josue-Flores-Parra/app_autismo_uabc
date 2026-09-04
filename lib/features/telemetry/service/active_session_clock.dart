/// Reloj monotónico de segmentos activos para medir `timing.activeDurationMs`.
///
/// Wrapper inyectable sobre un `Stopwatch` para que los tests sean
/// deterministas. Abre/cierra segmentos y devuelve milisegundos acumulados.
class ActiveSessionClock {
  ActiveSessionClock({Stopwatch? stopwatch})
      : _stopwatch = stopwatch ?? Stopwatch();

  final Stopwatch _stopwatch;
  int _accumulatedMs = 0;
  int _segmentCount = 0;

  /// Tiempo activo total = segmentos cerrados + elapsed del segmento activo.
  int get activeMs {
    final total =
        _accumulatedMs + (_stopwatch.isRunning ? _stopwatch.elapsedMilliseconds : 0);
    return total < 0 ? 0 : total;
  }

  /// Número de segmentos monotónicos iniciados.
  int get segmentCount => _segmentCount;

  /// `true` si hay un segmento abierto.
  bool get isRunning => _stopwatch.isRunning;

  /// Abre un nuevo segmento. No-op si ya hay uno corriendo.
  void startSegment() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _segmentCount++;
  }

  /// Cierra el segmento activo y acumula su elapsed.
  ///
  /// Devuelve el total acumulado. No-op si no hay segmento activo.
  int stopSegment() {
    if (!_stopwatch.isRunning) return _accumulatedMs;
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    if (elapsed > 0) {
      _accumulatedMs += elapsed;
    }
    _stopwatch.reset();
    return _accumulatedMs;
  }

  /// Reinicia acumulado y contador de segmentos.
  void reset() {
    _stopwatch
      ..stop()
      ..reset();
    _accumulatedMs = 0;
    _segmentCount = 0;
  }
}