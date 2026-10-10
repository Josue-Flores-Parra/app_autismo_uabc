// Siembra cuentas de prueba en los emuladores para probar
// sendConsentConfirmations sin un proyecto real.
//
// Uso (con los emuladores corriendo, desde functions/):
//   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
//   node scripts/seed-emulator.js
//
// Crea tres padres: uno que debe recibir el correo, uno con correo sin
// verificar y uno que aceptó hace una hora. Solo escribe en los emuladores.

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Define FIRESTORE_EMULATOR_HOST y FIREBASE_AUTH_EMULATOR_HOST.');
  process.exit(1);
}

initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-appy' });

const hoursAgo = (h) => Timestamp.fromMillis(Date.now() - h * 3600 * 1000);

const parents = [
  { uid: 'debe-recibir', email: 'debe-recibir@example.com', verified: true, hours: 25 },
  { uid: 'sin-verificar', email: 'sin-verificar@example.com', verified: false, hours: 25 },
  { uid: 'muy-reciente', email: 'muy-reciente@example.com', verified: true, hours: 1 },
];

(async () => {
  const auth = getAuth();
  const db = getFirestore();
  for (const p of parents) {
    await auth.deleteUser(p.uid).catch(() => {});
    await auth.createUser({
      uid: p.uid,
      email: p.email,
      emailVerified: p.verified,
      displayName: `Prueba ${p.uid}`,
    });
    await db.collection('users').doc(p.uid).set({
      role: 'parent',
      name: `Prueba ${p.uid}`,
      email: p.email,
      legal: {
        version: 2,
        acceptedAt: new Date().toISOString(),
        acceptedAtServer: hoursAgo(p.hours),
        consentMethod: 'email_plus',
        confirmationPending: true,
      },
    });
    console.log('sembrado', p.uid);
  }
})();
