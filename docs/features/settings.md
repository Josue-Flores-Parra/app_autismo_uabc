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
| `sendMetrics` | `bool` | `sendMetrics` | `false` |
| `parentalMinLevel` | `int` | `parentalMinLevel` | `0` |

Escalas reales:

| Opcion | Factor |
| --- | --- |
| `small` | `0.9` |
| `medium` | `1.0` |
| `large` | `1.15` |

`setParentalMinLevel(level)` aplica:

```text
level.clamp(0, 10)
```

`clearCache()` limpia:

- `PaintingBinding.instance.imageCache.clear()`.
- `PaintingBinding.instance.imageCache.clearLiveImages()`.
- `SharedPreferences.reload()`.

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
- Usa `ColorScheme.fromSeed`.
- Seed normal: `0xFF4A90E2`.
- Seed alto contraste: `0xFF0E1B4D`.
- En alto contraste fuerza `surface` negro, `onSurface` blanco y `outline` blanco70.
- `ElevatedButtonTheme` usa verde `0xFF50C878` salvo alto contraste.
- `CardTheme` sube elevacion y borde en alto contraste.
- `SwitchTheme` y `SliderTheme` se ajustan al `colorScheme`.
- Si `reduceMotion` es `true`, usa `NoTransitionsBuilder` para Android, iOS, macOS, Linux y Windows.

## SettingsPage

Archivo:

```text
lib/features/settings/view/settings_page.dart
```

Es un `StatefulWidget` que usa `Consumer<SettingsViewModel>` y obtiene
`AuthViewModel` con `Provider.of<AuthViewModel>(listen: false)` dentro de un
try/catch. Eso permite que algunos tests monten Settings sin AuthProvider.

Secciones visibles:

| Seccion | Contenido |
| --- | --- |
| Perfil de usuario | Nombre para mostrar editable y correo deshabilitado. |
| Cuenta y seguridad | Cambiar contrasena, cerrar sesion, eliminar cuenta. |
| Idioma | Radio `es` y `en`. |
| Apariencia | Tema sistema/claro/oscuro y chips de tamano de fuente. |
| Accesibilidad | Alto contraste, reducir animaciones, feedback auditivo, feedback haptico. |
| Notificaciones y recordatorios | Toggle de recordatorios y selector de hora si esta activo. |
| Privacidad y datos | Limpiar cache y enviar metricas anonimas. |
| Control parental | Slider 0..10 para nivel minimo. |
| Informacion y soporte | Version, terminos, privacy policy y mailto de soporte. |

`PackageInfo.fromPlatform()` muestra solo `version`, no `buildNumber`.

Links externos:

| Item | URL |
| --- | --- |
| Terminos y Privacidad | `https://policies.google.com/terms` |
| Privacy policy | `https://policies.google.com/privacy` |
| Feedback / soporte | `mailto:rosalesq.software@gmail.com?subject=Appy%20Feedback` |

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

### Cerrar sesion

1. Llama `AuthViewModel.logout`.
2. Muestra snackbar.
3. El swap a `LoginScreen` lo maneja `AuthGate` via `Consumer<AuthViewModel>`.

### Eliminar cuenta

1. Pide confirmar escribiendo `BORRAR` o `DELETE`, segun locale.
2. Llama `AuthViewModel.deleteAccount`.
3. En exito, `deleteAccount()` limpia `_currentUser` y `AuthGate` hace el swap a
   `LoginScreen` (sin navegacion imperativa).
4. Si falla, muestra snackbar.

## PIN de acceso a Settings

El PIN no vive en `SettingsPage`; vive en:

```text
lib/features/home/view/main_shell.dart
lib/shared/services/pin_service.dart
```

Clave:

```text
settingsPin
```

Reglas reales de PIN debil en `MainShell._isWeakPin`:

- Debe cumplir `^\d{4}$`.
- Rechaza cuatro digitos iguales.
- Rechaza secuencias ascendentes.
- Rechaza secuencias descendentes.
- Rechaza blacklist: `0000`, `1234`, `4321`, `1111`, `2222`, `3333`.

Si no hay PIN guardado y se toca la pestana de Ajustes/PIN desde bottom nav, se
pide crear uno. Si hay PIN, se pide ingresarlo. Si se olvida, se reautentica
con password de la cuenta actual y se borra el PIN local.

Nota importante: el icono de ajustes en el `AppBar` de `ModuleListScreen`
navega directamente a `SettingsPage` y no usa este gating de PIN.

## Control parental

`SettingsViewModel.parentalMinLevel` se aplica en:

```text
lib/features/learning_module/view/module_list_screen.dart
```

`ModulosGridView` reconstruye cada `ModuloInfo` y marca bloqueado si:

```text
modulo.bloqueado || modulo.nivel < parentalMinLevel
```

Esto significa que el valor configurado es "nivel minimo requerido". Si el
modulo tiene nivel menor que ese minimo, se bloquea visualmente.

## Localizacion

Settings usa `AppLocalizations` para la mayoria de textos. Hay excepciones:

- El item "Privacy policy" esta hardcodeado en ingles.
- Algunos mensajes de fallback siguen hardcodeados.
- El gating de PIN en `MainShell` usa textos hardcodeados en espanol.

Ver `docs/localization.md`.

## Reglas de mantenimiento

- Si agregas preferencia, define default, parser, getter, setter, persistencia y test.
- Si la preferencia afecta UI global, conectala en `main.dart` o `AppTheme`.
- Si afecta modulos o gating, documenta la pantalla que consume el valor.
- Si agregas textos visibles a Settings, agrega llaves en `app_es.arb` y `app_en.arb`.
- Si cambias el PIN, actualiza tambien `docs/accessibility.md` y `docs/data-model.md`.
