# Feature: legal

## Proposito

Mostrar los terminos de uso y el aviso de privacidad propios de Appy, pedir su
aceptacion expresa antes de usar la app y dejar constancia de que version acepto
cada cuenta.

Antes, los dos items de Ajustes abrian `policies.google.com`, que son las
politicas de Google y no las de Appy. Ademas no existia ningun registro de
consentimiento, algo necesario porque la app esta dirigida al apoyo de personas
con TEA y su uso puede relacionarse con informacion de salud de una persona
menor de edad.

## Archivos principales

```text
lib/features/legal/data/legal_documents.dart
lib/features/legal/viewmodel/legal_viewmodel.dart
lib/features/legal/view/legal_consent_screen.dart
lib/features/legal/view/legal_document_screen.dart
lib/features/legal/view/legal_document_view.dart
```

Archivos relacionados:

```text
lib/features/authentication/view/auth_gate.dart
lib/features/settings/view/settings_page.dart
lib/data/services/firestore_services.dart
lib/main.dart
```

## Contenido de los documentos

`legal_documents.dart` guarda el texto en Dart y no en los ARB. Son documentos
largos y versionados: lo relevante es comparar la version aceptada contra
`kLegalVersion`, no traducir cadena por cadena.

Constantes que el equipo debe revisar antes de cada publicacion:

| Constante | Uso |
| --- | --- |
| `kLegalVersion` | Version vigente. Subirla obliga a aceptar de nuevo a todas las cuentas. |
| `kLegalLastUpdated` | Fecha visible en el encabezado de ambos documentos. |
| `kLegalResponsable` | Nombre con el que el equipo se identifica como responsable de los datos. |
| `kLegalContactEmail` | Correo unico para asuntos legales y derechos sobre datos personales. |
| `kLegalJurisdiccion` | Entidad cuya legislacion rige el servicio. |

Cada documento es una lista de `LegalBlock` con cuatro tipos: `heading`,
`paragraph`, `bullet` y `note`. `LegalDocumentView` los pinta, de modo que los
dos documentos se ven igual en la pantalla de consentimiento y en la de
consulta.

Hay version en espanol y en ingles. Se elige con
`SettingsViewModel.locale.languageCode`. El texto en ingles incluye una nota de
que el espanol prevalece si hay discrepancia.

## Registro de la aceptacion

Ruta:

```text
users/{uid}.legal
```

| Campo | Tipo | Valor |
| --- | --- | --- |
| `version` | `int` | Valor de `kLegalVersion` aceptado. |
| `acceptedAt` | `String` ISO 8601 | Momento de la aceptacion. |

Se guarda por cuenta y no por dispositivo: reinstalar la app o cambiar de
telefono no vuelve a preguntar, y una cuenta nueva siempre pasa por la
pantalla.

`FirestoreService` expone `getAcceptedLegalVersion(uid)` y
`setAcceptedLegalVersion(uid, version)`.

## LegalViewModel

Estados de `LegalStatus`:

| Estado | Significado |
| --- | --- |
| `desconocido` | Aun no se consulta la cuenta. |
| `cargando` | Leyendo la version aceptada. |
| `requiereAceptacion` | Falta aceptar la version vigente. |
| `aceptado` | La cuenta esta al corriente. |

Reglas:

- `ensureChecked()` consulta una sola vez por uid.
- Si la lectura falla, el estado queda en `requiereAceptacion`. Es deliberado:
  sin lectura confiable no se puede dar por bueno un consentimiento que no
  consta.
- `accept()` devuelve `false` si no se pudo escribir, para no dejar entrar sin
  registro.
- `reset()` limpia el estado al cerrar sesion. Notifica con `Future.microtask`
  porque quien lo llama es el `update` del provider, que corre durante el build.

## Flujo

```text
AuthGate
  -> sin usuario: LoginScreen
  -> con usuario: _LegalGate
       -> cargando: indicador
       -> requiereAceptacion: LegalConsentScreen
       -> aceptado: MainShell
```

`main.dart` registra el viewmodel con
`ChangeNotifierProxyProvider<AuthViewModel, LegalViewModel>` y llama `reset()`
cuando `auth.currentUser` es null.

## LegalConsentScreen

Reglas de la pantalla:

- `PopScope` con `canPop: false`: no se esquiva con el boton atras.
- Dos pestanas, una por documento, cada una con su indicador de leido.
- El boton de aceptar exige haber llegado al final de **ambos** documentos y
  haber marcado la casilla.
- Un documento que cabe completo en pantalla cuenta como leido. Sin esa
  comprobacion el boton nunca se habilitaria en pantallas grandes.
- Mientras falte leer, un aviso dice cual documento falta.
- La casilla confirma tambien que quien acepta es madre, padre o tutor legal.
- "Ahora no" explica por que no se puede continuar y cierra sesion.

## LegalDocumentScreen

Consulta desde Ajustes, seccion "Informacion y soporte". Es solo lectura, con
las mismas dos pestanas. El item de terminos abre la pestana 0 y el de
privacidad la pestana 1.

## Reglas de mantenimiento

- Si cambias el contenido de forma sustancial, sube `kLegalVersion` y actualiza
  `kLegalLastUpdated`. Ese es el mecanismo que vuelve a pedir la aceptacion a
  las cuentas existentes.
- Si cambias solo una errata, no subas la version: obligarias a aceptar de nuevo
  sin motivo.
- Si agregas un dato personal nuevo al modelo, agregalo tambien a la seccion
  "Datos que recabamos" del aviso y actualiza `docs/data-model.md`.
- Si agregas un permiso de Android, revisa si toca declararlo en la seccion "Lo
  que no hacemos" del aviso.
- El texto no ha sido revisado por un despacho legal. Si el equipo consigue esa
  revision, deja constancia aqui de la fecha y de quien la hizo.
