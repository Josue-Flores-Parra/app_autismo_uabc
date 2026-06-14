# ADR 0001: MVVM con Provider y Firebase

## Estado

Aceptado.

## Contexto

La app necesita separar UI, estado de pantalla y acceso a Firebase para que el
codigo sea mantenible por varios colaboradores. El proyecto usa Flutter,
Firebase Auth, Cloud Firestore y `provider`.

La estructura del repo ya esta organizada por features, con carpetas `view`,
`viewmodel`, `model` y `data` cuando aplica. Tambien existen servicios
compartidos bajo `lib/data/services` y `lib/shared/services`.

## Decision

Usar una arquitectura MVVM ligera:

```text
View -> ViewModel -> Service/Repository -> Firebase/Assets/Plugins
```

Implementacion esperada:

| Rol | Ubicacion esperada |
| --- | --- |
| View | `lib/features/*/view` |
| ViewModel | `lib/features/*/viewmodel` |
| Service | `lib/data/services` o `lib/shared/services` |
| Repository | `lib/features/*/data` |
| Model | `lib/data/models` o `lib/features/*/model` |
| Provider | `main.dart` o subarbol de la feature |

La inyeccion de estado global se realiza con `provider`:

- `ChangeNotifierProvider`.
- `ChangeNotifierProxyProvider`.
- `Consumer`.
- `context.read/watch` en pantallas.

## Estado actual

La decision describe la direccion arquitectonica, pero el codigo actual tiene
excepciones:

- `AvatarViewModel` usa `FirebaseAuth.instance.currentUser` directamente.
- `ModuleListScreen` lee `FirebaseAuth.instance.currentUser` directamente para mostrar nombre.
- `MainShell` usa `FirebaseAuth.instance` directamente para recuperar PIN con reautenticacion.
- `SettingsPage` mezcla UI con dialogs de cuenta y llamadas a `AuthViewModel`.
- `LevelContentPreviewScreen` contiene logica de decision para lanzar actividades segun la tarjeta seleccionada.
- `ModuleListViewModel` existe, pero el flujo principal usa `LearningViewModel`.

Estas excepciones no invalidan el ADR, pero deben conocerse antes de refactorizar
o agregar features. La documentacion de `docs/architecture.md` y las paginas de
feature describen el comportamiento real con mas detalle.

## Consecuencias positivas

- Hay una estructura repetible por feature.
- Las pantallas principales consumen estado con Provider.
- Muchos side effects estan encapsulados en servicios o ViewModels.
- `LearningViewModel` centraliza carga de modulos, niveles y progreso.
- `LevelCompletionService` centraliza guardado de progreso y recompensas.

## Costos

- Hay mas archivos por feature.
- Se requiere disciplina para no saltarse capas.
- Algunos servicios crean Firebase directamente y son dificiles de testear.
- Algunas pantallas contienen logica de flujo compleja que podria estar en ViewModels.
- Las desviaciones reales deben documentarse para no confundir a nuevos devs.

## Reglas derivadas

- No agregar nuevo acceso directo a Firebase desde Views salvo que se documente y justifique.
- Preferir `Service` o `Repository` para integraciones externas.
- Preferir `ChangeNotifier` para estado mutable visible por UI.
- Documentar cambios de schema en `docs/data-model.md`.
- Documentar nuevos `actividadType` en `docs/features/minigames.md`.
- Agregar tests para parsers y ViewModels cuando cambie logica.
- Si se refactoriza una excepcion hacia MVVM mas estricto, actualizar este ADR y `docs/architecture.md`.
