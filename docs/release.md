# Release

Este documento resume el estado para preparar builds. Android y iOS usan el
identificador productivo `com.appytea.appy`, registrado en el proyecto Firebase
`app-autismo-25f44`, que es el entorno de produccion.

## Version

La version vive en `pubspec.yaml`:

```yaml
version: 1.0.0+5
```

Formato:

```text
<versionName>+<buildNumber>
```

Ejemplo:

```text
1.0.1+4
```

## Android

Build APK:

```bash
flutter build apk --release
```

App Bundle:

```bash
flutter build appbundle --release
```

Datos reales:

| Campo | Valor |
| --- | --- |
| `applicationId` | `com.appytea.appy` |
| `namespace` | `com.appytea.appy` |
| `minSdk` | `26` |
| `versionCode` | `flutter.versionCode` |
| `versionName` | `flutter.versionName` |
| Firma release | Llave de subida leida desde `android/key.properties`; sin ese archivo usa la llave debug. |

Antes de publicar Android:

- Confirmar que `android/key.properties` exista y apunte al keystore de subida
  (ver "Firma Android").
- Construir sin `--dart-define=APP_ENV=dev` para que la build use produccion
  y no muestre la banda `DEV`.
- Incrementar `version` en `pubspec.yaml`.
- Ejecutar pruebas manuales de login, modulos, minijuegos, avatar y settings.
- Probar los recordatorios en Android 13 o superior (permiso de notificaciones)
  y tras reiniciar el telefono. Ver `docs/features/settings.md`.
- Probar la descarga de un modulo y su uso sin conexion. Ver
  `docs/features/offline.md`.

### Firma Android

El keystore de subida y sus contrasenas viven fuera del repo. `android/key.properties`
esta ignorado por git y tiene este formato:

```properties
storePassword=<contrasena del keystore>
keyPassword=<contrasena de la llave; en PKCS12 es la misma>
keyAlias=upload
storeFile=/ruta/absoluta/al/upload-keystore.jks
```

Si el archivo no existe, el build release se firma con la llave debug para que
`flutter run --release` funcione. Play Console rechaza esos bundles. Play App
Signing guarda la llave de firma final; la nuestra es solo la de subida. El
keystore y sus contrasenas deben respaldarse en el gestor de contrasenas del
equipo.

## iOS

Build:

```bash
flutter build ios --release
```

Estado actual:

- `PRODUCT_BUNDLE_IDENTIFIER` es `com.appytea.appy` (`com.appytea.appy.RunnerTests`
  para pruebas).
- `lib/firebase_options.dart` tiene `iosBundleId: com.appytea.appy`.
- No existe `ios/Runner/GoogleService-Info.plist`. No hace falta: Firebase se
  inicializa con `DefaultFirebaseOptions`. Solo seria necesario para plugins
  como Crashlytics o Messaging.

Antes de publicar iOS:

- Usar el registro de App Store Connect de `com.appytea.appy`; el registro
  anterior con `com.example.appAutismoUabc` no puede cambiar de bundle id.
- Configurar certificados y provisioning profiles en Xcode.
- Probar inicializacion Firebase en dispositivo/simulador.

## Web

Build:

```bash
flutter build web --release
```

Estado actual:

- `firebase_options.dart` tiene configuracion Web.
- Flutter genera build en `build/web`.

## Desktop

Hay carpetas `linux/`, `macos/` y `windows/`, pero Firebase no esta configurado
para esas plataformas. `DefaultFirebaseOptions.currentPlatform` lanza
`UnsupportedError` en desktop. No considerar desktop listo para release hasta
regenerar FlutterFire y probar inicializacion.

## Icono y splash

Configuracion en:

```text
pubspec.yaml
```

Assets:

```text
assets/images/app_icon.png
assets/images/splash_icon.png
```

Paquetes configurados:

- `flutter_launcher_icons`.
- `flutter_native_splash`.

Despues de cambiar icono o splash, regenerar los archivos nativos con los
comandos de esos paquetes.
