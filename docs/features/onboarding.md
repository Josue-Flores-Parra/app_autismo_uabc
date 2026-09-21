# Feature: onboarding

## Proposito

Bienvenida de cuatro paginas que presenta al personaje y explica, con las
ilustraciones de `assets/images/presets/`, que hace la app: rutinas por
modulos, aprendizaje por video/pictograma/minijuego, el companero que gana
monedas, y las herramientas para la familia (PIN parental, progreso guardado).

Se muestra una sola vez por dispositivo, antes del login, porque en ese punto
no hay cuenta a la cual asociar la preferencia.

## Archivos principales

```text
lib/features/onboarding/data/onboarding_service.dart
lib/features/onboarding/view/onboarding_screen.dart
lib/features/onboarding/view/widgets/animated_entrance.dart
lib/features/authentication/view/auth_gate.dart
```

## OnboardingService

| Metodo | Que hace |
| --- | --- |
| `hasSeen()` | Lee `onboardingSeen` de `SharedPreferences`; `false` si no existe. |
| `markSeen()` | Escribe `onboardingSeen = true`. |

Clave:

```text
onboardingSeen
```

Es por dispositivo, no por cuenta. Cerrar sesion no la borra; desinstalar la
app si.

## OnboardingScreen

`OnboardingScreen({required VoidCallback onFinished})`.

Un `PageView` con cuatro paginas, indicador de puntos, boton "Saltar" y boton
"Siguiente" que en la ultima pagina dice "¡Empezar!". Tanto "Saltar" como
"Empezar" llaman `OnboardingService.markSeen()` y luego `onFinished`.

Composicion libre, no rejilla: cada pagina es un `_Scene` con una sola
ilustracion (`_Art`, `AspectRatio` 1:1, alineada a la derecha) y un panel de
texto (`_Copy`) que se **encima** sobre su borde inferior con
`Transform.translate(offset: Offset(0, -40))`. No se usa un preset por
tile; cada pagina trae una sola imagen y el resto del espacio lo ocupa el
texto, para no sobrecargar de ilustraciones una pantalla que ya es breve.

| Pagina | Ilustracion | Etiquetas (`_Tag`) |
| --- | --- | --- |
| `_WelcomePage` | `appy_happy_preset` | Higiene, Alimentacion |
| `_LearningPage` | `appy_tablet_preset` | Video, Minijuego |
| `_CompanionPage` | `appy_cooking_preset` | Monedas, Energia |
| `_FamilyPage` | `appy_peeking_preset` | PIN parental |

Piezas:

- `_SoftBlobs`: dos manchas de color desenfocadas detras de todo (fondo para que el vidrio tenga algo que difuminar).
- `_Glass`: `BackdropFilter` con `ImageFilter.blur` mas relleno translucido blanco (estetica "liquid glass"); el panel `_Copy` y las etiquetas `_Tag` lo usan.
- `_Copy`: kicker + titulo (`AppFonts.display`) + cuerpo con `**negritas**` resaltadas en `colors.ink` sobre `colors.inkSoft`, mas las `_Tag` en `Wrap`.
- `_Tag`: icono con fondo solido de color mas etiqueta, montada sobre el borde del panel de texto.
- `AnimatedEntrance` / `FloatingAnimation` (`widgets/animated_entrance.dart`): entrada escalonada (fade + slide + scale) por pieza y flotado continuo de la ilustracion. Ambas leen `SettingsViewModel.reduceAnimations` en `initState` y, si esta activo, saltan directo al estado final (sin animar).

Colores y radios salen de `context.appColors` y `AppRadius`. Los tintes de
`_Tag` (`0xFF4A90E2`, `0xFFE0972A`, `0xFFF2B233`) son literales, no
`context.appColors`, porque las paginas son `const`: cambiarlos por tema
implicaria quitar el `const` de todo el arbol de paginas por una diferencia de
tono menor en modo oscuro.

## Integracion con AuthGate

`AuthGate` carga `hasSeen()` en `initState`. Con `currentUser == null`:

- `null` (aun cargando): indicador de progreso.
- `false`: `OnboardingScreen`; `onFinished` hace `setState` y pasa a `LoginScreen`.
- `true`: `LoginScreen`.

Si ya hay sesion restaurada, el onboarding no se muestra aunque no se haya
visto: la cuenta ya conoce la app.

## Textos

Hardcodeados en espanol. Sin llaves ARB por ahora; si se localiza, agregar las
llaves y documentarlo en `docs/localization.md`.

## Reglas de mantenimiento

- Para volver a ver la bienvenida en desarrollo, borrar datos de la app o eliminar la clave `onboardingSeen`.
- Si se agrega una pagina, mantener el patron bento sin huecos y usar presets existentes o agregarlos a `docs/assets.md`.
- No pedir permisos ni datos aqui: la bienvenida es informativa.
