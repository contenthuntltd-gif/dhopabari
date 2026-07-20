// ============================================================
// Dhopa Bari — admin-create-user
//
// Creates a user account (customer or staff) on behalf of an admin/rider.
//
// Why this exists as an Edge Function rather than a Flutter call:
// setting another person's password requires Supabase's service_role key,
// which grants unrestricted database access and bypasses every RLS policy.
// Shipping it in the Flutter app would put it in the web bundle / APK,
// where anyone can extract it. It stays server-side here, and the client
// only ever gets to ask this function nicely — after proving who it is.
//
// Deploy:  supabase functions deploy admin-create-user
// ============================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
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

/**
 * Mirrors AuthService.normalizePhone in the Flutter app. Both sides must
 * agree exactly or a user created here cannot log in there.
 *   "01712-345678" | "1712345678" | "+8801712345678"  ->  "+8801712345678"
 */
function normalizePhone(input: string): string {
  let digits = input.trim().replace(/\D/g, '');
  if (digits.startsWith('880')) digits = digits.slice(3);
  else if (digits.startsWith('0')) digits = digits.slice(1);
  return `+880${digits}`;
}

/** Mirrors AuthService._phoneToEmail. */
function phoneToEmail(normalizedPhone: string): string {
  return `${normalizedPhone.replace(/\D/g, '')}@dhopabari.app`;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  // ---- 1. Who is calling? ----
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Missing Authorization header' }, 401);

  // A client bound to the CALLER's JWT — so auth.getUser() returns them,
  // not us, and any query runs under their RLS.
  const caller = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: { user }, error: userErr } = await caller.auth.getUser();
  if (userErr || !user) return json({ error: 'Invalid or expired session' }, 401);

  // ---- 2. Are they allowed? ----
  // Read the role with the service client: the caller's own RLS would let
  // them read their profile, but we do not want to depend on policy shape
  // for an authorization decision.
  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: callerProfile } = await admin
    .from('profiles')
    .select('role, blocked')
    .eq('id', user.id)
    .maybeSingle();

  const callerRole = callerProfile?.role;
  if (callerRole !== 'admin' && callerRole !== 'rider') {
    return json({ error: 'Only admin or rider can create users' }, 403);
  }
  if (callerProfile?.blocked) {
    return json({ error: 'Your account is blocked' }, 403);
  }

  // ---- 3. Validate input ----
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Body must be JSON' }, 400);
  }

  const rawPhone = String(body.phone ?? '').trim();
  const password = String(body.password ?? '');
  const name = String(body.name ?? '').trim();
  const role = String(body.role ?? 'customer');

  if (!rawPhone) return json({ error: 'ফোন নম্বর আবশ্যক' }, 400);
  if (password.length < 6) {
    return json({ error: 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' }, 400);
  }
  if (!['customer', 'rider', 'admin'].includes(role)) {
    return json({ error: 'Invalid role' }, 400);
  }

  // Creating staff grants the power to see every customer and place orders,
  // so only an admin may do it. A rider can register walk-in customers but
  // cannot mint another rider (or promote anyone to admin).
  if (role !== 'customer' && callerRole !== 'admin') {
    return json({ error: 'শুধুমাত্র অ্যাডমিন নতুন রাইডার বা অ্যাডমিন তৈরি করতে পারেন' }, 403);
  }

  const phone = normalizePhone(rawPhone);
  if (!/^\+8801\d{9}$/.test(phone)) {
    return json({ error: 'ফোন নম্বরটি সঠিক নয় (যেমন 01712345678)' }, 400);
  }

  // ---- 4. Create the auth user ----
  const { data: created, error: createErr } = await admin.auth.admin.createUser({
    email: phoneToEmail(phone),
    password,
    email_confirm: true, // pseudo-email; nothing to send a confirmation to
    user_metadata: {
      phone,
      name,
      area: String(body.area ?? '').trim(),
      local_address: String(body.local_address ?? '').trim(),
      whatsapp_number: String(body.whatsapp_number ?? '').trim(),
    },
  });

  if (createErr || !created?.user) {
    const msg = createErr?.message ?? 'User creation failed';
    const duplicate = /already|exists|registered|duplicate/i.test(msg);
    return json(
      { error: duplicate ? 'এই নম্বরে ইতিমধ্যে একটি অ্যাকাউন্ট আছে' : msg },
      duplicate ? 409 : 400,
    );
  }

  // ---- 5. Fill in the profile ----
  // The handle_new_user trigger already inserted a row from the metadata
  // above. Set the fields the trigger cannot know: role, and who created
  // this account. Update rather than insert so we never race the trigger.
  const { data: profile, error: profileErr } = await admin
    .from('profiles')
    .update({ role, created_by: user.id })
    .eq('id', created.user.id)
    .select()
    .single();

  if (profileErr) {
    // The auth user exists but its profile is wrong — roll back rather than
    // leave an account that can log in with no usable profile.
    await admin.auth.admin.deleteUser(created.user.id);
    return json({ error: `Profile setup failed: ${profileErr.message}` }, 500);
  }

  return json({ user: profile }, 201);
});
