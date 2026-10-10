const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  isConfirmationDue,
  buildConfirmationEmail,
} = require('../src/consent');

const now = new Date('2026-10-10T12:00:00Z');
const hoursAgo = (h) => new Date(now.getTime() - h * 3600 * 1000);
const parent = (legal) => ({ role: 'parent', legal });

describe('isConfirmationDue', () => {
  it('sends once 24 hours have passed for a verified parent', () => {
    const user = parent({ version: 2, confirmationPending: true });
    assert.equal(isConfirmationDue(user, hoursAgo(24), true, now), true);
  });

  it('waits until 24 hours have passed', () => {
    const user = parent({ version: 2, confirmationPending: true });
    assert.equal(isConfirmationDue(user, hoursAgo(23), true, now), false);
  });

  it('skips accounts with an unverified email', () => {
    const user = parent({ version: 2, confirmationPending: true });
    assert.equal(isConfirmationDue(user, hoursAgo(48), false, now), false);
  });

  it('skips accounts already confirmed or without a record', () => {
    assert.equal(
      isConfirmationDue(parent({ confirmationPending: false }), hoursAgo(48), true, now),
      false,
    );
    assert.equal(isConfirmationDue({ role: 'parent' }, hoursAgo(48), true, now), false);
  });

  it('skips child profiles and missing server timestamps', () => {
    const learner = { role: 'learner', legal: { confirmationPending: true } };
    assert.equal(isConfirmationDue(learner, hoursAgo(48), true, now), false);
    const user = parent({ version: 2, confirmationPending: true });
    assert.equal(isConfirmationDue(user, null, true, now), false);
  });
});

describe('buildConfirmationEmail', () => {
  const email = buildConfirmationEmail({
    name: 'Ana <script>',
    acceptedAt: new Date('2026-10-09T18:00:00Z'),
    version: 2,
    legalBaseUrl: 'https://example.org/legal/',
    contactEmail: 'privacy@example.org',
  });

  it('is bilingual and states the accepted version and date', () => {
    assert.match(email.subject, /Confirmación/);
    assert.match(email.subject, /confirmation/);
    assert.match(email.text, /versión 2/);
    assert.match(email.text, /version 2/);
    assert.match(email.text, /9 de octubre de 2026/);
    assert.match(email.text, /October 9, 2026/);
  });

  it('explains how to withdraw consent', () => {
    assert.match(email.text, /Cuenta y seguridad/);
    assert.match(email.text, /Account & security/);
    assert.match(email.text, /privacy@example\.org/);
  });

  it('links both privacy notices without a double slash', () => {
    assert.match(email.text, /https:\/\/example\.org\/legal\/privacy-es\.html/);
    assert.match(email.text, /https:\/\/example\.org\/legal\/privacy-en\.html/);
  });

  it('escapes the display name in the HTML body', () => {
    assert.ok(!email.html.includes('<script>'));
    assert.ok(email.html.includes('Ana &lt;script&gt;'));
  });

  it('omits links when no public legal URL is configured', () => {
    const plain = buildConfirmationEmail({
      name: '',
      acceptedAt: new Date('2026-10-09T18:00:00Z'),
      version: 2,
      legalBaseUrl: '',
      contactEmail: 'privacy@example.org',
    });
    assert.ok(!plain.text.includes('http'));
    assert.match(plain.text, /^Hola:/);
  });
});
