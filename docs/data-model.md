# Modelo de datos

Este documento describe los modelos Dart, las rutas de Firestore, las claves de
`SharedPreferences` y los mapas dinamicos usados por minijuegos. El objetivo es
reflejar el codigo actual, aunque haya duplicacion o schemas historicos.

## Modelos Dart generales

Los modelos en `lib/data/models/` son clases puras de Dart. No importan Flutter
ni Firebase.

| Archivo | Clases | Uso real |
| --- | --- | --- |
| `user_model.dart` | `UserModel` | Modelo serializable de usuario. Define mas campos de los que `AuthService` escribe actualmente. |
| `module_model.dart` | `ModuleModel`, `ModuleLevel` | Modelo generico con campos en ingles (`name`, `order`). No es el modelo principal del learning module actual. |
| `level_model.dart` | `LevelModel` | Modelo generico de nivel con campos en ingles (`title`, `difficulty`, `minigameData`). No es el parser principal de Firestore para timeline. |
| `progress_log_model.dart` | `ProgressLogModel` | Modelo serializable de progreso. No es usado directamente por `LevelCompletionService`, que escribe mapas. |

Estos modelos hacen conversion defensiva:

- Numeros pueden venir como `int`, `double` o `String`.
- Fechas pueden venir como `DateTime`, milisegundos `int`, `String` ISO 8601 o mapas tipo Timestamp con `seconds`/`nanoseconds`.
- `toJson()` elimina campos `null`.

## Modelos de learning module

| Archivo | Clase/enum | Uso |
| --- | --- | --- |
| `features/learning_module/model/modulo_info.dart` | `ModuloInfo` | Modelo principal de tarjeta de modulo en UI. |
| `features/learning_module/model/levels_models.dart` | `StateOfStep` | Estado visual: `completed`, `blocked`, `inProgress`. |
| `features/learning_module/model/levels_models.dart` | `ModuleLevelInfo` | Modelo principal de nivel leido desde Firestore. |
| `features/learning_module/model/levels_models.dart` | `LevelStepInfo` | Modelo adaptado para nodos del timeline. |
| `features/learning_module/model/content_card_model.dart` | `ContentType`, `ContentCardData` | Modelo de tarjetas de preview: pictograma, video, audio y miniGame. |

## Modelo de avatar

| Archivo | Clase | Uso |
| --- | --- | --- |
| `features/avatar/model/avatar_models.dart` | `SkinInfo` | Skin base, imagen, carpeta de backgrounds y expresiones opcionales. |
| `features/avatar/model/avatar_models.dart` | `AccesorioGeneral` | Accesorio superpuesto, posicion, tamano, bloqueo y costo. |
| `features/avatar/model/avatar_models.dart` | `AvatarEstado` | Estado completo del avatar actual. |

`AvatarRepository` no lee Firestore. Devuelve catalogos hardcodeados de skins,
accesorios y backgrounds.

## Firestore: users

Ruta:

```text
users/{uid}
```

Campos escritos o leidos por codigo actual:

| Campo | Tipo esperado | Escrito por | Leido por |
| --- | --- | --- | --- |
| `name` | `String` | `AuthService.register`, `AuthService.updateDisplayName` | `AvatarViewModel` como fallback de nombre |
| `email` | `String` | `AuthService.register` | No se lee desde Firestore en flujo principal |
| `createdAt` | `String` ISO 8601 | `AuthService.register` | No se lee en flujo principal |
| `deletedAt` | `String` ISO 8601 | `AuthService.deleteAccount` | No se lee en flujo principal |
| `nivel` | `int` o `String` parseable | No se escribe en el codigo actual | `FirestoreService.getUserLevel` |
| `avatarConfig` | `Map<String, dynamic>` | `AvatarViewModel.saveAvatarConfigToFirestore` | `AvatarViewModel.loadAvatarConfigFromFirestore` |

`UserModel` espera estos campos adicionales si se usa:

```text
id
displayName
monedas
role
updatedAt
```

Pero el registro actual no escribe `id`, `displayName`, `monedas`, `role` ni
`updatedAt` dentro de Firestore.

## users.avatarConfig

Ruta logica:

```text
users/{uid}.avatarConfig
```

Campos guardados por `AvatarViewModel`:

| Campo | Tipo | Detalle |
| --- | --- | --- |
| `nombre` | `String` | Nombre del avatar. |
| `felicidad` | `int` | Debe estar entre 0 y 100 cuando se cambia con `updateFelicidad`. |
| `energia` | `int` | Debe estar entre 0 y 100 cuando se cambia con `updateEnergia`. |
| `skinActual` | `String` | Nombre de `SkinInfo`, no ruta de imagen. |
| `expresionActual` | `String?` | Ruta de asset de expresion. |
| `accesorioActualPath` | `String?` | Ruta de asset del accesorio seleccionado. |
| `backgroundActual` | `String` | Ruta de asset del background. |
| `monedas` | `int` | Monedas actuales del avatar/usuario. |
| `accesoriosDesbloqueados` | `List<String>` | Nombres de accesorios desbloqueados. |

Al cargar, `AvatarViewModel`:

- Busca `skinActual` por nombre en `_availableSkins`; si no existe, usa la primera skin.
- Busca `accesorioActualPath` por `imagenPath`; si no existe, deja `null`.
- Castea `accesoriosDesbloqueados` como lista de `String` y luego `Set<String>`.
- Si no hay `avatarConfig`, intenta usar `FirebaseAuth.currentUser.displayName` o `users/{uid}.name` como nombre, pero solo guarda automaticamente si el nombre local actual es `MRBEAST`.

## Firestore: modules

Ruta:

```text
modules/{moduleId}
```

Campos usados por `ModuloInfo.fromFirestore`:

| Campo | Tipo esperado | Default |
| --- | --- | --- |
| `id` | `String` | `''`; normalmente lo inyecta `FirestoreService`. |
| `titulo` | `String` | `''` |
| `descripcion` | `String?` | `null` |
| `nivelMinimo` | `int` | `1` |
| `imagenUrl` | `String` | `''` |
| `lvlBackgroundImageUrl` | `String?` | `null` |
| `color` | `String` hex | `Colors.grey` si falta o falla parser |
| `bloqueado` | `bool` | `false` |

`imagenUrl` y `lvlBackgroundImageUrl` son tratados como assets locales por las
pantallas actuales. Si Firestore contiene URL remota para `imagenUrl`, la tarjeta
de modulo fallaria porque usa `Image.asset`.

## Firestore: levels

Ruta:

```text
modules/{moduleId}/levels/{levelId}
```

Campos usados por `ModuleLevelInfo` y `LearningViewModel`:

| Campo | Tipo esperado | Uso |
| --- | --- | --- |
| `id` | `String` | Inyectado desde doc id. |
| `titulo` | `String` | Titulo de nivel y de tarjetas. |
| `orden` | `int` o `String` parseable | Ordenamiento, estado secuencial y texto `Paso X`. |
| `pictogramaUrl` | `String?` | Preview, portada, pictograma y fallback de puzzle. |
| `videoUrl` | `String?` | Tarjeta de video y actividad de video. |
| `puzzleImageUrl` | `String?` | Imagen preferente del puzzle. |
| `audioUrl` | `String?` | Tarjeta y minijuego de audio. |
| `actividadType` | `String?` | Tipo base de actividad. |
| `actividadData` | `Map<String, dynamic>?` | Configuracion de minijuegos. |
| `estrellas` | `int` o `String` parseable | Campo del documento; en UI principal se sobreescribe con progreso. |
| `estado` | `String?` | Parser acepta `completed`, `inProgress`, `in_progress`, `blocked`. |

Estado actual de audio: el soporte esta implementado en codigo mediante
`audioUrl`, las tarjetas de audio y `AudioMinigame`, pero actualmente no hay
ningun nivel en Firestore con un recurso de audio configurado. Para activar un
nivel de audio, Firestore debe incluir un `audioUrl` valido que apunte a una URL
remota o a un asset disponible en la aplicacion.

`actividadType` se normaliza asi:

- `null` => `null`.
- `''` => `null`.
- `'null'` => `null`.
- Cualquier otro string trimmeado se conserva.

## Estado de niveles

`LearningViewModel._determineLevelStates()` recalcula estados con estas reglas:

1. Ordena niveles por `orden`.
2. Si hay progreso del nivel:
   - `status == completed` o `estrellas > 0` => `completed`.
   - `status == in_progress` o `inprogress` => `inProgress`.
   - Otros estados con `estrellas == 0` => `inProgress`.
3. Si no hay progreso:
   - Primer nivel => `inProgress`.
   - Niveles posteriores => `inProgress` solo si el nivel anterior esta `completed`; si no, `blocked`.

Esto significa que `estado` en Firestore no es la fuente final de verdad cuando
hay progreso calculado.

## Firestore: progreso

Hay dos rutas historicas:

```text
users/{uid}/progress/{levelId}
users/{uid}/progress/{moduleId}/levels/{levelId}
```

La ruta principal actual para el learning module es:

```text
users/{uid}/progress/{moduleId}/levels/{levelId}
```

Campos escritos por `LevelCompletionService.completeInteractiveLevel`:

| Campo | Tipo | Valor |
| --- | --- | --- |
| `status` | `String` | `completed` si success; `in_progress` si no. |
| `estrellas` | `int` | 3, 2, 1 o 0 segun intentos/exito. |
| `attempts` | `int` | Intentos usados. |
| `completedAt` | `String?` ISO 8601 | Solo si success. |
| `updatedAt` | `String` ISO 8601 | Siempre. |

Campos escritos por `completeObservationLevel`:

| Campo | Tipo | Valor |
| --- | --- | --- |
| `status` | `String` | `completed` |
| `estrellas` | `int` | `2` |
| `attempts` | `int` | `0` |
| `completedAt` | `String` ISO 8601 | Momento de guardado. |
| `updatedAt` | `String` ISO 8601 | Momento de guardado. |
| `type` | `String` | `observation` |

## SharedPreferences

### SettingsViewModel

| Clave | Tipo | Default |
| --- | --- | --- |
| `themeMode` | `String`: `system`, `light`, `dark` | `system` |
| `fontScale` | `String`: `small`, `medium`, `large` | `medium` |
| `locale` | `String`: `es`, `en` | `es` |
| `highContrast` | `bool` | `false` |
| `reduceAnimations` | `bool` | `false` |
| `audioFeedback` | `bool` | `true` |
| `hapticFeedback` | `bool` | `true` |
| `remindersEnabled` | `bool` | `false` |
| `reminderTime` | `String` formato `HH:mm` | `18:00` |
| `sendMetrics` | `bool` | `false` |
| `parentalMinLevel` | `int` | `0`, con clamp 0..10 al guardar |

Escala real:

| Opcion | `textScaleFactor` |
| --- | --- |
| `small` | `0.9` |
| `medium` | `1.0` |
| `large` | `1.15` |

### PinService

| Clave | Tipo | Uso |
| --- | --- | --- |
| `settingsPin` | `String` | PIN local de 4 digitos para abrir Ajustes desde `MainShell`. |

El PIN se guarda en texto plano en `SharedPreferences`. La validacion de PIN
debil vive en `MainShell`, no en `PinService`.

## actividadData

`actividadData` es un `Map<String, dynamic>` leido desde Firestore. Se fusiona
con campos del nivel en `LearningViewModel` y `LevelTimelineViewModel` para
agregar, si faltan:

```text
puzzleImageUrl
pictogramaUrl
videoUrl
```

Keys usadas por varios minijuegos:

| Key | Tipo | Uso |
| --- | --- | --- |
| `maxAttempts` | `int`, `num` o `String` | Intentos maximos de seleccion simple/puzzle. |
| `pictogramaUrl` | `String` | Imagen de pictograma, fallback visual y fallback de puzzle. |
| `videoUrl` | `String` | Video. |
| `url` | `String` | Fallback de video en `LevelPlayScreen`. |
| `audioUrl` | `String` | Audio. |
| `puzzleImageUrl` | `String` | Imagen principal de puzzle. |
| `isSimpleSelectionEnabled` | `bool`, `num` o `String` | Habilita tarjeta de seleccion simple. |
| `isPuzzleEnabled` | `bool`, `num` o `String` | Habilita tarjeta de puzzle. |
| `steps` | `List` | Secuencia de pictogramas o fuente para generar preguntas de seleccion simple. |
| `pictogramSteps` | `List` | Alias de `steps`. |
| `questions` | `List` o `Map` | Preguntas explicitas de seleccion simple. |
| `question` | `String` | Pregunta legacy de seleccion simple. |
| `correctIndex` | `int` o `String` | Indice correcto legacy. |
| `options` | `List` o `Map` | Opciones legacy/explicitas de seleccion simple. |
| `title` / `titulo` | `String` | Titulo en pictogram/audio. |
| `description` / `descripcion` | `String` | Descripcion en pictogram/audio. |

Aunque `audioUrl` esta documentado y el flujo de audio existe en la app, en el
estado actual de Firestore no hay ningun nivel con ese recurso poblado.

Shape para `steps`:

```json
[
  {
    "url": "https://...",
    "caption": "Abrir la llave"
  }
]
```

Aliases aceptados dentro de cada step:

| Concepto | Keys aceptadas |
| --- | --- |
| Imagen | `url`, `imagePath`, `src`, `pictogramaUrl` |
| Texto | `caption`, `label`, `text` |

Shape legacy de seleccion simple:

```json
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
```

Shape con preguntas explicitas:

```json
{
  "questions": [
    {
      "question": "Cual es la imagen correcta?",
      "correctIndex": 0,
      "maxAttempts": 3,
      "options": [
        {
          "imagePath": "https://...",
          "label": "Paso 1"
        }
      ]
    }
  ]
}
```

## Reglas de cambio de schema

- Si agregas un campo requerido, define default en el parser para documentos antiguos.
- Si cambias nombres de campos, agrega compatibilidad temporal en parser y documenta el periodo de migracion.
- Si cambias progreso, actualiza `FirestoreService`, `LearningViewModel`, `LevelCompletionService` y esta pagina.
- Si agregas un `actividadType`, actualiza `MinigameType`, registro en `main.dart`, factory, docs de minigames y tests.
- Si cambias assets remotos/locales, documenta si la UI espera `Image.asset` o acepta `Image.network`.
