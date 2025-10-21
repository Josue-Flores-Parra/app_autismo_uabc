import 'package:flutter/material.dart';

/// Enum que define todos los tipos de minijuegos disponibles
/// Agregar nuevos tipos de minijuegos aquí a medida que se implementen
enum MinigameType {
  simpleSelection, // primer minijuego especificado en el issue #65
  // TODO: Agregar más tipos de minijuegos a medida que se implementen
}

/// Función de callback que se llama cuando un minijuego se completa
/// [success] indica si el minijuego se completó exitosamente
/// [attempts] el número de intentos que tomó completarlo
typedef MinigameCompleteCallback = void Function(bool success, int attempts);

/// Clase abstracta base que todos los minijuegos deben implementar
/// Esto asegura que cada minijuego tenga el callback onComplete requerido
abstract class MinigameBase extends StatefulWidget {
  /// El callback que se llamará cuando el minijuego se complete
  final MinigameCompleteCallback onComplete;

  /// Los datos específicos para esta instancia del minijuego
  final Map<String, dynamic> minigameData;

  const MinigameBase({
    super.key,
    required this.onComplete,
    required this.minigameData,
  });
}

/// Tipo de definición para una función constructora de minijuegos
typedef MinigameBuilder =
    Widget Function({
      required MinigameCompleteCallback onComplete,
      required Map<String, dynamic> minigameData,
    });

/// Clase Factory para crear instancias de minijuegos
/// Esto elimina la necesidad de un switch statement y permite mejor extensibilidad
class MinigameFactory {
  static final Map<MinigameType, MinigameBuilder> _builders = {};

  /// Registrar un constructor de minijuego para un tipo específico
  /// Esto permite que los minijuegos se auto-registren sin modificar el factory
  static void register(MinigameType type, MinigameBuilder builder) {
    _builders[type] = builder;
  }

  /// Crear un widget de minijuego basado en el tipo
  /// Devuelve null si el tipo de minijuego no está registrado
  static Widget? create({
    required MinigameType type,
    required MinigameCompleteCallback onComplete,
    required Map<String, dynamic> minigameData,
  }) {
    final builder = _builders[type];
    if (builder == null) return null;

    return builder(onComplete: onComplete, minigameData: minigameData);
  }

  /// Verificar si un tipo de minijuego está registrado
  static bool isRegistered(MinigameType type) {
    return _builders.containsKey(type);
  }
}
