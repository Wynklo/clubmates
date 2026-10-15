// Sends invite pushes through Firebase Cloud Messaging.
//
// Called only by the invites trigger (pg_net) with the shared secret from
// Vault. The payload names an invite; everything else is read here, so a
// caller cannot choose who gets a push or what it says.
//
// Push text never contains phone numbers, locations, or chat text.

import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const notifySecret = Deno.env.get("NOTIFY_SECRET") ?? "";
const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "";

type ServiceAccount = { client_email: string; private_key: string };

let cachedToken: { value: string; expires: number } | null = null;

function reply(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function sameSecret(given: string, expected: string): boolean {
  if (!given || !expected || given.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < given.length; i++) {
    diff |= given.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return diff === 0;
}

async function googleAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expires > Date.now() + 60_000) {
    return cachedToken.value;
  }
  const account = JSON.parse(serviceAccountJson) as ServiceAccount;
  const key = await importPKCS8(account.private_key, "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`Google token ${response.status}`);
  const body = await response.json();
  cachedToken = {
    value: body.access_token,
    expires: Date.now() + body.expires_in * 1000,
  };
  return cachedToken.value;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return reply(405, { error: "POST only" });
  if (!sameSecret(request.headers.get("x-notify-secret") ?? "", notifySecret)) {
    return reply(401, { error: "Not allowed" });
  }
  if (!projectId || !serviceAccountJson) {
    return reply(503, { error: "Push is not configured" });
  }

  const { kind, invite_id: inviteId } = await request.json().catch(() => ({}));
  if (kind !== "invite" && kind !== "accepted") return reply(400, { error: "kind" });
  if (typeof inviteId !== "string") return reply(400, { error: "invite_id" });

  const db = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: invite } = await db
    .from("invites")
    .select("sender_id, receiver_id, status")
    .eq("id", inviteId)
    .maybeSingle();
  if (!invite) return reply(404, { error: "invite" });

  const expected = kind === "invite" ? "PENDING" : "ACCEPTED";
  if (invite.status !== expected) return reply(200, { sent: 0, reason: "stale" });

  const target = kind === "invite" ? invite.receiver_id : invite.sender_id;
  const { data: prefs } = await db
    .from("user_private")
    .select("notify_invites")
    .eq("user_id", target)
    .maybeSingle();
  if (prefs && prefs.notify_invites === false) {
    return reply(200, { sent: 0, reason: "switched off" });
  }

  let title = "New invite";
  let body = "Someone sent you an invite to go out tonight. Open Invites to see who.";
  let route = "invites";
  if (kind === "accepted") {
    const { data: accepter } = await db
      .from("profiles")
      .select("display_name")
      .eq("id", invite.receiver_id)
      .maybeSingle();
    const first = (accepter?.display_name ?? "").trim().split(/\s+/)[0] || "Someone";
    title = "You have a new mate";
    body = `${first} accepted your invite. You are mates now.`;
    route = "mates";
  }

  const { data: tokens } = await db
    .from("device_tokens")
    .select("token")
    .eq("user_id", target);
  if (!tokens?.length) return reply(200, { sent: 0, reason: "no devices" });

  const accessToken = await googleAccessToken();
  let sent = 0;
  for (const { token } of tokens) {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            data: { route },
            android: { priority: "HIGH" },
          },
        }),
      },
    );
    if (response.ok) {
      sent++;
      continue;
    }
    const failure = await response.text();
    if (
      response.status === 404 ||
      failure.includes("UNREGISTERED") ||
      failure.includes("registration-token-not-registered")
    ) {
      await db.from("device_tokens").delete().eq("token", token);
    }
  }

  return reply(200, { sent });
});
