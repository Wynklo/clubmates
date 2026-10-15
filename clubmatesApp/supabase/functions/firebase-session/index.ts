// Exchanges a Firebase phone sign-in for a Supabase session.
//
// The app sends the Firebase ID token it gets after the SMS code is
// accepted. This function checks the token against Google's keys, finds or
// creates the Supabase account for that phone, and returns a session. The
// service-role key stays here.

import { createClient } from "npm:@supabase/supabase-js@2";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@5";

const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const googleKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

const PER_PHONE_PER_HOUR = 10;
const PER_IP_PER_HOUR = 30;
const indianMobile = /^\+91[6-9][0-9]{9}$/;

const rejected = "That code did not work. Try again.";

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

async function verifiedPhone(idToken: string): Promise<string | null> {
  try {
    const { payload } = await jwtVerify(idToken, googleKeys, {
      issuer: `https://securetoken.google.com/${projectId}`,
      audience: projectId,
      algorithms: ["RS256"],
    });
    const firebase = payload.firebase as { sign_in_provider?: string } | undefined;
    const phone = payload.phone_number;
    if (firebase?.sign_in_provider !== "phone") return null;
    if (typeof phone !== "string" || !indianMobile.test(phone)) return null;
    return phone;
  } catch {
    return null;
  }
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return reply(405, { error: "POST only" });
  if (!projectId || !serviceKey) {
    return reply(503, { error: "Phone sign-in is not available yet." });
  }

  let idToken = "";
  try {
    const body = await request.json();
    idToken = typeof body?.id_token === "string" ? body.id_token : "";
  } catch {
    return reply(400, { error: rejected });
  }
  if (!idToken) return reply(400, { error: rejected });

  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const ip = (request.headers.get("x-forwarded-for") ?? "").split(",")[0].trim() ||
    "unknown";
  const since = new Date(Date.now() - 60 * 60 * 1000).toISOString();
  const { count: ipCount } = await admin
    .from("auth_exchange_attempts")
    .select("id", { count: "exact", head: true })
    .eq("bucket", `ip:${ip}`)
    .gte("created_at", since);
  if ((ipCount ?? 0) >= PER_IP_PER_HOUR) {
    return reply(429, { error: "Too many tries. Wait a while and try again." });
  }
  await admin.from("auth_exchange_attempts").insert({ bucket: `ip:${ip}` });

  const phone = await verifiedPhone(idToken);
  if (!phone) return reply(401, { error: rejected });

  const { count: phoneCount } = await admin
    .from("auth_exchange_attempts")
    .select("id", { count: "exact", head: true })
    .eq("bucket", `phone:${phone}`)
    .gte("created_at", since);
  if ((phoneCount ?? 0) >= PER_PHONE_PER_HOUR) {
    return reply(429, { error: "Too many tries. Wait a while and try again." });
  }
  await admin.from("auth_exchange_attempts").insert({ bucket: `phone:${phone}` });

  const digits = phone.slice(1);
  const local = phone.slice(3);
  const { data: found, error: findError } = await admin.rpc(
    "auth_user_for_phone",
    { p_phone: digits, p_legacy_email: `${local}@clubmates.dev` },
  );
  if (findError) return reply(500, { error: "Sign-in failed. Try again." });

  const existing = Array.isArray(found) ? found[0] : null;
  let email: string;
  if (existing) {
    email = existing.email;
    if (!existing.has_phone) {
      const { error } = await admin.auth.admin.updateUserById(existing.id, {
        phone: digits,
        phone_confirm: true,
      });
      if (error) return reply(500, { error: "Sign-in failed. Try again." });
    }
  } else {
    email = `${digits}@phone.clubmates.app`;
    const { error } = await admin.auth.admin.createUser({
      email,
      email_confirm: true,
      phone: digits,
      phone_confirm: true,
    });
    if (error) return reply(500, { error: "Sign-in failed. Try again." });
  }

  const { data: link, error: linkError } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email,
  });
  const tokenHash = link?.properties?.hashed_token;
  if (linkError || !tokenHash) {
    return reply(500, { error: "Sign-in failed. Try again." });
  }

  // A separate client, so the new session never replaces the admin one.
  const sessionClient = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: verified, error: verifyError } = await sessionClient.auth.verifyOtp({
    type: "magiclink",
    token_hash: tokenHash,
  });
  const session = verified?.session;
  if (verifyError || !session) {
    return reply(500, { error: "Sign-in failed. Try again." });
  }

  await admin
    .from("auth_exchange_attempts")
    .delete()
    .lt("created_at", new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

  return reply(200, {
    access_token: session.access_token,
    refresh_token: session.refresh_token,
    expires_in: session.expires_in,
  });
});
