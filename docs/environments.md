# Entornos

Appy usa dos proyectos Firebase con los mismos identificadores de app
(`com.appytea.appy` en Android e iOS):

| Entorno | Proyecto | Alias CLI | Uso |
| --- | --- | --- | --- |
| Desarrollo | `appy-dev-uabc` | `dev` | `flutter run`, QA y datos de prueba. |
| Produccion | `app-autismo-25f44` | `prod` | Builds de tienda y cuentas reales. |

## Como elige una build su entorno

`lib/core/app_environment.dart` decide que opciones recibe
`Firebase.initializeApp` en `lib/main.dart`:

| Comando | Entorno |
| --- | --- |
| `flutter run` (debug o profile) | Desarrollo |
| `flutter build appbundle --release`, `flutter build ipa --release` | Produccion |
| Cualquier comando con `--dart-define=APP_ENV=dev` | Desarrollo |
| Cualquier comando con `--dart-define=APP_ENV=prod` | Produccion |

Un valor distinto de `dev` o `prod` hace fallar el arranque en lugar de elegir
un proyecto. Las builds de desarrollo muestran una banda `DEV` en la esquina.

Ejemplos:

```bash
# Build release para testers que debe escribir en desarrollo
flutter build appbundle --release --dart-define=APP_ENV=dev
AUDIO_SESSION_MICROPHONE=0 flutter build ipa --release --dart-define=APP_ENV=dev

# Probar localmente contra produccion (solo lectura, con cuidado)
flutter run --dart-define=APP_ENV=prod
```

Ambos entornos comparten `applicationId` y bundle id, asi que una build de
desarrollo y una de produccion no pueden instalarse a la vez en el mismo
dispositivo.

## Archivos de configuracion

| Archivo | Proyecto |
| --- | --- |
| `lib/firebase_options.dart` | Produccion. |
| `lib/firebase_options_dev.dart` | Desarrollo. |
| `android/app/google-services.json` | Produccion. Android ya no lo usa; FlutterFire lo regenera. |

Android no aplica el plugin `com.google.gms.google-services`. Con el plugin,
Android inicia Firebase desde `google-services.json` antes de Dart, y
`firebase_core` lanza `duplicate-app` al pedir las opciones de desarrollo.

Para regenerar la configuracion:

```bash
flutterfire configure --project=app-autismo-25f44 --out=lib/firebase_options.dart
flutterfire configure --project=appy-dev-uabc --out=lib/firebase_options_dev.dart
```

Despues de correrlo, revisa `android/app/build.gradle.kts`: FlutterFire vuelve
a agregar el plugin google-services y hay que quitarlo de nuevo.

## Reglas e indices

`firebase.json` apunta a `firestore.rules` y `firestore.indexes.json`.
`.firebaserc` define los alias; `dev` es el proyecto por omision.

```bash
firebase deploy --only firestore:rules,firestore:indexes --project dev
firebase deploy --only firestore:rules,firestore:indexes --project prod
```

Corre las pruebas de `firestore-tests/` antes de desplegar a produccion.

## Copiar contenido a desarrollo

`tools/firestore-content/copy-content.js` copia `modules` y sus `levels` de
produccion a desarrollo. No copia usuarios, progreso ni telemetria, y se niega
a escribir en produccion.

Necesita una llave de cuenta de servicio de cada proyecto (Configuracion del
proyecto > Cuentas de servicio > Generar nueva clave privada). Guardalas fuera
del repo y borralas al terminar.

```bash
cd tools/firestore-content
npm ci
node copy-content.js --from-key ~/keys/prod-key.json --to-key ~/keys/dev-key.json
node copy-content.js --from-key ~/keys/prod-key.json --to-key ~/keys/dev-key.json --write
```

Sin `--write` solo cuenta los documentos. Las URLs de media del contenido
copiado siguen apuntando a donde estan alojados los archivos de produccion.
