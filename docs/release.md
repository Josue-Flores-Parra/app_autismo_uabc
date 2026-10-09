# Release

Este documento resume el estado para preparar builds. Android y iOS usan el
identificador productivo `com.appytea.appy`, registrado en el proyecto Firebase
`app-autismo-25f44`, que es el entorno de produccion.

## Version

La version vive en `pubspec.yaml`:

```yaml
version: 1.0.0+6
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
flutter build ipa --release
```

Sube `build/ios/ipa/*.ipa` con Transporter, o abre
`build/ios/archive/Runner.xcarchive` en el Organizer de Xcode. No archives
directo desde Xcode sin este comando: Xcode toma un numero de build viejo.

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
- Verificar que el `.ipa` tenga `NSMicrophoneUsageDescription` (ver abajo).
- Cada subida necesita un numero de build mayor, aunque la anterior haya sido
  rechazada al procesarse.
- Configurar certificados y provisioning profiles en Xcode.
- Probar inicializacion Firebase en dispositivo/simulador.

### Microfono

La app no graba audio, pero `audio_session` (dependencia de `just_audio`)
incluye llamadas al microfono, y App Store exige `NSMicrophoneUsageDescription`
si estan en el binario (ITMS-90683), aunque nunca se ejecuten.

`ios/Runner/Info.plist` incluye esa descripcion. La app nunca pide el permiso,
asi que el usuario no la ve. No quitarla mientras la app dependa de
`audio_session`.

La bandera `AUDIO_SESSION_MICROPHONE=0` del plugin (en `ios/Podfile` para
CocoaPods) no basta con Swift Package Manager, que es lo que usa Flutter por
omision: Xcode guarda en cache la evaluacion de `Package.swift` y no ve la
variable de entorno. Por eso se usa la descripcion.

Comprobacion del `.ipa` en macOS; debe imprimir la descripcion:

```bash
rm -rf /tmp/ipa-check && mkdir /tmp/ipa-check
unzip -q build/ios/ipa/*.ipa -d /tmp/ipa-check
plutil -p /tmp/ipa-check/Payload/Runner.app/Info.plist | grep NSMicrophoneUsageDescription
```

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
