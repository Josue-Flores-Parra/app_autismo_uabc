# Feature: settings

## Proposito

Settings permite administrar perfil, seguridad de cuenta, idioma, apariencia,
accesibilidad, recordatorios, privacidad, control parental e informacion de
soporte. La mayoria de preferencias se guardan en `SharedPreferences` mediante
`SettingsViewModel`; las operaciones de cuenta pasan por `AuthViewModel`.

## Archivos principales

```text
lib/features/settings/view/settings_page.dart
lib/features/settings/viewmodel/settings_viewmodel.dart
```

Archivos relacionados:

```text
lib/features/home/view/main_shell.dart
lib/shared/services/pin_service.dart
lib/core/app_theme.dart
lib/main.dart
lib/l10n/app_es.arb
lib/l10n/app_en.arb
```

## SettingsViewModel

Archivo:

```text
lib/features/settings/viewmodel/settings_viewmodel.dart
```

Constructor:

- Llama `_loadPreferences()` inmediatamente.
- Mientras carga, `_loading = true`.
- El getter `isReady` retorna `!_loading`.

Estado y persistencia:

| Getter | Tipo | Clave SharedPreferences | Default |
| --- | --- | --- | --- |
| `themeMode` | `ThemeMode` | `themeMode` | `ThemeMode.system` |
| `fontScale` | `FontScaleOption` | `fontScale` | `FontScaleOption.medium` |
| `locale` | `Locale` | `locale` | `Locale('es')` |
| `highContrast` | `bool` | `highContrast` | `false` |
| `reduceAnimations` | `bool` | `reduceAnimations` | `false` |
| `audioFeedback` | `bool` | `audioFeedback` | `true` |
| `hapticFeedback` | `bool` | `hapticFeedback` | `true` |
| `remindersEnabled` | `bool` | `remindersEnabled` | `false` |
| `reminderTime` | `TimeOfDay` | `reminderTime` | `18:00` |
| `sendMetrics` | `bool` | `sendMetrics_{uid}` | `false` |
| `parentalAllowedModules` | `int` | `parentalAllowedModules` | `0` |

El consentimiento de telemetría (`sendMetrics`) y el flag de onboarding
(`telemetryOnboardingShown`) se guardan **por cuenta** (UID), no del dispositivo;
ver sección `Telemetria sendMetrics`.

Escalas reales:

| Opcion | Factor |
| --- | --- |
| `small` | `0.9` |
| `medium` | `1.0` |
| `large` | `1.15` |

`setParentalAllowedModules(count)` aplica:

```text
count.clamp(0, 10)
```

`toggleAudioFeedback` y `toggleHapticFeedback` publican ademas su valor en
`FeedbackPreferences`, que es lo que consultan los servicios sin `BuildContext`
(`TtsService`, `CelebrationHelper`, `NegativeFeedbackHelper`, `HapticsService`).

`clearCache()` limpia:

- `PaintingBinding.instance.imageCache.clear()`.
- `PaintingBinding.instance.imageCache.clearLiveImages()`.
- `SharedPreferences.reload()`.

## Telemetria sendMetrics

`sendMetrics` es el consentimiento de telemetría y es **por cuenta**. Se
persiste en SharedPreferences como `sendMetrics_{uid}` (y
`telemetryOnboardingShown_{uid}`) y se carga con `SettingsViewModel.setAccount`
al cambiar de usuario, conectado en `lib/main.dart` vía
`ChangeNotifierProxyProvider<AuthViewModel, SettingsViewModel>`.

`ActivityTelemetryService` se conecta a `SettingsViewModel` vía `ProxyProvider2`
en `lib/main.dart`:

- El servicio **no** evalúa `sendMetrics` hasta que `SettingsViewModel.isReady`.
  Antes de eso, el estado efectivo es deshabilitado.
- Al crear una cuenta se muestra **una sola vez** un diálogo informativo de
  telemetría; la decisión queda asociada a esa cuenta. `sendMetrics` puede
  ajustarse en cualquier momento desde Ajustes.
- El consentimiento se captura en el instante de `requestLaunch`; activarlo a
  mitad de una actividad no crea sesión para esa actividad (sólo para la
  siguiente).
- Al desactivar, se intenta **una sola vez** un cierre `telemetry_opt_out` de la
  sesión activa; no se reintenta ni se conserva payload, y no se borra histórico.
- `main.dart` llama `reconcilePending` tras Auth y Settings listos para cerrar
  marcadores locales de procesos muertos.

El contrato completo está en `../decisions/telemetry-implementation.md`.

## Integracion global

`main.dart` consume `SettingsViewModel` con `Consumer` y configura:

| Configuracion MaterialApp | Fuente |
| --- | --- |
| `theme` | `AppTheme.light(fontScale, highContrast, reduceMotion)` |
| `darkTheme` | `AppTheme.dark(fontScale, highContrast, reduceMotion)` |
| `themeMode` | `settings.themeMode` |
| `locale` | `settings.locale` |
| `supportedLocales` | `AppLocalizations.supportedLocales` |
| `localizationsDelegates` | `AppLocalizations.localizationsDelegates` |
| `MediaQuery.textScaler` | `TextScaler.linear(settings.textScaleFactor)` |

`AppTheme` no multiplica fuentes directamente. La escala se aplica en el
`MediaQuery` del builder de `MaterialApp`.

## AppTheme

Archivo:

```text
lib/core/app_theme.dart
```

Mecanica:

- Usa Material 3.
- Usa `ColorScheme.fromSeed` y lo sobrescribe con la paleta `AppColors` activa (`surface`, `onSurface`, `outline`, `primary`).
- Seed normal: `0xFF4A90E2`.
- Seed alto contraste: `0xFF0E1B4D`.
- Registra `AppColors` como `ThemeExtension`; las pantallas leen `context.appColors`.
- Tipografia: `Commissioner` para el cuerpo, `Coiny` para `display*` y `headline*`.
- Botones (`FilledButton`, `ElevatedButton`, `OutlinedButton`, `TextButton`), inputs, cards, dialogs, snackbars, chips, switches y sliders toman color y radio del tema; los radios vienen de `AppRadius`.
- `AppBar` transparente con `foregroundColor` en `ink`.
- Si `reduceMotion` es `true`, usa `NoTransitionsBuilder` para Android, iOS, macOS, Linux y Windows.

Ver `docs/architecture.md`, seccion "Tema y accesibilidad", para el detalle de
paletas y campos.

## SettingsPage

Archivo:

```text
lib/features/settings/view/settings_page.dart
```

Es un `StatefulWidget` que usa `Consumer<SettingsViewModel>` y obtiene
`AuthViewModel` con `Provider.of<AuthViewModel>(listen: false)` dentro de un
try/catch. Eso permite que algunos tests monten Settings sin AuthProvider.

Estructura visual: un encabezado de perfil (preset
`appy_head_happy_preset.png`, nombre y correo) seguido de tarjetas agrupadas.
Cada tarjeta es un `_Section` con filas `_SettingsRow` (icono, titulo,
subtitulo y control a la derecha) o `_ChoiceRow` con `_Chip`s para elegir
entre opciones. No hay `ListTile` ni colores fijos: todo sale de
`context.appColors`.

Secciones visibles:

| Seccion | Contenido |
| --- | --- |
| Perfil | Nombre para mostrar editable y correo. |
| Cuenta y seguridad | Cambiar contrasena, cambiar PIN, cerrar sesion, reiniciar progreso, eliminar cuenta. |
| Idioma | Chips `es` y `en`. |
| Apariencia | Chips de tema sistema/claro/oscuro y de tamano de fuente. |
| Accesibilidad | Alto contraste, reducir animaciones, feedback auditivo, feedback haptico. |
| Notificaciones y recordatorios | Toggle de recordatorios y selector de hora si esta activo. |
| Privacidad y datos | Limpiar cache y enviar metricas anonimas. |
| Control parental | Modulos permitidos, con resumen en el subtitulo (`_parentalSummary`). |
| Informacion y soporte | Version, terminos, privacy policy y mailto de soporte. |

`PackageInfo.fromPlatform()` muestra solo `version`, no `buildNumber`.

Links externos:

| Item | Destino |
| --- | --- |
| Terminos y Privacidad | `LegalDocumentScreen`, pestana 0. |
| Politica de privacidad | `LegalDocumentScreen`, pestana 1. |
| Feedback / soporte | `mailto:rosalesq.software@gmail.com?subject=Appy%20Feedback` |

Terminos y privacidad ya no abren `policies.google.com`: esas politicas son de
Google, no de Appy, y mostrarlas como propias confundia al padre. Ahora abren
los documentos propios, los mismos que la cuenta acepto al entrar. Ver
`docs/features/legal.md`.

## Operaciones de cuenta desde Settings

### Editar nombre

1. Abre dialog con `TextField`.
2. Si el resultado no esta vacio, llama `AuthViewModel.updateDisplayName`.
3. Si fue exitoso, llama `AvatarViewModel.updateNombreDesdeDisplayName`.
4. Muestra snackbar de exito o error.

### Cambiar password

1. Abre dialog con password nuevo.
2. Solo llama `AuthViewModel.changePassword` si el texto tiene minimo 6 caracteres.
3. Muestra snackbar de exito o error.

No hay flujo de reautenticacion en esta pantalla. Firebase puede rechazar la
operacion si la sesion no es reciente.

### Cambiar PIN

1. Llama `SettingsAccessGuard.changePinFlow(context)` (mismo servicio que el
   gating de PIN al entrar a Ajustes).
2. Si el flujo termina bien, snackbar "PIN actualizado correctamente".

### Reiniciar progreso

1. Dialogo de confirmacion: borra estrellas, monedas ganadas en niveles y
   vuelve a bloquear los niveles.
2. En exito llama `LearningViewModel.clearAllProgress()` (la View no toca
   Firestore directamente) y muestra snackbar.
3. En error, snackbar con el mensaje de la excepcion.

Fila destructiva; no forma parte de los ajustes que pidio el equipo
originalmente. Confirmar con el equipo antes de subir si se quiere conservar
para el usuario final o dejarla solo para pruebas internas.

### Cerrar sesion

1. Llama `AuthViewModel.logout`.
2. Muestra snackbar.
3. El swap a `LoginScreen` lo maneja `AuthGate` via `Consumer<AuthViewModel>`.

### Eliminar cuenta

1. Pide confirmar escribiendo `BORRAR` o `DELETE`, segun locale, y la password
   de la cuenta.
2. Llama `AuthViewModel.deleteAccount(password)`.
3. `AuthService.deleteAccount` reautentica con esa password antes de borrar.
   Firebase exige sesion reciente; sin este paso la operacion fallaba aunque la
   palabra de confirmacion fuera correcta.
4. En exito, `deleteAccount()` limpia `_currentUser`, borra el PIN de esa cuenta
   y `AuthGate` hace el swap a `LoginScreen` (sin navegacion imperativa).
5. Si falla, muestra snackbar.

## PIN de acceso a Settings

El PIN no vive en `SettingsPage`; vive en:

```text
lib/shared/services/settings_access_guard.dart
lib/shared/services/pin_service.dart
```

Clave, una por cuenta:

```text
settingsPin_<uid>
```

Reglas reales de PIN debil en `SettingsAccessGuard.isWeakPin`:

- Debe cumplir `^\d{4}$`.
- Rechaza cuatro digitos iguales.
- Rechaza secuencias ascendentes.
- Rechaza secuencias descendentes.
- Rechaza blacklist: `0000`, `1234`, `4321`, `1111`, `2222`, `3333`.

Si no hay PIN guardado y se toca el engrane de Ajustes en el `AppBar` de
Modulos, se pide crear uno. Si hay PIN, se pide ingresarlo. Si se olvida, se
reautentica con password de la cuenta actual y se borra el PIN local.

Dialogo (`_PinDialog` en `settings_access_guard.dart`):

- Cuatro casillas (`_PinBox`) y teclado numerico propio (`_PinKey`); no abre el teclado del sistema. Tambien acepta digitos y Backspace de un teclado fisico.
- Al escribir el cuarto digito se valida solo; no hay boton "Confirmar".
- Con PIN guardado: correcto cierra con `true`; incorrecto muestra "PIN incorrecto" y limpia las casillas. "Olvide el PIN" cierra con `null` y dispara la reautenticacion.
- Sin PIN guardado: primer ingreso se valida con `isWeakPin`, segundo ingreso debe coincidir ("Los PIN no coinciden" reinicia el flujo). Cierra con el PIN elegido o `null` al cancelar.

El gating vive en `SettingsAccessGuard` y no en `MainShell` porque, cuando
existia la pestana de Ajustes en el bottom nav, habia dos entradas al mismo
PIN. Esa pestana se elimino por redundante (ver `docs/architecture.md`); el
gating se quedo en `SettingsAccessGuard` porque `ModuleListScreen` tambien lo
necesita para su icono de engrane.

## Control parental

`SettingsViewModel.parentalAllowedModules` se aplica en:

```text
lib/features/learning_module/view/module_list_screen.dart
```

`ModulosGridView` reconstruye cada `ModuloInfo` y marca bloqueado si:

```text
modulo.bloqueado || (parentalAllowedModules > 0 && indice >= parentalAllowedModules)
```

El valor configurado es "cuantos modulos, en el orden en que se muestran, puede
abrir el nino". `0` significa sin limite.

La regla anterior comparaba `modulo.nivel` contra el slider. Como todos los
modulos tienen `nivelMinimo = 1`, `0` y `1` daban el mismo resultado y cualquier
valor mayor o igual a `2` bloqueaba todos los modulos. Contar modulos permitidos
hace visible cada posicion del slider y nunca deja al nino sin contenido.

## Localizacion

Settings usa `AppLocalizations` para la mayoria de textos. Hay excepciones:

- El item de politica de privacidad ya usa la llave `privacyPolicy`.
- Algunos mensajes de fallback siguen hardcodeados.
- El gating de PIN en `MainShell` usa textos hardcodeados en espanol.

Ver `docs/localization.md`.

## Reglas de mantenimiento

- Si agregas preferencia, define default, parser, getter, setter, persistencia y test.
- Si la preferencia afecta UI global, conectala en `main.dart` o `AppTheme`.
- Si afecta modulos o gating, documenta la pantalla que consume el valor.
- Si agregas textos visibles a Settings, agrega llaves en `app_es.arb` y `app_en.arb`.
- Si cambias el PIN, actualiza tambien `docs/accessibility.md` y `docs/data-model.md`.
