# Arquitectura

Appy es una aplicacion Flutter organizada por features, con estado basado en
`provider` y `ChangeNotifier`, Firebase Auth para identidad y Cloud Firestore
para datos de usuario, modulos, niveles y progreso. La arquitectura pretendida
es MVVM, pero este documento describe tambien las desviaciones reales que
existen hoy en el codigo para que un dev nuevo no trabaje con supuestos falsos.

## Estructura

```text
lib/
|-- core/
|   `-- app_theme.dart
|-- data/
|   |-- models/
|   |   |-- level_model.dart
|   |   |-- module_model.dart
|   |   |-- progress_log_model.dart
|   |   `-- user_model.dart
|   `-- services/
|       |-- auth_services.dart
|       `-- firestore_services.dart
|-- features/
|   |-- authentication/
|   |   |-- view/
|   |   `-- viewmodel/
|   |-- avatar/
|   |   |-- data/
|   |   |-- model/
|   |   |-- view/
|   |   `-- viewmodel/
|   |-- home/
|   |   `-- view/
|   |-- legal/
|   |   |-- data/
|   |   |-- view/
|   |   `-- viewmodel/
|   |-- onboarding/
|   |   |-- data/
|   |   `-- view/
|   |-- learning_module/
|   |   |-- data/
|   |   |-- model/
|   |   |-- view/
|   |   `-- viewmodel/
|   |-- minigames/
|   |   |-- minigame_core.dart
|   |   `-- view/
|   |-- settings/
|   |   |-- view/
|   |   `-- viewmodel/
|   `-- telemetry/
|       |-- data/
|       |-- model/
|       |-- service/
|       `-- view/
|-- l10n/
|   |-- app_en.arb
|   |-- app_es.arb
|   `-- gen/
|-- shared/
|   |-- services/
|   `-- widgets/
|-- firebase_options.dart
`-- main.dart
```

Tambien existen carpetas de plataforma generadas por Flutter: `android/`,
`ios/`, `web/`, `linux/`, `macos/` y `windows/`. No todas las plataformas
tienen Firebase configurado de forma ejecutable; ver `docs/firebase.md`.

## Inicio de la app

El punto de entrada es `lib/main.dart`.

Secuencia real:

1. Ejecuta `WidgetsFlutterBinding.ensureInitialized()`.
2. Inicializa Firebase con `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
3. Registra manualmente los minijuegos en `MinigameFactory`.
4. Construye `MyApp`.
5. Crea un `AvatarEstado` inicial usando la primera skin de `AvatarRepository`.
6. Monta `MultiProvider`.
7. Envuelve la app con `LoadingWrapper`.
8. Configura `MaterialApp` con tema, locale, delegates de l10n y `MediaQuery.textScaler`.
9. Usa `AuthGate` como pantalla inicial (resuelve entre `LoginScreen` y `MainShell` segun la sesion).

Los minijuegos registrados en `main.dart` son:

```text
registerSimpleSelectionMinigame()
registerVideoMinigame()
registerPictogramMinigame()
registerAudioMinigame()
registerPuzzleMinigame()
```

## Providers globales

`main.dart` registra estos providers en el arbol raiz:

| Provider | Tipo | Responsabilidad real |
| --- | --- | --- |
| `SettingsViewModel` | `ChangeNotifierProvider` | Preferencias locales: tema, idioma, escala de texto, accesibilidad, recordatorios, metricas, control parental y limpieza de cache de imagenes. |
| `AuthViewModel` | `ChangeNotifierProvider` | Estado de autenticacion, login, registro, logout, restablecimiento de password, cambio de nombre, cambio de password y eliminacion de cuenta. |
| `AvatarViewModel` | `ChangeNotifierProxyProvider<AuthViewModel, AvatarViewModel>` | Estado visual del avatar y persistencia en `users/{uid}.avatarConfig`. Cuando hay usuario autenticado llama `initialize()`. |
| `LegalViewModel` | `ChangeNotifierProxyProvider<AuthViewModel, LegalViewModel>` | Resuelve si la cuenta acepto la version vigente de los documentos legales. Se reinicia al cerrar sesion. |
| `LearningViewModel` | `ChangeNotifierProvider` | Carga modulos, niveles, progreso, cache de niveles y pines de imagenes de portada en `ImageCache`. |
| `LoadingService` | `ChangeNotifierProvider` | Overlay global de carga consumido por `LoadingWrapper` y `LoadingHook`. |

`AvatarViewModel` se crea con un estado inicial hardcodeado:

- `nombre`: `nombre`.
- `felicidad`: `64`.
- `energia`: `92`.
- `monedas`: `150`.
- `backgroundActual`: `assets/images/Skins/DefaultSkin/backgrounds/default.jpg`.
- `accesoriosDesbloqueados`: `Antenitas` y `Gafas`.

## Flujo de navegacion principal

La app arranca con `AuthGate` (`lib/features/authentication/view/auth_gate.dart`)
como pantalla inicial en `main.dart`. El gate es un `StatefulWidget` que:

- Muestra un splash (`CircularProgressIndicator`) hasta el primer post-frame callback.
- Consulta `OnboardingService.hasSeen()` una vez por arranque.
- Escucha `AuthViewModel` con `Consumer`; ante cualquier cambio de `currentUser`
  (login, logout, deleteAccount, registro) hace el swap automatico:
  - sin usuario y sin bienvenida vista → `OnboardingScreen`; al terminar marca `onboardingSeen` y pasa a `LoginScreen`.
  - sin usuario → `LoginScreen`.
  - con usuario (login o sesion restaurada por Firebase) → `_LegalGate` → `MainShell`.

Esto elimino la navegacion imperativa (`pushReplacement` / `pushAndRemoveUntil`)
que antes usaban login, registro y settings para moverse entre pantallas.

Flujo despues de autenticarse:

```text
AuthGate
  -> OnboardingScreen (solo la primera vez en el dispositivo)
  -> LoginScreen / RegisterScreen / ForgotPasswordScreen
  -> AuthViewModel
  -> AuthService
  -> FirebaseAuth
  -> _LegalGate (visto via AuthGate cuando currentUser != null)
       -> LegalConsentScreen si falta aceptar la version vigente
       -> MainShell si la cuenta esta al corriente
```

El gate legal va despues del de autenticacion porque la version aceptada se
guarda por cuenta, en `users/{uid}.legal`, y solo puede consultarse con sesion
abierta. Ver `docs/features/legal.md`.

`RegisterScreen` y `ForgotPasswordScreen` se empujan sobre el `LoginScreen` del
gate con `Navigator.push` y regresan con `Navigator.pop()`. Tras un registro
exitoso, `AuthViewModel.register` cierra la sesion auto-iniciada por Firebase,
marca `registrationSuccess` y el gate permanece en `LoginScreen` mostrando un
cue de exito.

`MainShell` contiene dos pantallas en el bottom nav:

| Indice | Pantalla | Archivo |
| --- | --- | --- |
| `0` | Modulos | `lib/features/learning_module/view/module_list_screen.dart` |
| `1` | Avatar | `lib/features/avatar/view/avatar_screen.dart` |

Ajustes no tiene pestaña propia: es redundante abrirla desde el bottom nav
cuando ya existe el icono de engrane en el `AppBar` de `ModuleListScreen`, que
lleva al mismo `SettingsPage` tras el mismo PIN. Ese unico atajo pasa por
`SettingsAccessGuard`, que a su vez usa `PinService`. Si no hay PIN, pide
crear uno; si ya existe, pide ingresarlo. Si el usuario toca "Olvide el PIN",
se reautentica con email/password usando `FirebaseAuth.instance.currentUser` y
`EmailAuthProvider.credential`, borra `settingsPin_<uid>` y solicita crear un
PIN nuevo.

## MVVM
La regla general del proyecto es:

```text
View -> ViewModel -> Service/Repository -> Firebase / Assets / Plugins
```

Ejemplos que siguen esta forma:

```text
LoginScreen
  -> AuthViewModel.login()
    -> AuthService.login()
      -> FirebaseAuth.signInWithEmailAndPassword()
```

```text
LevelTimelineScreen
  -> LevelTimelineViewModel
    -> LearningViewModel
      -> FirestoreService
        -> Cloud Firestore
```

```text
SettingsPage
  -> SettingsViewModel
    -> SharedPreferences
```

Desviaciones reales que hay que conocer:

- `AvatarViewModel` consulta `FirebaseAuth.instance.currentUser` directamente para guardar/cargar avatar.
- `ModuleListScreen` lee `FirebaseAuth.instance.currentUser` directamente para mostrar nombre de usuario.
- `SettingsAccessGuard` usa `FirebaseAuth.instance` directamente para resolver el uid y recuperar el PIN por reautenticacion.
- Algunas pantallas contienen logica de flujo importante dentro del widget, por ejemplo `LevelContentPreviewScreen` decide que actividad lanzar segun la tarjeta seleccionada.
- `ModuleListViewModel` existe, pero el flujo principal de modulos usa el `LearningViewModel` global.

No se debe interpretar la documentacion como si esas desviaciones no existieran.
Si se refactorizan, hay que actualizar esta pagina y las paginas de feature.

## Learning module en alto nivel

El modulo de aprendizaje tiene este flujo conectado:

```text
ModuleListScreen
  -> LearningViewModel.loadModules()
  -> ModulosGridView / ModuloPlantilla
  -> LevelTimelineScreen
  -> LevelTimelineViewModel
  -> LevelContentPreviewScreen
  -> PopupPreview
  -> LevelPlayScreen
  -> MinigamesWidget o reproductor de video dedicado
  -> LevelCompletionService
  -> FirestoreService.updateUserLevelProgress()
  -> AvatarViewModel.agregarMonedas()
  -> LearningViewModel.getModuleLevels(forceReload: true)
```

Hay dos botones `JUGAR` en el timeline: uno flotante para el primer nivel en
progreso y otro dentro del popup al tocar un nodo. Ambos construyen contenido
con `_buildContentFromLevel()` y navegan a `LevelContentPreviewScreen`.

## Estado, cache y side effects

Estado local:

- `SettingsViewModel` persiste en `SharedPreferences` y publica las preferencias de feedback en `FeedbackPreferences`.
- `PinService` persiste `settingsPin_<uid>` en `SharedPreferences`.
- `FeedbackPreferences` mantiene en memoria si el audio y la vibracion estan activos, para los servicios que no tienen `BuildContext`.
- `LoadingService` solo mantiene estado en memoria.

Estado remoto:

- `AuthService` escribe datos basicos del usuario en Firestore durante registro, cambio de nombre y eliminacion.
- `AvatarViewModel` guarda `avatarConfig` dentro de `users/{uid}`.
- `LevelCompletionService` guarda progreso en `users/{uid}/progress/{moduleId}/levels/{levelId}`.

Cache de runtime:

- `LearningViewModel` cachea niveles por `moduleId` en `_moduleLevels`.
- `LearningViewModel` cachea progreso por modulo en `_userProgress`.
- `LearningViewModel` evita cargas duplicadas con `_pendingLevelLoads`.
- `LearningViewModel` fija portadas remotas de niveles en `ImageCache` usando `ImageStreamCompleterHandle.keepAlive()` y libera los handles al salir del timeline.
- `VideoControllerManager` reutiliza `VideoPlayerController` por URL/path con conteo de referencias.
- `LevelContentPreviewScreen` retiene temporalmente videos preprecargados y libera esas referencias en `dispose`.
- `PictogramMinigame` descarga imagenes remotas a `getTemporaryDirectory()/pictogram_images`.

## Tema y accesibilidad

`core/app_theme.dart` construye tema claro y oscuro con Material 3 y expone
tres piezas que las pantallas consumen directamente:

| Pieza | Que es | Como se usa |
| --- | --- | --- |
| `AppColors` | `ThemeExtension` con los colores semanticos de la app. | `context.appColors.surface`, `.ink`, `.accent`, etc. |
| `AppRadius` | Escala unica de radios: `input` 14, `card` 18, `button` 16, `pill` 28, `sheet` 24. | `BorderRadius.circular(AppRadius.card)` |
| `AppFonts` | Familias: `display` (Coiny) y `body` (Commissioner). | `fontFamily: AppFonts.display` |

Paletas de `AppColors`:

- `light`: pasteles celestes tomados de los fondos de los presets del personaje.
- `dark`: el azul profundo original de la app.
- `highContrastLight` y `highContrastDark`: blanco/negro puros con un solo acento.

Campos: `backgroundTop`, `backgroundBottom`, `surface`, `surfaceBorder`,
`headerTop`, `headerBottom`, `ink`, `inkSoft`, `accent`, `accentSoft`,
`success`, `warning`, `glassFill`, `glassBorder`, mas los getters
`backgroundGradient` y `headerGradient`.

Parametros que recibe desde `SettingsViewModel`:

- `fontScale`.
- `highContrast`.
- `reduceMotion`.

Detalles reales:

- La escala de texto efectiva no se aplica dentro de `TextTheme`; se aplica con `MediaQuery.textScaler` en `main.dart`.
- `highContrast` cambia el seed color y elige las paletas `highContrast*`.
- `reduceMotion` cambia `pageTransitionsTheme` a `NoTransitionsBuilder`.
- `MainShell` tambien usa `reduceAnimations`: si esta activo, `AnimatedSwitcher` dura `Duration.zero`.
- `PuzzleGridBackground` (fondo animado de `LevelContentPreviewScreen`) recibe `animate: !reduceMotion`.
- El `AppBar` del tema es transparente con `foregroundColor` en `ink`; las pantallas que van sobre ilustraciones usan `GlassPill` (`shared/widgets/glass_pill.dart`).
- La orientacion se fija a `portraitUp` en `main.dart`; solo el video en pantalla completa la libera y la restaura al salir.
- Otras pantallas tienen animaciones propias que no consultan `reduceAnimations`; esto sigue siendo un gap.

Regla: ningun color fijo (`Color(0xFF...)`, `Colors.white`) en pantallas
nuevas salvo colores de marca compartidos (estrellas y monedas usan
`0xFFF2B233`) o superficies que siempre son oscuras (reproductor de video).

## Convenciones actuales

- Views: `*_screen.dart`, `*_page.dart` o widgets con nombre de la pantalla/componente.
- ViewModels: `*_viewmodel.dart`.
- Services compartidos: `lib/shared/services/` o `lib/data/services/`.
- Repositories especificos de feature: `features/*/data/`.
- Modelos de UI de feature: `features/*/model/`.
- Assets nuevos deben declararse o quedar cubiertos por `pubspec.yaml`.
- Colores desde `context.appColors`, radios desde `AppRadius`, fuentes desde `AppFonts`.

## Reglas para agregar funcionalidad

1. Ubica el cambio en la feature existente cuando sea posible.
2. Si el cambio necesita estado observable por UI, usa un `ChangeNotifier` o extiende uno existente.
3. Si toca Firestore/Auth/SharedPreferences/plugins, documenta la ruta o clave afectada.
4. Si agrega campos a Firestore, actualiza `docs/data-model.md` y la pagina de la feature.
5. Si agrega `actividadType` o forma nueva de `actividadData`, actualiza `docs/features/minigames.md`.
6. Si agrega textos visibles, agrega llaves ARB o documenta por que queda hardcodeado temporalmente.
7. Si agrega assets, actualiza `pubspec.yaml` si la ruta no esta cubierta y actualiza `docs/assets.md`.

## Riesgos conocidos de arquitectura

- Hay logica de Firebase en algunas Views/ViewModels fuera de `data/services`.
- No hay abstracciones mockeables para `FirebaseAuth` o `FirebaseFirestore`.
- Hay textos hardcodeados en varias pantallas aunque existe l10n.
- El proyecto incluye plataformas desktop generadas, pero Firebase no esta configurado para desktop.

## Telemetría de actividades

Existe una feature `lib/features/telemetry/` que instrumenta sesiones de
actividad con la siguiente separación:

```text
View -> ActivityTelemetryService -> TelemetryRepository -> Cloud Firestore
```

- Las vistas emiten **señales semánticas** (`ActivitySessionHandle`) y no
  construyen mapas de Firestore ni calculan KPI.
- `ActivityTelemetryService` (provisto por `ProxyProvider2`) mantiene la máquina
  de estados, consentimiento, lifecycle y persistencia serializada.
- `TelemetryRepository` recibe `FirebaseFirestore` por constructor (inyectable y
  testeable) y propaga errores tipados; **no** reutiliza el patrón silencioso de
  `FirestoreService`.
- El consentimiento vive en `SettingsViewModel.sendMetrics`; el servicio no
  evalúa `sendMetrics` hasta que `SettingsViewModel.isReady == true`.

Detalle completo en `decisions/telemetry-implementation.md` y consultas en
`db/telemetry-kpi-queries.md`.
