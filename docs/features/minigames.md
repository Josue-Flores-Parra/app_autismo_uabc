# Feature: minigames

## Proposito

La feature `minigames` provee actividades interactivas reutilizables dentro del
learning module. Cada minijuego se registra en un factory global y se instancia
desde `MinigamesWidget` cuando `LevelPlayScreen` decide que tipo abrir.

## Archivos principales

```text
lib/features/minigames/minigame_core.dart
lib/features/minigames/view/minigames_widget.dart
lib/features/minigames/view/types/simple_selection_minigame.dart
lib/features/minigames/view/types/video_minigame.dart
lib/features/minigames/view/types/pictogram_minigame.dart
lib/features/minigames/view/types/audio_minigame.dart
lib/features/minigames/view/types/puzzle_minigame.dart
```

Servicios usados:

```text
lib/shared/services/tts_service.dart
lib/shared/services/celebration_helper.dart
lib/features/learning_module/viewmodel/audio_viewmodel.dart
lib/features/learning_module/viewmodel/video_viewmodel.dart
```

## Registro

`main.dart` registra todos los minijuegos antes de `runApp`:

```dart
registerSimpleSelectionMinigame();
registerVideoMinigame();
registerPictogramMinigame();
registerAudioMinigame();
registerPuzzleMinigame();
```

Si un tipo no esta registrado, `MinigamesWidget` muestra un placeholder con:

```text
<minigameType.name> - No Implementado
```

## Contrato base

Archivo:

```text
lib/features/minigames/minigame_core.dart
```

`MinigameType` actual:

| Enum | actividadType usado por LevelPlayScreen |
| --- | --- |
| `simpleSelection` | `simple_selection` |
| `video` | `video` solo si se usa `VideoMinigame`; el flujo principal de video usa reproductor dedicado. |
| `pictogram` | `pictogram` |
| `audio` | `audio` |
| `puzzle` | `puzzle` |

`MinigameBase` exige:

```dart
final MinigameCompleteCallback onComplete;
final Map<String, dynamic> minigameData;
```

Callback:

```dart
void Function(bool success, int attempts)
```

`MinigameFactory` mantiene un `Map<MinigameType, MinigameBuilder>` y expone:

- `register(type, builder)`.
- `create(type, onComplete, minigameData)`.
- `isRegistered(type)`.

## Como se abre un minijuego

Flujo actual:

```text
LevelContentPreviewScreen
  -> PopupPreview
  -> LevelPlayScreen
    -> MinigamesWidget
      -> MinigameFactory.create()
```

`LevelPlayScreen` traduce strings a enum:

| String normalizado | Resultado |
| --- | --- |
| `simple_selection` | `MinigameType.simpleSelection`, solo si `isSimpleSelectionEnabled` es true o se lanza desde tarjeta simple selection. |
| `pictogram` | `MinigameType.pictogram` |
| `audio` | `MinigameType.audio` |
| `puzzle` | `MinigameType.puzzle` |
| otro/null/vacio | Pantalla "Actividad no disponible." |

Para `video`, `LevelPlayScreen` usa `_LevelVideoPlayerScreen` y no el
`VideoMinigame` registrado, salvo que otro flujo cree explicitamente
`MinigameType.video`.

## SimpleSelectionMinigame

Archivo:

```text
lib/features/minigames/view/types/simple_selection_minigame.dart
```

Mecanica:

- Prepara preguntas desde `actividadData`.
- Precachea todas las imagenes antes de habilitar interaccion.
- Usa TTS en `es-MX` para leer la pregunta.
- Permite reproducir pregunta con boton de volumen.
- Mezcla opciones en cada pregunta.
- Lleva intentos por pregunta (`_attempts`) e intentos totales (`_totalAttempts`).
- Muestra feedback inline "Correcto" o "Intenta de nuevo".
- En exito reproduce confetti y `assets/audio/celebration.mp3`.
- En fallo reproduce `assets/audio/negative_beeps.mp3`.
- Llama `onComplete(success, _totalAttempts)` despues de 1.5 s.

Prioridad para construir preguntas:

1. Si `steps` o `pictogramSteps` tiene al menos 2 pasos validos, genera exactamente 3 preguntas.
2. Si existe `questions`, usa ese formato y limita a maximo 3 preguntas.
3. Si no, el minijuego usa una pregunta por defecto (`¿Cuál es la imagen correcta?`) con opciones placeholder, evitando un soft-lock.

### steps / pictogramSteps

Acepta:

```json
{
  "maxAttempts": 3,
  "steps": [
    {
      "url": "https://...",
      "caption": "Abrir la llave"
    }
  ]
}
```

Aliases por step:

| Concepto | Keys |
| --- | --- |
| Imagen | `url`, `imagePath`, `src`, `pictogramaUrl` |
| Caption | `caption`, `label`, `text` |

Con `steps`, la pregunta generada usa el prefijo:

```text
Cual es la imagen correcta para el paso...
```

Opciones:

- La opcion correcta es el step objetivo.
- Los distractores salen de otros steps.
- Si hay 4 o mas steps, usa 3 distractores.
- Si hay menos, usa `steps.length - 1` distractores.

### questions

Acepta `List` o `Map`:

```json
{
  "questions": [
    {
      "question": "Selecciona la imagen correcta",
      "correctIndex": 0,
      "maxAttempts": 3,
      "options": [
        {
          "imagePath": "assets/images/FELIZ.png",
          "label": "Feliz"
        }
      ]
    }
  ]
}
```

`options` tambien puede venir como `Map`; el codigo usa `values.toList()`.

Si no hay opciones validas, usa placeholders:

- `assets/images/icon-questionmark.png`.
- `assets/images/icon-questionmark2x.png`.
- `assets/images/icon-salute-hidden.png`.

## PuzzleMinigame

Archivo:

```text
lib/features/minigames/view/types/puzzle_minigame.dart
```

Mecanica:

- Rompecabezas fijo de 5x5 (`_gridSize = 5`), 25 piezas.
- Genera formas tipo jigsaw en runtime con pestañas/encajes.
- Usa `Draggable` y `DragTarget`.
- Tiene bandeja inferior `DraggableScrollableSheet`.
- La bandeja:
  - `minChildSize = 0.14`.
  - `initialChildSize = 0.18`.
  - `maxChildSize = 0.5`.
  - snap entre min y max.
- El tablero se valida solo cuando esta lleno.
- El boton `COMPROBAR` aparece cuando todas las celdas tienen pieza.
- Las piezas correctas se bloquean.
- Las incorrectas muestran feedback rojo, esperan 3 s y vuelven a la bandeja.
- En exito reproduce celebracion, espera 3 s y llama `onComplete(true, attempts)`.
- En maximo de intentos llama `onComplete(false, attempts)`.

Imagen:

Prioridad de keys:

1. `puzzleImageUrl`.
2. `pictogramaUrl`.
3. `imageUrl`.
4. `imagePath`.
5. Si no hay imagen, muestra "Imagen no disponible para este rompecabezas".

`maxAttempts`:

- Acepta `int`, `num` o `String`.
- Default `999`.

## PictogramMinigame

Archivo:

```text
lib/features/minigames/view/types/pictogram_minigame.dart
```

Mecanica:

- Muestra un pictograma unico o secuencia de pasos en `PageView`.
- Precachea imagenes antes de mostrar el contenido.
- Para imagenes remotas descarga a cache local en `getTemporaryDirectory()/pictogram_images`.
- El nombre de archivo cacheado deriva de `url.hashCode`.
- Si falla la descarga, intenta `NetworkImage` como respaldo.
- Usa TTS `es-MX` para leer captions.
- Lee automaticamente el primer caption cuando las imagenes estan listas.
- Tiene boton `Escuchar`.
- Muestra boton `COMPLETAR` solo en la ultima imagen.
- En completar reproduce celebracion, espera 1.5 s y llama `onComplete(true, 1)`.

Keys:

| Key | Uso |
| --- | --- |
| `pictogramaUrl` | Imagen unica si no hay steps. |
| `steps` | Secuencia. |
| `pictogramSteps` | Alias de secuencia. |
| `title` / `titulo` | Titulo. |
| `description` / `descripcion` | Descripcion. |

Formato de step:

```json
{
  "url": "https://...",
  "caption": "Lavarse las manos"
}
```

Tambien acepta step como string URL. En maps, para URL acepta `url` o `src`; para
texto acepta `caption`, `label` o `text`.

## AudioMinigame

Archivo:

```text
lib/features/minigames/view/types/audio_minigame.dart
```

Estado actual de datos:

- El minijuego de audio esta implementado y registrado en la app.
- En el estado actual de Firestore no hay ningun nivel con un recurso de audio
  configurado.
- Por esa razon, el flujo existe en codigo y puede renderizarse si recibe
  `audioUrl`, pero no cuenta con contenido de audio disponible hasta que algun
  documento de nivel incluya una URL remota o asset valido.

Mecanica:

- Crea `AudioViewModel`.
- Carga `minigameData.audioUrl`.
- Si falta audio, muestra error: "No se encontro el archivo de audio en actividadData".
- Si falla carga, muestra error con la ruta.
- Muestra titulo y descripcion desde `title`/`titulo`, `description`/`descripcion`.
- Muestra pictograma si hay `pictogramaUrl`.
- Tiene play/pause, replay, slider de progreso y volumen.
- Solo habilita `COMPLETAR` cuando el audio llego al 100%.
- Si el usuario reinicia al principio, resetea `_audioFinished`.
- En completar reproduce celebracion, espera 1.5 s y llama `onComplete(true, 1)`.

Keys:

| Key | Uso |
| --- | --- |
| `audioUrl` | Requerida. URL remota o asset. |
| `pictogramaUrl` | Imagen opcional. |
| `title` / `titulo` | Titulo. |
| `description` / `descripcion` | Descripcion. |

## VideoMinigame

Archivo:

```text
lib/features/minigames/view/types/video_minigame.dart
```

Estado actual:

- Existe y esta registrado.
- El flujo principal para `actividadType == video` en `LevelPlayScreen` usa un reproductor dedicado (`_LevelVideoPlayerScreen`), no este minijuego.

Mecanica si se instancia:

- Carga `minigameData.videoUrl`.
- Si falta, llama `onComplete(false, 1)` despues del primer frame.
- Usa `VideoViewModel`.
- Reproduce automaticamente al inicializar.
- Desactiva looping.
- Muestra video con overlay play/pause, progress bar, replay y boton `Completar`.
- El timer detecta si se vio 90%, pero el boton `Completar` no esta bloqueado por ese progreso; solo se deshabilita si `_isCompleted`.
- Al completar pausa, hace seek a cero y llama `onComplete(true, 1)`.

## Preview cards y minigames

`LevelContentPreviewScreen` no instancia minijuegos directamente. Primero muestra
tarjetas de contenido:

- Pictograma.
- Video.
- Simple selection.
- Puzzle.
- Audio.

Despues `PopupPreview` confirma. Finalmente `LevelPlayScreen` instancia la
actividad.

`simple_selection` solo se lanza desde tarjeta si `isSimpleSelectionEnabled` es
true. Esto evita abrir seleccion simple solo porque exista data antigua.

## Agregar un minijuego

1. Agrega valor en `MinigameType`.
2. Crea archivo en `lib/features/minigames/view/types/`.
3. Implementa widget que extienda `MinigameBase`.
4. Crea funcion `registerXMinigame()`.
5. Llama esa funcion desde `main.dart` antes de `runApp`.
6. Actualiza `LevelPlayScreen` para traducir `actividadType` al enum.
7. Si aparece en previews, actualiza `ContentType` o `ContentCardData` si hace falta.
8. Actualiza `LevelTimelineScreen._buildContentFromLevel`.
9. Actualiza `RadialFocusPreviewSelector` y `PopupPreview`.
10. Documenta `actividadData`.
11. Agrega test widget basico.

## Reglas de mantenimiento

- Todo minijuego debe llamar `onComplete(success, attempts)` exactamente cuando termina.
- Si el minijuego usa audio/video/TTS, liberar recursos en `dispose`.
- Si acepta URLs remotas y assets, documentar la prioridad de keys.
- Si hay defaults de desarrollo, documentarlos para no confundirlos con schema requerido.
- Si el minijuego otorga progreso, no debe escribir Firestore directamente; dejarlo a `LevelPlayScreen`/`LevelCompletionService`.
