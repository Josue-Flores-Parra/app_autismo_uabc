import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Columna de controles de video anclada a la derecha: play/pausa, repetir y
/// pantalla completa. Va sobre el video, asi que el contraste del icono se
/// calcula contra el relleno real y no contra el tema.
class VideoControlRail extends StatelessWidget {
  final bool isPlaying;
  final bool isFullscreen;
  final VoidCallback onPlayPause;
  final VoidCallback onReplay;
  final VoidCallback onFullscreen;

  const VideoControlRail({
    super.key,
    required this.isPlaying,
    required this.isFullscreen,
    required this.onPlayPause,
    required this.onReplay,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = Color.alphaBlend(colors.glassFill, Colors.black);
    final iconColor = fill.computeLuminance() > 0.5 ? colors.ink : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.glassFill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RailButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              tooltip: isPlaying ? 'Pausar' : 'Reproducir',
              color: iconColor,
              onPressed: onPlayPause,
            ),
            _RailButton(
              icon: Icons.replay_rounded,
              tooltip: 'Repetir',
              color: iconColor,
              onPressed: onReplay,
            ),
            _RailButton(
              icon: isFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              tooltip: isFullscreen
                  ? 'Salir de pantalla completa'
                  : 'Pantalla completa',
              color: iconColor,
              onPressed: onFullscreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _RailButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      color: color,
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon),
    );
  }
}

/// Icono breve de play/pausa que aparece al tocar el video. Va centrado y con
/// tamano fijo para que no se estire al area completa del reproductor.
class VideoTapFeedback extends StatelessWidget {
  final bool visible;
  final bool isPlaying;

  const VideoTapFeedback({
    super.key,
    required this.visible,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 0.9 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
