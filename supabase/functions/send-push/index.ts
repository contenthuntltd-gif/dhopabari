// ============================================================
// Dhopa Bari — send-push
//
// Sends FCM push notifications when an order changes. Triggered by a
// Supabase Database Webhook on public.orders (INSERT + UPDATE), which POSTs
// { type, record, old_record } here.
//
// Who gets notified:
//   • INSERT ....................... every admin ("new order")
//   • UPDATE, status changed ....... the order's customer ("status update")
//   • UPDATE, rider newly assigned . that rider ("new delivery")
//
// Secrets (set once):
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
//
// Deploy:  supabase functions deploy send-push --no-verify-jwt
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SERVICE_ACCOUNT = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');

const STATUS_BN: Record<string, string> = {
  'Confirmed': '✅ অর্ডার নিশ্চিত হয়েছে',
  'Picked Up': '🚚 কাপড় সংগ্রহ করা হয়েছে',
  'Cleaning': '🧺 কাপড় পরিষ্কার হচ্ছে',
  'Packaging Done': '📦 প্যাকেজিং সম্পন্ন',
  'Out for Delivery': '🚛 ডেলিভারির পথে',
  'Delivered': '🏠 ডেলিভারি সম্পন্ন',
  'Cancelled': '❌ অর্ডার বাতিল হয়েছে',
};

const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ── Google OAuth (service account -> access token for FCM v1) ──

function base64url(bytes: Uint8Array): string {
  let s = btoa(String.fromCharCode(...bytes));
  return s.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function base64urlStr(str: string): string {
  return base64url(new TextEncoder().encode(str));
}
function pemToPkcs8(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '').replace(/\s/g, '');
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

let _cachedToken: { token: string; exp: number } | null = null;

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (_cachedToken && _cachedToken.exp > now + 60) return _cachedToken.token;

  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: SERVICE_ACCOUNT.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: SERVICE_ACCOUNT.token_uri,
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${base64urlStr(JSON.stringify(header))}.${base64urlStr(JSON.stringify(claims))}`;
  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToPkcs8(SERVICE_ACCOUNT.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));
  const jwt = `${unsigned}.${base64url(new Uint8Array(sig))}`;

  const res = await fetch(SERVICE_ACCOUNT.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const data = await res.json();
  if (!data.access_token) throw new Error(`OAuth failed: ${JSON.stringify(data)}`);
  _cachedToken = { token: data.access_token, exp: now + 3500 };
  return data.access_token;
}

// ── Recipients + send ──

async function tokensForUsers(userIds: string[]): Promise<string[]> {
  const ids = userIds.filter(Boolean);
  if (ids.length === 0) return [];
  const { data } = await admin.from('device_tokens').select('token').in('user_id', ids);
  return (data ?? []).map((r: { token: string }) => r.token);
}

async function tokensForAdmins(): Promise<string[]> {
  const { data } = await admin.from('profiles').select('id').eq('role', 'admin');
  const ids = (data ?? []).map((r: { id: string }) => r.id);
  return tokensForUsers(ids);
}

async function sendToTokens(tokens: string[], title: string, body: string, data: Record<string, string>) {
  if (tokens.length === 0) return;
  const accessToken = await getAccessToken();
  const url = `https://fcm.googleapis.com/v1/projects/${SERVICE_ACCOUNT.project_id}/messages:send`;
  await Promise.all(tokens.map(async (token) => {
    const message = {
      message: {
        token,
        notification: { title, body },
        data,
        android: { priority: 'HIGH', notification: { sound: 'default', channel_id: 'dhopabari_orders' } },
      },
    };
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(message),
    });
    if (!res.ok) {
      const txt = await res.text();
      // A stale token (404/410) — drop it so we stop trying.
      if (res.status === 404 || res.status === 410) {
        await admin.from('device_tokens').delete().eq('token', token);
      }
      console.error(`FCM ${res.status}: ${txt}`);
    }
  }));
}

Deno.serve(async (req) => {
  if (req.method !== 'POST') return new Response('ok');
  let payload: { type?: string; record?: Record<string, unknown>; old_record?: Record<string, unknown> };
  try {
    payload = await req.json();
  } catch {
    return new Response('bad json', { status: 400 });
  }

  const type = payload.type;
  const rec = payload.record ?? {};
  const old = payload.old_record ?? {};
  const orderNo = String(rec.order_no ?? '');

  try {
    if (type === 'INSERT') {
      await sendToTokens(
        await tokensForAdmins(),
        '🔔 নতুন অর্ডার এসেছে',
        `${orderNo} · ৳${rec.total ?? ''}`,
        { kind: 'new_order', order_no: orderNo },
      );
    } else if (type === 'UPDATE') {
      // Status change → tell the customer.
      if (rec.status !== old.status && rec.status) {
        const label = STATUS_BN[String(rec.status)] ?? String(rec.status);
        await sendToTokens(
          await tokensForUsers([String(rec.customer_id ?? '')]),
          'আপনার অর্ডার আপডেট',
          `${orderNo} — ${label}`,
          { kind: 'status', order_no: orderNo },
        );
      }
      // Rider newly assigned → tell the rider.
      if (rec.rider_id && rec.rider_id !== old.rider_id) {
        await sendToTokens(
          await tokensForUsers([String(rec.rider_id)]),
          '🏍️ নতুন ডেলিভারি অ্যাসাইন',
          `${orderNo}`,
          { kind: 'assigned', order_no: orderNo },
        );
      }
    }
  } catch (e) {
    console.error('send-push error:', e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }

  return new Response(JSON.stringify({ ok: true }), { headers: { 'Content-Type': 'application/json' } });
});
