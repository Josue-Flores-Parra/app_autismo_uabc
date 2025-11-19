import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../minigames/minigame_core.dart';
import '../../minigames/view/minigames_widget.dart';
import '../../../data/services/firestore_services.dart';
import '../viewmodel/learning_viewmodel.dart';
import '../../avatar/viewmodel/avatar_viewmodel.dart';

/// Pantalla de juego de nivel
/// Se muestra cuando el usuario presiona "JUGAR" en un nivel del timeline
class LevelPlayScreen extends StatefulWidget {
  final String levelTitle;
  final Map<String, dynamic>? minigameData;
  final String? actividadType;
  final String? levelId;
  final String? moduleId;

  const LevelPlayScreen({
    super.key,
    required this.levelTitle,
    this.minigameData,
    this.actividadType,
    this.levelId,
    this.moduleId,
  });

  @override
  State<LevelPlayScreen> createState() => _LevelPlayScreenState();
}

class _LevelPlayScreenState extends State<LevelPlayScreen> {
  late int _retriesLeft;
  Key _minigameKey = UniqueKey();
  final FirestoreService _firestoreService = FirestoreService();

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
    // Convertir actividadType directamente desde Firestore a MinigameType
    MinigameType minigameType;
    if (widget.actividadType != null) {
      switch (widget.actividadType!.toLowerCase().trim()) {
        case 'simple_selection':
          minigameType = MinigameType.simpleSelection;
          break;
        case 'video':
          minigameType = MinigameType.video;
          break;
        // TODO: Agregar más casos cuando se implementen otros tipos
        default:
          minigameType = MinigameType.simpleSelection; // Fallback por defecto
      }
    } else {
      minigameType = MinigameType.simpleSelection; // Fallback por defecto
    }
    
    return Scaffold(
      body: MinigamesWidget(
        key: _minigameKey,
        minigameType: minigameType,
        minigameData: widget.minigameData ?? _getDefaultMinigameData(),
        onComplete: (success, attempts) {
          _handleMinigameComplete(context, success, attempts);
        },
      ),
    );
  }

  /// Calcula las estrellas basado en los intentos
  /// 1 intento = 3 estrellas, 2 intentos = 2 estrellas, 3+ intentos = 1 estrella
  int _calculateStars(int attempts) {
    if (attempts <= 1) return 3;
    if (attempts == 2) return 2;
    return 1;
  }

  /// Calcula las monedas basado en las estrellas obtenidas
  /// 3 estrellas = 30 monedas, 2 estrellas = 20 monedas, 1 estrella = 10 monedas
  int _calculateCoins(int stars) {
    switch (stars) {
      case 3:
        return 30;
      case 2:
        return 20;
      case 1:
        return 10;
      default:
        return 0;
    }
  }

  /// Guarda el progreso del usuario en Firestore y otorga recompensas
  Future<void> _saveProgress(BuildContext context, bool success, int attempts) async {
    if (widget.levelId == null || widget.moduleId == null) {
      return; // No se puede guardar sin levelId y moduleId
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // No hay usuario autenticado
    }

    try {
      final stars = success ? _calculateStars(attempts) : 0;
      
      final progressData = {
        'status': success ? 'completed' : 'in_progress',
        'estrellas': stars,
        'attempts': attempts,
        'completedAt': success ? DateTime.now().toIso8601String() : null,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestoreService.updateUserLevelProgress(
        user.uid,
        widget.moduleId!,
        widget.levelId!,
        progressData,
      );

      // Otorgar monedas si el nivel se completó exitosamente
      if (success && stars > 0 && context.mounted) {
        try {
          final avatarViewModel = context.read<AvatarViewModel>();
          final coins = _calculateCoins(stars);
          await avatarViewModel.agregarMonedas(coins);
        } catch (e) {
          // Error al agregar monedas, pero no bloqueamos la UI
          // Log de error silencioso para no interrumpir la experiencia del usuario
        }
      }

      // Limpiar caché del módulo para forzar recarga
      if (context.mounted) {
        final learningViewModel = context.read<LearningViewModel>();
        await learningViewModel.getModuleLevels(widget.moduleId!, forceReload: true);
      }
    } catch (e) {
      // Error al guardar, pero no bloqueamos la UI
      // Log de error silencioso para no interrumpir la experiencia del usuario
    }
  }

  /// Maneja la finalización del minijuego
  void _handleMinigameComplete(
    BuildContext context,
    bool success,
    int attempts,
  ) async {
    // Guardar progreso si fue exitoso
    if (success) {
      await _saveProgress(context, success, attempts);
    }
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                  if (success) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        Text(
                          'Monedas: +${_calculateCoins(_calculateStars(attempts))}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                // El progreso ya se guardó en _handleMinigameComplete
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

