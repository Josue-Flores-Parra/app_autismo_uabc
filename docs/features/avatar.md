# Feature: avatar

## Proposito

La feature de avatar permite personalizar el personaje de la app con skin,
expresion, fondo, accesorio, nombre, felicidad, energia y monedas. El catalogo
de opciones es local y hardcodeado; la configuracion elegida por el usuario se
guarda en Firestore dentro de `users/{uid}.avatarConfig`.

## Archivos principales

```text
lib/features/avatar/model/avatar_models.dart
lib/features/avatar/data/avatar_repository.dart
lib/features/avatar/viewmodel/avatar_viewmodel.dart
lib/features/avatar/view/avatar_screen.dart
```

Archivos relacionados:

```text
lib/main.dart
lib/data/services/firestore_services.dart
lib/shared/services/level_completion_service.dart
lib/features/settings/view/settings_page.dart
```

## Modelo

### SkinInfo

Campos:

| Campo | Tipo | Detalle |
| --- | --- | --- |
| `nombre` | `String` | Identificador visible/logico de skin. |
| `imagenBase` | `String` | Ruta de asset principal. |
| `carpetaBackground` | `String` | Ruta base de backgrounds. |
| `expresiones` | `List<String>?` | Rutas de expresiones. Puede ser `null`. |
| `bloqueado` | `bool` | `false` por defecto. Si requiere desbloqueo. |
| `costoMonedas` | `int` | `0` por defecto. Monedas necesarias. |

### FondoInfo

Campos:

| Campo | Tipo | Detalle |
| --- | --- | --- |
| `path` | `String` | Ruta del asset de fondo. |
| `bloqueado` | `bool` | `false` por defecto. Si requiere desbloqueo. |
| `costoMonedas` | `int` | `0` por defecto. Monedas necesarias. |

Los fondos se eligen sueltos: no estan atados a la skin activa, cualquier
fondo desbloqueado se puede usar con cualquier skin.

### AccesorioGeneral

Campos:

| Campo | Tipo | Default | Detalle |
| --- | --- | --- | --- |
| `nombre` | `String` | requerido | Identificador usado para desbloqueo. |
| `imagenPath` | `String` | requerido | Ruta de asset. |
| `top` | `double` | `-20` | Posicion vertical al superponer. |
| `left` | `double?` | `null` | Si es `null`, queda centrado por el Stack. |
| `width` | `double` | `280` | Ancho del accesorio. |
| `height` | `double` | `280` | Alto del accesorio. |
| `bloqueado` | `bool` | `false` | Si requiere desbloqueo. |
| `costoMonedas` | `int` | `0` | Monedas necesarias. |

### AvatarEstado

Campos:

| Campo | Tipo | Detalle |
| --- | --- | --- |
| `skinActual` | `SkinInfo` | Skin activa. |
| `expresionActual` | `String?` | Ruta de expresion activa. |
| `accesorioActual` | `AccesorioGeneral?` | Accesorio activo. |
| `backgroundActual` | `String` | Ruta del fondo activo. |
| `nombre` | `String` | Nombre mostrado. |
| `felicidad` | `int` | Valor 0..100 cuando se actualiza por ViewModel. |
| `energia` | `int` | Valor 0..100 cuando se actualiza por ViewModel. |
| `monedas` | `int` | Monedas actuales. Default del modelo: 100. |
| `accesoriosDesbloqueados` | `Set<String>` | Nombres de accesorios desbloqueados. |
| `skinsDesbloqueadas` | `Set<String>` | Nombres de skins desbloqueadas. |
| `fondosDesbloqueados` | `Set<String>` | Rutas de fondos desbloqueados. |

`copyWith()` permite resetear expresion/accesorio con flags:

- `resetExpresion`.
- `resetAccesorio`.

## Catalogo local

Archivo:

```text
lib/features/avatar/data/avatar_repository.dart
```

`AvatarRepository` expone solo metodos estaticos:

| Metodo | Devuelve |
| --- | --- |
| `obtenerSkinsDisponibles()` | Lista hardcodeada de `SkinInfo`. |
| `obtenerAccesoriosGenerales()` | Lista hardcodeada de `AccesorioGeneral`. |
| `obtenerFondosDisponibles()` | Lista hardcodeada de `FondoInfo`. |

Skins actuales:

| Skin | Imagen base | Expresiones | Bloqueada | Costo |
| --- | --- | --- | --- | --- |
| `Default` | `assets/images/Skins/DefaultSkin/default.png` | 5 expresiones. | No | 0 |
| `Astronaut` | `assets/images/Skins/Astronaut/astronauta.png` | 3 expresiones. | Si | 60 |
| `Chef` | `assets/images/Skins/Chef/chefskin.png` | 4 expresiones. | Si | 70 |
| `Dinosaur` | `assets/images/Skins/Dinosaur/dinosaurio.png` | `null`. | Si | 80 |
| `Firefighter` | `assets/images/Skins/Firefighter/Bombero.png` | `null`. | Si | 90 |
| `Superhero` | `assets/images/Skins/Superhero/Superheroe.png` | `null`. | Si | 100 |

Accesorios actuales:

| Accesorio | Bloqueado | Costo |
| --- | --- | --- |
| `Antenitas` | No | 0 |
| `Corona` | Si | 50 |
| `Diadema Joyas` | Si | 75 |
| `Gafas` | No | 0 |
| `Halo Dorado` | Si | 100 |

Fondos: solo `DefaultSkin/backgrounds/default.jpg` viene gratis; los otros 9
(Astronaut, Chef, Dinosaur, Firefighter, Superhero, dos por skin salvo Chef)
cuestan 25 monedas cada uno.

## Estado inicial

`AvatarEstado.inicial(skin:)` es la unica fuente del estado de arranque; lo
usan `main.dart` (estado del provider antes de cargar) y `AuthService`
(documento `avatarConfig` que se escribe al registrar la cuenta):

```text
nombre: Appy
felicidad: 100
energia: 100
skinActual: primera skin del repositorio
backgroundActual: assets/images/Skins/DefaultSkin/backgrounds/default.jpg
monedas: 0
accesoriosDesbloqueados: Antenitas, Gafas
skinsDesbloqueadas: Default
fondosDesbloqueados: assets/images/Skins/DefaultSkin/backgrounds/default.jpg
```

Cuentas creadas antes de que skins y fondos tuvieran costo no traen estas dos
listas en Firestore. `loadAvatarConfigFromFirestore()` las rellena al vuelo
con lo que esa cuenta ya tenia puesto (`skinActual`/`backgroundActual`), para
no bloquearle a nadie algo que ya estaba usando.

`AvatarViewModel.isLoaded` es `false` hasta que `initialize()` leyo
`users/{uid}`. Mientras tanto la pantalla muestra `—` en felicidad, energia y
monedas, y la cara feliz; nunca cifras inventadas. Un guardado antes de cargar
se ignora para no pisar el documento real con valores por defecto.

Luego registra:

```text
ChangeNotifierProxyProvider<AuthViewModel, AvatarViewModel>
```

En `update`, si `auth.currentUser != null`, llama `avatarVM.initialize()`.

## AvatarViewModel

Archivo:

```text
lib/features/avatar/viewmodel/avatar_viewmodel.dart
```

Estado privado:

| Campo | Uso |
| --- | --- |
| `_showEditPanel` | Controla si el panel inferior de edicion esta visible. |
| `_currentEstado` | Estado actual del avatar. |
| `_estadoInicial` | Estado con el que se construyo el viewmodel; se reusa cuando entra otra cuenta. |
| `_loadedUid` | uid cuya configuracion ya se leyo. Mientras sea `null` no se escribe nada en Firestore. |
| `_isLoading` | Evita cargas concurrentes. |
| `_energiaActualizadaEn` | Momento del ultimo calculo de energia; base del descanso. |
| `_availableSkins` | Cache local del repositorio. |
| `_availableAccesorios` | Cache local del repositorio. |
| `_availableFondos` | Cache local del repositorio. |
| `_firestoreService` | Servicio para `users/{uid}`. |

Getters publicos:

- `showEditPanel`.
- `currentEstado`.
- `availableSkins`.
- `availableAccesorios`.
- `availableFondos`.

## Persistencia Firestore

Ruta:

```text
users/{uid}.avatarConfig
```

`saveAvatarConfigToFirestore()` obtiene el usuario con:

```text
FirebaseAuth.instance.currentUser
```

y no escribe si `_loadedUid` no coincide con ese uid. Esa guarda es la que
evita el bug de monedas: antes, una escritura disparada antes de terminar la
carga sobrescribia las monedas reales con el estado inicial hardcodeado, de modo
que un saldo de varios cientos volvia a `150` mas la recompensa recien ganada.

`initialize()` tambien detecta el cambio de cuenta: si entra otro uid, vuelve al
estado inicial antes de cargar, para no heredar monedas ni accesorios.

Si no hay usuario, lanza excepcion. Si hay usuario, guarda:

```json
{
  "avatarConfig": {
    "nombre": "...",
    "felicidad": 64,
    "energia": 92,
    "skinActual": "Default",
    "expresionActual": "assets/...",
    "accesorioActualPath": "assets/...",
    "backgroundActual": "assets/...",
    "monedas": 150,
    "accesoriosDesbloqueados": ["Antenitas", "Gafas"],
    "skinsDesbloqueadas": ["Default"],
    "fondosDesbloqueados": ["assets/.../default.jpg"]
  }
}
```

La escritura usa `FirestoreService.setUserData`, por lo que hace merge en
`users/{uid}`.

Nota de arquitectura: este ViewModel usa `FirebaseAuth.instance` directamente.
No pasa por `AuthService`.

## Carga desde Firestore

`loadAvatarConfigFromFirestore()`:

1. Toma `FirebaseAuth.instance.currentUser`.
2. Si no hay usuario, retorna sin cambiar estado.
3. Lee `users/{uid}` con `FirestoreService.getUserData`.
4. Si existe `avatarConfig`, reconstruye:
   - skin por `skinActual`.
   - expresion por path.
   - accesorio por `accesorioActualPath`.
   - background por path.
   - nombre, felicidad, energia, monedas y desbloqueados.
5. Si no encuentra skin/accesorio, usa fallback seguro.
6. Llama `notifyListeners()`.

Fallback de nombre:

- Si `avatarConfig.nombre` existe, no esta vacio y no es el valor por defecto `nombre`, usa ese valor.
- Si no, intenta `user.displayName`.
- Si no, intenta `users/{uid}.name`.
- Si no, conserva `_currentEstado.nombre`.

Si no existe `avatarConfig`, intenta usar displayName o `name`, pero solo guarda
automaticamente si `_currentEstado.nombre == 'nombre'`.

## Operaciones de personalizacion

Cada metodo actualiza estado local, llama `notifyListeners()` y luego intenta
guardar en Firestore:

| Metodo | Efecto |
| --- | --- |
| `toggleEditPanel()` | Abre/cierra panel inferior. No guarda Firestore. |
| `updateSkin(newSkin)` | Cambia skin y limpia expresion. |
| `updateExpresion(expresion)` | Cambia o limpia expresion. |
| `updateAccesorio(accesorio)` | Cambia o limpia accesorio. |
| `updateBackground(background)` | Cambia fondo. |
| `updateNombre(nuevoNombre)` | Cambia nombre y guarda. |
| `updateNombreDesdeDisplayName(nuevoNombre)` | Sincroniza nombre desde cuenta; si falla Firestore, conserva estado local. |
| `updateFelicidad(nuevaFelicidad)` | Valida 0..100; si no, lanza `ArgumentError`. |
| `updateEnergia(nuevaEnergia)` | Valida 0..100; si no, lanza `ArgumentError`. |
| `desbloquearAccesorio(accesorio)` | Descuenta monedas si alcanza y agrega nombre al set. |
| `desbloquearSkin(skin)` | Igual, para skins. |
| `desbloquearFondo(fondo)` | Igual, para fondos. |
| `agregarMonedas(cantidad)` | Suma monedas. |
| `registrarActividad({success, monedas, esRepaso})` | Efecto de una actividad terminada: sube felicidad, sube o baja energia y suma monedas en un solo guardado. Devuelve `AvatarActivityDelta` (cuanto subio/bajo cada estadistica). |
| `resetEstado(nuevoEstado)` | Reemplaza estado y cierra panel. |

Los metodos que tocan la economia (`registrarActividad`, `agregarMonedas`,
`desbloquearAccesorio`/`desbloquearSkin`/`desbloquearFondo`, `updateNombre`)
esperan a `initialize()` antes de aplicar el cambio, para no calcular sobre un
estado que todavia no se leyo.

## Felicidad y energia

No son valores fijos ni de una sola direccion:

| Evento | Felicidad | Energia |
| --- | --- | --- |
| Actividad completada con exito (primera vez) | +5 | -4 |
| Actividad intentada sin exito | +1 | -4 |
| Repaso: modalidad que el nivel ya tenia completada | +1 | +3 |
| Tiempo sin jugar | -1 cada 15 min (piso 30) | +1 cada 6 min (techo 100) |

`esRepaso` lo decide `LevelCompletionService._persistActivity`: es `true`
cuando la modalidad (video/pictograma/minijuego de ese nivel) ya estaba en
`completedActivities` antes de este intento. Un repaso no cansa al personaje,
lo ayuda a descansar, y sigue dando monedas (`_repasoCoins`, ver
`docs/features/learning-module.md`) aunque menos que la primera vez: repetir
tiene que seguir valiendo la pena o nadie vuelve a ver un video ya visto.

Ambos valores se limitan a 0..100 y se persisten en `avatarConfig`. Los dos
calculos (descanso de energia, decaimiento de felicidad) comparten la misma
marca `energiaActualizadaEn`; esa marca avanza en cada `registrarActividad` y
en cada carga, para no contar dos veces el mismo intervalo. La felicidad tiene
un piso de 30 por simple paso del tiempo: fallar o no abrir la app no debe
sentirse como un castigo, asi que la inactividad la baja hasta "serio", nunca
hasta "triste".

`AvatarActivityDelta` (mismo archivo) trae `felicidad` y `energia`: son los
numeros nominales del evento (no el resultado final tras aplicar clamp), para
mostrarlos en el dialogo de resultado con `LevelCompletionService.statsSummary`.

`isAccesorioDesbloqueado(nombreAccesorio)` / `isSkinDesbloqueada(nombreSkin)` /
`isFondoDesbloqueado(path)` revisan los sets correspondientes de
`currentEstado`.

## AvatarScreen

Archivo:

```text
lib/features/avatar/view/avatar_screen.dart
```

Mecanica visual:

- Usa `Consumer<AvatarViewModel>`.
- Usa el `backgroundActual` como `DecorationImage`.
- Dibuja skin base con `Image.asset`.
- Si hay `expresionActual`, dibuja otra imagen encima.
- Si hay `accesorioActual`, lo dibuja con `Positioned` usando `top`, `left`, `width` y `height`.
- Header muestra, en pastillas de vidrio (`_buildButton`):
  - cara segun felicidad (`_buildFaceButton`).
  - nombre; tocarlo abre el dialogo para renombrar al robot (`_buildNameButton`).
  - boton editar.
  - felicidad, energia y monedas (`_buildStatButton`, muestra `—` si `isLoaded` es `false`).
- Panel inferior ocupa 65% de la altura de pantalla.
- Panel contiene secciones horizontales:
  - Skins.
  - Expresiones.
  - Accesorios.
  - Fondos.
- Skins, accesorios y fondos bloqueados comparten un mismo patron: candado +
  precio (`_buildPrecioBadge`) sobre la miniatura, y tocarla abre un dialogo
  con imagen, costo y saldo actual (`_mostrarDialogoDesbloqueoSkin` /
  `_mostrarDialogoDesbloqueo` / `_mostrarDialogoDesbloqueoFondo`). Es el mismo
  patron en las tres listas a proposito: se aprende una vez y funciona igual
  en todos lados, pensado para que sea entendible incluso para el grado de
  TEA con menos tolerancia a interfaces complejas.

Imagen de cara segun felicidad:

| Condicion | Asset |
| --- | --- |
| `felicidad > 70` o aun no cargado | `assets/images/presets/FELIZ.png` |
| `felicidad >= 40` | `assets/images/presets/MEH.png` |
| Menor a 40 | `assets/images/presets/TRISTE.png` |

Los textos visibles de esta pantalla estan hardcodeados en espanol. No usan ARB.

## Monedas y progreso

`LevelCompletionService._persistActivity` calcula las monedas de cada
modalidad completada y las aplica junto con felicidad/energia en una sola
llamada a `AvatarViewModel.registrarActividad`, no con `agregarMonedas`
directo. Ver la tabla completa de recompensas (primera vez vs repaso) en
`docs/features/learning-module.md`, seccion `LevelCompletionService`.

`agregarMonedas(cantidad)` sigue existiendo como suma directa, para casos que
no pasan por `LevelCompletionService`.

## Reglas de mantenimiento

- Si agregas una skin, agrega assets, actualiza `pubspec.yaml` si hace falta, decide si va bloqueada y con que costo, y actualiza `AvatarRepository`.
- Si agregas un fondo, decide si va bloqueado y con que costo en `obtenerFondosDisponibles()`.
- Si agregas un accesorio bloqueado, define `nombre`, `imagenPath`, posicion y costo. El nombre es el identificador de desbloqueo.
- Los costos de skins/fondos/accesorios deben ser alcanzables con uso normal de la app, no triviales: la meta es que le tome tiempo real al nino, sin volverse inaccesible.
- Si agregas un campo a `AvatarEstado`, actualiza `copyWith`, guardado Firestore, carga Firestore y `docs/data-model.md`.
- Si cambias el estado inicial en `main.dart`, revisa si el fallback `MRBEAST` sigue teniendo sentido.
- Si internacionalizas `AvatarScreen`, mueve textos hardcodeados a ARB y actualiza `docs/localization.md`.
