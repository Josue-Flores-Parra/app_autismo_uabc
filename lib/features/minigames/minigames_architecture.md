# Arquitectura del Framework de Minijuegos

## Descripción General
Este framework proporciona un sistema flexible y de bajo acoplamiento para implementar diferentes tipos de actividades interactivas (minijuegos) utilizando el **Patrón Factory**.

## Estructura del modulo

```
lib/features/minigames/
├── minigame_core.dart                           # Abstracciones principales (enum, clase abstracta, factory)
├── minigames_architecture.md                    # Este archivo
└── view/
    ├── minigames_widget.dart                    # Widget principal (usa factory)
    └── types/                                   # Implementaciones individuales de minijuegos
        └── simple_selection_minigame.dart.example  # Ejemplo (no implementado aún)
```

## Componentes Principales

### 1. `minigame_core.dart` - Núcleo del Framework

#### MinigameType (Enum)
- Define todos los tipos de minijuegos disponibles
- Actualmente incluye: `simpleSelection` (no implementado aún - viene en una issue futura)
- Agregar nuevos tipos aquí a medida que se implementen

#### MinigameCompleteCallback (Typedef)
- Función de callback: `void Function(bool success, int attempts)`
- **success**: Indica si el minijuego se completó exitosamente
- **attempts**: Número de intentos que tomó completar el minijuego

#### MinigameBase (Clase Abstracta)
- Todos los minijuegos **deben** extender esta clase
- Garantiza que cada minijuego tenga:
  - Callback `onComplete` requerido
  - Map `minigameData` para configuración y datos del nivel

#### MinigameFactory (Patrón Factory)
- Mantiene un registro de constructores de minijuegos
- Crea instancias de minijuegos sin acoplamiento directo
- Permite que los minijuegos se auto-registren

### 2. `MinigamesWidget` - Widget Principal

- Recibe `minigameType` y `minigameData` como parámetros
- Utiliza el factory para crear el minijuego apropiado
- Muestra un placeholder si el minijuego no está registrado
- **No conoce las implementaciones específicas** - mantiene bajo acoplamiento

## ¿Por Qué Usamos el Patrón Factory?

El patrón factory nos proporciona:

✅ **Bajo Acoplamiento** - `MinigamesWidget` no necesita importar ni conocer implementaciones específicas de minijuegos

✅ **Alta Cohesión** - Cada minijuego es auto-contenido en su propio archivo

✅ **Principio Open/Closed** - Abierto para extensión, cerrado para modificación. Podemos agregar nuevos minijuegos sin modificar código existente

✅ **Auto-Registro** - Cada minijuego gestiona su propio registro con el factory

✅ **Facilita Testing** - Los minijuegos pueden ser probados de forma aislada

✅ **Escalabilidad** - No hay switch statements que crezcan con cada nuevo minijuego

## Cómo Funciona el Sistema

### Flujo de Creación de Minijuegos

1. **Registro** (Durante inicialización de la app):
   ```dart
   void main() {
     // Registrar todos los minijuegos
     registerSimpleSelectionMinigame();
     registerMemoryMatchMinigame();
     // ... más registros
     
     runApp(const MyApp());
   }
   ```

2. **Uso** (Cuando se necesita mostrar un minijuego):
   ```dart
   MinigamesWidget(
     minigameType: MinigameType.simpleSelection,
     minigameData: {
       'level': 1,
       'difficulty': 'easy',
       // O cualquier dato que vaya a llevar el minijuego
     },
     onComplete: (bool success, int attempts) {
       if (success) {
         print('¡Completado en $attempts intentos!'); // log de debug pero aqui iria la logica de interfaz, negocio, etc.
       }
     },
   )
   ```

3. **Resolución** (El factory crea la instancia correcta):
   ```dart
   // MinigamesWidget internamente llama:
   final widget = MinigameFactory.create(
     type: minigameType,
     onComplete: onComplete,
     minigameData: minigameData,
   );
   ```

## Cómo Implementar un Nuevo Minijuego

### Paso 1: Agregar el Tipo al Enum

Editar `minigame_core.dart`:

```dart
enum MinigameType {
  simpleSelection,
  myNewMinigame,  // ← Agregar aquí
}
```

### Paso 2: Crear el Widget del Minijuego

Crear un nuevo archivo en `view/types/` (por ejemplo, `my_new_minigame.dart`):

```dart
import 'package:flutter/material.dart';
import '../../minigame_core.dart';

class MyNewMinigame extends MinigameBase {
  const MyNewMinigame({
    super.key,
    required super.onComplete,
    required super.minigameData,
  });

  @override
  State<MyNewMinigame> createState() => _MyNewMinigameState();
}

class _MyNewMinigameState extends State<MyNewMinigame> {
  int attempts = 0;

  @override
  Widget build(BuildContext context) {
    // Obtener datos del nivel/configuración
    final level = widget.minigameData['level'] ?? 1;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Nuevo Minijuego')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            setState(() => attempts++);
            // Cuando el juego se complete, llamar:
            widget.onComplete(true, attempts);
          },
          child: const Text('Completar'),
        ),
      ),
    );
  }
}

// Función de registro
void registerMyNewMinigame() {
  MinigameFactory.register(
    MinigameType.myNewMinigame,
    ({required onComplete, required minigameData}) => MyNewMinigame(
      onComplete: onComplete,
      minigameData: minigameData,
    ),
  );
}
```

### Paso 3: Registrar el Minijuego

En la inicialización de tu app (por ejemplo, `main.dart`):

```dart
import 'features/minigames/view/types/my_new_minigame.dart';

void main() {
  // Registrar todos los minijuegos
  registerMyNewMinigame();
  
  runApp(const MyApp());
}
```

## Sistema de Niveles

El framework está preparado para soportar un sistema de niveles a través del Map `minigameData`:

```dart
MinigamesWidget(
  minigameType: MinigameType.simpleSelection,
  minigameData: {
    'level': 5,                    // Nivel actual
    'difficulty': 'hard',          // Dificultad
    'customParameter': 'value',    // Cualquier parámetro personalizado
  },
  onComplete: (success, attempts) { ... },
)
```

Cada minijuego puede acceder a estos datos y ajustar su contenido/dificultad según corresponda.

## Ventajas de esta Arquitectura

| Característica | Beneficio |
|----------------|-----------|
| **Sin switch statements** | Agregar minijuegos sin modificar `MinigamesWidget` |
| **Auto-contenido** | Cada minijuego gestiona su propia lógica y registro |
| **Testeable** | Fácil de probar minijuegos de forma aislada |
| **Extensible** | Sigue el principio Open/Closed |
| **Separación de concerns** | Las abstracciones principales están separadas de las implementaciones |
| **Bajo acoplamiento** | Los componentes dependen de abstracciones, no de implementaciones concretas |

## Próximos Pasos

1. Implementar el primer minijuego (`simpleSelection`)
2. Implementar el sistema de niveles
3. Agregar más tipos de minijuegos según se necesiten
4. Integrar con sistema de progreso/analytics

