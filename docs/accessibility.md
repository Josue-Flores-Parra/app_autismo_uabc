# Accesibilidad

Appy esta orientada a una experiencia educativa para personas con autismo. La
app tiene preferencias de accesibilidad configuradas, pero no todas las pantallas
las consumen de forma completa. Esta pagina distingue entre lo implementado y
lo que debe cuidarse al agregar UI.

## Preferencias actuales

`SettingsViewModel` controla:

| Preferencia | Estado actual |
| --- | --- |
| `themeMode` | Conectado a `MaterialApp.themeMode`. |
| `fontScale` | Conectado a `MediaQuery.textScaler` con factores 0.9, 1.0 y 1.15. |
| `locale` | Conectado a `MaterialApp.locale`. |
| `highContrast` | Conectado a `AppTheme.light/dark`. |
| `reduceAnimations` | Conectado a transiciones de pagina en `AppTheme` y a `AnimatedSwitcher` de `MainShell`. |
| `audioFeedback` | Persistido, pero no aplicado globalmente a todos los sonidos. |
| `hapticFeedback` | Persistido, pero no se observa uso global en el codigo actual. |
| `remindersEnabled` | Persistido; permite elegir hora, pero no programa notificaciones reales. |
| `parentalMinLevel` | Conectado a bloqueo visual de modulos en `ModuleListScreen`. |

## Escala de texto

`main.dart` aplica:

```dart
final textScaler = TextScaler.linear(settings.textScaleFactor);
MediaQuery(
  data: mediaQuery.copyWith(textScaler: textScaler),
  child: child ?? const SizedBox.shrink(),
)
```

Factores:

| Opcion | Factor |
| --- | --- |
| Pequeno | `0.9` |
| Medio | `1.0` |
| Grande | `1.15` |

Las pantallas nuevas deben probarse con `large`, especialmente tarjetas,
botones compactos y dialogs.

## Alto contraste

`AppTheme` modifica:

- Seed color.
- `surface`.
- `onSurface`.
- `outline`.
- Elevacion y borde de cards.
- Colores de botones, switches y sliders.

Limitacion real: muchas pantallas usan colores hardcodeados y gradientes propios,
por lo que no todo responde automaticamente a `highContrast`.

## Reducir animaciones

Implementado:

- `AppTheme` reemplaza transiciones de pagina por `NoTransitionsBuilder`.
- `MainShell` usa `Duration.zero` y transicion directa si `reduceAnimations` es true.

No implementado de forma completa:

- `LoginScreen` mantiene `AnimatedSwitcher`.
- `AvatarScreen` mantiene efectos visuales.
- `LevelTimelineScreen` mantiene animacion del nodo activo.
- `RadialFocusPreviewSelector` mantiene snap/animaciones.
- Skeletons y shimmers siguen animando.
- Minijuegos mantienen feedback animado.

Si una nueva pantalla agrega animaciones, debe leer `SettingsViewModel.reduceAnimations`
cuando el usuario pueda quedar expuesto a movimiento repetitivo o no esencial.

## Audio y TTS

Componentes con audio:

| Componente | Audio/TTS |
| --- | --- |
| `SimpleSelectionMinigame` | TTS de pregunta, celebracion y beep negativo. |
| `PictogramMinigame` | TTS de caption y celebracion al completar. |
| `AudioMinigame` | Reproduccion de audio del nivel y celebracion. |
| `_LevelVideoPlayerScreen` | Audio del video y celebracion. |
| `LevelPlayScreen` | TTS de feedback final. |
| `CelebrationHelper` | `assets/audio/celebration.mp3`. |

`SettingsViewModel.audioFeedback` existe, pero estos componentes no lo consultan
de forma global. Si se implementa control real de audio feedback, hay que pasar
esa preferencia a los servicios o consultarla desde contexto.

## Pictogramas y semantica

`PictogramMinigame` envuelve cada item del `PageView` en `Semantics` con:

- Caption del step si existe.
- Fallback `Paso X - <title>`.

Otras pantallas usan muchas imagenes decorativas o educativas sin `Semantics`
explicito. Si se agregan recursos importantes para entender una actividad,
deben tener label semantico o texto equivalente visible.

## PIN y control parental

`MainShell` protege Ajustes con PIN desde bottom nav. Esto sirve como control de
adulto/cuidador, pero el icono de ajustes del `AppBar` en `ModuleListScreen`
abre `SettingsPage` sin pedir PIN. Si el PIN debe ser una barrera real, ese
acceso directo debe revisarse.

`parentalMinLevel` bloquea modulos cuyo `modulo.nivel` es menor que el minimo
configurado. Es bloqueo visual en la lista; no es una regla de seguridad en
Firestore.

## Consideraciones para usuarios con autismo

- Mantener instrucciones cortas, concretas y consistentes.
- Evitar feedback inesperado o sonidos imposibles de detener.
- Permitir repetir instrucciones; los minijuegos con TTS ya tienen boton de escuchar en algunos casos.
- Evitar depender solo de color; agregar icono/texto cuando el estado sea importante.
- Evitar pantallas con muchas animaciones simultaneas.
- Mantener targets tactiles claros.
- Evitar que errores cierren la actividad sin explicacion.

## Checklist por pantalla nueva

- Funciona con `fontScale = large` sin overflow critico.
- No depende solo de color para comunicar bloqueo, exito o error.
- Tiene labels o texto equivalente para imagenes importantes.
- Respeta `reduceAnimations` si contiene movimiento no esencial.
- No reproduce audio automatico sin razon clara.
- Tiene boton para repetir audio/TTS si la actividad depende de audio.
- Maneja assets faltantes con fallback visible.
- Si usa PIN/control parental, no deja rutas alternativas sin documentar.
