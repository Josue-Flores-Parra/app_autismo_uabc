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
flutter build ipa --release --dart-define=APP_ENV=dev

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

## Cloud Functions

`functions/` contiene `sendConsentConfirmations`, que envia el correo de
confirmacion del consentimiento parental cada 6 horas. Requiere el plan Blaze
en el proyecto y un proveedor SMTP.

```bash
cd functions && npm ci && npm test && cd ..
firebase functions:secrets:set SMTP_PASSWORD --project dev
firebase deploy --only functions --project dev
```

El primer despliegue pide `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `MAIL_FROM`,
`LEGAL_BASE_URL` y `CONTACT_EMAIL` y los guarda en `functions/.env.<proyecto>`.
La contrasenia vive solo en Secret Manager. Para probarla sin esperar al
horario, ejecuta el job desde Cloud Scheduler en la consola de Google Cloud.

Produccion se despliega solo cuando el equipo lo pide:
`firebase deploy --only functions --project prod`.

### Probar la funcion sin plan Blaze

Desarrollo no tiene Blaze, asi que la funcion se prueba en los emuladores, que
no lo necesitan. El proyecto `demo-appy` garantiza que nada toque un proyecto
real.

1. Crea un buzon SMTP de prueba (los correos se capturan, no se entregan):

   ```bash
   cd functions && npm ci
   node -e "require('nodemailer').createTestAccount().then(a=>console.log(a.user, a.pass))"
   ```

2. Crea `functions/.env.local` y `functions/.secret.local` (ambos ignorados por
   git) con esos datos:

   ```bash
   # functions/.env.local
   SMTP_HOST=smtp.ethereal.email
   SMTP_PORT=587
   SMTP_USER=<usuario>
   MAIL_FROM="Appy <usuario>"
   LEGAL_BASE_URL=https://example.org/legal
   CONTACT_EMAIL=rosalesq.software@gmail.com

   # functions/.secret.local
   SMTP_PASSWORD=<contrasenia>
   ```

3. En la raiz del repo, arranca los emuladores (Pub/Sub es necesario para que
   la funcion programada se registre):

   ```bash
   firebase emulators:start --only auth,firestore,functions,pubsub --project demo-appy
   ```

4. En otra terminal, siembra tres padres de prueba y ejecuta la funcion:

   ```bash
   cd functions
   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
     node scripts/seed-emulator.js
   scripts/trigger-emulator.sh
   ```

   La terminal de los emuladores debe mostrar `"pending":3,"sent":1`: solo
   `debe-recibir` cumple las condiciones (`sin-verificar` no confirmo su correo y
   `muy-reciente` acepto hace una hora). Una segunda ejecucion muestra
   `"sent":0`. En http://127.0.0.1:4000/firestore, `users/debe-recibir.legal`
   tiene `confirmationPending: false` y `confirmationSentAt`.

5. Para ver el correo, entra a https://ethereal.email/login con el usuario y la
   contrasenia del paso 1 y abre "Messages".

La app no se conecta a los emuladores: el flujo de la app (verificar correo,
aceptar, perfiles, borrado de telemetria) se prueba en desarrollo con
`flutter run`, que no necesita Blaze.

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
