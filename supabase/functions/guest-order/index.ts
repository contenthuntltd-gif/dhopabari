// ============================================================
// Dhopa Bari — guest-order
//
// Lets a customer order WITHOUT logging in first. They give a name, phone
// and address at checkout; this function:
//
//   1. finds the account for that phone, or creates one automatically
//      (no password the customer has to choose — the system sets a fresh
//      random one and returns it so the app can sign the device in),
//   2. keeps the profile's name/address up to date,
//   3. saves the order against that account.
//
// It runs with the service_role key (server-side only) so it can create
// users and write orders while bypassing RLS — none of which a guest,
// holding only the public key, could do directly.
//
// Public on purpose (no caller auth) — it is the storefront order form.
//
// Deploy:  supabase functions deploy guest-order --no-verify-jwt
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
  // 24 hex chars — the customer never sees or types this.
  const bytes = new Uint8Array(12);
  crypto.getRandomValues(bytes);
  return 'g_' + Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Body must be JSON' }, 400);
  }

  const rawPhone = String(body.phone ?? '').trim();
  const name = String(body.name ?? '').trim();
  const address = String(body.address ?? '').trim();
  const area = String(body.area ?? '').trim();
  const items = Array.isArray(body.items) ? body.items : [];
  const pieces = Number(body.pieces ?? 0);
  const total = Number(body.total ?? 0);
  const paymentMethod = String(body.payment_method ?? 'Cash on Delivery');
  const service = String(body.service ?? 'Wash');
  const category = String(body.category ?? '');
  const note = String(body.note ?? '').trim();

  if (!name) return json({ error: 'নাম আবশ্যক' }, 400);
  if (!rawPhone) return json({ error: 'ফোন নম্বর আবশ্যক' }, 400);
  if (!address) return json({ error: 'ঠিকানা আবশ্যক' }, 400);
  if (items.length === 0) return json({ error: 'অন্তত একটি আইটেম নির্বাচন করুন' }, 400);

  const phone = normalizePhone(rawPhone);
  if (!/^\+8801\d{9}$/.test(phone)) {
    return json({ error: 'ফোন নম্বরটি সঠিক নয় (যেমন 01712345678)' }, 400);
  }

  const password = randomPassword();

  // ── 1. Find or create the account for this phone ──
  const { data: existing } = await admin
    .from('profiles')
    .select('id')
    .eq('phone', phone)
    .maybeSingle();

  let userId: string;

  if (existing?.id) {
    userId = existing.id as string;
    // Set a fresh password so the app can sign this device in. (A guest
    // order re-establishes access on whatever device placed it.)
    const { error } = await admin.auth.admin.updateUserById(userId, { password });
    if (error) return json({ error: error.message }, 400);
    // Keep the profile's contact details current with what they just typed.
    await admin
      .from('profiles')
      .update({ name, area: area || null, local_address: address })
      .eq('id', userId);
  } else {
    const { data: created, error } = await admin.auth.admin.createUser({
      email: phoneToEmail(phone),
      password,
      email_confirm: true,
      user_metadata: { phone, name, area, local_address: address },
    });
    if (error || !created?.user) {
      return json({ error: error?.message ?? 'অ্যাকাউন্ট তৈরি করা যায়নি' }, 400);
    }
    userId = created.user.id;
    // The handle_new_user trigger seeds the profile from the metadata above.
  }

  // ── 2. Save the order ──
  const { data: order, error: orderErr } = await admin
    .from('orders')
    .insert({
      customer_id: userId,
      placed_by: userId,
      service,
      category: category || null,
      items,
      pieces,
      total,
      address,
      area: area || null,
      payment_method: paymentMethod,
      note: note || null,
    })
    .select('*, customer:customer_id(name, phone), rider:rider_id(name, phone)')
    .single();

  if (orderErr) return json({ error: `অর্ডার সংরক্ষণ করা যায়নি: ${orderErr.message}` }, 500);

  // password + phone let the app sign the device in silently, so the
  // customer immediately has a session and can see this order.
  return json({ order, phone, password }, 201);
});
