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
          -> VideoPlayerScreen (actividadType == video) o LevelPlayScreen (resto)
            -> MinigamesWidget
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
- Si hay progreso y el nivel reunio sus 3 estrellas, queda `completed`.
- Si hay progreso pero le faltan estrellas, queda `inProgress`.
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
- El nivel mostrado en header sale de `completedLevelsCount`, con minimo `1`.
- Lee `SettingsViewModel.parentalAllowedModules`.
- El icono de ajustes del `AppBar` pasa por `SettingsAccessGuard`. Es la unica
  entrada a Ajustes; no hay pestana propia en el bottom nav.
- Pasa modulos a `ModulosGridView`.

`ModulosGridView` reconstruye modulos y agrega bloqueo si:

```text
modulo.bloqueado || (parentalAllowedModules > 0 && indice >= parentalAllowedModules)
```

`ModuloPlantilla`:

- En `onTapDown`, si no esta bloqueado, llama `prefetchModuleLevels(modulo.id)`.
- En `onTap`, si no esta bloqueado, navega a `LevelTimelineScreen`.
- Usa `Image.asset(modulo.imagenPath)`.
- Muestra badge `NV <niveles completados>`.
- Muestra hasta 3 estrellas, calculadas con `moduleStarsForCompletedLevels`:
  3 niveles terminados dan 1 estrella, 6 dan 2 y terminar el modulo da 3.

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
- Si el asset falla o no hay background, usa `colors.backgroundGradient`.
- Encabezado en `GlassPill` opacas (`color: colors.surface`) sobre la ilustracion, con `extendBodyBehindAppBar`; el scroll reserva `padding.top + kToolbarHeight`.
- Dibuja path curvo con `PathPainter`; recibe `baseColor` (`ink` al 40%) y `completedColor` (`success`) desde el tema.
- Usa nodos circulares rellenos con `surface` y borde por estado:
  - lock, borde `surfaceBorder`, icono `inkSoft` para `blocked`.
  - play, borde `accent` para `inProgress`.
  - check, borde `success` para `completed`.
- Estrellas: `0xFFF2B233` ganadas, `surface`/`surfaceBorder` vacias.
- Popup del nodo: tarjeta `surface` con borde `surfaceBorder`, boton `FilledButton` en pastilla.
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

- Mostrar header del nivel en pastillas (`GlassPill`): atras, titulo en `AppFonts.display` y "Desliza para explorar" como piezas separadas.
- Fondo: `colors.backgroundGradient` mas `PuzzleGridBackground`.
- Mostrar `RadialFocusPreviewSelector`.
- Vibrar (`HapticsService.selection`) al abrir la vista previa.
- Pasar `totalActivities` (modalidades reales del nivel) a `LevelPlayScreen`.
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
- Tocar el nodo enfocado llama `onFocusedNodePressed`; tocar un satelite lo trae al frente (`_bringToFront`).
- Muestra labels `PICTOGRAMA`, `VIDEO`, `AUDIO`, `MINIJUEGO`.
- Usa iconos PNG locales para pictograma, video y simple selection.

Disposicion en cruz: todos los nodos son visibles a la vez. El enfocado va al
frente, centrado en `(w/2, h*0.60)` con `focusSize = min(w*0.50, h*0.52)`; los
demas se reparten en el arco superior de 180 grados con
`satelliteSize = focusSize*0.55`. La posicion de cada nodo se interpola por
`(offset + _dragPhase) % length`, asi el arrastre los desplaza de forma
continua. Los colores del anillo y de los labels salen de `context.appColors`.

### PuzzleGridBackground

Archivo:

```text
lib/features/learning_module/view/puzzle_grid_background.dart
```

Fondo decorativo de `LevelContentPreviewScreen`: once rectangulos en patron
"bento" que muestran, a muy baja opacidad (`0.10` claro, `0.14` oscuro), las
imagenes del nivel (`bgLevelImg`, `imagePaths` de las tarjetas, pictograma,
imagen del puzzle, urls de los pasos). Acepta URLs remotas y assets locales.
Cada pieza respira con una senoidal (desplazamiento de 1.2%, escala 2%,
ciclo de 14 s). Envuelto en `IgnorePointer`; `animate: false` cuando
`reduceAnimations` esta activo.

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
- Manejar reintentos globales de minijuego.
- Mostrar dialog de resultado.
- Ejecutar TTS de feedback final.
- Guardar progreso exitoso mediante `LevelCompletionService`.

Los niveles de tipo `video` **no** llegan a `LevelPlayScreen`:
`LevelContentPreviewScreen._openSelectedPreviewFlow` los enruta directo a
`VideoPlayerScreen` (ver seccion "Video de nivel" mas abajo). El `if (type ==
'video')` que existia aqui se elimino junto con la clase interna
`_LevelVideoPlayerScreen`: quedaba inalcanzable y duplicaba el reproductor.

### Reintentos

`_retriesLeft` inicia en `2`.

Si un minijuego falla:

- Muestra dialog "Buen Intento".
- Si quedan reintentos, boton `Reintentar` recrea el minijuego con nueva key y decrementa `_retriesLeft`.
- Si no quedan, boton sale al timeline.

### Telemetría de sesión

`LevelPlayScreen` recibe un `ActivitySessionHandle?` opcional (null si el
consentimiento no está activo). Cuando hay handle:

- `onReady`/`onObjectiveMet` se cablean al `MinigamesWidget`.
- El resultado del run (`success`, `attempts`) se reporta una sola vez al
  servicio, que decide si continúa (`started`), completa o falla.
- `Reintentar` llama `onStartRetryRun()` antes de recrear la UI (conserva la
  misma sesión y acumulados).
- Back con reintentos disponibles → `abandon`; salir tras agotarlos → `failed`.
- `VideoPlayerScreen` recibe el mismo `ActivitySessionHandle?` e instrumenta
  ready, launch_error (sin URL o falla de init), 90% (objetivo), replay
  explícito, `COMPLETAR` y abandono por back.

Detalle completo en `../decisions/telemetry-implementation.md`.

### TTS

Usa `TtsService.initializeDefaultEsMx()`.

Mensajes:

- Exito: `Nivel completado. Excelente trabajo.`
- Fallo con reintentos: `Buen intento. Puedes intentarlo de nuevo.`
- Fallo sin reintentos: `Buen intento. Has agotado tus reintentos.`

### Video de nivel

Archivo:

```text
lib/features/learning_module/view/video_player_screen.dart
```

Pantalla dedicada, separada de `LevelPlayScreen`. Si `actividadType == video`,
`LevelContentPreviewScreen` navega directo a `VideoPlayerScreen` en vez de
`LevelPlayScreen`; los minijuegos siguen yendo por `LevelPlayScreen` /
`MinigamesWidget`.

Reglas:

- URL resuelta en `LevelContentPreviewScreen` desde `widget.videoUrl`,
  `minigameData.videoUrl` o `minigameData.url`. Si ninguna existe, se navega
  igual con `videoUrl: ''`; `VideoPlayerScreen` detecta la cadena vacia y
  muestra "No hay video disponible para este nivel." sin inicializar ningun
  controller, y reporta `onLaunchError` en el primer frame.
- Renderiza video en pantalla negra, en fullscreen (`enterFullscreenMode`/
  `exitFullscreenMode`; fuera de aqui la app es solo vertical). A diferencia
  de otras pantallas, esta **sigue la rotacion fisica del telefono**
  (`enterFullscreenMode(allowPortrait: true)`) en vez de forzar horizontal:
  hay ninos con TEA que no saben girar el telefono para "entrar" al video, asi
  que tiene que verse igual de bien en cualquier orientacion, como en
  cualquier otra app de video. Es una sola pantalla en ambos casos, no dos
  vistas separadas; solo cambia donde caen los controles
  (`MediaQuery.orientationOf(context)` en `build()`):
  - Horizontal: `VideoControlRail`
    (`lib/shared/widgets/video_control_rail.dart`), riel vertical de vidrio a
    la derecha (play/pausa, repetir, salir). El mismo widget lo usan
    `_FullscreenVideoPlayer` en `preview_cards.dart` y `VideoMinigame`.
  - Vertical: controles al pie, en horizontal (`_buildBottomControls`), estilo
    "TikTok": barra de progreso, hora, y botones de repetir/pausa en fila, sin
    tapar el video.

  `enterFullscreenMode(allowPortrait: true)` manda las 4 orientaciones
  (`portraitUp`, `portraitDown`, `landscapeLeft`, `landscapeRight`), no 3.
  Android/Flutter solo reconoce combinaciones especificas de
  `setPreferredOrientations`; una lista de 3 (vertical + las dos horizontales,
  sin la vertical invertida) no es ninguna de esas combinaciones y el motor la
  reduce a la primera orientacion de la lista, dejando el video forzado en vez
  de libre. Con las 4 si es una combinacion reconocida (rotacion libre real).
  El boton de salir no se repite ahi porque la flecha de
    regreso de arriba-izquierda ya esta visible en ambas orientaciones.
- Tocar el video alterna play/pausa y muestra `VideoTapFeedback`, un icono
  breve y de tamano fijo (no el area completa del reproductor).
- Los controles se ocultan con fade a los 3 s (`_kControlsAutoHide`) solo
  mientras reproduce; cualquier toque los vuelve a mostrar. No se ocultan
  mientras `_isCompleted` es `true`.
- La barra de progreso va con `allowScrubbing: true`.
- Marca `_isCompleted = true` la primera vez que el progreso llega al 90% o al
  final; dispara `onObjectiveMet()` una sola vez en ese instante.
- Muestra boton `COMPLETAR` solo cuando `_isCompleted`. Al presionarlo:
  `onComplete()`, pausa, seek a cero, celebracion, espera 1.5 s y
  `LevelCompletionService.showVideoCompletionDialog`.
- Replay explicito dispara `onRecordVideoReplay()` antes de reiniciar.
- Intercepta back (`PopScope`) para pausar y reportar `onAbandon(userBack)`
  antes de salir, salvo que ya se haya completado.

## LevelCompletionService

Archivo:

```text
lib/shared/services/level_completion_service.dart
```

Guarda progreso y recompensas.

Las estrellas del nivel no dependen de los intentos: cada modalidad completada
(pictograma, video y minijuego) vale una estrella y el nivel se cierra al
completarlas todas. Por eso el servicio lee el documento de progreso antes de
escribir, fusiona la modalidad recien jugada en `activities` y recalcula
`estrellas`.

La meta no es siempre 3. `LevelContentPreviewScreen` cuenta las modalidades que
ese nivel realmente ofrece y las pasa como `totalActivities`; el servicio usa
ese numero con tope de 3. Sin esa cuenta, un nivel con solo dos modalidades
nunca podria terminarse y dejaria bloqueado el resto del modulo.

Invariante de UI: `estrellas == 3` significa siempre "nivel terminado". Un nivel
incompleto nunca guarda 3, aunque su meta sea menor.

`calculateCoins(attempts)`, donde `attempts` son equivocaciones y no
selecciones totales:

| Errores | Monedas |
| --- | --- |
| `0` | 30 |
| `1` o `2` | 20 |
| `>= 3` | 10 |

Una actividad de observacion (pictograma o video) paga 10 monedas fijas.

Repasar una modalidad que el nivel ya tenia completada (`alreadyRewarded`)
paga `_repasoCoins` (5 monedas) en vez de 0: repetir tiene que seguir
valiendo la pena, para que repasar un video o un minijuego ya superado no se
sienta como tiempo perdido. Ese mismo repaso, en el avatar, no cansa: la
energia sube en vez de bajar (ver `docs/features/avatar.md`, seccion
"Felicidad y energia").

`completeInteractiveLevel()`:

- Requiere `moduleId`, `levelId`, `actividadType` y usuario autenticado.
- Escribe progreso, incluso al fallar, para que el timeline lo registre.
- La primera vez que se completa una modalidad paga `coinsIfFirstTime`
  completo; repetirla paga `_repasoCoins`. La marca de si ya se habia
  completado vive en `activities.<tipo>.rewarded`.
- Aplica el efecto sobre el avatar con `AvatarViewModel.registrarActividad`
  (felicidad, energia y monedas en un solo guardado; `esRepaso: true` cuando
  la modalidad ya estaba completada). Su resultado (`AvatarActivityDelta`) se
  guarda en `LevelCompletionResult.felicidadDelta`/`energiaDelta`.
- El refresco de cache local (`getModuleLevels(forceReload: true)` +
  `refreshModulesProgress()`) va en su propio try/catch: si falla (ej. hipo de
  red), no se pierde el resultado ya calculado ni las monedas ya guardadas en
  Firestore.
- Retorna `LevelCompletionResult` o `null` si falla.

`completeObservationLevel()`:

- Misma ruta, con `attempts` en 0 y `type: observation`.

`LevelCompletionResult` trae `felicidadDelta`, `energiaDelta` y `esRepaso`
ademas de `coins`, para que la pantalla de resultado muestre el efecto
completo, no solo las monedas. `LevelCompletionService.statsSummary(felicidad,
energia)` da el texto corto ("+5 felicidad · -4 energía") que usan tanto el
dialogo de `LevelPlayScreen` como `showVideoCompletionDialog`.

## Reglas de mantenimiento

- `modules/{moduleId}/levels` debe tener `orden` para ordenar timeline.
- Si agregas un tipo nuevo de tarjeta, actualiza `ContentType`, `_buildContentFromLevel`, `RadialFocusPreviewSelector`, `PopupPreview` y docs.
- Colores de estas pantallas desde `context.appColors`; las unicas excepciones son el negro del reproductor y el dorado `0xFFF2B233` de estrellas y monedas.
- Si agregas minijuego, actualiza `LevelPlayScreen`, `MinigameType`, registros en `main.dart` y docs de minigames.
- Si cambias progreso, actualiza `LevelCompletionService`, `LearningViewModel` y `docs/data-model.md`.
- Si agregas imagen remota masiva, revisar cache/pinning para no saturar conexiones.
