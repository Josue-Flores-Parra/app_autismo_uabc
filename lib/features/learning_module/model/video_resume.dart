/// Dónde se quedó un video al salir de la pantalla completa: la posición del
/// reproductor y el tiempo visto de verdad, para retomarlo sin empezar de cero.
class VideoResume {
  const VideoResume({required this.position, required this.watchedSeconds});

  final Duration position;
  final double watchedSeconds;
}
