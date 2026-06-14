# Feature: learning module

## Proposito

El learning module muestra modulos educativos, timeline de niveles, previews de
contenido y actividades interactivas. Es la feature mas grande de la app y
coordina Firestore, assets locales, contenido remoto, minijuegos, video, audio,
progreso, monedas y cache de imagenes.

## Archivos principales

```text
lib/features/learning_module/model/modulo_info.dart
lib/features/learning_module/model/levels_models.dart
lib/features/learning_module/model/content_card_model.dart
lib/features/learning_module/viewmodel/learning_viewmodel.dart
lib/features/learning_module/viewmodel/level_timeline_viewmodel.dart
lib/features/learning_module/view/module_list_screen.dart
lib/features/learning_module/view/level_timeline_screen.dart
lib/features/learning_module/view/level_content_screen.dart
lib/features/learning_module/view/popup_preview.dart
lib/features/learning_module/view/radial_focus_preview_selector.dart
lib/features/learning_module/view/level_play_screen.dart
lib/features/learning_module/view/preview_cards.dart
lib/features/learning_module/data/video_controller_manager.dart
```

Archivos relacionados:

```text
lib/data/services/firestore_services.dart
lib/shared/services/level_completion_service.dart
lib/shared/services/celebration_helper.dart
lib/shared/services/tts_service.dart
lib/features/minigames/
lib/features/avatar/viewmodel/avatar_viewmodel.dart
```

## Flujo conectado actual

```text
MainShell
  -> ModuleListScreen
    -> LearningViewModel.loadModules()
    -> ModuloPlantilla
      -> prefetchModuleLevels() en onTapDown
      -> LevelTimelineScreen
        -> LevelTimelineViewModel
        -> nodos de timeline
        -> popup opcional por nodo
        -> LevelContentPreviewScreen
          -> RadialFocusPreviewSelector
          -> PopupPreview
          -> LevelPlayScreen
            -> MinigamesWidget o _LevelVideoPlayerScreen
            -> LevelCompletionService
              -> FirestoreService.updateUserLevelProgress()
              -> AvatarViewModel.agregarMonedas()
              -> LearningViewModel.getModuleLevels(forceReload: true)
```

El timeline no abre el minijuego inmediatamente. Primero abre una pantalla de
preview con carrusel radial. En esa pantalla el usuario selecciona una tarjeta,
abre un popup de preview y confirma. Solo entonces entra a `LevelPlayScreen`.

## LearningViewModel

Archivo:

```text
lib/features/learning_module/viewmodel/learning_viewmodel.dart
```

Se registra globalmente en `main.dart` y carga modulos desde el constructor.

Estado principal:

| Campo | Getter | Uso |
| --- | --- | --- |
| `_modulos` | `modulos` | Lista de `ModuloInfo` para `ModuleListScreen`. |
| `_isLoadingModules` | `isLoadingModules` | Skeleton de modulos. |
| `_errorMessageModules` | `errorMessageModules` | Error de carga de modulos. |
| `_moduleLevels` | no directo | Cache de niveles por moduleId. |
| `_userProgress` | no directo | Cache de progreso por moduleId. |
| `_isLoadingLevels` | `isLoadingLevels` | Estado de niveles. |
| `_errorMessageLevels` | `errorMessageLevels` | Error de niveles. |
| `_userLevel` | `userLevel` | Nivel global del usuario; default `1`. |
| `_pendingLevelLoads` | no directo | Evita requests duplicados por moduleId. |
| `_imagePins` | no directo | Handles keepAlive para portadas remotas. |

### Carga de modulos

`loadModules()`:

1. Marca loading.
2. Carga en paralelo:
   - `FirestoreService.getAllModules()`.
   - `FirestoreService.getUserLevel(uid)` si hay usuario; si no, `1`.
3. Convierte cada map a `ModuloInfo`.
4. Calcula bloqueo por:
   - `data['bloqueado'] == true`.
   - `userLevel < nivelMinimo`.
5. Llama `_loadModulesProgress()` para sumar estrellas por modulo.

Si Firestore no devuelve modulos, el error visible es:

```text
No se encontraron modulos en Firestore
```

### Progreso de modulos

`_loadModulesProgress()`:

- Lee progreso de todos los modulos en paralelo con `Future.wait`.
- Suma `estrellas` de cada nivel.
- Reconstruye cada `ModuloInfo` con el total.

### Carga de niveles

`getModuleLevels(moduleId, forceReload: false)`:

- Retorna cache si existe y `forceReload == false`.
- Reutiliza `_pendingLevelLoads[moduleId]` si ya hay carga en curso.
- Si no hay cache ni carga pendiente, llama `_fetchModuleLevels`.

`_fetchModuleLevels(moduleId)`:

1. Marca loading de niveles.
2. Carga en paralelo:
   - `FirestoreService.getModuleLevels(moduleId)` ordenado por `orden`.
   - `FirestoreService.getUserLevelsProgress(uid, moduleId)` si hay usuario.
3. Convierte cada map a `ModuleLevelInfo` combinando progreso.
4. Recalcula estados con `_determineLevelStates`.
5. Guarda cache.
6. Guarda progreso en cache.
7. Fija portadas remotas en `ImageCache` con `_pinLevelImages`.

### Estados de niveles

Reglas reales:

- Niveles se ordenan por `orden`.
- Si hay progreso y `status == completed`, el nivel queda `completed`.
- Si hay progreso y `estrellas > 0`, tambien queda `completed`.
- Si hay progreso y `status == in_progress` o `inprogress`, queda `inProgress`.
- Si hay progreso con otro status y sin estrellas, queda `inProgress`.
- Si no hay progreso, el primer nivel queda `inProgress`.
- Si no hay progreso y el nivel anterior esta `completed`, queda `inProgress`.
- Si no hay progreso y el anterior no esta completado, queda `blocked`.

### Cache de imagenes

`_pinLevelImages()` solo fija `pictogramaUrl` remotas (`http/https`) de niveles.
No fija todas las imagenes de actividad para evitar saturar conexiones.

Detalles:

- Usa `PaintingBinding.instance.imageCache.putIfAbsent`.
- Usa `ImageStreamCompleterHandle.keepAlive()`.
- Escalona descargas cada 80 ms.
- Libera handles en:
  - `releasePinsForModule(moduleId)`.
  - `reloadModules()`.
  - `reloadModuleLevels(moduleId)`.
  - `dispose()`.

`LevelTimelineScreen.dispose()` llama `releasePinsForModule`.

## ModuleListScreen

Archivo:

```text
lib/features/learning_module/view/module_list_screen.dart
```

Mecanica:

- Usa `Consumer<LearningViewModel>`.
- Muestra `_ModuleListSkeleton` mientras `isLoadingModules`.
- Muestra error con boton `Reintentar` si `errorMessageModules != null`.
- Lee nombre de usuario directamente desde `FirebaseAuth.instance.currentUser`.
- Usa `displayName`; si no, parte local del email; si no, `Usuario`.
- El nivel mostrado en header esta hardcodeado como `2`; el propio codigo deja
  indicado que deberia obtenerse desde Firestore en el futuro.
- Lee `SettingsViewModel.parentalMinLevel`.
- Pasa modulos a `ModulosGridView`.

`ModulosGridView` reconstruye modulos y agrega bloqueo si:

```text
modulo.bloqueado || modulo.nivel < parentalMinLevel
```

`ModuloPlantilla`:

- En `onTapDown`, si no esta bloqueado, llama `prefetchModuleLevels(modulo.id)`.
- En `onTap`, si no esta bloqueado, navega a `LevelTimelineScreen`.
- Usa `Image.asset(modulo.imagenPath)`.
- Muestra badge `NV <nivel>`.
- Muestra hasta 3 estrellas.

## LevelTimelineScreen

Archivo:

```text
lib/features/learning_module/view/level_timeline_screen.dart
```

`LevelTimelineScreen` crea un `LevelTimelineViewModel` local usando el
`LearningViewModel` global.

`LevelTimelineViewModel`:

- Carga titulo y niveles en paralelo.
- Convierte `ModuleLevelInfo` a `LevelStepInfo`.
- Calcula posiciones alternadas izquierda/derecha para nodos.
- Ignora taps en nodos bloqueados.
- Permite seleccionar/deseleccionar nodos.
- Fusiona `actividadData` con `puzzleImageUrl`, `pictogramaUrl` y `videoUrl`.

La vista:

- Dibuja background de modulo con `Image.asset(backgroundImagePath)` si existe.
- Si el asset falla o no hay background, usa gradiente.
- Dibuja path curvo con `PathPainter`.
- Usa nodos circulares:
  - lock para `blocked`.
  - play para `inProgress`.
  - check para `completed`.
- Anima el nodo `inProgress` con escala 1.0 -> 1.05.
- Dibuja `assets/images/appysittin.png` cerca del nodo activo.
- Muestra boton flotante `JUGAR` para el primer nivel en progreso.
- Al tocar nodo no bloqueado, muestra overlay oscuro y popup con boton `JUGAR`.

## Construccion de contenido

`_buildContentFromLevel(ModuleLevelInfo level)` existe dentro de
`LevelTimelineScreen` y construye tarjetas en este orden:

1. Pictograma si `pictogramaUrl` existe.
2. Video si `videoUrl` existe.
3. Minijuego `simple_selection` si `actividadData.isSimpleSelectionEnabled` es verdadero.
4. Minijuego `puzzle` si `actividadData.isPuzzleEnabled` es verdadero o `actividadType == puzzle`, y hay `puzzleImageUrl` o `pictogramaUrl`.
5. Audio si `audioUrl` existe.
6. Si no hay contenido, agrega una tarjeta pictogram con descripcion "Contenido pendiente de agregar" e imagen vacia.

`isSimpleSelectionEnabled` e `isPuzzleEnabled` aceptan `bool`, numero distinto de
cero o string `true`, `1`, `yes`.

## LevelContentPreviewScreen

Archivo:

```text
lib/features/learning_module/view/level_content_screen.dart
```

Responsabilidades:

- Mostrar header del nivel.
- Mostrar hint "Desliza para explorar".
- Mostrar `RadialFocusPreviewSelector`.
- Resolver que actividad abrir segun la tarjeta seleccionada, no solo segun `actividadType`.
- Preprecargar videos de preview con `VideoControllerManager`.
- Abrir `PopupPreview`.
- Navegar a `LevelPlayScreen` si el usuario confirma en popup.
- Recargar niveles al volver.
- Completar niveles de observacion si corresponde.

### Seleccion de actividad

La actividad seleccionada se deriva asi:

| Tarjeta | `_selectedActivityType` |
| --- | --- |
| `ContentType.video` | `video` |
| `ContentType.pictogram` | `pictogram` |
| `ContentType.audio` | `audio` |
| `ContentType.miniGame` | `miniGameType` |

El label del boton dentro del popup:

- `VER VIDEO` si es video.
- `JUGAR` para los demas.

### Reglas para habilitar launch

- Video: requiere `videoPath`, `widget.videoUrl`, `minigameData.videoUrl` o `minigameData.url`.
- Pictogram/audio: requiere `minigameData != null`.
- Simple selection: requiere `isSimpleSelectionEnabled == true` y `minigameData != null`.
- Puzzle: requiere `puzzleImageUrl` o fallback `pictogramaUrl`.

## RadialFocusPreviewSelector

Archivo:

```text
lib/features/learning_module/view/radial_focus_preview_selector.dart
```

Mecanica:

- Carrusel radial/infinito con indice virtual anclado en `10000`.
- El gesto horizontal controla la rotacion.
- `_dragSensitivity = 0.62`.
- Hace snap al item mas cercano al terminar el gesto.
- Notifica `onIndexChanged` solo cuando cambia el item logico.
- Tocar el nodo enfocado llama `onFocusedNodePressed`.
- Muestra labels `PICTOGRAMA`, `VIDEO`, `AUDIO`, `MINIJUEGO`.
- Usa iconos PNG locales para pictograma, video y simple selection.

## PopupPreview

Archivo:

```text
lib/features/learning_module/view/popup_preview.dart
```

Mecanica:

- Dialog transparente con `BackdropFilter.blur`.
- Cierra con boton X.
- Si el contenido es video y hay `videoPreviewPath`, usa `VideoPreviewCard`.
- Si no es video, usa `BasePreviewCard` con imagen o placeholder.
- Para simple selection usa siempre `assets/imgs/simple_selection_preview.png`.
- Si `canLaunch == false`, deshabilita boton y muestra mensaje.

## LevelPlayScreen

Archivo:

```text
lib/features/learning_module/view/level_play_screen.dart
```

Responsabilidades:

- Resolver `actividadType`.
- Abrir `MinigamesWidget` para minijuegos.
- Abrir reproductor dedicado `_LevelVideoPlayerScreen` para tipo `video`.
- Manejar reintentos globales de minijuego.
- Mostrar dialog de resultado.
- Ejecutar TTS de feedback final.
- Guardar progreso exitoso mediante `LevelCompletionService`.

### Reintentos

`_retriesLeft` inicia en `2`.

Si un minijuego falla:

- Muestra dialog "Buen Intento".
- Si quedan reintentos, boton `Reintentar` recrea el minijuego con nueva key y decrementa `_retriesLeft`.
- Si no quedan, boton sale al timeline.

### TTS

Usa `TtsService.initializeDefaultEsMx()`.

Mensajes:

- Exito: `Nivel completado. Excelente trabajo.`
- Fallo con reintentos: `Buen intento. Puedes intentarlo de nuevo.`
- Fallo sin reintentos: `Buen intento. Has agotado tus reintentos.`

### Video de nivel

Si `actividadType == video`, `LevelPlayScreen` usa `_LevelVideoPlayerScreen`,
no `VideoMinigame`.

Reglas:

- URL tomada de `widget.videoUrl`, `minigameData.videoUrl` o `minigameData.url`.
- Si no hay URL, muestra mensaje "No hay video disponible para este nivel."
- Renderiza video en pantalla negra con top bar y controles.
- Muestra portada `previewImageUrl` hasta el primer tap.
- Marca `_isCompleted = true` cuando el usuario vio 90% o llego al final.
- Muestra boton `COMPLETAR` solo cuando `_isCompleted`.
- Al completar, pausa, hace seek a cero, reproduce celebracion, espera 1.5 s y llama callback de exito.
- Intercepta back para pausar antes de salir.

## LevelCompletionService

Archivo:

```text
lib/shared/services/level_completion_service.dart
```

Guarda progreso y recompensas.

`calculateStars(attempts)`:

| Attempts | Estrellas |
| --- | --- |
| `<= 1` | 3 |
| `== 2` | 2 |
| `> 2` | 1 |

`calculateCoins(stars)`:

| Estrellas | Monedas |
| --- | --- |
| 3 | 30 |
| 2 | 20 |
| 1 | 10 |
| otro | 0 |

`completeInteractiveLevel()`:

- Requiere `moduleId`, `levelId` y usuario autenticado.
- Escribe progreso.
- Si success y monedas > 0, intenta `AvatarViewModel.agregarMonedas`.
- Recarga niveles con `LearningViewModel.getModuleLevels(forceReload: true)`.
- Retorna `LevelCompletionResult` o `null` si falla.

`completeObservationLevel()`:

- Otorga 2 estrellas y 20 monedas.
- Escribe `type: observation`.

## Componentes existentes no principales

| Archivo | Estado |
| --- | --- |
| `viewmodel/module_list_viewmodel.dart` | ViewModel alternativo/legado. `ModuleListScreen` no lo usa. |
| `data/level_repository.dart` | Convierte niveles a steps. No es el camino principal del timeline actual. |
| `view/fullscreen_view.dart` | PageView fullscreen con callbacks. No es el flujo principal de launch actual. |
| `viewmodel/video_player_viewmodel.dart` | Controller propio con looping. El flujo actual usa principalmente `VideoViewModel`. |
| `view/barrel_preview_selector.dart.example` | Archivo de ejemplo. |

## Reglas de mantenimiento

- `modules/{moduleId}/levels` debe tener `orden` para ordenar timeline.
- Si agregas un tipo nuevo de tarjeta, actualiza `ContentType`, `_buildContentFromLevel`, `RadialFocusPreviewSelector`, `PopupPreview` y docs.
- Si agregas minijuego, actualiza `LevelPlayScreen`, `MinigameType`, registros en `main.dart` y docs de minigames.
- Si cambias progreso, actualiza `LevelCompletionService`, `LearningViewModel` y `docs/data-model.md`.
- Si agregas imagen remota masiva, revisar cache/pinning para no saturar conexiones.
