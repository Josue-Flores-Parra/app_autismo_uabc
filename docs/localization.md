# Localizacion

Appy usa la generacion oficial de localizaciones de Flutter con archivos ARB.
La configuracion existe y `SettingsPage`, `CustomBottomNavBar` y algunas partes
de `ModuleListScreen` la consumen. Sin embargo, muchas pantallas todavia tienen
textos hardcodeados en espanol. Esta pagina describe el estado real.

## Configuracion

Archivo:

```text
l10n.yaml
```

Contenido actual:

```yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
nullable-getter: false
output-dir: lib/l10n/gen
```

`pubspec.yaml` tiene:

```yaml
flutter:
  generate: true
```

## Idiomas actuales

```text
lib/l10n/app_es.arb
lib/l10n/app_en.arb
```

El template es `app_es.arb`, por lo que espanol es el idioma base del proyecto.

Locales soportados vienen de:

```dart
AppLocalizations.supportedLocales
```

En `SettingsViewModel`, solo se guardan:

- `Locale('es')`.
- `Locale('en')`.

## Archivos generados

```text
lib/l10n/gen/app_localizations.dart
lib/l10n/gen/app_localizations_es.dart
lib/l10n/gen/app_localizations_en.dart
```

No editar manualmente `lib/l10n/gen/`.

## Integracion en MaterialApp

`main.dart` configura:

```dart
locale: settings.locale,
supportedLocales: AppLocalizations.supportedLocales,
localizationsDelegates: AppLocalizations.localizationsDelegates,
```

El idioma se cambia desde `SettingsPage`, llamando:

```dart
settings.setLocale(const Locale('es'));
settings.setLocale(const Locale('en'));
```

La clave guardada en `SharedPreferences` es:

```text
locale
```

## Llaves actuales

Los ARB actuales cubren principalmente:

- Titulo de app.
- Bottom nav.
- Secciones de Settings.
- Labels de perfil/cuenta.
- Tema e idioma.
- Preferencias de accesibilidad.
- Recordatorios.
- Privacidad.
- Control parental.
- Informacion/soporte.
- Snackbars de Settings.
- Confirmar/cancelar.

Detalle importante en los ARB:

```text
navSettings = "PIN"
```

Tanto `app_es.arb` como `app_en.arb` definen `navSettings` como `PIN`. Sin
embargo, los archivos generados versionados pueden quedar stale si no se ejecuta
`flutter gen-l10n`; en el estado previo a regenerar, `app_localizations_es.dart`
devolvia `Ajustes` y `app_localizations_en.dart` devolvia `Settings`. Si el
bottom nav no muestra `PIN`, regenera l10n.

## Uso real por pantalla

| Pantalla/componente | Usa ARB | Notas |
| --- | --- | --- |
| `main.dart` | Si | Delegates, supported locales y locale. |
| `CustomBottomNavBar` | Si | Usa `navModules`, `navAvatar`, `navSettings`; tiene fallbacks hardcodeados. |
| `SettingsPage` | Parcialmente | La mayoria de textos usan ARB; `Privacy policy` esta hardcodeado. |
| `ModuleListScreen` | Parcialmente | AppBar usa `navModules` y tooltip `settingsTitle`; gran parte del contenido sigue hardcodeado. |
| `LoginScreen` | No | Textos hardcodeados en espanol. |
| `RegisterScreen` | No | Textos hardcodeados en espanol. |
| `AvatarScreen` | No | Textos hardcodeados en espanol. |
| `MainShell` dialogs de PIN | No | Textos hardcodeados en espanol. |
| `LevelTimelineScreen` | No | Textos hardcodeados como `JUGAR`. |
| `LevelContentPreviewScreen` | No | Textos hardcodeados como `VISTA PREVIA`. |
| `PopupPreview` | No | Labels hardcodeados. |
| `LevelPlayScreen` | No | Dialogs y mensajes hardcodeados. |
| Minijuegos | No | Textos hardcodeados en espanol. |

## Agregar texto nuevo

1. Agrega la llave en `lib/l10n/app_es.arb`.
2. Agrega la misma llave en `lib/l10n/app_en.arb`.
3. Ejecuta:

```bash
flutter gen-l10n
```

4. Usa el texto desde la UI:

```dart
final l10n = AppLocalizations.of(context);
Text(l10n?.miLlave ?? 'Fallback temporal')
```

Como `nullable-getter: false`, los getters generados no son nullables cuando se
accede desde una instancia no nula. En el codigo actual se usa `l10n?.key ??
fallback` en varios sitios porque `AppLocalizations.of(context)` puede retornar
nullable.

## Reglas

- No editar archivos generados.
- Mantener las mismas llaves en `app_es.arb` y `app_en.arb`.
- Si agregas placeholders, usar formato ARB y actualizar ambos idiomas.
- Si una pantalla queda con texto hardcodeado por decision temporal, documentarlo en esta pagina o en la pagina de la feature.
- Al internacionalizar una pantalla, revisar tests widget que busquen texto literal.
