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
| `accesoriosDesbloqueados` | `Set<String>` | Nombres desbloqueados. |

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
| `obtenerBackgroundsDisponibles()` | Lista hardcodeada de rutas de fondo. |

Skins actuales:

| Skin | Imagen base | Expresiones |
| --- | --- | --- |
| `Default` | `assets/images/Skins/DefaultSkin/default.png` | 5 expresiones. |
| `Astronaut` | `assets/images/Skins/Astronaut/astronauta.png` | 3 expresiones. |
| `Chef` | `assets/images/Skins/Chef/chefskin.png` | 4 expresiones. |
| `Dinosaur` | `assets/images/Skins/Dinosaur/dinosaurio.png` | `null`. |
| `Firefighter` | `assets/images/Skins/Firefighter/Bombero.png` | `null`. |
| `Superhero` | `assets/images/Skins/Superhero/Superheroe.png` | `null`. |

Accesorios actuales:

| Accesorio | Bloqueado | Costo |
| --- | --- | --- |
| `Antenitas` | No | 0 |
| `Corona` | Si | 50 |
| `Diadema Joyas` | Si | 75 |
| `Gafas` | No | 0 |
| `Halo Dorado` | Si | 100 |

## Estado inicial

`main.dart` crea el estado inicial antes de registrar providers:

```text
nombre: nombre
felicidad: 64
energia: 92
skinActual: primera skin del repositorio
backgroundActual: assets/images/Skins/DefaultSkin/backgrounds/default.jpg
monedas: 150
accesoriosDesbloqueados: Antenitas, Gafas
```

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
| `_isInitialized` | Evita cargar Firestore varias veces. |
| `_availableSkins` | Cache local del repositorio. |
| `_availableAccesorios` | Cache local del repositorio. |
| `_availableBackgrounds` | Cache local del repositorio. |
| `_firestoreService` | Servicio para `users/{uid}`. |

Getters publicos:

- `showEditPanel`.
- `currentEstado`.
- `availableSkins`.
- `availableAccesorios`.
- `availableBackgrounds`.

## Persistencia Firestore

Ruta:

```text
users/{uid}.avatarConfig
```

`saveAvatarConfigToFirestore()` obtiene el usuario con:

```text
FirebaseAuth.instance.currentUser
```

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
    "accesoriosDesbloqueados": ["Antenitas", "Gafas"]
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

- Si `avatarConfig.nombre` existe, no esta vacio y no es `MRBEAST`, usa ese valor.
- Si no, intenta `user.displayName`.
- Si no, intenta `users/{uid}.name`.
- Si no, conserva `_currentEstado.nombre`.

Si no existe `avatarConfig`, intenta usar displayName o `name`, pero solo guarda
automaticamente si `_currentEstado.nombre == 'MRBEAST'`.

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
| `agregarMonedas(cantidad)` | Suma monedas. |
| `resetEstado(nuevoEstado)` | Reemplaza estado y cierra panel. |

`isAccesorioDesbloqueado(nombreAccesorio)` revisa el set
`currentEstado.accesoriosDesbloqueados`.

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
- Header muestra:
  - cara segun felicidad.
  - nombre.
  - boton editar.
  - felicidad, energia y monedas.
- Panel inferior ocupa 65% de la altura de pantalla.
- Panel contiene secciones horizontales:
  - Skins.
  - Expresiones.
  - Accesorios.
  - Fondos.

Imagen de cara segun felicidad:

| Condicion | Asset |
| --- | --- |
| `felicidad > 70` | `assets/images/FELIZ.png` |
| `felicidad >= 40` | `assets/images/MEH.png` |
| Menor a 40 | `assets/images/TRISTE.png` |

Los textos visibles de esta pantalla estan hardcodeados en espanol. No usan ARB.

## Monedas y progreso

`LevelCompletionService` suma monedas al avatar cuando se completa un nivel:

| Caso | Monedas |
| --- | --- |
| 3 estrellas | 30 |
| 2 estrellas | 20 |
| 1 estrella | 10 |
| Nivel de observacion | 20 |

La suma se hace con:

```text
AvatarViewModel.agregarMonedas(coins)
```

Eso actualiza `avatarConfig.monedas`.

## Reglas de mantenimiento

- Si agregas una skin, agrega assets, actualiza `pubspec.yaml` si hace falta y actualiza `AvatarRepository`.
- Si agregas un accesorio bloqueado, define `nombre`, `imagenPath`, posicion y costo. El nombre es el identificador de desbloqueo.
- Si agregas un campo a `AvatarEstado`, actualiza `copyWith`, guardado Firestore, carga Firestore y `docs/data-model.md`.
- Si cambias el estado inicial en `main.dart`, revisa si el fallback `MRBEAST` sigue teniendo sentido.
- Si internacionalizas `AvatarScreen`, mueve textos hardcodeados a ARB y actualiza `docs/localization.md`.
