# Especificación de consultas KPI de telemetría

Este documento fija el contrato de consultas para los siete KPI iniciales usando
exclusivamente documentos de `telemetryActivitySessions` (salvo el KPI 7 de
progreso de módulo). Usa aggregate queries de Firestore (`count`, `sum`,
`average`) sobre rangos temporales y filtros de dashboard dados. No hay
documentos agregados ni Cloud Functions.

## Filtros temporales

- Para KPIs de **iniciadas** se filtra por `timing.startedAt` (nunca por
  `createdAt`), lo que excluye por diseño `launch_requested`/`launch_error`.
- Para conteos históricos generales se puede usar `createdAt`.
- El dashboard trata todo denominador `0` como **N/D**.

## Conjunto base de rangos

```text
start = <inicio del rango>
end   = <fin del rango>
```

Todas las consultas parten de `telemetryActivitySessions` y añaden
`timing.startedAt >= start && timing.startedAt < end`, salvo que se indique otra
columna temporal.

---

## KPI 1 — Promedio de tiempo activo

`sum(timing.activeDurationMs) / count(...)` sobre completadas.

```dart
final q = db.collection('telemetryActivitySessions')
  .where('lifecycle.status', isEqualTo: 'completed')
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end);
final res = await q.count().get();               // denominador
final sum = await q.aggregate(
  sum('timing.activeDurationMs'),
  average('timing.activeDurationMs'),
).get();                                          // numerador y promedio
```

Si `count == 0` → mostrar N/D (no 0 ms).

## KPI 2 — Repeticiones de video por actividad iniciada

`sum(video.replayCount) / count(outcome.hasStarted == true)`. El denominador
incluye todas las actividades iniciadas de cualquier tipo; los no-video aportan
`replayCount = 0`.

```dart
final q = db.collection('telemetryActivitySessions')
  .where('outcome.hasStarted', isEqualTo: true)
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end);
final res = await q.aggregate(
  sum('video.replayCount'),
  count(),
).get(); // resultado = sum / count
```

## KPI 3 — Tasa de abandono

`count(lifecycle.status == abandoned) / count(outcome.hasStarted == true)`.

```dart
final abandoned = db.collection('telemetryActivitySessions')
  .where('lifecycle.status', isEqualTo: 'abandoned')
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end)
  .count().get();
final started = db.collection('telemetryActivitySessions')
  .where('outcome.hasStarted', isEqualTo: true)
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end)
  .count().get();
// tasa = abandoned / started
```

`launch_error` queda fuera de ambos términos (no tiene `hasStarted == true`).

## KPI 4 — Navegación exitosa

`count(status == completed && wasInterrupted == false) / count(hasStarted == true)`.

```dart
final ok = db.collection('telemetryActivitySessions')
  .where('lifecycle.status', isEqualTo: 'completed')
  .where('lifecycle.wasInterrupted', isEqualTo: false)
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end)
  .count().get();
final started = /* igual que KPI 3 */;
```

Una sesión interrumpida que luego completa cuenta para finalización (KPI 5),
pero no para navegación exitosa.

## KPI 5 — Tasa de finalización

`count(lifecycle.status == completed) / count(outcome.hasStarted == true)`,
independientemente de interrupciones.

```dart
final completed = db.collection('telemetryActivitySessions')
  .where('lifecycle.status', isEqualTo: 'completed')
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end)
  .count().get();
final started = /* igual que KPI 3 */;
```

## KPI 6 — Intentos promedio

`sum(interaction.attempts) / count(...)` sólo sobre interactivas (`simple_selection`
y `puzzle`) completadas.

```dart
final q = db.collection('telemetryActivitySessions')
  .where('lifecycle.status', isEqualTo: 'completed')
  .where('interaction.attemptsApplicable', isEqualTo: true)
  .where('timing.startedAt', isGreaterThanOrEqualTo: start)
  .where('timing.startedAt', isLessThan: end);
final res = await q.aggregate(
  sum('interaction.attempts'),
  count(),
).get(); // promedio = sum / count
```

Video e interactivas fallidas no participan. Los intentos se acumulan entre
reintentos globales/runs de la misma sesión.

## KPI 7 — Progreso de módulo

No se consulta telemetría. Para `learnerId` y `moduleId`:

1. Niveles definidos: `modules/{moduleId}/levels` (únicos por `levelId`).
2. Progreso: `users/{learnerId}/progress/{moduleId}/levels` (únicos por `levelId`).
3. Contar `levelId` únicos cuyo progreso cumpla `status == completed` o
   `estrellas > 0` (conforme a `../data-model.md`).
4. Dividir entre niveles únicos definidos cuando se requiera porcentaje.

```dart
final defined = await db.collection('modules').doc(moduleId)
  .collection('levels').get();                       // ids únicos
final progress = await db.collection('users').doc(learnerId)
  .collection('progress').doc(moduleId)
  .collection('levels').get();                       // ids únicos
// completados = progress donde (status == 'completed' || estrellas > 0)
// porcentaje = completados / defined.length
```

Documentos/lecturas repetidas del mismo nivel no incrementan el conteo.

## Índices

Los índices compuestos necesarios están en `../../firestore.indexes.json`. Se crean a
partir de las consultas exactas de esta especificación; no crear índices
redundantes "por si acaso" (cada índice aumenta costo de escritura/almacenamiento).

## Resolución de identidad visible

`subject.learnerId` / `subject.actorId` son UIDs sin PII. Para mostrar un nombre
visible, el dashboard (rol/backend privilegiado, no cliente móvil) resuelve
`users/{learnerId}` con permiso verificable. No se copia PII a telemetría.
## Validación y despliegue

### Harness de emulador

Los tests de reglas (matriz §12) y la validación de agregados KPI (fixtures §15)
viven en `../../firestore-tests` (Node aislado del proyecto Flutter):

```sh
cd firestore-tests && npm install          # una vez
firebase emulators:exec --only firestore --project demo-appy \
  "export PATH=/usr/bin:\$PATH && cd firestore-tests && npm test"
```

El emulador carga `firestore.rules` y `../../firestore.indexes.json` del repo; si una
consulta KPI requiere un índice no declarado, el error del emulador muestra el
índice exacto a crear.

### Despliegue

- **Índices** (aditivo y no destructivo, seguro de re-ejecutar):

  ```sh
  firebase deploy --only firestore:indexes
  ```

- **Reglas**: este proyecto se gestionan en la consola de Firebase (editor de
  reglas). El archivo `firestore.rules` del repo es la fuente de verdad para
  copiar el bloque `match /telemetryActivitySessions/{sessionId}` + funciones
  helper en la consola. NO desplegar `firestore.rules` con `firebase deploy`
  salvo que el archivo contenga también las reglas de las demás colecciones
  (`users`, `modules`, ...), porque el deploy reemplaza todo el ruleset.

### Rollback

- **Reglas**: en la consola, Firestore → Rules → historial de versiones y
  restaurar la versión previa.
- **Índices**: Firestore → Indexes → eliminar el índice compuesto problemático
  (los índices no afectan datos; sólo vuelven la consulta a pedir índice, no
  rompen escrituras).

## Diccionario de estados y razones terminales

`lifecycle.status` es el estado canónico.

| Estado | Significado | `outcome.hasStarted` |
| --- | --- | --- |
| `launch_requested` | El usuario confirmó el launch. | `false` |
| `started` | La actividad notificó `onReady`. | `true` |
| `completed` | Finalización de producto alcanzada. | `true` |
| `abandoned` | Salida explícita o timeout de inactividad. | `true` |
| `failed` | Fallo definitivo (reintentos agotados). | `true` |
| `launch_error` | No se llegó a una actividad lista. | `false` |

`outcome.terminalReason` (controlado, nunca texto libre):

- `completed`: `objective_completed`.
- `abandoned`: `user_back`, `user_exit`, `route_removed`,
  `inactivity_timeout`, `stale_session`, `telemetry_opt_out`.
- `failed`: `attempts_exhausted`, `definitive_activity_failure`.
- `launch_error`: `activity_unavailable`, `invalid_activity_data`,
  `resource_initialization_failed`, `navigation_failed`,
  `launch_cancelled_before_navigation`.

## Ejemplo sanitizado (sesión completada)

```json
{
  "schemaVersion": 1,
  "sessionId": "c93e3713-7399-450e-9a66-ff9657000741",
  "subject": { "learnerId": "uid-abc", "actorId": "uid-abc", "identityModel": "account_as_learner" },
  "activity": { "activityId": "m1:l1:simple_selection", "moduleId": "m1", "levelId": "l1", "activityType": "simple_selection" },
  "outcome": { "hasStarted": true, "objectiveReached": true, "isCompleted": true, "navigationSuccessful": true, "terminalReason": "objective_completed" },
  "timing": { "activeDurationMs": 12500, "activeSegmentCount": 1, "launchRequestedAt": "<server>", "startedAt": "<server>", "objectiveMetAt": "<server>", "terminalAt": "<server>" },
  "lifecycle": { "status": "completed", "wasInterrupted": false, "interruptionCount": 0 },
  "interaction": { "attemptsApplicable": true, "attempts": 3, "runCount": 1 },
  "video": { "replayCount": 0, "objectiveThreshold": null },
  "client": { "platform": "android", "appVersion": "1.0.0", "buildNumber": "4", "locale": "es" },
  "createdAt": "<server>",
  "updatedAt": "<server>"
}
```
