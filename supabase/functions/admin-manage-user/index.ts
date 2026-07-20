// ============================================================
// Dhopa Bari — admin-manage-user
//
// Staff actions on an existing account that need the service_role key:
//
//   set_password  — accounts are keyed to a pseudo-email (01712…@dhopabari.app)
//                   that receives no mail, so there is no "reset link" path.
//                   The shop sets a new password and tells the customer.
//   delete        — removes the auth user. The profiles row (and its orders)
//                   cascade from the auth.users foreign key. Deleting only
//                   the profile would strand an account that can still log in.
//
// Deploy:  supabase functions deploy admin-manage-user
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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Missing Authorization header' }, 401);

  const caller = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userErr } = await caller.auth.getUser();
  if (userErr || !user) return json({ error: 'Invalid or expired session' }, 401);

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
    return json({ error: 'অনুমতি নেই' }, 403);
  }
  if (callerProfile?.blocked) return json({ error: 'Your account is blocked' }, 403);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Body must be JSON' }, 400);
  }

  const action = String(body.action ?? '');
  const targetId = String(body.user_id ?? '');
  if (!targetId) return json({ error: 'user_id is required' }, 400);

  // What is the target? Staff accounts are only touchable by an admin, and
  // nobody may delete or lock themselves out of their own session by accident.
  const { data: target } = await admin
    .from('profiles')
    .select('role')
    .eq('id', targetId)
    .maybeSingle();

  if (!target) return json({ error: 'ব্যবহারকারী পাওয়া যায়নি' }, 404);

  if (target.role !== 'customer' && callerRole !== 'admin') {
    return json({ error: 'শুধুমাত্র অ্যাডমিন স্টাফ অ্যাকাউন্ট পরিবর্তন করতে পারেন' }, 403);
  }

  switch (action) {
    case 'set_password': {
      const password = String(body.password ?? '');
      if (password.length < 6) {
        return json({ error: 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' }, 400);
      }
      const { error } = await admin.auth.admin.updateUserById(targetId, { password });
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    case 'delete': {
      if (targetId === user.id) {
        return json({ error: 'নিজের অ্যাকাউন্ট মুছে ফেলা যাবে না' }, 400);
      }
      const { error } = await admin.auth.admin.deleteUser(targetId);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true });
    }

    default:
      return json({ error: `Unknown action: ${action}` }, 400);
  }
});
