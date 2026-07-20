require('dotenv').config();

function bool(v, def = false) {
  if (v === undefined) return def;
  return String(v).toLowerCase() === 'true';
}

const env = {
  port: Number(process.env.PORT || 4000),
  nodeEnv: process.env.NODE_ENV || 'development',
  clientUrl: process.env.CLIENT_URL || 'http://localhost:3000',

  databaseUrl: process.env.DATABASE_URL || '',

  jwtSecret: process.env.JWT_SECRET || 'dev-only-insecure-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',

  adminSeedPhone: process.env.ADMIN_SEED_PHONE || '01700000000',
  adminSeedPassword: process.env.ADMIN_SEED_PASSWORD || 'admin2026',

  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    get configured() {
      return Boolean(this.projectId && this.clientEmail && this.privateKey);
    },
  },

  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
    apiKey: process.env.CLOUDINARY_API_KEY || '',
    apiSecret: process.env.CLOUDINARY_API_SECRET || '',
    get configured() {
      return Boolean(this.cloudName && this.apiKey && this.apiSecret);
    },
  },

  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || '',

  smtp: {
    host: process.env.SMTP_HOST || '',
    port: Number(process.env.SMTP_PORT || 587),
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASS || '',
    fromEmail: process.env.SMTP_FROM_EMAIL || 'no-reply@dhopabari.com',
    fromName: process.env.SMTP_FROM_NAME || 'Dhopa Bari',
    get configured() {
      return Boolean(this.host && this.user && this.pass);
    },
  },

  resetPassword: {
    // Base URL of the web page that hosts the "set a new password" form,
    // e.g. https://app.dhopabari.com/reset-password?token=...
    webUrl: process.env.RESET_PASSWORD_WEB_URL || 'http://localhost:3000/reset-password',
    tokenTtlMinutes: Number(process.env.RESET_PASSWORD_TTL_MINUTES || 30),
  },

  bkash: {
    appKey: process.env.BKASH_APP_KEY || '',
    appSecret: process.env.BKASH_APP_SECRET || '',
    username: process.env.BKASH_USERNAME || '',
    password: process.env.BKASH_PASSWORD || '',
    baseUrl: process.env.BKASH_BASE_URL || '',
    get configured() {
      return Boolean(this.appKey && this.appSecret && this.username && this.password);
    },
  },
  nagad: {
    merchantId: process.env.NAGAD_MERCHANT_ID || '',
    merchantPrivateKey: process.env.NAGAD_MERCHANT_PRIVATE_KEY || '',
    pgPublicKey: process.env.NAGAD_PG_PUBLIC_KEY || '',
    baseUrl: process.env.NAGAD_BASE_URL || '',
    get configured() {
      return Boolean(this.merchantId && this.merchantPrivateKey && this.pgPublicKey);
    },
  },
  sslcommerz: {
    storeId: process.env.SSLCOMMERZ_STORE_ID || '',
    storePassword: process.env.SSLCOMMERZ_STORE_PASSWORD || '',
    sandbox: bool(process.env.SSLCOMMERZ_SANDBOX, true),
    get configured() {
      return Boolean(this.storeId && this.storePassword);
    },
  },
};

// Fail fast in production rather than silently running with insecure
// defaults — a missing/weak JWT secret or DB URL is an auth-bypass /
// total-outage risk that should never reach a live deploy unnoticed.
if (env.nodeEnv === 'production') {
  const problems = [];
  if (!process.env.JWT_SECRET || env.jwtSecret === 'dev-only-insecure-secret' || env.jwtSecret.length < 32) {
    problems.push('JWT_SECRET is missing, using the dev default, or shorter than 32 characters');
  }
  if (!env.databaseUrl) {
    problems.push('DATABASE_URL is not set');
  }
  if (env.clientUrl === '*') {
    problems.push('CLIENT_URL is "*" — do not use a wildcard origin together with credentialed CORS in production');
  }
  if (!process.env.ADMIN_SEED_PASSWORD || env.adminSeedPassword === 'admin2026') {
    problems.push('ADMIN_SEED_PASSWORD is missing or using the default seed password');
  }
  if (problems.length) {
    throw new Error(`Refusing to start in production with insecure configuration:\n  - ${problems.join('\n  - ')}`);
  }
}

module.exports = env;
