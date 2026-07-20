const env = require('../config/env');

let app = null;
let messaging = null;

function init() {
  if (!env.firebase.configured) return null;
  if (app) return app;

  // Lazy-require so the package is optional at runtime if never configured.
  const admin = require('firebase-admin');
  app = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.firebase.projectId,
      clientEmail: env.firebase.clientEmail,
      privateKey: env.firebase.privateKey,
    }),
  });
  messaging = admin.messaging();
  return app;
}

/**
 * Verifies a Firebase ID token sent by the client after phone/Google login.
 * Returns { uid, phone, email, name } or throws.
 * In dev mode (no Firebase configured), accepts a demo token "DEMO_TOKEN:<phone>"
 * so the API is exercisable without real Firebase credentials.
 */
async function verifyIdToken(idToken) {
  if (!env.firebase.configured) {
    if (typeof idToken === 'string' && idToken.startsWith('DEMO_TOKEN:')) {
      const phone = idToken.slice('DEMO_TOKEN:'.length);
      return { uid: `demo_${phone}`, phone, email: null, name: null, devMode: true };
    }
    const err = new Error('Firebase is not configured on this server (dev mode requires a DEMO_TOKEN:<phone> token)');
    err.status = 503;
    throw err;
  }
  init();
  const admin = require('firebase-admin');
  const decoded = await admin.auth().verifyIdToken(idToken);
  return {
    uid: decoded.uid,
    phone: decoded.phone_number || null,
    email: decoded.email || null,
    name: decoded.name || null,
    devMode: false,
  };
}

/**
 * Sends a push notification via FCM. No-ops (logs) if Firebase isn't configured.
 */
async function sendPushNotification({ token, title, body, data }) {
  if (!env.firebase.configured) {
    console.log(`[fcm:dev-mode] would send push to ${token}: ${title} — ${body}`);
    return { sent: false, reason: 'firebase-not-configured' };
  }
  init();
  const message = {
    token,
    notification: { title, body },
    data: data ? Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])) : undefined,
  };
  const id = await messaging.send(message);
  return { sent: true, id };
}

module.exports = { verifyIdToken, sendPushNotification };
