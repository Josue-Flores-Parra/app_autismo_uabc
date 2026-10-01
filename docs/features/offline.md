# Contenido sin conexion

Permite descargar un modulo al telefono para usarlo sin internet. Resuelve el
issue #141: hay familias sin conexion estable y el contenido (videos,
pictogramas, audio e imagenes de los minijuegos) vive en Firebase Storage.

## Alcance

- La descarga es por modulo, desde `Ajustes > Privacidad y datos > Contenido sin
  conexion` (`DownloadsScreen`). Esa pantalla queda detras del PIN de la cuenta.
- Descarga todo lo que usan los niveles del modulo: `pictogramaUrl`, `videoUrl`,
  `puzzleImageUrl`, `audioUrl` y cualquier URL dentro de `actividadData` (pools,
  pasos y preguntas). La lista sale de `collectLevelAssetUrls`
  (`lib/features/learning_module/model/levels_models.dart`).
- Es opcional. Sin descarga, la app funciona como antes, por red.
- Hace falta conexion para iniciar sesion la primera vez y para descargar.

## Piezas

| Pieza | Archivo | Responsabilidad |
| --- | --- | --- |
| `OfflineAssetsService` | `lib/data/services/offline_assets_service.dart` | Unico punto que toca red y disco para este contenido. Descarga, valida, borra y responde "donde esta este archivo". |
| `OfflineManifest` | `lib/data/models/offline_manifest.dart` | Lista por modulo de URL original, nombre local y bytes. |
| `DownloadsViewModel` | `lib/features/offline/viewmodel/downloads_viewmodel.dart` | Estado de cada modulo y acciones descargar y borrar. Lee el catalogo de Firestore por su cuenta: la pantalla vive en la zona del padre, donde `LearningViewModel` no tiene perfil activo. |
| `DownloadsScreen` | `lib/features/offline/view/downloads_screen.dart` | Lista de modulos con estado, progreso, errores y boton de borrar. |

## Almacenamiento

```text
<application support>/offline_assets/<moduleId>/
|-- manifest.json
|-- <hash de 64 bits de la URL><extension>
`-- ...
```

- Se usa el directorio de soporte de la app, no el temporal, para que el sistema
  no lo limpie. "Limpiar cache de recursos" de Ajustes no lo toca.
- `manifest.json` guarda por cada archivo la URL remota original, el nombre local
  y el tamano. Los lectores buscan por la misma URL que ya traen los niveles.
- Cada archivo se escribe en un `.part` y se renombra solo al terminar, asi un
  corte nunca deja un archivo a medias que parezca valido.

## Descarga

- Los archivos se piden uno por uno, para no abrir muchas conexiones a la vez
  contra Firebase Storage (ver el comentario de pines en `LearningViewModel`).
- Si un archivo ya esta completo (existe y su tamano coincide con el manifiesto)
  no se vuelve a bajar. Reintentar un modulo solo pide lo que falta.
- Integridad: la respuesta debe ser 200, no vacia y, si el servidor declara
  `Content-Length`, los bytes recibidos deben coincidir. Si no, se descarta el
  `.part`.
- Errores y reintentos: hasta 2 reintentos (1 s y 3 s) para fallas de red y
  archivos incompletos. No se reintenta un 404 u otro rechazo permanente, ni la
  falta de espacio. El plazo por solicitud y por bloque de datos es de 30 s.
- Falta de espacio: se reconoce el error del sistema (`ENOSPC`) y la pantalla
  muestra "No hay espacio suficiente en el telefono".
- Lo que ya se guardo antes de un error queda disponible; el manifiesto se
  escribe aunque la descarga falle a la mitad.

### Compresion

No se recomprime nada en reposo: los videos (mp4), las imagenes (png y jpg) y el
audio ya son formatos comprimidos, recomprimirlos casi no ahorra espacio y
obligaria a descomprimir antes de reproducir, porque `video_player` y
`just_audio` leen el archivo directo. La transferencia si viaja comprimida
cuando el servidor lo permite: el cliente HTTP negocia gzip y descomprime solo.
Si el equipo decide una compresion propia, el punto de cambio es
`OfflineAssetsService._downloadFile`.

## Lectura

El servicio se inicia en `main.dart` (`OfflineAssetsService.instance.init()`),
que lee los manifiestos y descarta del indice los archivos que ya no existen o
cambiaron de tamano. Si falla, la app sigue por red.

| Contenido | Donde se usa el archivo local |
| --- | --- |
| Videos | `VideoControllerManager.getOrCreateController` usa `VideoPlayerController.file`. |
| Audio | `AudioViewModel.initialize` usa `setFilePath`. |
| Imagenes | `OfflineAssetsService.imageProvider(url)` devuelve `FileImage` si esta descargada y `NetworkImage` si no. Lo usan los widgets que antes llamaban `Image.network` o `NetworkImage`. |
| Pictogramas | `PictogramMinigame` consulta primero el archivo descargado, antes de su propio cache temporal. |

`LearningViewModel._tryPin` no fija en memoria las imagenes ya descargadas: salen
del disco.

## Escrituras a Firestore sin conexion

Con Firestore sin conexion, el `Future` de una escritura no termina hasta que el
servidor confirma, aunque el dato ya este en la cola local. Si la app lo esperaba
sin limite, el resultado de una actividad nunca aparecia. `FirestoreService` ahora
espera la confirmacion solo 3 s (`_queuedWrite`): si responde, los errores se
propagan como antes; si no, la escritura sigue en cola y se envia sola al volver
la red. Aplica a `setUserData` y `updateUserLevelProgress`, que son las escrituras
de avatar, monedas y progreso de niveles.

## Pruebas

- `test/offline_assets_service_test.dart`: descarga, omision de lo completo,
  archivo truncado, reintentos, 404, espera agotada, falta de espacio, lectura al
  iniciar y borrado.
- `test/level_asset_urls_test.dart`: recoleccion de URLs de los niveles.

## Pendiente

- Los datos de los niveles (titulos, URLs) y el progreso siguen viniendo de
  Firestore. Un modulo nunca abierto con internet no tiene sus niveles en la
  cache de Firestore y no se puede descargar sin conexion.
- No hay deteccion de conectividad ni descarga automatica al tener Wi-Fi.

## Arranque sin conexion

Los perfiles se leen con `get()`, que sale de la cache de Firestore. Una
transaccion exige servidor, por eso `ProfileRepository.ensureParent` solo la
corre si la cuenta aun necesita correccion. La cache se llena la primera vez que
la cuenta inicia sesion con red: sin ese primer inicio no hay nada que leer.
