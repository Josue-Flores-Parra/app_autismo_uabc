# 🧩 Appy

Appy es una aplicación móvil educativa desarrollada con **Flutter** para apoyar
a personas autistas mediante módulos interactivos centrados en la autonomía, el
aprendizaje y las habilidades sociales. Se publica para **Android** e **iOS**
con el identificador `com.appytea.appy`.

---

## 🚀 Qué incluye

- **Módulos de aprendizaje:** Alimentación, Higiene y Socialización, de 10
  niveles cada uno. Cada nivel combina video, pictogramas, audio y un minijuego,
  y se completa al terminar sus tres actividades.
- **Minijuegos:** selección simple, pictogramas, rompecabezas y audio.
- **Perfiles infantiles** dentro de la cuenta del adulto, con ajustes por niño y
  acceso a la configuración protegido con PIN.
- **Avatar** con monedas, energía y accesorios que se ganan al practicar.
- **Uso sin conexión:** cada módulo se puede descargar y jugar sin internet; el
  progreso se sincroniza al volver la red.
- **Recordatorios de práctica** con notificaciones locales.
- **Accesibilidad:** tamaño de texto, alto contraste, menos animaciones y
  retroalimentación con audio o vibración. Interfaz en español e inglés.
- **Métricas de uso** de las actividades, solo con el consentimiento del adulto.

---

## 🛠️ Tecnologías utilizadas

- Flutter con Dart `^3.9.2`, organizado en MVVM con Provider.
- Firebase Authentication (correo y contraseña) y Cloud Firestore. Ambos son
  necesarios: la app no funciona sin ellos.
- Firebase Storage para imágenes, videos y audios, que la app carga por URL.
- Node.js y el emulador de Firestore para probar las reglas de seguridad.
- GitHub Projects para la gestión del proyecto.

---

## 📦 Estructura del proyecto

```bash
├── lib/
│   ├── core/                    # Tema, tipografías y entorno (dev/prod)
│   ├── data/                    # Servicios y modelos compartidos (Firestore, auth, red)
│   ├── features/<feature>/      # Cada funcionalidad: view/, viewmodel/, model/, data/
│   ├── shared/                  # Servicios y widgets reutilizables
│   ├── l10n/                    # Traducciones (app_es.arb, app_en.arb)
│   ├── firebase_options.dart    # Firebase de producción
│   ├── firebase_options_dev.dart# Firebase de desarrollo
│   └── main.dart                # Punto de entrada
├── test/                        # Pruebas unitarias y de widgets
├── firestore-tests/             # Pruebas de reglas e índices en el emulador
├── tools/firestore-content/     # Copia el contenido de producción a desarrollo
├── tool/                        # Generación de las páginas legales
├── docs/                        # Arquitectura, modelo de datos y funcionalidades
├── firestore.rules              # Reglas de seguridad de Firestore
├── firestore.indexes.json       # Índices de Firestore
├── pubspec.yaml
├── CONTRIBUTING.md
└── README.md
```

El flujo es siempre View → ViewModel → Service/Repository. Los detalles están en
[docs/architecture.md](./docs/architecture.md).

---

## 📲 ¿Cómo ejecutar la app?

1. Clona el repositorio:
   ```bash
   git clone https://github.com/Josue-Flores-Parra/app_autismo_uabc.git
   cd app_autismo_uabc
   ```

2. Asegúrate de tener [Flutter instalado](https://docs.flutter.dev/get-started/install).

3. Instala las dependencias:
   ```bash
   flutter pub get
   ```

4. Conecta un emulador o dispositivo físico (`flutter devices` lista los
   disponibles).

5. Ejecuta la app:
   ```bash
   flutter run
   ```

`flutter run` se conecta al proyecto Firebase de **desarrollo** y muestra una
banda `DEV` en la esquina. Crea ahí tus cuentas de prueba.

### Entornos

| Comando | Proyecto Firebase |
| --- | --- |
| `flutter run` (debug o profile) | Desarrollo (`appy-dev-uabc`) |
| `flutter build ... --release` | Producción (`app-autismo-25f44`) |
| Cualquiera con `--dart-define=APP_ENV=dev` | Desarrollo |
| Cualquiera con `--dart-define=APP_ENV=prod` | Producción |

Producción tiene las cuentas reales: usa `APP_ENV=prod` en debug solo cuando
sea necesario y con cuidado. Los detalles, incluido cómo regenerar la
configuración de Firebase, están en [docs/environments.md](./docs/environments.md).

### Compilación Android

La configuración Android se verifica con Flutter **3.47** estable (probada con
3.47.5 y 3.47.6). Usa un JDK **17 o 21**, Android SDK **36** y el NDK
**28.2.13676358** que selecciona Flutter. Las rutas locales del SDK Android y de
Flutter se configuran en `android/local.properties`; cada desarrollador debe
usar sus propias rutas.

El repositorio fija Gradle **8.14.3** en
`android/gradle/wrapper/gradle-wrapper.properties` y Android Gradle Plugin
**8.13.2** con Kotlin **2.3.0** en `android/settings.gradle.kts`. Ejecuta el
wrapper del proyecto para respetar esas versiones; no hace falta instalar
Gradle globalmente.

```bash
flutter pub get
flutter build apk --debug
flutter build apk --release
```

Si Flutter informa que Gradle está por debajo de su versión mínima, revisa
también los mínimos de AGP y Kotlin del SDK Flutter instalado. Flutter 3.47
exige Gradle >= 8.14, AGP >= 8.11.1 y Kotlin >= 2.2.20. AGP 8.13.2 incluye
el soporte de R8 para Kotlin 2.3, necesario para la compilación release.
No uses `--android-skip-build-dependency-validation` como solución: omite la
comprobación sin corregir la incompatibilidad.

Flutter puede mostrar avisos de futura retirada de soporte para estas
versiones de Gradle, AGP y Kotlin. Son distintos de un error de versión mínima;
una actualización futura de Flutter requiere volver a comprobar la matriz de
compatibilidad antes de actualizar las herramientas.

Android no aplica el plugin `com.google.gms.google-services`: Firebase se
inicializa desde `lib/firebase_options*.dart` para poder elegir el entorno. Si
`flutterfire configure` lo vuelve a agregar, quítalo de
`android/app/build.gradle.kts`.

Sin `android/key.properties`, la build release se firma con la llave debug y
Play Console la rechaza. La firma de producción está descrita en
[docs/release.md](./docs/release.md).

### Compilación iOS

Necesitas macOS con Xcode y CocoaPods. Abre `ios/Runner.xcworkspace` y elige tu
equipo en Signing & Capabilities del target Runner.

```bash
flutter pub get
cd ios && pod install && cd ..
flutter clean
AUDIO_SESSION_MICROPHONE=0 flutter build ipa --release
```

`AUDIO_SESSION_MICROPHONE=0` es obligatorio: sin él, App Store rechaza la build
por código de micrófono que la app no usa. El motivo y cómo verificar el `.ipa`
están en [docs/release.md](./docs/release.md).

Si los Pods quedan en mal estado, `./clear-ios-build.sh` limpia la build y los
reinstala.

---

## 🧪 Pruebas

```bash
dart format .
flutter analyze
flutter test
```

Las reglas de Firestore se prueban contra el emulador, sin tocar ningún proyecto
real. Instala las dependencias una vez con `npm ci` dentro de
`firestore-tests/` y ejecuta desde la raíz:

```bash
firebase emulators:exec --only firestore --project demo-appy \
  "export PATH=/usr/bin:\$PATH && cd firestore-tests && npm test"
```

El `export PATH` es necesario en Linux; el motivo está en
[firestore-tests/README.md](./firestore-tests/README.md). Corre estas pruebas
antes de desplegar reglas a producción.

---

## 🚢 Publicación

Las builds de tienda se compilan sin `APP_ENV`, así que usan producción y no
muestran la banda `DEV`. La versión vive en `pubspec.yaml` y cada subida a una
tienda necesita un número de build mayor. Los pasos para Android e iOS están en
[docs/release.md](./docs/release.md).

---

## 📚 Documentación

| Documento | Contenido |
| --- | --- |
| [docs/setup.md](./docs/setup.md) | Preparación del entorno de desarrollo. |
| [docs/architecture.md](./docs/architecture.md) | Capas, MVVM y flujo de datos. |
| [docs/environments.md](./docs/environments.md) | Proyectos dev y prod, reglas y copia de contenido. |
| [docs/firebase.md](./docs/firebase.md) | Autenticación, Firestore y rutas usadas. |
| [docs/data-model.md](./docs/data-model.md) | Documentos y campos de Firestore. |
| [docs/features/](./docs/features/) | Una guía por funcionalidad. |
| [docs/accessibility.md](./docs/accessibility.md) | Criterios de accesibilidad. |
| [docs/localization.md](./docs/localization.md) | Traducciones y `flutter gen-l10n`. |
| [docs/release.md](./docs/release.md) | Versiones, firma y publicación. |

---

## 🙋 Contribuciones

¿Quieres ayudar? Revisa [CONTRIBUTING.md](./CONTRIBUTING.md) para conocer el
flujo de trabajo, cómo abrir issues, crear ramas y hacer pull requests
correctamente. Todo el trabajo parte de `develop` y vuelve a `develop` por pull
request.

---

## 📅 Estado del desarrollo

La versión **1.0.0** es la primera publicada en Google Play y App Store.
Consulta el tablero del proyecto y los milestones activos:  
👉 [Proyectos en GitHub](https://github.com/Josue-Flores-Parra/app_autismo_uabc/projects)

---

## 🧠 Créditos

Este proyecto se realiza como parte de una colaboración educativa entre alumnos y docentes, con el objetivo de crear tecnología accesible y socialmente útil.

---

## 🪪 Licencia

MIT – Uso libre con fines educativos y sociales.
