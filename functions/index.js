// Cloud Functions de Appy.
//
// sendConsentConfirmations completa el consentimiento parental "email plus":
// la app registra la aceptación con `legal.confirmationPending = true` y, al
// menos 24 horas después, esta función envía el correo de confirmación y apaga
// la marca. Las reglas de Firestore impiden que el cliente la apague.

const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { logger } = require('firebase-functions');
const { defineInt, defineSecret, defineString } = require('firebase-functions/params');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const nodemailer = require('nodemailer');

const { buildConfirmationEmail, isConfirmationDue } = require('./src/consent');

initializeApp();

// Configuración del correo. Los valores no secretos se guardan en
// `functions/.env.<proyecto>` al desplegar; la contraseña va en Secret Manager.
const smtpHost = defineString('SMTP_HOST');
const smtpPort = defineInt('SMTP_PORT', { default: 465 });
const smtpUser = defineString('SMTP_USER');
const smtpPassword = defineSecret('SMTP_PASSWORD');
const mailFrom = defineString('MAIL_FROM');
const legalBaseUrl = defineString('LEGAL_BASE_URL', { default: '' });
const contactEmail = defineString('CONTACT_EMAIL', {
  default: 'rosalesq.software@gmail.com',
});

exports.sendConsentConfirmations = onSchedule(
  {
    schedule: 'every 6 hours',
    timeZone: 'America/Tijuana',
    secrets: [smtpPassword],
    // Una sola instancia evita enviar dos veces el mismo correo.
    maxInstances: 1,
  },
  async () => {
    const db = getFirestore();
    const auth = getAuth();
    const transport = nodemailer.createTransport({
      host: smtpHost.value(),
      port: smtpPort.value(),
      secure: smtpPort.value() === 465,
      auth: { user: smtpUser.value(), pass: smtpPassword.value() },
    });

    const pending = await db
      .collection('users')
      .where('legal.confirmationPending', '==', true)
      .get();
    const now = new Date();
    let sent = 0;

    for (const doc of pending.docs) {
      const user = doc.data();
      const acceptedAt = user.legal.acceptedAtServer?.toDate?.() ?? null;
      let authUser;
      try {
        authUser = await auth.getUser(doc.id);
      } catch (error) {
        // Cuenta borrada en Auth: su documento desaparece con la eliminación.
        logger.warn('Cuenta sin usuario de Auth', { uid: doc.id, code: error.code });
        continue;
      }
      if (!isConfirmationDue(user, acceptedAt, authUser.emailVerified, now)) {
        continue;
      }

      const email = buildConfirmationEmail({
        name: authUser.displayName ?? user.name ?? '',
        acceptedAt,
        version: user.legal.version,
        legalBaseUrl: legalBaseUrl.value(),
        contactEmail: contactEmail.value(),
      });

      try {
        await transport.sendMail({
          from: mailFrom.value(),
          to: authUser.email,
          replyTo: contactEmail.value(),
          ...email,
        });
      } catch (error) {
        // Se reintenta en la siguiente ejecución porque la marca sigue activa.
        logger.error('No se pudo enviar la confirmación', { uid: doc.id, error: error.message });
        continue;
      }

      try {
        // La precondición evita apagar la marca si el padre aceptó otra
        // versión mientras se enviaba el correo: esa versión necesita el suyo.
        await doc.ref.update(
          {
            'legal.confirmationPending': false,
            'legal.confirmationSentAt': FieldValue.serverTimestamp(),
            'legal.confirmationVersion': user.legal.version,
          },
          { lastUpdateTime: doc.updateTime },
        );
        sent++;
      } catch (error) {
        logger.warn('Confirmación enviada pero el documento cambió', { uid: doc.id });
      }
    }

    logger.info('Confirmaciones de consentimiento', {
      pending: pending.size,
      sent,
    });
  },
);
