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
|   |-- learning_module/
|   |   |-- data/
|   |   |-- model/
|   |   |-- view/
|   |   `-- viewmodel/
|   |-- minigames/
|   |   |-- minigame_core.dart
|   |   `-- view/
|   `-- settings/
|       |-- view/
|       `-- viewmodel/
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
- Escucha `AuthViewModel` con `Consumer`; ante cualquier cambio de `currentUser`
  (login, logout, deleteAccount, registro) hace el swap automatico:
  - sin usuario → `LoginScreen`.
  - con usuario (login o sesion restaurada por Firebase) → `MainShell`.

Esto elimino la navegacion imperativa (`pushReplacement` / `pushAndRemoveUntil`)
que antes usaban login, registro y settings para moverse entre pantallas.

Flujo despues de autenticarse:

```text
AuthGate
  -> LoginScreen / RegisterScreen / ForgotPasswordScreen
  -> AuthViewModel
  -> AuthService
  -> FirebaseAuth
  -> MainShell (visto via AuthGate cuando currentUser != null)
```

`RegisterScreen` y `ForgotPasswordScreen` se empujan sobre el `LoginScreen` del
gate con `Navigator.push` y regresan con `Navigator.pop()`. Tras un registro
exitoso, `AuthViewModel.register` cierra la sesion auto-iniciada por Firebase,
marca `registrationSuccess` y el gate permanece en `LoginScreen` mostrando un
cue de exito.

`MainShell` contiene tres pantallas:

| Indice | Pantalla | Archivo |
| --- | --- | --- |
| `0` | Modulos | `lib/features/learning_module/view/module_list_screen.dart` |
| `1` | Avatar | `lib/features/avatar/view/avatar_screen.dart` |
| `2` | Ajustes | `lib/features/settings/view/settings_page.dart` |

La pestaña de Ajustes no se abre libremente desde el bottom nav. `MainShell`
protege el indice `2` con un PIN local usando `PinService`. Si no hay PIN, pide
crear uno; si ya existe, pide ingresarlo. Si el usuario toca "Olvide el PIN",
se reautentica con email/password usando `FirebaseAuth.instance.currentUser` y
`EmailAuthProvider.credential`, borra `settingsPin` y solicita crear un PIN
nuevo.

Importante: `ModuleListScreen` tambien tiene un icono de ajustes en el `AppBar` superior
que navega directamente a `SettingsPage` sin pasar por el gating de PIN de
`MainShell`.

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
- `MainShell` usa `FirebaseAuth.instance` directamente para recuperar el PIN por reautenticacion.
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

- `SettingsViewModel` persiste en `SharedPreferences`.
- `PinService` persiste `settingsPin` en `SharedPreferences`.
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

`core/app_theme.dart` construye tema claro y oscuro con Material 3.

Parametros que recibe desde `SettingsViewModel`:

- `fontScale`.
- `highContrast`.
- `reduceMotion`.

Detalles reales:

- La escala de texto efectiva no se aplica dentro de `TextTheme`; se aplica con `MediaQuery.textScaler` en `main.dart`.
- `highContrast` cambia el seed color, fuerza `surface` negro, `onSurface` blanco y bordes mas fuertes.
- `reduceMotion` cambia `pageTransitionsTheme` a `NoTransitionsBuilder`.
- `MainShell` tambien usa `reduceAnimations`: si esta activo, `AnimatedSwitcher` dura `Duration.zero`.
- Muchas pantallas tienen animaciones propias que no consultan `reduceAnimations`; esto es un gap pendiente.

## Convenciones actuales

- Views: `*_screen.dart`, `*_page.dart` o widgets con nombre de la pantalla/componente.
- ViewModels: `*_viewmodel.dart`.
- Services compartidos: `lib/shared/services/` o `lib/data/services/`.
- Repositories especificos de feature: `features/*/data/`.
- Modelos serializables generales: `lib/data/models/`.
- Modelos de UI de feature: `features/*/model/`.
- Assets nuevos deben declararse o quedar cubiertos por `pubspec.yaml`.

## Componentes existentes pero no principales

Estos archivos existen y compilan como parte del proyecto, pero no son el camino
principal descrito arriba:

- `lib/features/learning_module/viewmodel/module_list_viewmodel.dart`: carga modulos de Firestore, pero `ModuleListScreen` usa `LearningViewModel`.
- `lib/features/learning_module/data/level_repository.dart`: convierte niveles a `LevelStepInfo`, pero el timeline actual usa `LearningViewModel` y `LevelTimelineViewModel`.
- `lib/features/learning_module/view/fullscreen_view.dart`: implementa un `PageView` fullscreen para contenido, pero el flujo actual de preview usa carrusel radial + popup + `LevelPlayScreen`.
- `lib/features/learning_module/viewmodel/video_player_viewmodel.dart`: maneja un `VideoPlayerController` propio con looping, pero el flujo actual usa principalmente `VideoViewModel` y `VideoControllerManager`.
- `lib/features/learning_module/view/barrel_preview_selector.dart.example`: archivo de ejemplo, no forma parte del build.

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
- Hay dos estructuras de progreso historicas bajo `users/{uid}/progress`.
- El proyecto incluye plataformas desktop generadas, pero Firebase no esta configurado para desktop.
