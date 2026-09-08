# Plan técnico de implementación de telemetría de actividades

## 1. Propósito y alcance

Este documento define un plan ejecutable para instrumentar telemetría de sesiones de actividad en Appy sin volver a decidir contratos fundamentales durante la implementación. El diseño se alinea con la arquitectura Flutter/MVVM ligera descrita en `../architecture.md` y `docs/decisions/adr-0001-mvvm-provider-firebase.md`: estado e inyección con `provider`/`ChangeNotifier`, identidad con Firebase Auth y persistencia remota con Cloud Firestore.

La unidad de telemetría será **una sesión por ejecución de una actividad**. Cada sesión tendrá un `sessionId` UUID v4 y se persistirá como un único documento idempotente en:

```text
telemetryActivitySessions/{sessionId}
```

Firestore será la fuente de verdad de sesiones y la única persistencia remota de telemetría en esta etapa. Este plan no incluye Firebase Storage, archivos de exportación, BigQuery, documentos agregados ni Cloud Functions.

## 2. Decisiones cerradas

1. La arquitectura del flujo será:

   ```text
   View -> ActivityTelemetryService -> TelemetryRepository -> Cloud Firestore
   ```

   Las vistas emiten señales semánticas; no construyen mapas de Firestore ni calculan KPI. El servicio mantiene la máquina de estados y el reloj activo. El repositorio serializa y persiste.

2. La colección es raíz para facilitar consultas y futuros dashboards web: `telemetryActivitySessions/{sessionId}`.
3. `sessionId` es un UUID v4 nuevo por cada ejecución. Se agregará una dependencia de generación UUID compatible con el SDK declarado en `../../pubspec.yaml`; no se derivará de UID, nivel, hora ni ruta.
4. La cuenta representa al niño, aunque un padre use su correo para registrarla. Por ello:
   - `subject.learnerId` identifica al niño cuya actividad se mide.
   - `subject.actorId` identifica la cuenta autenticada que ejecuta la acción.
   - En el modelo actual ambos contienen el Firebase Auth UID.
   - `subject.identityModel` vale `account_as_learner`.
   - No se generará un segundo UUID artificial para fingir dos identidades.
5. No se copiarán nombre, correo, `displayName` ni otra PII al documento. Un dashboard resolverá la identidad visible mediante `users/{learnerId}` cuando sus permisos lo permitan.
6. Preview, carrusel, popup y selección de dificultad no son actividad iniciada. Se distingue `launch_requested` de `started`; todos los denominadores de “iniciadas” requieren `outcome.hasStarted == true`.
7. El documento representa el estado actual de la sesión mediante escrituras idempotentes. No se requiere un log de eventos ni una subcolección.
8. Los estados válidos son `launch_requested`, `started`, `completed`, `abandoned`, `failed` y `launch_error`.
9. El tiempo de KPI es `timing.activeDurationMs`, medido con `Stopwatch` monotónico. Los timestamps de servidor se conservan sólo para auditoría y ordenamiento, no para calcular duración activa.
10. Observación/media (`video`, `pictogram`, `audio`) no participa en el KPI de intentos: `interaction.attemptsApplicable == false` e `interaction.attempts == null`.
11. Actividades interactivas (`simple_selection`, `puzzle`) acumulan intentos de todos los runs/reintentos globales de la misma sesión y registran `interaction.runCount`.
12. El progreso de módulo no se reconstruye desde telemetría. Sigue usando `modules/{moduleId}/levels/{levelId}` y `users/{learnerId}/progress/{moduleId}/levels/{levelId}`, contando niveles únicos.

## 3. Semántica de una sesión

### 3.1 Inicio y preparación

El flujo actual inicia en `../../lib/features/learning_module/view/level_content_screen.dart`, donde `_openSelectedPreviewFlow()` muestra `PopupPreview`, opcionalmente muestra `_showPuzzleDifficultyDialog()` y finalmente navega a `LevelPlayScreen`.

La instrumentación debe aplicar estas fronteras:

- Abrir o recorrer `LevelContentPreviewScreen`: no crea sesión.
- Abrir/cerrar `PopupPreview`: no crea sesión.
- Confirmar el botón dinámico `JUGAR`/`VER VIDEO`: emite `launch_requested` y reserva el UUID.
- Elegir/cancelar dificultad de puzzle: todavía no establece `hasStarted`; cancelar puede cerrar la sesión como `launch_error` con razón `launch_cancelled_before_navigation`, o evitar la creación remota si el servicio aún no persistió. La implementación elegida debe conservar la distinción y nunca marcar `started`.
- Entrar a `LevelPlayScreen`: por sí solo no significa `started`.
- Actividad lista para uso: emite `started`, establece `outcome.hasStarted = true` y arranca el `Stopwatch`.

Para evitar sesiones parciales cuando `sendMetrics` cambia durante el flujo, el consentimiento se captura al solicitar el launch. Si no estaba listo/activo en ese instante, no se crea contexto de sesión y señales posteriores se ignoran.

### 3.2 Definición de “actividad lista”

Cada actividad debe exponer una señal explícita `onReady`, consumida una sola vez por `LevelPlayScreen`:

- `simple_selection`: preguntas construidas, recursos imprescindibles precargados y opciones visibles/habilitadas.
- `puzzle`: imagen/configuración resuelta, tablero y bandeja renderizables.
- `pictogram`: imágenes imprescindibles cargadas o fallback utilizable y primera pantalla disponible.
- `audio`: controlador inicializado y controles utilizables; no es necesario haber pulsado play.
- Reproductor dedicado de video `_LevelVideoPlayerScreen`: `VideoViewModel.initializeVideoFuture` termina correctamente y el reproductor/portada están disponibles; no es necesario el primer tap de play.
- `VideoMinigame`, aunque no sea el flujo principal: mismo criterio de controlador inicializado.

Una actividad no disponible, recurso obligatorio faltante, excepción de construcción o fallo de inicialización antes de `onReady` termina como `launch_error`, con `outcome.hasStarted = false`. No entra en denominadores KPI.

### 3.3 Estados y transiciones

```text
launch_requested
  -> started
  -> launch_error

started
  -> completed
  -> abandoned
  -> failed
```

Reglas:

- `launch_requested`: el usuario confirmó el launch y existe un contexto de sesión.
- `started`: la actividad notificó que está lista. `outcome.hasStarted` cambia una sola vez a `true`.
- `completed`: se alcanzó el criterio de finalización de producto y se emitió la señal terminal explícita.
- `abandoned`: el usuario sale explícitamente de una actividad ya iniciada sin completar, o vence la ventana de inactividad.
- `failed`: la actividad llegó a un fallo definitivo. Un run fallido con reintentos disponibles no es terminal.
- `launch_error`: no se pudo llegar a una actividad lista. También cubre actividad no disponible, datos requeridos inválidos y error de navegación/inicialización previo a `started`.

Una sesión terminal (`completed`, `abandoned`, `failed`, `launch_error`) es inmutable. Llamadas terminales repetidas o tardías se convierten en no-op. No se permite `completed -> abandoned`, `failed -> abandoned` ni otra transición posterior.

Razones terminales serán valores controlados, no mensajes libres. Conjunto inicial:

- Abandono: `user_back`, `user_exit`, `route_removed`, `inactivity_timeout`, `stale_session`, `telemetry_opt_out`.
- Fallo: `attempts_exhausted`, `definitive_activity_failure`.
- Error de launch: `activity_unavailable`, `invalid_activity_data`, `resource_initialization_failed`, `navigation_failed`, `launch_cancelled_before_navigation`.

Los detalles técnicos no sensibles de un error se reportarán mediante logging de desarrollo/observabilidad local, pero no se guardarán stack traces, URLs de contenido, mensajes que puedan incluir datos sensibles ni texto libre en telemetría.

### 3.4 Abandono, fallo y reintentos

- Salir mediante back, botón `Volver`, `PopScope`, reemplazo/remoción de ruta o disposición no esperada después de `started` y antes de terminalizar es abandono explícito.
- Salir antes de `started` es `launch_error`, no abandono.
- Cuando `simple_selection` o `puzzle` reporten fallo de un run y queden reintentos globales en `LevelPlayScreen`, la sesión sigue `started`; se suma el intento reportado y no se escribe terminal.
- Al pulsar `Reintentar`, se incrementa `interaction.runCount`; `_minigameKey = UniqueKey()` sólo recrea la UI, no crea otra sesión ni reinicia el acumulado.
- Si se agotan reintentos y el fallo es definitivo, terminaliza como `failed` con `attempts_exhausted`; no se considera abandono.
- Si hay reintentos disponibles pero el usuario elige `Volver`, terminaliza como `abandoned` con `user_exit`.
- Un callback fallido no debe guardar dos veces sus intentos si se reconstruye un diálogo o se recibe dos veces. El servicio debe aceptar un identificador secuencial de run o mantener el run actual ya contabilizado.

### 3.5 Background e interrupciones

`ActivityTelemetryService` observará `WidgetsBindingObserver.didChangeAppLifecycleState` desde un punto global, no desde cada minijuego.

Al pasar a `inactive`, `paused`, `hidden` o `detached` con sesión `started`:

1. Detener inmediatamente el `Stopwatch` y acumular su elapsed en `activeDurationMs`.
2. Marcar `lifecycle.wasInterrupted = true` e incrementar `lifecycle.interruptionCount` una sola vez por transición efectiva a background.
3. Guardar un marcador local mínimo de sesión pendiente y solicitar update idempotente en Firestore.
4. Registrar timestamp de auditoría de background con servidor cuando haya escritura.

Al volver a `resumed`:

- Si la ausencia es menor a 15 minutos, continúa la misma sesión y se reinicia un nuevo segmento del `Stopwatch` cuando la ruta siga activa. La sesión puede terminar `completed`, pero `outcome.navigationSuccessful` permanece `false` porque existió una interrupción.
- Si la ausencia es de 15 minutos o más, la sesión anterior termina `abandoned` con razón `inactivity_timeout` (o `stale_session` si se detecta durante reconciliación). Si el usuario continúa, se crea una sesión nueva con otro UUID y sólo se marca `started` cuando la actividad vuelva a estar lista.
- Los 15 minutos se determinan con tiempo local persistido únicamente para reconciliación de la ventana; no se suman a `activeDurationMs`. Los timestamps de servidor siguen siendo la evidencia auditable.

Una transición breve `inactive` causada por UI del sistema debe deduplicarse con la transición posterior `paused`; no debe incrementar dos veces la interrupción.

### 3.6 Video y media

Para el reproductor dedicado en `../../lib/features/learning_module/view/level_play_screen.dart`:

- Alcanzar 90% o el final sólo emite `objective_met`, establece `outcome.objectiveReached = true` y habilita `COMPLETAR`.
- La sesión sólo termina `completed` cuando el usuario toca `COMPLETAR`.
- `video.replayCount` aumenta exclusivamente al tocar el control explícito de replay que actualmente llama `VideoViewModel.replay()`.
- Play inicial, pausa, resume, scrubbing con `VideoProgressIndicator`, seek interno al completar y volver desde background no cuentan como replay.
- La misma semántica se aplicará a `../../lib/features/minigames/view/types/video_minigame.dart`, aunque el flujo principal use `_LevelVideoPlayerScreen`.

Para audio, pictograma y video, los valores actuales `attempts = 1` enviados por callbacks son una convención de progreso existente, no intentos KPI. Telemetría debe escribir `attemptsApplicable = false` y `attempts = null`.

## 4. Medición del tiempo activo

### 4.1 Fuente de tiempo

El servicio tendrá un acumulador entero y un `Stopwatch` monotónico por sesión:

```text
activeDurationMs = acumulado de segmentos cerrados + elapsed del segmento activo
```

Nunca se calculará restando `Timestamp` de Firestore ni `DateTime.now()`, porque cambios de reloj, latencia y offline distorsionan el KPI.

### 4.2 Intervalos incluidos

El reloj comienza con `started`/`onReady` y corre sólo mientras la actividad está en foreground y aceptando la experiencia principal. Incluye interacción cognitiva normal, visualización/reproducción activa y pausas deliberadas dentro de la actividad mientras la app permanece visible.

### 4.3 Intervalos excluidos

Se excluyen explícitamente:

- preview, carrusel y `PopupPreview` de `../../lib/features/learning_module/view/level_content_screen.dart`;
- selección de dificultad del puzzle;
- carga/preparación anterior a `onReady`;
- tiempo en background/interrupción;
- espera de persistencia Firestore o progreso;
- TTS de feedback terminal;
- celebración/confetti/audio terminal;
- delays terminales (`Future.delayed`) actuales;
- diálogo de resultado de `LevelPlayScreen` y espera para elegir `Continuar`, `Reintentar`, `Volver` o `Salir`.

### 4.4 Señal `objective_met`

Los callbacks actuales incluyen delays: `simple_selection_minigame.dart` espera 1.5 s después de feedback/celebración, `puzzle_minigame.dart` espera celebración, pictograma/audio esperan 1.5 s, y el reproductor dedicado espera 1.5 s antes de `onCompleted`. Por ello no se usará el callback existente como instante de fin del reloj.

Cada actividad debe emitir `onObjectiveMet` inmediatamente al cumplirse el objetivo, antes de celebración, TTS, persistencia y diálogos. El servicio:

1. detiene el reloj;
2. establece `outcome.objectiveReached = true`;
3. conserva la sesión no terminal hasta recibir la decisión de producto correspondiente.

En interactivas, el objetivo exitoso puede terminalizar `completed` de inmediato en la máquina de estados, aunque la UI continúe celebrando. En video, `objective_met` a 90% no terminaliza: el reloj queda detenido para excluir espera/celebración y sólo el tap explícito en `COMPLETAR` marca `completed`. Si después de alcanzar 90% el usuario hace replay antes de completar, se reanuda un segmento activo y `objectiveReached` permanece verdadero; al volver a tocar `COMPLETAR`, se detiene definitivamente.

## 5. Esquema Firestore

### 5.1 Documento canónico

Ruta:

```text
telemetryActivitySessions/{sessionId}
```

No habrá campos `archive`, `archived`, `archiveAt` ni equivalentes.

| Campo | Tipo | Requerido | Semántica |
| --- | --- | --- | --- |
| `schemaVersion` | `int` | Sí | Inicia en `1`; permite evolución compatible. |
| `sessionId` | `string` UUID v4 | Sí | Igual al ID del documento. Facilita resultados de aggregate/query sin depender de metadata del snapshot. |
| `subject` | `map` | Sí | Identidad semántica sin PII. |
| `subject.learnerId` | `string` | Sí | UID de la cuenta que representa al niño. |
| `subject.actorId` | `string` | Sí | UID autenticado que ejecuta. Actualmente igual a `learnerId`. |
| `subject.identityModel` | `string` | Sí | Valor fijo `account_as_learner`. |
| `activity` | `map` | Sí | Identidad y clasificación de la actividad. |
| `activity.activityId` | `string` | Sí | ID transitorio estable `{moduleId}:{levelId}:{activityType}`. |
| `activity.moduleId` | `string` | Sí | ID real de `modules/{moduleId}`. No permitir vacío al solicitar launch. |
| `activity.levelId` | `string` | Sí | ID real de `modules/{moduleId}/levels/{levelId}`. No permitir vacío. |
| `activity.activityType` | `string` | Sí | Normalizado: `simple_selection`, `puzzle`, `video`, `pictogram` o `audio`. |
| `activity.difficulty` | `string?` | No | Clasificación estable si existe; para puzzle puede derivarse del grid elegido, sin texto libre. |
| `activity.gridSize` | `int?` | No | Tamaño elegido para puzzle; ausente en otros tipos. |
| `outcome` | `map` | Sí | Flags derivados y resultado terminal. |
| `outcome.hasStarted` | `bool` | Sí | `true` sólo después de `onReady`; base de todos los denominadores de iniciadas. |
| `outcome.objectiveReached` | `bool` | Sí | Objetivo pedagógico/umbral alcanzado antes de efectos terminales. |
| `outcome.isCompleted` | `bool` | Sí | `true` sólo con estado `completed`. |
| `outcome.navigationSuccessful` | `bool` | Sí | `true` sólo si terminó `completed` y `lifecycle.wasInterrupted == false`. |
| `outcome.terminalReason` | `string?` | Sí | `null` mientras no sea terminal; enum controlado al terminalizar. |
| `timing` | `map` | Sí | Duración monotónica y timestamps de auditoría. |
| `timing.activeDurationMs` | `int` | Sí | Suma de segmentos activos; mínimo 0. |
| `timing.activeSegmentCount` | `int` | Sí | Número de segmentos monotónicos iniciados. |
| `timing.launchRequestedAt` | `Timestamp` | Sí | Timestamp de servidor de primera creación. |
| `timing.startedAt` | `Timestamp?` | Sí | Timestamp de servidor al primer `started`. |
| `timing.objectiveMetAt` | `Timestamp?` | Sí | Timestamp de servidor de primer `objective_met`. |
| `timing.terminalAt` | `Timestamp?` | Sí | Timestamp de servidor de primera transición terminal. |
| `lifecycle` | `map` | Sí | Estado actual e interrupciones. |
| `lifecycle.status` | `string` | Sí | Uno de los seis estados válidos. |
| `lifecycle.wasInterrupted` | `bool` | Sí | Sticky: una vez `true`, no vuelve a `false`. |
| `lifecycle.interruptionCount` | `int` | Sí | Número deduplicado de entradas a background. |
| `lifecycle.lastBackgroundAt` | `Timestamp?` | Sí | Auditoría con timestamp de servidor. |
| `lifecycle.lastResumedAt` | `Timestamp?` | Sí | Auditoría con timestamp de servidor. |
| `interaction` | `map` | Sí | Métricas de actividades interactivas. |
| `interaction.attemptsApplicable` | `bool` | Sí | `true` sólo para `simple_selection` y `puzzle`. |
| `interaction.attempts` | `int?` | Sí | Acumulado de intentos de todos los runs; `null` para observación/media. |
| `interaction.runCount` | `int` | Sí | `1` al iniciar una interactiva; aumenta con cada reintento global. Para no interactivas puede ser `0`. |
| `video` | `map` | Sí | Métricas exclusivas de video, con defaults para esquema uniforme. |
| `video.replayCount` | `int` | Sí | Taps explícitos en replay; `0` para otros tipos. |
| `video.objectiveThreshold` | `double?` | Sí | `0.9` para video; `null` para otros tipos. |
| `client` | `map` | Sí | Contexto técnico no identificable. |
| `client.platform` | `string` | Sí | Valor controlado: `android`, `ios` o `web` en plataformas Firebase soportadas según `../firebase.md`. |
| `client.appVersion` | `string` | Sí | Versión de `PackageInfo`; no contiene PII. |
| `client.buildNumber` | `string` | Sí | Build de `PackageInfo`. |
| `client.locale` | `string` | Sí | Código de idioma activo (`es`/`en`), no locale del sistema completo si no es necesario. |
| `createdAt` | `Timestamp` | Sí | `FieldValue.serverTimestamp()` sólo al crear. Inmutable. |
| `updatedAt` | `Timestamp` | Sí | `FieldValue.serverTimestamp()` en cada escritura aceptada. |

`lifecycle.status` es el estado canónico; no se duplicará como otro campo raíz. Los booleanos de `outcome` se almacenan porque hacen legibles y económicas las aggregate queries, pero el servicio debe derivarlos siempre de la transición, nunca aceptarlos arbitrariamente desde la vista.

### 5.2 Invariantes

- `documentId == sessionId`.
- `subject.actorId == request.auth.uid` y, mientras rija `account_as_learner`, `subject.learnerId == subject.actorId`.
- `activity.activityId == "${moduleId}:${levelId}:${activityType}"` durante esta etapa.
- `outcome.hasStarted == false` para `launch_requested` y `launch_error`.
- `outcome.hasStarted == true` para `started`, `completed`, `abandoned` y `failed`.
- `outcome.isCompleted == (lifecycle.status == completed)`.
- `outcome.navigationSuccessful == (status == completed && wasInterrupted == false)`.
- Estados terminales requieren `timing.terminalAt` y `outcome.terminalReason`.
- `completed` usa una razón controlada como `objective_completed`; `terminalReason` no queda nulo.
- `attemptsApplicable == false` implica `attempts == null`.
- `attemptsApplicable == true` implica `attempts >= 0` y `runCount >= 1` una vez iniciada.
- Contadores y `activeDurationMs` nunca decrecen.
- `actorId`, `learnerId`, `identityModel`, identidad de actividad, `sessionId`, `schemaVersion`, `createdAt` y estado terminal son inmutables.

## 6. Arquitectura y archivos propuestos

Crear la feature bajo `../../lib/features/telemetry`:

```text
lib/features/telemetry/
|-- model/
|   |-- activity_telemetry_session.dart
|   |-- telemetry_enums.dart
|   `-- telemetry_signals.dart
|-- data/
|   `-- telemetry_repository.dart
`-- service/
    |-- activity_telemetry_service.dart
    |-- active_session_clock.dart
    `-- pending_session_store.dart
```

Responsabilidades:

- `activity_telemetry_session.dart`: modelo inmutable, invariantes, `copyWith` y serialización canónica. No contiene dependencias de widgets.
- `telemetry_enums.dart`: estados, razones terminales, tipos normalizados e `identityModel`; evita strings libres en capas superiores.
- `telemetry_signals.dart`: contrato UI-servicio (`requestLaunch`, `activityReady`, `objectiveMet`, `recordAttempts`, `startRetryRun`, `recordVideoReplay`, `complete`, `fail`, `abandon`).
- `telemetry_repository.dart`: recibe `FirebaseFirestore` por constructor, crea/actualiza `telemetryActivitySessions/{sessionId}`, usa timestamps de servidor y propaga errores tipados. No reutiliza `FirestoreService`.
- `activity_telemetry_service.dart`: máquina de estados, UUID, consentimiento, UID, lifecycle, deduplicación terminal y coordinación de persistencia. Será provisto por Provider y no expondrá Firebase a las vistas.
- `active_session_clock.dart`: wrapper inyectable sobre `Stopwatch` para tests deterministas; abre/cierra segmentos y devuelve milisegundos acumulados.
- `pending_session_store.dart`: marcador local mínimo para recuperación offline/proceso muerto. Debe estar namespaced por actor y no guardar PII.

En `../../lib/main.dart`:

- Instanciar `TelemetryRepository` con `FirebaseFirestore` inyectable.
- Registrar `ActivityTelemetryService` mediante `ProxyProvider`/`ChangeNotifierProxyProvider` conectado a `SettingsViewModel` y `AuthViewModel`.
- El servicio no debe evaluar `sendMetrics` hasta que `SettingsViewModel.isReady == true`.
- Registrar/desregistrar el observer global de lifecycle en el ciclo de vida del servicio.
- Reconciliar marcador pendiente sólo después de Firebase, Auth y Settings listos.

Aunque el servicio pueda ser `ChangeNotifier` para facilitar Provider y diagnóstico, las vistas no deben observar cada tick del reloj ni reconstruirse por telemetría; deben usar `context.read<ActivityTelemetryService>()` para emitir señales.

## 7. Puntos exactos de instrumentación

### 7.1 Preview y launch

En `../../lib/features/learning_module/view/level_content_screen.dart`, método `_openSelectedPreviewFlow()`:

1. No instrumentar `_onFocusedNodePressed`, apertura del popup ni cambios de carrusel.
2. Después de `shouldLaunch == true`, y sólo cuando Settings esté listo y `sendMetrics` activo, solicitar un contexto con `requestLaunch` usando `moduleId`, `levelId`, `_selectedActivityType` y datos de dificultad disponibles.
3. Para puzzle, no marcar `started` durante `_showPuzzleDifficultyDialog()`. Si se desea incluir la dificultad en el documento inicial, retrasar la persistencia de `launch_requested` hasta que el usuario elija; si el UUID se reservó antes y cancela, cerrar como `launch_error` sin `hasStarted`.
4. Pasar `sessionId`/handle opaco a `LevelPlayScreen`; no pasar un mapa mutable de telemetría.
5. Si `Navigator.push` falla, terminalizar `launch_error:navigation_failed`.
6. Si no hay consentimiento efectivo al confirmar, navegar normalmente sin handle y sin telemetría.

### 7.2 Coordinación de actividad y resultado

En `../../lib/features/learning_module/view/level_play_screen.dart`:

- Añadir el handle opcional de sesión. Toda la experiencia debe funcionar igual cuando sea `null`.
- Usar `PopScope` a nivel de `LevelPlayScreen` para cubrir minijuegos, no sólo `_LevelVideoPlayerScreen`.
- Emitir abandono antes del pop explícito, salvo que el servicio ya esté terminal.
- Modificar el contrato hacia `MinigamesWidget` para recibir señales `onReady` y `onObjectiveMet`, además del resultado de run.
- En `_handleMinigameComplete`, detener/terminalizar telemetría **antes** de `LevelCompletionService`, `_speakCompletionFeedback`, celebración y `showDialog`.
- Separar “resultado del run” de “resultado terminal de sesión”. El callback actual `bool success, int attempts` puede adaptarse en `LevelPlayScreen`, pero el servicio recibe intentos una sola vez y decide si continúa o termina.
- En `_restartMinigame()`, llamar `startRetryRun()` antes de cambiar `_minigameKey`; conservar el mismo `sessionId` y acumulados.
- En acciones del diálogo:
  - `Continuar` después de éxito no vuelve a terminalizar.
  - `Reintentar` mantiene `started` e incrementa `runCount`.
  - `Volver` con reintentos disponibles abandona.
  - `Salir` tras agotar reintentos ya corresponde a `failed`, no abandono.
- No medir el tiempo de `LevelCompletionService`, TTS ni diálogo de resultado.

### 7.3 Minijuegos

En `../../lib/features/minigames/minigame_core.dart` y `lib/features/minigames/view/minigames_widget.dart`:

- Extender el contrato del factory para señales semánticas opcionales y mantener testabilidad.
- `onReady` y `onObjectiveMet` deben ser callbacks idempotentes.
- No pasar `ActivityTelemetryService` directamente a cada minijuego ni importar Firestore allí.

En `../../lib/features/minigames/view/types/simple_selection_minigame.dart`:

- `onReady` después de `_preloadImages()` y `_loadCurrentQuestion()` cuando la primera pregunta sea utilizable.
- Contar cada selección aceptada como intento, conservando `_totalAttempts` por run.
- Emitir `onObjectiveMet` en `_completeGame(success: true)` antes de `_celebrateCompletion()` y del delay de 1.5 s.
- En fallo emitir resultado del run antes del feedback terminal, sin convertir automáticamente en abandono.

En `../../lib/features/minigames/view/types/puzzle_minigame.dart`:

- `onReady` cuando imagen, `_gridSlots`, bandeja y dificultad estén resueltas.
- Un intento KPI corresponde a cada `_checkPuzzle()` aceptado; el valor `_attempts` del run ya sigue esa regla.
- Emitir `onObjectiveMet` inmediatamente al detectar `incorrectSlots.isEmpty`, antes de `playCelebration()` y `_celebrationDuration`.
- Emitir fallo de run al agotar `_remainingAttempts`, antes del delay de feedback.

En `../../lib/features/minigames/view/types/pictogram_minigame.dart`:

- `onReady` al disponer de la primera imagen/fallback.
- Emitir `onObjectiveMet` al tocar `COMPLETAR` en la última imagen, antes de `_celebrateCompletion()` y del delay.
- `attemptsApplicable` permanece falso aunque el callback de progreso use `1`.

En `../../lib/features/minigames/view/types/audio_minigame.dart`:

- `onReady` al terminar inicialización del audio con controles utilizables.
- Llegar al 100% puede marcar objetivo disponible; la finalización de producto ocurre al tocar `COMPLETAR`.
- Emitir `onObjectiveMet` al tocar `COMPLETAR`, antes de celebración/delay.
- Replay de audio no afecta `video.replayCount` ni el KPI de repeticiones de video.

### 7.4 Reproductores de video

En `_LevelVideoPlayerScreen` dentro de `../../lib/features/learning_module/view/level_play_screen.dart`:

- Emitir `onReady` al completar correctamente `initializeVideoFuture`.
- En `_onVideoUpdate`, al cruzar por primera vez 90%, emitir `onObjectiveMet` y dejar `_isCompleted` únicamente como habilitación del botón.
- En el `GestureDetector` de replay, emitir `recordVideoReplay()` exactamente junto a la llamada explícita `_viewModel.replay()`.
- No instrumentar `togglePlayPause`, `VideoProgressIndicator.allowScrubbing`, `_syncStartedStateFromController` ni el `seekTo(Duration.zero)` interno de completar.
- En `COMPLETAR`, terminalizar telemetría antes de resetear, celebrar y esperar 1.5 s.
- `_pauseAndPop()` abandona sólo si `started` y no terminal.
- Error de `initializeVideoFuture` antes de ready termina `launch_error:resource_initialization_failed`.

En `../../lib/features/minigames/view/types/video_minigame.dart`, aplicar el mismo contrato para evitar métricas distintas si esa ruta registrada comienza a usarse.

### 7.5 Lifecycle, logout y cierre

- `../../lib/main.dart`: observer global y Provider del servicio.
- `../../lib/features/authentication/viewmodel/auth_viewmodel.dart` y/o `lib/data/services/auth_services.dart`: antes de `signOut`, pedir cierre best-effort de una sesión iniciada como `abandoned:user_exit`; debe ocurrir mientras todavía existe UID autorizado. Mantener después la liberación de `VideoControllerManager` documentada en `docs/firebase.md`.
- Cambios de ruta inesperados/dispose: usar la guarda terminal del servicio; `dispose` es respaldo, no la única señal, porque no puede esperarse una escritura async de forma confiable.

## 8. Consentimiento `sendMetrics`

La preferencia existente vive en `SettingsViewModel` (`../../lib/features/settings/viewmodel/settings_viewmodel.dart`) y se carga asíncronamente desde `SharedPreferences`.

Reglas obligatorias:

1. Esperar `SettingsViewModel.isReady`. Antes de ello, el estado efectivo es “deshabilitado/desconocido”; no crear sesión ni bufferizar actividad para enviarla después.
2. Al activar `sendMetrics`, medir sólo actividades cuyo `launch_requested` ocurra después de la activación. No crear una sesión parcial para una actividad ya abierta o iniciada.
3. Al desactivar, impedir inmediatamente nuevos launches y dejar de recolectar nuevos samples.
4. No borrar documentos históricos ya enviados.
5. Descartar payloads todavía no enviados, reintentos en memoria y marcador local pendiente asociado a telemetría, salvo la actualización terminal best-effort descrita abajo.
6. No reanudar una sesión anterior si se vuelve a activar dentro de la misma actividad; la siguiente actividad tendrá un UUID nuevo.

### Decisión segura para una sesión activa al desactivar

Para no dejar indefinidamente un documento `started` que sesgue KPI, la acción de opt-out seguirá este orden coordinado:

1. Congelar la sesión sin tomar nuevas muestras y cerrar el segmento monotónico actual.
2. Intentar **una sola vez**, sin cola ni retry posterior, una actualización mínima con datos ya recolectados: `abandoned`, razón `telemetry_opt_out`, duración acumulada y timestamp de servidor.
3. Independientemente del resultado, marcar consentimiento efectivo como deshabilitado, cancelar futuras escrituras y eliminar payload/marcador local.
4. Si la actualización terminal falla, no conservarla para reenvío: prevalece la revocación del consentimiento. El documento remoto puede quedar no terminal; las consultas operativas podrán identificarlo por antigüedad, pero no se escribirá de nuevo mientras el opt-out siga activo.

`SettingsViewModel.toggleSendMetrics` deberá coordinar esta transición asíncrona con el servicio antes de confirmar el estado efectivo en UI/persistencia, o exponer un controlador de consentimiento que haga ese orden. La UI debe evitar taps concurrentes durante la transición y mostrar un error accionable si falla guardar la preferencia local; el fallo del cierre remoto no debe impedir el opt-out.

## 9. Repositorio, idempotencia y robustez offline

### 9.1 Escrituras

`TelemetryRepository` debe:

- Recibir `FirebaseFirestore` por constructor para poder usar emulator/fakes.
- Crear el documento con ID conocido (`sessionId`), no con `add()`.
- Usar create/set inicial idempotente y updates con precondiciones/transacciones cuando se necesite proteger estado terminal.
- Propagar excepciones con contexto (`sessionId`, operación, estado objetivo) sin incluir PII.
- No reutilizar el patrón de `../../lib/data/services/firestore_services.dart`, que actualmente captura errores y retorna defaults o silencia `updateUserLevelProgress`.
- Clasificar errores recuperables (offline/timeout) y permanentes (permission-denied/invalid-argument).

El servicio serializará mutaciones por sesión para impedir carreras entre objective, back, lifecycle y callbacks retrasados. Mantendrá un `Future`/mutex lógico por `sessionId` y una bandera terminal local. La escritura terminal deberá verificar el estado remoto cuando haya riesgo de dos clientes/callbacks y no sobreescribir una terminal existente.

### 9.2 Marcador pendiente y reconciliación

`PendingSessionStore` guardará localmente lo mínimo necesario para reconciliar una sesión iniciada si el proceso muere:

- `sessionId`, UID actor, identidad de actividad y último estado no terminal;
- `activeDurationMs` ya cerrado, contadores, flags de interrupción;
- instante local de background/última persistencia para evaluar 15 minutos;
- versión del esquema.

No guardará nombre, correo, URLs de contenido ni stack traces.

Al arranque, después de Auth y Settings listos:

- Sin opt-in: borrar marcador local sin escribir remoto.
- UID distinto al actor del marcador: no intentar escribir con otra identidad; borrar marcador y registrar diagnóstico local.
- Sesión ya terminal en Firestore: limpiar marcador.
- Ausencia menor a 15 minutos y el flujo/ruta puede restaurar la actividad: continuar la misma sesión sólo si se puede garantizar el mismo contexto; en caso contrario abandonarla como `stale_session`.
- Ausencia de 15 minutos o más: actualizar idempotentemente a `abandoned:stale_session` con la duración ya acumulada.
- Error recuperable y opt-in vigente: conservar marcador con backoff acotado.
- Error permanente: reportar y limpiar el marcador para evitar loop infinito.

Firestore SDK ya ofrece caché/cola offline, pero el marcador sigue siendo necesario para detectar proceso muerto y decidir terminalidad. No debe asumirse que una escritura local aceptada por el SDK ya fue confirmada por servidor; el repositorio debe exponer estado de operación suficiente para diagnóstico.

### 9.3 Errores visibles y logging

La telemetría no debe romper ni bloquear la actividad educativa. Sin embargo, los errores tampoco serán silenciosos:

- logging estructurado en debug/test;
- estado de salud consultable en `ActivityTelemetryService` para tests y soporte;
- captura explícita de última operación fallida sin PII;
- opción de mostrar aviso no intrusivo sólo si producto lo decide, nunca un diálogo que interrumpa al niño;
- tests que demuestren que la experiencia continúa cuando Firestore falla.

## 10. KPI y consultas iniciales

Todas las consultas usarán documentos de `telemetryActivitySessions`. El dashboard inicial ejecutará aggregate queries `count`, `sum` y `average` compatibles con Firestore; no habrá documentos agregados ni Cloud Functions.

Definiciones canónicas para un rango temporal y filtros de dashboard dados:

1. **Promedio de tiempo**

   ```text
   sum(timing.activeDurationMs donde lifecycle.status == completed)
   / count(donde lifecycle.status == completed)
   ```

   Equivale a `average(timing.activeDurationMs)` sobre completadas. Si el count es 0, mostrar N/D, no 0 ms.

2. **Repeticiones de video por actividad iniciada**

   ```text
   sum(video.replayCount donde outcome.hasStarted == true)
   / count(donde outcome.hasStarted == true)
   ```

   El denominador incluye todas las actividades iniciadas de todos los tipos; no se filtra a video. Tipos no video aportan `video.replayCount = 0`.

3. **Tasa de abandono**

   ```text
   count(donde lifecycle.status == abandoned)
   / count(donde outcome.hasStarted == true)
   ```

4. **Navegación exitosa**

   ```text
   count(donde lifecycle.status == completed y lifecycle.wasInterrupted == false)
   / count(donde outcome.hasStarted == true)
   ```

   Una sesión interrumpida que luego completa cuenta en finalización, pero no en navegación exitosa.

5. **Tasa de finalización**

   ```text
   count(donde lifecycle.status == completed)
   / count(donde outcome.hasStarted == true)
   ```

6. **Intentos promedio**

   ```text
   sum(interaction.attempts donde lifecycle.status == completed
       y interaction.attemptsApplicable == true)
   / count(donde lifecycle.status == completed
           y interaction.attemptsApplicable == true)
   ```

   Sólo incluye `simple_selection` y `puzzle` completadas. Los intentos se acumulan entre reintentos globales/runs de la sesión.

7. **Progreso de módulo**

   No se consulta en telemetría. Para `learnerId` y módulo:
   - obtener niveles definidos de `modules/{moduleId}/levels`;
   - obtener progreso de `users/{learnerId}/progress/{moduleId}/levels`;
   - contar `levelId` únicos cuyo progreso cumpla la regla existente (`status == completed` o `estrellas > 0`, conforme a `../data-model.md`);
   - dividir entre niveles únicos definidos cuando se requiera porcentaje.

Filtros temporales deben usar `createdAt` o `timing.startedAt` según la pantalla. Para KPI de iniciadas se recomienda `timing.startedAt`; nunca incluir `launch_requested`/`launch_error` por accidente. El dashboard debe tratar denominador 0 como N/D.

## 11. Índices probables

Los índices definitivos se crearán a partir de las consultas exactas del dashboard y errores de índice de Firestore. Preparar inicialmente índices compuestos para combinaciones frecuentes:

- `outcome.hasStarted ASC, timing.startedAt DESC`;
- `lifecycle.status ASC, timing.startedAt DESC`;
- `lifecycle.status ASC, lifecycle.wasInterrupted ASC, timing.startedAt DESC`;
- `interaction.attemptsApplicable ASC, lifecycle.status ASC, timing.startedAt DESC`;
- `subject.learnerId ASC, timing.startedAt DESC`;
- `subject.learnerId ASC, activity.moduleId ASC, timing.startedAt DESC`;
- `activity.moduleId ASC, activity.levelId ASC, timing.startedAt DESC`;
- `activity.activityType ASC, outcome.hasStarted ASC, timing.startedAt DESC`;
- si el dashboard combina identidad, módulo y estado: `subject.learnerId ASC, activity.moduleId ASC, lifecycle.status ASC, timing.startedAt DESC`.

Agregar `../../firestore.indexes.json` como artefacto de implementación sólo cuando las consultas estén fijadas y desplegarlo con Firebase CLI. No crear índices redundantes “por si acaso”; las agregaciones sobre filtros iguales reutilizan los mismos índices y cada índice aumenta costo de escritura/almacenamiento.

## 12. Seguridad Firestore

Crear y versionar `firestore.rules` durante la fase correspondiente; actualmente no existe en el repositorio.

Reglas mínimas del cliente móvil:

- Requerir `request.auth != null`.
- En create, exigir `subject.actorId == request.auth.uid`.
- Mientras `identityModel == account_as_learner`, exigir también `subject.learnerId == request.auth.uid`.
- Validar UUID/document ID, `schemaVersion`, tipos, estados y límites no negativos.
- Impedir cualquier cambio de `subject.actorId`, `subject.learnerId`, `identityModel`, `sessionId`, `activity.*`, `createdAt` y `schemaVersion`.
- Permitir update sólo si el documento existente pertenece al actor autenticado.
- Rechazar updates cuando `resource.data.lifecycle.status` ya sea terminal.
- Permitir sólo transiciones declaradas (`launch_requested -> started|launch_error`; `started -> completed|abandoned|failed`; updates no terminales de contadores/lifecycle que mantengan `started`).
- Exigir que contadores y duración no decrezcan y que flags sticky no vuelvan a falso.
- Validar coherencia de `outcome` con estado/interrupción.
- No permitir delete desde móvil; desactivar telemetría no borra histórico.
- Lectura móvil: limitar a documentos propios sólo si la app realmente necesita reconciliación; de lo contrario, permitir únicamente el get puntual propio necesario y negar listados amplios.

El dashboard futuro no debe autenticarse como cliente móvil común para leer toda la colección. Usará custom claims verificadas por reglas o un backend privilegiado. El acceso a `users/{learnerId}` para resolver nombre visible será exclusivo de ese rol/backend y no causará copia de PII a telemetría.

Probar reglas con Firebase Emulator Suite: create propio, create ajeno, mutación de actor, mutación terminal, decremento de contadores, transición inválida, delete y lectura de otro usuario.

## 13. Plan de implementación por fases

### Fase 1 — Contratos y modelos

1. Agregar dependencia UUID en `../../pubspec.yaml` y fijar generación UUID v4.
2. Crear enums, modelo y señales bajo `../../lib/features/telemetry/model`.
3. Implementar validación de IDs no vacíos y `activityId` transitorio.
4. Definir serialización exacta del esquema v1, defaults uniformes y timestamps como instrucciones de repositorio.
5. Implementar `ActiveSessionClock` inyectable.
6. Añadir tests puros de invariantes, transiciones y reloj.

Salida verificable: modelos no dependen de Flutter UI/Firestore salvo tipos aislados en la capa de serialización; todos los estados/razones son exhaustivos.

### Fase 2 — Repositorio Firestore

1. Crear `TelemetryRepository` con `FirebaseFirestore` por constructor.
2. Implementar create idempotente y update serializado con protección de terminalidad.
3. Implementar lectura puntual para reconciliación.
4. Aplicar `FieldValue.serverTimestamp()` a auditoría.
5. Clasificar y propagar errores; no copiar manejo silencioso de `FirestoreService`.
6. Probar contra Firestore Emulator o fake que preserve semántica de merge/transacción.

Salida verificable: dos creates del mismo UUID no duplican documentos y dos terminalizaciones concurrentes dejan exactamente un estado terminal.

### Fase 3 — Servicio y máquina de estados

1. Crear `ActivityTelemetryService` y `PendingSessionStore`.
2. Integrar Auth, `SettingsViewModel.isReady/sendMetrics` y Provider en `../../lib/main.dart`.
3. Implementar estado efectivo de consentimiento y transición segura de opt-out.
4. Implementar lifecycle, ventana de 15 minutos, segmentos monotónicos y deduplicación.
5. Implementar acumulación de intentos/runs, replay explícito y objetivo.
6. Añadir logging/estado de salud sin PII.

Salida verificable: el servicio puede probarse con reloj, repositorio, preferencias y UID falsos sin montar minijuegos.

### Fase 4 — Instrumentación de actividades

1. Instrumentar launch en `level_content_screen.dart`.
2. Instrumentar coordinación, back, retries y resultado en `level_play_screen.dart`.
3. Extender contratos en `minigame_core.dart` y `minigames_widget.dart`.
4. Añadir `onReady`/`onObjectiveMet` en simple selection, puzzle, pictograma, audio y ambas rutas de video.
5. Instrumentar replay sólo en botones explícitos.
6. Verificar que `LevelCompletionService` y sus escrituras de progreso mantienen comportamiento independiente.

Salida verificable: cada tipo genera una sesión completa con fronteras temporales correctas, y la app funciona igual con telemetría deshabilitada.

### Fase 5 — Lifecycle y reconciliación

1. Integrar observer global y señales de ruta/dispose.
2. Cerrar sesión antes de logout mientras el UID sigue autenticado.
3. Persistir marcador mínimo al pausar y en mutaciones relevantes.
4. Reconciliar arranque, proceso muerto, UID distinto y timeout.
5. Probar offline, retorno antes/después de 15 minutos y escrituras pendientes.

Salida verificable: no se suma background a tiempo activo; no hay doble interrupción; sesiones stale terminan una sola vez.

### Fase 6 — Reglas e índices

1. Crear reglas de seguridad y pruebas emulator.
2. Implementar consultas KPI de referencia contra fixtures.
3. Capturar índices requeridos en `../../firestore.indexes.json`.
4. Validar aggregates con rangos temporales y filtros reales.
5. Documentar despliegue y rollback de reglas/índices.

Salida verificable: un usuario sólo crea/actualiza sesiones propias válidas y no puede mutar terminales.

### Fase 7 — Preparación de dashboard y documentación

1. Entregar una especificación de consultas para los siete KPI.
2. Documentar resolución visible desde `users/{learnerId}` y rol futuro del dashboard.
3. Actualizar, al implementar, `../architecture.md`, `docs/data-model.md`, `docs/firebase.md`, `docs/features/learning-module.md`, `docs/features/minigames.md` y `docs/features/settings.md`.
4. Agregar diccionario de estados/razones y ejemplos sanitizados.
5. Validar que no existan PII, campos archive ni dependencias/planes de Storage, exportación o BigQuery.

Salida verificable: otro consumidor puede construir dashboard sólo con el contrato y las consultas documentadas.

## 14. Estrategia de pruebas

### 14.1 Unitarias

Ubicación sugerida: `../../test/features/telemetry`.

- Máquina de estados: todas las transiciones válidas e inválidas; terminalidad idempotente.
- Reloj: múltiples segmentos, pausa/background, objective antes de delay, nunca duración negativa.
- Timeout: 14:59 continúa; 15:00 terminaliza anterior y una continuación usa nuevo UUID.
- Consentimiento: Settings no listo, activación a mitad, desactivación activa, fallo del cierre best-effort y descarte de payload.
- Identidad: learner/actor iguales bajo `account_as_learner`, sin UUID adicional.
- Intentos: suma entre runs, callback duplicado no suma dos veces, media produce null.
- Video: replay explícito suma; pause/resume/scrub/seek no suma; 90% sólo objective.
- Serialización: esquema v1 completo, sin PII ni campos archive.
- Reconciliación: documento terminal, marker stale, UID distinto, offline recuperable y permission-denied.
- Cálculos KPI sobre fixtures, incluyendo denominador cero.

### 14.2 Widget

- `LevelContentPreviewScreen`: preview/cancel no inicia; confirmación genera launch; dificultad no marca started.
- `LevelPlayScreen`: unavailable produce launch_error; `onReady` inicia; back abandona; callback tras terminal no cambia estado.
- Simple selection/puzzle: señal objective ocurre antes del delay/celebración; retry conserva sesión y aumenta run.
- Video dedicado: 90% habilita botón sin completar; `COMPLETAR` completa; sólo botón replay incrementa.
- Settings: esperar `isReady`, activar sólo próxima actividad, opt-out bloquea nuevas sesiones y no borra histórico.
- Fallo del repositorio: UI educativa sigue utilizable y el error queda observable, no silencioso.

### 14.3 Integración/emulator

- Flujo completo por cada `activityType` con Firebase Auth y Firestore Emulator.
- Reglas: actor propio/ajeno, campos inmutables, terminal inmutable y no delete.
- Offline durante started/terminal, reconexión e idempotencia por UUID.
- Cierre forzado de proceso y reconciliación.
- Background/resume antes y después de 15 minutos.
- Aggregate queries para cada KPI con dataset conocido.
- Logout con sesión activa y cambio de cuenta.

## 15. Criterios de aceptación verificables

### Contrato general

- Cada ejecución instrumentada crea como máximo un documento cuyo ID es UUID v4.
- No existe nombre, correo, URL de recurso, stack trace ni otro dato PII en telemetría.
- `subject.learnerId` y `subject.actorId` son campos separados, iguales al UID actual, con `identityModel = account_as_learner`.
- Ningún documento/código de esquema incluye campos archive.
- Preview y dificultad nunca producen `outcome.hasStarted = true`.
- Sesiones terminales no cambian ante callbacks, lifecycle o retries posteriores.

### Opt-in/opt-out

- Con `sendMetrics == false` o Settings no listo no se crea documento ni payload pendiente.
- Activar durante una actividad ya abierta no crea sesión para ella; la siguiente sí.
- Desactivar no elimina histórico, impide launches posteriores y no inicia sesiones parciales.
- La sesión activa intenta una única terminalización `telemetry_opt_out`; tras ello no se reintenta ni conserva payload.
- Reactivar no recupera la actividad en curso; sólo mide una nueva ejecución.

### KPI 1 — Tiempo promedio

Fixture: dos completadas con 1000 y 3000 ms, una abandonada con 9000 ms. Resultado esperado: 2000 ms. Preview, background, persistencia, TTS, celebración y diálogo no alteran los valores de las completadas.

### KPI 2 — Repeticiones de video

Fixture: video iniciado con dos taps replay, otro video con uno y siete actividades iniciadas totales. Resultado esperado: `3 / 7`. Pause, resume y tres scrubs no cambian el numerador.

### KPI 3 — Abandono

Fixture: diez sesiones con `hasStarted`, dos `abandoned`, una `launch_error` sin inicio. Resultado esperado: `2 / 10`; launch_error queda fuera de ambos términos.

### KPI 4 — Navegación exitosa

Fixture: diez iniciadas, seis completadas; dos de las completadas tuvieron background. Resultado esperado: `4 / 10`. Las dos interrumpidas siguen contando para finalización.

### KPI 5 — Finalización

Con el fixture anterior, resultado esperado: `6 / 10`, independientemente de interrupciones.

### KPI 6 — Intentos promedio

Fixture: simple selection completada con runs de 2 y 3 intentos, puzzle completado con 1, video completado y una interactiva fallida. Numerador `6`, denominador `2`, resultado `3`. Video e interactiva fallida no participan.

### KPI 7 — Progreso de módulo

Fixture: módulo con cinco `levelId` únicos y progreso completado para tres; documentos/lecturas repetidas del mismo nivel no incrementan el conteo. Resultado esperado: `3/5`. No se consulta `telemetryActivitySessions` para resolverlo.

### Lifecycle y terminalidad

- Background detiene tiempo activo y marca una sola interrupción.
- Resume a 14:59 conserva UUID; si completa, `navigationSuccessful == false`.
- Resume a 15:00 abandona la sesión anterior y crea UUID nuevo sólo si continúa.
- Fallo definitivo termina `failed`, nunca `abandoned`.
- Back después de started y antes de terminal termina `abandoned`.
- Dos señales terminales concurrentes producen un único estado terminal persistido.

## 16. Fuera de alcance

- Firebase Storage para telemetría o cualquier otro propósito derivado de este plan.
- Exportaciones manuales/automáticas, CSV, JSON, data lake o backups de telemetría.
- BigQuery y Firebase Analytics.
- Cloud Functions y documentos precalculados/agregados.
- Dashboard web implementado; sólo se deja listo el contrato de consultas y seguridad futura.
- Identidad separada padre/niño con perfiles múltiples. Se documenta la separación semántica, pero ambos IDs siguen siendo el UID actual.
- UUID propio permanente para actividades. Hasta entonces se usa `{moduleId}:{levelId}:{activityType}`.
- Cambiar la fuente de verdad del progreso de módulos.
- Captura de eventos finos de taps, trayectorias, respuestas concretas, contenido visto o texto libre.
- Borrado retroactivo de historial al desactivar `sendMetrics`.

## 17. Riesgos y migración

| Riesgo | Impacto | Mitigación |
| --- | --- | --- |
| Callbacks actuales llegan después de delays | Infla tiempo activo | Introducir `onObjectiveMet` antes de celebración/TTS y detener reloj allí. |
| `FirestoreService` silencia errores | Pérdida invisible | Repositorio nuevo inyectable que propaga errores; no reutilizar ese patrón. |
| Callbacks/run duplicados | Intentos o terminales dobles | Serialización por sesión, IDs de run y guardas idempotentes. |
| Route disposal no permite await | Sesión abierta | Señales explícitas antes de pop, marcador local y reconciliación; dispose sólo como respaldo. |
| Opt-out durante sesión deja documento started si falla red | Sesgo de datos | Un único cierre best-effort y consultas/monitoreo de no terminales antiguos; privacidad prevalece, sin retry posterior. |
| Caché offline confirma localmente antes que servidor | Falsa sensación de persistencia | Estado de operación, marker y reconciliación al reconectar. |
| Índices excesivos | Mayor costo de escritura | Crear sólo los exigidos por consultas KPI reales. |
| Reglas complejas de transición | Bloqueo de escrituras legítimas | Tests de Emulator Suite por transición y despliegue gradual. |
| Reloj perdido por proceso muerto | Duración incompleta | Persistir acumulado al pausar/mutaciones; aceptar que no se puede reconstruir tiempo monotónico no cerrado. Nunca sustituirlo con wall clock. |
| Video registrado y reproductor dedicado divergen | KPI inconsistente | Compartir adaptador/contrato de señales y probar ambas rutas. |
| Cambio futuro a perfiles padre/niño | Identidad histórica ambigua | Mantener campos semánticos e `identityModel`; una futura versión de esquema podrá permitir IDs distintos sin reescribir histórico. |
| `activityId` compuesto colisiona si cambia el catálogo | Series mezcladas | Mantener tipos normalizados; migrar a UUID de actividad en una nueva `schemaVersion`, conservando el compuesto histórico. |

### Estrategia de activación

1. Desplegar primero reglas e índices compatibles con colección vacía.
2. Publicar la app con `sendMetrics` default `false`, como hoy documenta `../data-model.md`.
3. Habilitar pruebas internas mediante opt-in explícito.
4. Validar calidad: sesiones sin iniciar, no terminales antiguas, duración extrema, duplicados y coherencia de invariantes.
5. Construir consultas/dashboard sólo después de aprobar fixtures KPI.
6. Si se detecta una falla de esquema, deshabilitar recolección desde la preferencia/versión siguiente; no migrar ni borrar histórico automáticamente. Evolucionar con `schemaVersion` y hacer que consultas filtren versiones compatibles.

## 18. Definición de terminado

La implementación estará terminada cuando:

- las siete definiciones KPI produzcan los resultados de aceptación;
- todos los tipos de actividad emitan ready/objective/terminal en fronteras correctas;
- opt-in, opt-out, offline, lifecycle y timeout estén cubiertos por tests;
- reglas impidan escritura ajena, mutación de actor y cambios terminales;
- Firestore sea la única fuente remota de sesiones y no existan agregados/Functions;
- no haya PII, campos archive, Storage, exportaciones ni BigQuery en la solución;
- documentación de arquitectura, datos, Firebase, learning module, minijuegos y settings se actualice junto con la implementación real.
