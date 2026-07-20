const env = require('../config/env');

/**
 * Payment gateway integrations. Each of bKash/Nagad/SSLCommerz has its own
 * multi-step tokenized checkout flow with sandbox/live credentials only the
 * merchant (you) can obtain by registering with that provider. These
 * functions define the integration surface our order/checkout flow calls
 * against; until real credentials are set in .env, they return a clear
 * "not configured" error rather than pretending to charge anything.
 */

function assertConfigured(gateway, configured) {
  if (!configured) {
    const err = new Error(`${gateway} is not configured on this server — add credentials to .env to enable it`);
    err.status = 503;
    throw err;
  }
}

// Integration point: tokenized checkout — POST /tokenized/checkout/create
// against env.bkash.baseUrl using an OAuth grant token from
// /tokenized/checkout/token/grant (username/password/app key/secret).
// Requires real bKash merchant credentials, which only the business owner
// can obtain by registering with bKash — deliberately not implemented here.
async function initiateBkashPayment({ orderId, amount }) {
  assertConfigured('bKash', env.bkash.configured);
  throw Object.assign(new Error('bKash integration not yet implemented'), { status: 501 });
}

// Integration point: Nagad's checkout/init + checkout/complete flow using
// RSA-signed payloads with env.nagad.merchantPrivateKey / pgPublicKey.
// Requires real Nagad merchant credentials — deliberately not implemented here.
async function initiateNagadPayment({ orderId, amount }) {
  assertConfigured('Nagad', env.nagad.configured);
  throw Object.assign(new Error('Nagad integration not yet implemented'), { status: 501 });
}

// Integration point: POST to SSLCommerz's /gwprocess/v4/api.php with
// store_id/store_passwd and the order/customer details, returning the
// GatewayPageURL to redirect to. Requires real SSLCommerz merchant
// credentials — deliberately not implemented here.
async function initiateSslcommerzPayment({ orderId, amount, customer }) {
  assertConfigured('SSLCommerz', env.sslcommerz.configured);
  throw Object.assign(new Error('SSLCommerz integration not yet implemented'), { status: 501 });
}

module.exports = { initiateBkashPayment, initiateNagadPayment, initiateSslcommerzPayment };
