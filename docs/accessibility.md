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
| `audioFeedback` | Conectado via `FeedbackPreferences` a `TtsService`, `CelebrationHelper` y `NegativeFeedbackHelper`. Apagarlo silencia el dictado de pictogramas y los sonidos de acierto y fallo. |
| `hapticFeedback` | Conectado via `FeedbackPreferences` a `HapticsService`, que vibra al abrir y cerrar elementos y al resolver una actividad. |
| `remindersEnabled` | Persistido; permite elegir hora, pero no programa notificaciones reales. La pantalla lo advierte junto al horario. |
| `parentalAllowedModules` | Conectado a bloqueo visual de modulos en `ModuleListScreen`. |

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

`SettingsViewModel.audioFeedback` llega a estos componentes a traves de
`FeedbackPreferences`, un espejo en memoria que `SettingsViewModel` actualiza al
cargar preferencias y en cada cambio del switch. `TtsService.speak`,
`CelebrationHelper` y `NegativeFeedbackHelper` lo consultan antes de reproducir,
porque son servicios sin `BuildContext` y no pueden leer el provider.

Queda fuera del switch el contenido educativo en si: el audio del video de nivel
y el del `AudioMinigame`, que sin sonido no tendrian actividad que resolver.

## Pictogramas y semantica

`PictogramMinigame` envuelve cada item del `PageView` en `Semantics` con:

- Caption del step si existe.
- Fallback `Paso X - <title>`.

Otras pantallas usan muchas imagenes decorativas o educativas sin `Semantics`
explicito. Si se agregan recursos importantes para entender una actividad,
deben tener label semantico o texto equivalente visible.

## PIN y control parental

`SettingsAccessGuard` protege Ajustes con PIN desde su unico punto de entrada:
el icono del `AppBar` en `ModuleListScreen`. El PIN se guarda por cuenta
(`settingsPin_<uid>`), asi que no se filtra entre usuarios del dispositivo ni
sobrevive a borrar y recrear la cuenta.

`parentalAllowedModules` limita cuantos modulos, en el orden mostrado, puede
abrir el nino. Es bloqueo visual en la lista; no es una regla de seguridad en
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
