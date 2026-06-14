# Release

Este documento resume el estado para preparar builds. El repo no tiene
configuracion completa de release productivo: Android release firma con debug e
iOS no incluye `GoogleService-Info.plist`.

## Version

La version vive en `pubspec.yaml`:

```yaml
version: 1.0.0+3
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
| `applicationId` | `com.example.app_autismo_uabc` |
| `namespace` | `com.example.app_autismo_uabc` |
| `minSdk` | `26` |
| `versionCode` | `flutter.versionCode` |
| `versionName` | `flutter.versionName` |
| Firma release | Actualmente usa debug signing config. |

Antes de publicar Android:

- Cambiar `applicationId` si se requiere ID productivo.
- Configurar firma release fuera del repo.
- Confirmar `android/app/google-services.json`.
- Incrementar `version` en `pubspec.yaml`.
- Ejecutar pruebas manuales de login, modulos, minijuegos, avatar y settings.

## iOS

Build:

```bash
flutter build ios --release
```

Estado actual:

- `lib/firebase_options.dart` tiene `iosBundleId: com.example.appAutismoUabc`.
- No existe `ios/Runner/GoogleService-Info.plist` en el repo.

Antes de publicar iOS:

- Agregar/generar `ios/Runner/GoogleService-Info.plist`.
- Confirmar bundle id con Firebase.
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
