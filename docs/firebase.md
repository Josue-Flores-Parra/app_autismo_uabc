# Firebase

Appy usa Firebase en Flutter para autenticacion y Cloud Firestore. El repo
incluye configuracion generada de FlutterFire para Android, iOS y Web en
`lib/firebase_options.dart`. El archivo `firebase.json` contiene la metadata de
FlutterFire usada por el proyecto.

## Proyecto configurado

El proyecto Firebase usado por los archivos actuales es:

```text
app-autismo-25f44
```

Archivos reales relacionados con Firebase:

| Archivo | Estado actual |
| --- | --- |
| `firebase.json` | Declara metadata de FlutterFire para Android y las apps Dart de Android/iOS/Web. |
| `lib/firebase_options.dart` | Generado por FlutterFire CLI. Contiene opciones para Web, Android e iOS. |
| `android/app/google-services.json` | Presente en el repo. Se usa por el plugin `com.google.gms.google-services`. |
| `ios/Runner/GoogleService-Info.plist` | No existe actualmente en el repo. |

## Plataformas

`firebase.json` contiene estas referencias:

```text
android: 1:591509844503:android:cb109334431d2ca726e252
ios:     1:591509844503:ios:69798e0e1ee93bf326e252
web:     1:591509844503:web:739430b021b2b7ae26e252
```

`lib/firebase_options.dart` soporta:

- Web.
- Android.
- iOS.

Para estas plataformas lanza `UnsupportedError`:

- macOS.
- Windows.
- Linux.

Aunque existen carpetas `macos/`, `windows/` y `linux/`, la app no puede
inicializar Firebase ahi con la configuracion actual.

## Inicializacion

La inicializacion ocurre en `lib/main.dart` antes de `runApp`:

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Ninguna feature inicializa Firebase por su cuenta. Si una pantalla o servicio
usa Firebase, asume que `main()` ya termino esa inicializacion.

## Authentication

La autenticacion usa `firebase_auth`.

Archivos principales:

```text
lib/data/services/auth_services.dart
lib/features/authentication/viewmodel/auth_viewmodel.dart
lib/features/authentication/view/login_screen.dart
lib/features/authentication/view/register_screen.dart
lib/features/settings/view/settings_page.dart
lib/features/home/view/main_shell.dart
```

Operaciones reales:

| Operacion | Donde vive | Firebase usado |
| --- | --- | --- |
| Registro email/password | `AuthService.register` | `createUserWithEmailAndPassword` |
| Login email/password | `AuthService.login` | `signInWithEmailAndPassword` |
| Logout | `AuthService.logout` | `signOut` |
| Update display name | `AuthService.updateDisplayName` | `User.updateDisplayName` |
| Cambio de password | `AuthService.changePassword` | `User.updatePassword` |
| Restablecimiento de password | `AuthService.sendPasswordResetEmail` | `sendPasswordResetEmail` |
| Marcado/eliminacion de cuenta | `AuthService.deleteAccount` | Firestore + `User.delete` |
| Reautenticacion para recuperar PIN | `MainShell._handleForgotPin` | `EmailAuthProvider.credential` + `reauthenticateWithCredential` |

Durante `logout`, antes de `FirebaseAuth.signOut()`, se llama:

```text
VideoControllerManager().disposeAll()
```

Esto libera controladores de video compartidos para evitar que queden
decodificadores activos al cerrar sesion.

## FirestoreService

La capa compartida de acceso a Firestore esta en:

```text
lib/data/services/firestore_services.dart
```

La clase crea directamente:

```dart
final FirebaseFirestore _db = FirebaseFirestore.instance;
```

No recibe la instancia por constructor, por lo que los tests unitarios no pueden
inyectar facilmente un fake sin cambiar la clase.

Metodos reales:

| Metodo | Ruta Firestore | Comportamiento |
| --- | --- | --- |
| `setUserData(uid, data)` | `users/{uid}` | `set(data, SetOptions(merge: true))`. |
| `getUserData(uid)` | `users/{uid}` | Retorna `Map<String, dynamic>?`. |
| `saveUserProgress(userId, levelId, result)` | `users/{uid}/progress/{levelId}` | Escribe progreso por `levelId` directo. Si falla, relanza. |
| `getUserProgress(userId)` | `users/{uid}/progress` | Lee documentos directos y retorna map por doc id o `null`. |
| `getModuleData(moduleId)` | `modules/{moduleId}` | Lee un modulo y agrega `id` desde doc id. |
| `getAllModules()` | `modules` | Lee todos los modulos y agrega `id`. Si falla retorna `[]`. |
| `getModules()` | `modules` | Duplicado funcional de `getAllModules()`. |
| `getModuleLevels(moduleId)` | `modules/{moduleId}/levels` | Ordena por `orden`; si `moduleId` vacio retorna `[]`. |
| `getLevelsForModule(moduleId)` | `modules/{moduleId}/levels` | Lee sin ordenar por `orden`. |
| `getModuleLevel(moduleId, levelId)` | `modules/{moduleId}/levels/{levelId}` | Lee un nivel y agrega `id`. |
| `updateUserLevelProgress(uid, moduleId, levelId, data)` | `users/{uid}/progress/{moduleId}/levels/{levelId}` | Escribe con merge; si falla lo silencia. |
| `getUserModuleProgress(uid, moduleId)` | `users/{uid}/progress/{moduleId}` | Lee el documento de modulo. |
| `getUserLevelsProgress(uid, moduleId)` | `users/{uid}/progress/{moduleId}/levels` | Retorna map por `levelId`; si falla retorna `{}`. |
| `getUserLevelProgress(uid, moduleId, levelId)` | `users/{uid}/progress/{moduleId}/levels/{levelId}` | Retorna progreso de un nivel o `null`. |
| `getUserLevel(uid)` | `users/{uid}.nivel` | Lee `nivel` como `int` o `String`; default `1`. |

## Rutas Firestore usadas

```text
users/{uid}
users/{uid}/progress/{levelId}
users/{uid}/progress/{moduleId}
users/{uid}/progress/{moduleId}/levels/{levelId}
modules/{moduleId}
modules/{moduleId}/levels/{levelId}
```

Hay dos estructuras de progreso coexistiendo:

1. Progreso directo por nivel:

```text
users/{uid}/progress/{levelId}
```

Usado por `saveUserProgress()` y `getUserProgress()`.

2. Progreso agrupado por modulo:

```text
users/{uid}/progress/{moduleId}/levels/{levelId}
```

Usado por `LearningViewModel` y `LevelCompletionService`. Este es el camino
principal del learning module actual.

## users/{uid}

Campos escritos por el codigo actual:

| Campo | Quien lo escribe | Detalle |
| --- | --- | --- |
| `name` | Registro y update display name | Nombre visible en Firestore. |
| `email` | Registro | Email usado para Auth. |
| `createdAt` | Registro | String ISO 8601. |
| `deletedAt` | Eliminacion de cuenta | String ISO 8601, escrito antes de `User.delete()`. |
| `avatarConfig` | `AvatarViewModel` | Mapa completo de personalizacion del avatar. |

Campos leidos por el codigo actual:

| Campo | Quien lo lee | Detalle |
| --- | --- | --- |
| `name` | `AvatarViewModel` | Fallback para nombre del avatar. |
| `nivel` | `FirestoreService.getUserLevel` y `LearningViewModel` | Puede ser `int` o `String`; default `1`. |
| `avatarConfig` | `AvatarViewModel` | Se castea a `Map<String, dynamic>`. |

`UserModel` tambien define `displayName`, `monedas`, `role`, `createdAt` y
`updatedAt`, pero esos campos no son todos escritos por `AuthService`.

## modules/{moduleId}

Campos esperados por `ModuloInfo.fromFirestore`:

| Campo | Tipo esperado | Default/parsing |
| --- | --- | --- |
| `id` | `String` | Lo agrega `FirestoreService` desde el doc id. |
| `titulo` | `String` | Default `''`. |
| `descripcion` | `String?` | Opcional. |
| `nivelMinimo` | `int` | Default `1`. |
| `imagenUrl` | `String` | Usado como asset local en `ModuleListScreen`. |
| `lvlBackgroundImageUrl` | `String?` | Usado como asset local de fondo del timeline. |
| `color` | `String` hex | Si falta o no parsea, `Colors.grey`. |
| `bloqueado` | `bool` | Default `false`. |

`LearningViewModel.loadModules()` ademas bloquea modulos si:

- `bloqueado` viene `true` desde Firestore.
- `userLevel < nivelMinimo`.

`ModulosGridView` agrega otro bloqueo visual si:

- `modulo.nivel < SettingsViewModel.parentalMinLevel`.

## modules/{moduleId}/levels/{levelId}

Campos esperados:

| Campo | Tipo esperado | Uso |
| --- | --- | --- |
| `id` | `String` | Lo agrega `FirestoreService` desde doc id. |
| `titulo` | `String` | Titulo de nivel. |
| `orden` | `int` o `String` parseable | Ordenamiento y titulo `Paso X`. |
| `pictogramaUrl` | `String?` | Preview, portada y fallback de puzzle. Puede ser URL remota o asset. |
| `videoUrl` | `String?` | Video educativo. Puede ser URL remota o asset. |
| `puzzleImageUrl` | `String?` | Imagen principal para puzzle. |
| `audioUrl` | `String?` | Audio educativo. |
| `actividadType` | `String?` | Tipo de actividad. `null`, vacio o `"null"` se trata como sin actividad. |
| `actividadData` | `Map<String, dynamic>?` | Datos especificos de actividad. |
| `estrellas` | `int` o `String` parseable | Campo leido por el modelo, aunque en el flujo principal las estrellas vienen del progreso. |
| `estado` | `String?` | Parser acepta `completed`, `inProgress`, `in_progress`, `blocked`. |

`LearningViewModel` combina datos del nivel y progreso. El estado final mostrado
en timeline no depende solo de `estado` del documento; se recalcula con progreso.

## Progreso por nivel

La escritura principal se hace desde `LevelCompletionService`.

Para niveles interactivos exitosos:

```text
users/{uid}/progress/{moduleId}/levels/{levelId}
```

Campos escritos:

| Campo | Valor |
| --- | --- |
| `status` | `completed` si `success == true`; `in_progress` si no. |
| `estrellas` | `3` si `attempts <= 1`, `2` si `attempts == 2`, `1` para mas intentos. |
| `attempts` | Intentos reportados por el minijuego. |
| `completedAt` | ISO 8601 si hubo exito; `null` si no. |
| `updatedAt` | ISO 8601. |

Para niveles de observacion:

| Campo | Valor |
| --- | --- |
| `status` | `completed` |
| `estrellas` | `2` |
| `attempts` | `0` |
| `completedAt` | ISO 8601 |
| `updatedAt` | ISO 8601 |
| `type` | `observation` |

Recompensas:

| Caso | Estrellas | Monedas |
| --- | --- | --- |
| Interactivo en 1 intento o menos | 3 | 30 |
| Interactivo en 2 intentos | 2 | 20 |
| Interactivo en 3+ intentos | 1 | 10 |
| Observacion | 2 | 20 |

Las monedas se suman en el `AvatarViewModel` actual y se guardan dentro de
`avatarConfig.monedas`.

## Storage

No hay uso directo del SDK de Firebase Storage en el codigo actual. Las imagenes,
videos y audios remotos se tratan como URLs `http://` o `https://` y se cargan
con widgets/plugins como:

- `Image.network`.
- `VideoPlayerController.networkUrl`.
- `AudioPlayer.setUrl`.
- `http.get` dentro de `PictogramMinigame` para cachear imagenes.

El `storageBucket` existe en `firebase_options.dart`, pero no hay servicio de
Storage ni Cloud Function proxy en el repo.

## Mantenimiento

- Si se regenera FlutterFire, revisar `firebase.json`, `lib/firebase_options.dart`, `android/app/google-services.json` y, si aplica, `ios/Runner/GoogleService-Info.plist`.
- Si se agrega soporte Firebase para macOS, Windows o Linux, actualizar `DefaultFirebaseOptions.currentPlatform`.
- Si se cambia la estructura de progreso, actualizar `docs/data-model.md`, `docs/features/learning-module.md` y tests relacionados.
- Si se introduce Firebase Storage SDK, documentar el servicio y las reglas de paths.
