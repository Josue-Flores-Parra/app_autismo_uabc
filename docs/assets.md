# Assets

La app usa imagenes, audio, video, iconos SVG/PNG y assets de skins. Algunas
rutas vienen de Firestore y pueden ser URLs remotas o paths locales. Cuando una
pantalla usa `Image.asset`, el valor debe ser un asset local; cuando usa
`Image.network`, puede ser URL remota.

## Carpetas

```text
assets/
|-- audio/
|-- icons/
|-- images/
|   |-- LevelBGs/
|   `-- Skins/
|-- imgs/
|-- pictogramas/
`-- videos/
```

## Declaracion en pubspec

`pubspec.yaml` declara entradas amplias y rutas especificas:

```yaml
assets:
  - assets/
  - assets/images/
  - assets/images/LevelBGs/Alimentacion/AlimentacionModuloBG.png
  - assets/images/LevelBGs/Socializar/SocializarModuloBG.png
  - assets/images/LevelBGs/Higiene/HigieneModuloBG.png
  - assets/images/Skins/
  - assets/images/Skins/accesorios generales/
  - assets/images/Skins/DefaultSkin/
  - assets/images/Skins/DefaultSkin/backgrounds/
  - assets/images/Skins/DefaultSkin/expresions/
  - assets/images/Skins/Astronaut/
  - assets/images/Skins/Astronaut/backgrounds/
  - assets/images/Skins/Astronaut/expresions/
  - assets/images/Skins/Chef/
  - assets/images/Skins/Chef/backgrounds/
  - assets/images/Skins/Chef/expresions/
  - assets/images/Skins/Dinosaur/
  - assets/images/Skins/Dinosaur/backgrounds/
  - assets/images/Skins/Firefighter/
  - assets/images/Skins/Firefighter/backgrounds/
  - assets/images/Skins/Superhero/
  - assets/images/Skins/Superhero/backgrounds/
  - assets/icons/
  - assets/imgs/
  - assets/videos/
  - assets/audio/
```

Hay carpetas con archivos que no aparecen como entrada especifica, por ejemplo
`assets/pictogramas/` y `assets/images/LevelBGs/Dormir/`. Estan bajo la entrada
amplia `assets/`, pero si se reduce esa declaracion en el futuro hay que agregar
esas rutas explicitamente.

## Imagenes base de UI

Archivos usados en pantallas principales:

| Asset | Uso |
| --- | --- |
| `assets/images/salute.png` | Avatar de login sin error. |
| `assets/images/icon-questionmark2x.png` | Avatar de login/registro con pregunta/error. |
| `assets/images/icon-questionmark.png` | Placeholder de seleccion simple. |
| `assets/images/icon-salute-hidden.png` | Placeholder de seleccion simple. |
| `assets/images/icon-salute-hidden2x.png` | LoadingScreen. |
| `assets/images/CARITAROBOT.png` | Header de modulos. |
| `assets/images/appysittin.png` | Indicador de nodo activo en timeline. |
| `assets/images/FELIZ.png` | Cara feliz del avatar. |
| `assets/images/MEH.png` | Cara neutral del avatar. |
| `assets/images/TRISTE.png` | Cara triste del avatar. |
| `assets/images/app_icon.png` | Fuente de icono de launcher. |
| `assets/images/splash_icon.png` | Fuente de splash. |
| `assets/images/forgot-password.png` | Imagen del flujo de recuperacion de contrasena (`ForgotPasswordScreen`). |

Tambien existe `assets/pictogramas/appysittin.png`, pero el timeline usa
`assets/images/appysittin.png`.

## Skins del avatar

Carpeta:

```text
assets/images/Skins/
```

Catalogo conectado:

| Skin | Imagen base | Backgrounds | Expresiones |
| --- | --- | --- | --- |
| Default | `DefaultSkin/default.png` | `DefaultSkin/backgrounds/default.jpg` | `CALMADO.png`, `curioso.png`, `emocionado.png`, `FELIZ.png`, `pensativo.png` |
| Astronaut | `Astronaut/astronauta.png` | `espacio.jpg`, `espacio2.jpg` | `expastron.png`, `expastron2.png`, `expastron3.png` |
| Chef | `Chef/chefskin.png` | `cocina.jpg` | `expchef.png`, `expchef2.png`, `expchef3.png`, `expchef4.png` |
| Dinosaur | `Dinosaur/dinosaurio.png` | `prehistoria.jpg`, `prehistoria2.jpg` | ninguna |
| Firefighter | `Firefighter/Bombero.png` | `departamento_bomberos.jpg`, `departamento_bomberos2.jpg` | ninguna |
| Superhero | `Superhero/Superheroe.png` | `superbase.jpg`, `superbase2.jpg` | ninguna |

Accesorios conectados en `AvatarRepository.obtenerAccesoriosGenerales()`:

```text
assets/images/Skins/accesorios generales/antenitas.png
assets/images/Skins/accesorios generales/corona.png
assets/images/Skins/accesorios generales/diademajoyas.png
assets/images/Skins/accesorios generales/gafas.png
assets/images/Skins/accesorios generales/halodorado.png
```

Assets existentes pero no conectados al catalogo actual de accesorios:

```text
assets/images/Skins/DefaultSkin/accessories/audifonos.png
assets/images/Skins/DefaultSkin/accessories/chef.png
assets/images/Skins/DefaultSkin/accessories/construccion.png
assets/images/Skins/DefaultSkin/accessories/flowers.png
assets/images/Skins/DefaultSkin/accessories/gorra.png
assets/images/Skins/DefaultSkin/accessories/sleephat.png
```

## Assets de modulos y niveles

Fondos de modulo existentes:

```text
assets/images/LevelBGs/Alimentacion/AlimentacionModuloBG.png
assets/images/LevelBGs/Dormir/DormirModuloBG.png
assets/images/LevelBGs/Socializar/SocializarModuloBG.png
assets/images/LevelBGs/Higiene/HigieneModuloBG.png
```

Fondos/imagenes de pasos de Higiene:

```text
assets/images/LevelBGs/Higiene/StepsBGs/LavadoDeManos.jpg
assets/images/LevelBGs/Higiene/StepsBGs/UsoDesodorante.jpg
assets/images/LevelBGs/Higiene/StepsBGs/CuidadoCabello.jpg
assets/images/LevelBGs/Higiene/StepsBGs/CambioDeRopa.jpg
assets/images/LevelBGs/Higiene/StepsBGs/UsodelInodoro.jpg
assets/images/LevelBGs/Higiene/StepsBGs/RUTINADIARIA.jpg
assets/images/LevelBGs/Higiene/StepsBGs/BanoCorporal.jpg
assets/images/LevelBGs/Higiene/StepsBGs/CuidadoZapatos.jpg
assets/images/LevelBGs/Higiene/StepsBGs/CepilladoDeDientes.jpg
assets/images/LevelBGs/Higiene/StepsBGs/CorteDeUnas.jpg
```

`ModuleListScreen` usa `Image.asset(modulo.imagenPath)`, por lo que
`modules/{moduleId}.imagenUrl` debe ser path local si se usa en esa pantalla.

`LevelTimelineScreen` usa `Image.asset(backgroundImagePath)` para
`lvlBackgroundImageUrl`, por lo que ese campo tambien debe ser path local.

En cambio, `pictogramaUrl`, `videoUrl`, `audioUrl` y `puzzleImageUrl` pueden ser
URL remota o asset local segun el widget/minijuego que los consuma.

## Iconos y previews

Iconos de reproductor:

```text
assets/icons/fullscreen.svg
assets/icons/replay.svg
assets/icons/playbuttoncontroller.svg
assets/icons/pausebutton.svg
assets/icons/playbigbutton.svg
assets/icons/pausebigbutton.svg
```

Iconos de tipo de minijuego:

```text
assets/icons/minigame_video.png
assets/icons/minigame_video.svg
assets/icons/minigame_pictogram.png
assets/icons/minigame_simple_selection.png
assets/icons/minigame_simple_selection.svg
```

Preview conectado:

```text
assets/imgs/simple_selection_preview.png
```

`PopupPreview` usa siempre `simple_selection_preview.png` para minijuegos de
seleccion simple.

## Audio

Archivos reales:

| Asset | Uso |
| --- | --- |
| `assets/audio/celebration.mp3` | `CelebrationHelper` al completar minijuegos/video. |
| `assets/audio/negative_beeps.mp3` | Feedback negativo en `SimpleSelectionMinigame`. |
| `assets/audio/lavado_manos_completo.mp3` | Audio local disponible para niveles/minijuegos si Firestore lo referencia. |

## Video

Archivo local real:

```text
assets/videos/dog.mp4
```

Los reproductores tambien aceptan URLs remotas.

## Icono y splash

Configuracion en `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/app_icon.png"

flutter_native_splash:
  color: "#1A3D52"
  image: "assets/images/splash_icon.png"
  android: true
  ios: true
```

Despues de cambiar esos assets, regenerar con los paquetes configurados.

## Reglas de mantenimiento

- Si Firestore va a guardar una ruta local, confirmar que la pantalla use `Image.asset` o equivalente.
- Si Firestore va a guardar URL remota, confirmar que el widget soporte `http/https`.
- No renombrar assets ya referenciados desde Firestore sin migrar documentos.
- Si agregas una skin/accesorio/background, actualizar `AvatarRepository`.
- Si agregas icono de minijuego, actualizar `RadialFocusPreviewSelector` o `PopupPreview` si aplica.
- Si quitas la entrada amplia `assets/` de `pubspec.yaml`, declara explicitamente todas las subcarpetas usadas.
