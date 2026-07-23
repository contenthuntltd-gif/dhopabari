// ============================================================
// Dhopa Bari — phone-login
//
// Passwordless customer login by phone number. The shop chose phone-only
// login for maximum convenience (their whole model is phone-keyed, and
// guest orders already auto-create accounts with no customer password).
//
// Given a phone number this function finds — or creates — the account for
// it, sets a fresh random password server-side, and returns that password
// so the app can immediately establish a Supabase session. The customer
// never sees or types a password.
//
// Optional name/area/local_address (from the sign-up screen) update the
// profile so a first-time login doubles as registration.
//
// Public on purpose (no caller auth) and deployed with --no-verify-jwt.
// Called as a CORS "simple request" (text/plain, no custom headers) so no
// preflight fires — managed/DLP browsers block preflights.
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  });

/** Mirrors AuthService.normalizePhone in the app. */
function normalizePhone(input: string): string {
  let digits = String(input).trim().replace(/\D/g, '');
  if (digits.startsWith('880')) digits = digits.slice(3);
  else if (digits.startsWith('0')) digits = digits.slice(1);
  return `+880${digits}`;
}

/** Mirrors AuthService._phoneToEmail. */
function phoneToEmail(normalizedPhone: string): string {
  return `${normalizedPhone.replace(/\D/g, '')}@dhopabari.app`;
}

function randomPassword(): string {
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  return 'p_' + Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Body must be JSON' }, 400);
  }

  const rawPhone = String(body.phone ?? '').trim();
  const name = String(body.name ?? '').trim();
  const area = String(body.area ?? '').trim();
  const localAddress = String(body.local_address ?? '').trim();
  const whatsapp = String(body.whatsapp_number ?? '').trim();

  if (!rawPhone) return json({ error: 'ফোন নম্বর আবশ্যক' }, 400);
  const phone = normalizePhone(rawPhone);
  if (!/^\+8801\d{9}$/.test(phone)) {
    return json({ error: 'ফোন নম্বরটি সঠিক নয় (যেমন 01712345678)' }, 400);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const password = randomPassword();

  const { data: existing } = await admin
    .from('profiles')
    .select('id, role')
    .eq('phone', phone)
    .maybeSingle();

  // SECURITY: never let passwordless customer login touch a STAFF account —
  // otherwise anyone typing an admin/rider number would reset its password
  // and sign in as that staff member. Staff use their own password + URL.
  if (existing?.role === 'admin' || existing?.role === 'rider') {
    return json({ error: 'এই নম্বরটি স্টাফ অ্যাকাউন্টের — এটি দিয়ে কাস্টমার লগইন করা যাবে না।' }, 403);
  }

  if (existing?.id) {
    const userId = existing.id as string;
    const { error } = await admin.auth.admin.updateUserById(userId, { password });
    if (error) return json({ error: error.message }, 400);
    // Keep contact details fresh if the sign-up screen sent any.
    const patch: Record<string, unknown> = {};
    if (name) patch.name = name;
    if (area) patch.area = area;
    if (localAddress) patch.local_address = localAddress;
    if (whatsapp) patch.whatsapp_number = whatsapp;
    if (Object.keys(patch).length > 0) {
      await admin.from('profiles').update(patch).eq('id', userId);
    }
  } else {
    const { data: created, error } = await admin.auth.admin.createUser({
      email: phoneToEmail(phone),
      password,
      email_confirm: true,
      user_metadata: {
        phone,
        name: name || 'কাস্টমার',
        area,
        local_address: localAddress,
        whatsapp_number: whatsapp,
      },
    });
    if (error || !created?.user) {
      return json({ error: error?.message ?? 'অ্যাকাউন্ট তৈরি করা যায়নি' }, 400);
    }
  }

  // phone + password let the app sign the device in silently.
  return json({ phone, password }, 200);
});
