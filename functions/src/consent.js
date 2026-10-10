// Lógica pura del correo de confirmación del consentimiento parental.
//
// COPPA acepta el método "email plus" cuando los datos solo se usan de forma
// interna: la persona adulta da su consentimiento con un correo verificado y,
// después de un tiempo, recibe un segundo correo que confirma ese
// consentimiento y explica cómo revocarlo. Este módulo decide a quién enviarlo
// y arma el mensaje; no toca Firebase para poder probarse sin un proyecto.

/** Horas de espera entre la aceptación y el correo de confirmación. */
const CONFIRMATION_DELAY_HOURS = 24;

/**
 * Indica si a la cuenta le toca recibir el correo de confirmación.
 *
 * @param {object} user Documento `users/{uid}` (datos crudos de Firestore).
 * @param {Date} acceptedAt Hora de servidor de la aceptación, o null.
 * @param {boolean} emailVerified Estado de verificación en Firebase Auth.
 * @param {Date} now Hora actual.
 * @returns {boolean}
 */
function isConfirmationDue(user, acceptedAt, emailVerified, now) {
  const legal = user && user.legal;
  if (!legal || legal.confirmationPending !== true) return false;
  // Los perfiles infantiles no tienen correo propio ni dan consentimiento.
  if (user.role === 'learner') return false;
  // Sin correo verificado no hay a quién confirmar; la app no deja avanzar.
  if (!emailVerified) return false;
  if (!(acceptedAt instanceof Date)) return false;
  const elapsedMs = now.getTime() - acceptedAt.getTime();
  return elapsedMs >= CONFIRMATION_DELAY_HOURS * 60 * 60 * 1000;
}

/**
 * Escapa texto para insertarlo en el HTML del correo.
 * @param {string} text
 */
function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Formatea la fecha de aceptación en el idioma indicado, en hora de Tijuana.
 * @param {Date} date
 * @param {'es'|'en'} lang
 */
function formatDate(date, lang) {
  return new Intl.DateTimeFormat(lang === 'es' ? 'es-MX' : 'en-US', {
    dateStyle: 'long',
    timeZone: 'America/Tijuana',
  }).format(date);
}

/**
 * Arma el correo bilingüe de confirmación.
 *
 * No incluye nombres de los perfiles infantiles: el correo puede leerse en
 * dispositivos compartidos y no necesita datos del menor.
 *
 * @param {object} params
 * @param {string} params.name Nombre para mostrar de la persona adulta.
 * @param {Date} params.acceptedAt Hora de la aceptación.
 * @param {number} params.version Versión aceptada de los documentos legales.
 * @param {string} params.legalBaseUrl URL https de las páginas legales, o ''.
 * @param {string} params.contactEmail Correo de privacidad y derechos ARCO.
 * @returns {{subject: string, text: string, html: string}}
 */
function buildConfirmationEmail({
  name,
  acceptedAt,
  version,
  legalBaseUrl,
  contactEmail,
}) {
  const base = (legalBaseUrl || '').replace(/\/+$/, '');
  const privacyEs = base ? `${base}/privacy-es.html` : '';
  const privacyEn = base ? `${base}/privacy-en.html` : '';
  const greetingName = name && name.trim() ? ` ${name.trim()}` : '';

  const es = [
    `Hola${greetingName}:`,
    `El ${formatDate(acceptedAt, 'es')} aceptaste los Términos y Condiciones y ` +
      `el Aviso de Privacidad de Appy (versión ${version}) como madre, padre o ` +
      'tutor legal, y autorizaste el tratamiento de los datos de los perfiles ' +
      'infantiles de tu cuenta.',
    'Appy guarda el avance educativo, la personalización del avatar, las ' +
      'preferencias de cada perfil y, solo si las activas, métricas de uso de ' +
      'las actividades. No hay publicidad ni se venden datos.',
    'Si no fuiste tú o quieres revocar tu consentimiento, elimina la cuenta en ' +
      `Ajustes → Cuenta y seguridad, o escribe a ${contactEmail}. Al eliminarla ` +
      'se borran todos los datos de la cuenta y de sus perfiles.',
  ];
  if (privacyEs) es.push(`Aviso de Privacidad: ${privacyEs}`);

  const en = [
    `Hello${greetingName},`,
    `On ${formatDate(acceptedAt, 'en')} you accepted Appy's Terms and ` +
      `Conditions and Privacy Notice (version ${version}) as a parent or legal ` +
      'guardian, and authorized the processing of the child profiles in your ' +
      'account.',
    'Appy stores learning progress, avatar customization, each profile\'s ' +
      'preferences and, only if you turn them on, activity usage metrics. There ' +
      'are no ads and no data is sold.',
    'If this wasn\'t you or you want to withdraw your consent, delete the ' +
      `account in Settings → Account & security, or write to ${contactEmail}. ` +
      'Deleting it removes all data of the account and its profiles.',
  ];
  if (privacyEn) en.push(`Privacy Notice: ${privacyEn}`);

  const text = [...es, '', '—', '', ...en].join('\n\n');
  const paragraphs = (lines) =>
    lines.map((line) => `<p>${escapeHtml(line)}</p>`).join('\n');
  const html =
    `<div lang="es">${paragraphs(es)}</div>\n<hr>\n` +
    `<div lang="en">${paragraphs(en)}</div>`;

  return {
    subject:
      'Confirmación de tu consentimiento en Appy / Your Appy consent confirmation',
    text,
    html,
  };
}

module.exports = {
  CONFIRMATION_DELAY_HOURS,
  isConfirmationDue,
  buildConfirmationEmail,
};
