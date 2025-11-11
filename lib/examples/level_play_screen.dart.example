import 'package:flutter/material.dart';
import '../../minigames/minigame_core.dart';
import '../../minigames/view/minigames_widget.dart';

/// Pantalla de juego de nivel
/// Se muestra cuando el usuario presiona "JUGAR" en un nivel del timeline
/// P.D: ESTA PANTALLA ES UN ENTRYPOINT TEMPORAL PARA PROBAR EL
/// WIDGET DEL MINIJUEGO
class LevelPlayScreen extends StatefulWidget {
  final String levelTitle;
  final Map<String, dynamic>? minigameData;

  const LevelPlayScreen({
    super.key,
    required this.levelTitle,
    this.minigameData,
  });

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen> {
  late int _retriesLeft;
  Key _minigameKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _retriesLeft =
        2; // Número de veces que puede reintentar después del primer intento
  }

  /// Reinicia el minigame con opciones mezcladas y intentos reducidos
  void _restartMinigame() {
    if (_retriesLeft > 0) {
      setState(() {
        _retriesLeft--;
        _minigameKey = UniqueKey(); // Esto fuerza la recreación del widget
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MinigamesWidget(
        key: _minigameKey,
        minigameType: MinigameType.simpleSelection,
        minigameData: widget.minigameData ?? _getDefaultMinigameData(),
        onComplete: (success, attempts) {
          _handleMinigameComplete(context, success, attempts);
        },
      ),
    );
  }

  /// Maneja la finalización del minijuego
  void _handleMinigameComplete(
    BuildContext context,
    bool success,
    int attempts,
  ) {
    // Mostrar resultado y navegar de regreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A3D52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x66FFFFFF), width: 1.5),
        ),
        title: Row(
          children: [
            Icon(
              success ? Icons.celebration : Icons.emoji_events_outlined,
              color: success
                  ? const Color(0xFF05E995)
                  : const Color(0xFFFF9800),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? '¡Nivel Completado!' : '¡Buen Intento!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              success
                  ? '¡Excelente trabajo! Has completado el nivel con éxito.'
                  : _retriesLeft > 0
                  ? 'No te preocupes, puedes intentarlo de nuevo.'
                  : 'Has agotado todos tus reintentos.',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2C5F7A), Color(0xFF1A3D52)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33FFFFFF), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  Text(
                    'Intentos: $attempts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (!success && _retriesLeft > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(100, 255, 152, 0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF9800), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Reintentos disponibles: $_retriesLeft',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!success)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Volver al timeline
              },
              child: const Text(
                'Volver',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              if (success) {
                Navigator.of(context).pop(); // Volver al timeline
                // TODO: Actualizar progreso del usuario
                // TODO: Desbloquear siguiente nivel
                // TODO: Dar recompensas (monedas, estrellas, etc.)
              } else {
                // Reintentar: reiniciar el minigame con opciones mezcladas
                if (_retriesLeft > 0) {
                  _restartMinigame();
                } else {
                  // Si no quedan reintentos, volver al timeline
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success
                  ? const Color(0xFF05E995)
                  : (_retriesLeft > 0 ? const Color(0xFFFF9800) : Colors.grey),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              success
                  ? 'Continuar'
                  : (_retriesLeft > 0 ? 'Reintentar' : 'Salir'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Datos por defecto del minijuego para testing
  Map<String, dynamic> _getDefaultMinigameData() {
    return {
      'question': 'Selecciona la imagen correcta',
      'correctIndex': 0,
      'maxAttempts': 3,
      'options': [
        {'imagePath': 'assets/images/FELIZ.png', 'label': 'Opción 1'},
        {'imagePath': 'assets/images/TRISTE.png', 'label': 'Opción 2'},
        {'imagePath': 'assets/images/MEH.png', 'label': 'Opción 3'},
      ],
    };
  }
}
