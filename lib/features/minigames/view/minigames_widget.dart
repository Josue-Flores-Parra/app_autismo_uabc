import 'package:flutter/material.dart';
import '../minigame_core.dart';

/// Widget principal que carga y muestra el minijuego apropiado
/// basado en el tipo y datos proporcionados
class MinigamesWidget extends StatelessWidget {
  /// El tipo de minijuego a cargar
  final MinigameType minigameType;

  /// Datos específicos para la instancia del minijuego
  /// Puede incluir nivel, dificultad y otra configuración
  final Map<String, dynamic> minigameData;

  /// Callback cuando el minijuego se completa
  final MinigameCompleteCallback onComplete;

  const MinigamesWidget({
    super.key,
    required this.minigameType,
    required this.minigameData,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    // Usar el factory para crear el widget del minijuego
    final minigameWidget = MinigameFactory.create(
      type: minigameType,
      onComplete: onComplete,
      minigameData: minigameData,
    );

    // Si el minijuego no está registrado, mostrar un placeholder
    return minigameWidget ?? _notImplementedPlaceholder(context);
  }

  /// Placeholder temporal para minijuegos que no han sido implementados aún
  Widget _notImplementedPlaceholder(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(minigameType.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 100, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              '${minigameType.name} - No Implementado',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
