// Copia el contenido de la app (`modules` y sus `levels`) de un proyecto
// Firebase a otro. Lee del origen y solo escribe en el destino.
//
// Uso:
//   node copy-content.js --from-key <llave-prod.json> --to-key <llave-dev.json> [--write]
//
// Sin `--write` solo cuenta lo que copiaria. Las llaves son de cuentas de
// servicio (Configuracion del proyecto > Cuentas de servicio) y deben
// guardarse fuera del repo.

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, DocumentReference } = require('firebase-admin/firestore');
const fs = require('node:fs');

// El destino nunca puede ser produccion: ahi viven las cuentas reales.
const PROTECTED_PROJECTS = new Set(['app-autismo-25f44']);
// Limite de operaciones por lote de Firestore.
const BATCH_LIMIT = 500;

function parseArgs(argv) {
  const args = { write: false };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--write') args.write = true;
    else if (argv[i] === '--from-key') args.fromKey = argv[++i];
    else if (argv[i] === '--to-key') args.toKey = argv[++i];
    else throw new Error(`Argumento desconocido: ${argv[i]}`);
  }
  if (!args.fromKey || !args.toKey) {
    throw new Error('Faltan --from-key y --to-key.');
  }
  return args;
}

function openProject(keyPath, name) {
  const key = JSON.parse(fs.readFileSync(keyPath, 'utf8'));
  const app = initializeApp({ credential: cert(key) }, name);
  return { projectId: key.project_id, db: getFirestore(app) };
}

// Las referencias apuntan a la base de origen; se reescriben hacia el destino
// para que el contenido copiado no enlace documentos de otro proyecto.
function remapReferences(value, targetDb) {
  if (value instanceof DocumentReference) return targetDb.doc(value.path);
  if (Array.isArray(value)) return value.map((v) => remapReferences(v, targetDb));
  if (value && typeof value === 'object' && value.constructor === Object) {
    return Object.fromEntries(
      Object.entries(value).map(([k, v]) => [k, remapReferences(v, targetDb)]),
    );
  }
  return value;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const source = openProject(args.fromKey, 'source');
  const target = openProject(args.toKey, 'target');

  if (PROTECTED_PROJECTS.has(target.projectId)) {
    throw new Error(`El destino ${target.projectId} es produccion; no se escribe ahi.`);
  }
  if (source.projectId === target.projectId) {
    throw new Error('El origen y el destino son el mismo proyecto.');
  }
  console.log(`Origen: ${source.projectId} -> destino: ${target.projectId}`);

  // Se lee todo antes de escribir para no dejar el destino a medias si la
  // lectura falla.
  const docs = [];
  const modules = await source.db.collection('modules').get();
  for (const module of modules.docs) {
    docs.push(module);
    const levels = await module.ref.collection('levels').get();
    docs.push(...levels.docs);
  }
  console.log(`${modules.size} modulos y ${docs.length - modules.size} niveles leidos.`);

  if (!args.write) {
    console.log('Ensayo: no se escribio nada. Agrega --write para copiar.');
    return;
  }

  for (let i = 0; i < docs.length; i += BATCH_LIMIT) {
    const batch = target.db.batch();
    for (const doc of docs.slice(i, i + BATCH_LIMIT)) {
      batch.set(target.db.doc(doc.ref.path), remapReferences(doc.data(), target.db));
    }
    await batch.commit();
  }
  console.log(`${docs.length} documentos copiados a ${target.projectId}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
