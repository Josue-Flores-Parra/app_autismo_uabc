# Configuracion local

Este documento explica como preparar el entorno de desarrollo para ejecutar la
app Flutter actual.

## Requisitos

- Flutter con Dart compatible con `sdk: ^3.9.2`.
- Android Studio o Visual Studio Code con plugins Flutter/Dart.
- Un dispositivo fisico o emulador Android para el camino mas directo.
- Para iOS: Xcode y configuracion Firebase iOS adicional, porque `ios/Runner/GoogleService-Info.plist` no esta en el repo.
- Firebase CLI y FlutterFire CLI solo si vas a regenerar configuracion Firebase.

Dependencias relevantes:

- `firebase_core`, `firebase_auth`, `cloud_firestore`.
- `provider`.
- `video_player`, `just_audio`, `audio_session`, `flutter_tts`.
- `shared_preferences`.
- `confetti`, `url_launcher`, `package_info_plus`.

## Instalacion inicial

Desde la raiz del repositorio:

```bash
flutter pub get
```

## Ejecucion de la app

Listar dispositivos:

```bash
flutter devices
```

Ejecutar en el dispositivo disponible:

```bash
flutter run
```

Ejemplos por plataforma:

```bash
flutter run -d android
flutter run -d chrome
```

Android es la plataforma mejor configurada en el repo porque existe
`android/app/google-services.json` y `android/app/build.gradle.kts` aplica
`com.google.gms.google-services`.

## Firebase local

La app inicializa Firebase en `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Proyecto configurado:

```text
app-autismo-25f44
```

Archivos reales:

| Archivo | Estado |
| --- | --- |
| `firebase.json` | Metadata de FlutterFire. |
| `lib/firebase_options.dart` | Opciones para Android, iOS y Web. |
| `android/app/google-services.json` | Presente. |
| `ios/Runner/GoogleService-Info.plist` | Ausente. |

Si necesitas regenerar Firebase:

```bash
flutterfire configure
```

Despues revisa que no se haya agregado configuracion que contradiga
`docs/firebase.md`.

## Android

Datos de `android/app/build.gradle.kts`:

| Campo | Valor |
| --- | --- |
| `namespace` | `com.example.app_autismo_uabc` |
| `applicationId` | `com.example.app_autismo_uabc` |
| `minSdk` | `26` |
| `compileOptions` | Java 11 |
| `kotlinOptions.jvmTarget` | Java 11 |
| Release signing | Usa `signingConfigs.getByName("debug")` actualmente. |

Si Android falla por Firebase, primero confirma:

```text
android/app/google-services.json
```

## iOS

`lib/firebase_options.dart` tiene opciones iOS con:

```text
iosBundleId: com.example.appAutismoUabc
```

Pero el repo no contiene:

```text
ios/Runner/GoogleService-Info.plist
```

Para correr iOS con Firebase, genera o agrega ese archivo desde FlutterFire CLI
o Firebase Console y confirma que el bundle id coincida.

## Web

`lib/firebase_options.dart` tiene opciones Web.

Para correr localmente en Chrome:

```bash
flutter run -d chrome
```

Para build web:

```bash
flutter build web --release
```

## Desktop

Existen carpetas de plataforma para `linux/`, `macos/` y `windows/`, pero
`DefaultFirebaseOptions.currentPlatform` lanza `UnsupportedError` para esas
plataformas. Con la configuracion actual, no son plataformas soportadas para
ejecutar la app con Firebase.

## Comandos de calidad

Formato:

```bash
dart format .
```

Analisis:

```bash
flutter analyze
```

Tests:

```bash
flutter test
```

Un test especifico:

```bash
flutter test test/puzzle_minigame_test.dart
```

## Flujo recomendado para un dev nuevo

1. Ejecutar `flutter pub get`.
2. Verificar `flutter devices`.
3. Correr en Android o Chrome.
4. Crear usuario con email/password desde la pantalla de registro.
5. Probar login.
6. Entrar a modulos.
7. Entrar a avatar.
8. Tocar la pestana PIN/Ajustes desde bottom nav y crear PIN.
9. Ejecutar `flutter test`.
10. Antes de cambiar Firestore o assets, leer `docs/firebase.md`, `docs/data-model.md` y `docs/assets.md`.

## Problemas frecuentes de setup

- Si `flutter run` falla por plataforma no configurada, usa Android o Web antes de desktop.
- Si Android falla por Firebase, revisa `android/app/google-services.json`.
- Si iOS falla por Firebase, agrega `ios/Runner/GoogleService-Info.plist`.
- Si aparece `UnsupportedError` en macOS/Windows/Linux, esa plataforma no tiene Firebase configurado.
- Si un asset no carga, confirma que el path exista y que este cubierto por `pubspec.yaml`.
