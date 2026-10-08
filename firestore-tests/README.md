# Firestore emulator tests (telemetry)

Harness aislado (Node) para validar las reglas de seguridad de
`telemetryActivitySessions` y las consultas KPI contra el Firestore Emulator.
No toca `pubspec.yaml` ni el código Flutter.

## Requisitos

- Node >= 20 (probado con Node 22) y npm.
- Java 11+ (requerido por el emulador de Firestore; el jar se descarga solo la
  primera vez).
- Firebase CLI (`firebase`). Se usa en modo demo, sin credenciales.

## Instalación (una vez)

```sh
cd firestore-tests
npm install
```

## Ejecución

Desde la raíz del repo (para que el emulador lea `firebase.json`,
`firestore.rules` y `firestore.indexes.json`):

```sh
firebase emulators:exec --only firestore --project demo-appy \
  "export PATH=/usr/bin:\$PATH && cd firestore-tests && npm test"
```

> **Nota (Linux):** se exporta `PATH=/usr/bin` primero porque `firebase
> emulators:exec` pone en PATH un `node` shim (v20) que no respeta flags
> (`node -v` falla con "Cannot find module -v"). El PATH real de Node es
> `/usr/bin/node` (v22). Sin este export, los tests ni siquiera arrancan.

El script corre los tres archivos **en serie** (evita que las limpiezas de un
suite borren datos del otro):

```sh
node --test tests/rules.test.js && node --test tests/kpi.test.js && node --test tests/terminal-recovery.test.js
```

- `tests/rules.test.js` — matriz de reglas (§12): create propio/ajeno/inválido,
  campos inmutables, terminalidad, no-decremento, transiciones, delete/get/list.
- `tests/kpi.test.js` — fixtures de §15 y aggregate queries reales para KPI 1-7.
  El emulador valida también que los índices de `firestore.indexes.json` cubran
  las consultas; si falta un índice, el error indicará el índice exacto a crear.
- `tests/terminal-recovery.test.js` — secuencia de recuperación del cliente tras
  quedar offline: de `launch_requested` a `started` antes de abandonar, sin
  permitir sobrescribir un estado terminal.

## Notas

- `firebase-admin` siembra los fixtures saltándose las reglas (sólo para KPI).
  Las reglas se prueban aparte con `@firebase/rules-unit-testing`.
- Cada KPI usa su propio día en `timing.startedAt` (año 2027) para no
  contaminarse entre tests ni con `new Date()` escritos por otros suites.
- Los tests de reglas usan `timing.startedAt` fijo (2000-01-01) por la misma
  razón.