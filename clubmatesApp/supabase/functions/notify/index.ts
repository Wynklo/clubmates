// Sends invite and mate message pushes through Firebase Cloud Messaging.
//
// Called only by the invites and mate_messages triggers (pg_net) with the
// shared secret from Vault. The payload names an invite or a message;
// everything else is read here, so a caller cannot choose who gets a push
// or what it says.
//
// Push text never contains phone numbers, locations, or chat text.

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
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

  const payload = await request.json().catch(() => ({}));
  const db = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  if (payload.kind === "message") {
    if (typeof payload.message_id !== "string") return reply(400, { error: "message_id" });
    const push = await messagePush(db, payload.message_id);
    if ("reason" in push) return reply(200, { sent: 0, reason: push.reason });
    return reply(200, { sent: await sendToUser(db, push.target, push) });
  }

  const { kind, invite_id: inviteId } = payload;
  if (kind !== "invite" && kind !== "accepted") return reply(400, { error: "kind" });
  if (typeof inviteId !== "string") return reply(400, { error: "invite_id" });

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

  return reply(200, { sent: await sendToUser(db, target, { title, body, data: { route } }) });
});

type Push = {
  title: string;
  body: string;
  data: Record<string, string>;
  // Later pushes with the same tag replace the earlier one on the phone.
  tag?: string;
};

// Message pushes name the sender but never include the message text.
async function messagePush(
  db: SupabaseClient,
  messageId: string,
): Promise<(Push & { target: string }) | { reason: string }> {
  const { data: message } = await db
    .from("mate_messages")
    .select("id, mate_id, sender_id, image_path, deleted_at, read_at, created_at")
    .eq("id", messageId)
    .maybeSingle();
  if (!message || message.deleted_at || message.read_at) return { reason: "stale" };

  const { data: mate } = await db
    .from("mates")
    .select("user_one_id, user_two_id, status")
    .eq("id", message.mate_id)
    .maybeSingle();
  if (!mate || mate.status !== "ACTIVE") return { reason: "closed" };
  const target = mate.user_one_id === message.sender_id ? mate.user_two_id : mate.user_one_id;

  const { count: blocks } = await db
    .from("user_blocks")
    .select("blocker_id", { count: "exact", head: true })
    .or(
      `and(blocker_id.eq.${target},blocked_id.eq.${message.sender_id}),` +
        `and(blocker_id.eq.${message.sender_id},blocked_id.eq.${target})`,
    );
  if (blocks) return { reason: "blocked" };

  const { data: prefs } = await db
    .from("user_private")
    .select("notify_mates")
    .eq("user_id", target)
    .maybeSingle();
  if (prefs && prefs.notify_mates === false) return { reason: "switched off" };

  // One push per burst: skip if an earlier unread message from the same
  // sender in this thread arrived in the last two minutes.
  const since = new Date(new Date(message.created_at).getTime() - 120_000).toISOString();
  const { count: earlier } = await db
    .from("mate_messages")
    .select("id", { count: "exact", head: true })
    .eq("mate_id", message.mate_id)
    .eq("sender_id", message.sender_id)
    .is("read_at", null)
    .is("deleted_at", null)
    .neq("id", message.id)
    .gte("created_at", since)
    .lte("created_at", message.created_at);
  if (earlier) return { reason: "burst" };

  const { data: sender } = await db
    .from("profiles")
    .select("display_name")
    .eq("id", message.sender_id)
    .maybeSingle();
  const first = (sender?.display_name ?? "").trim().split(/\s+/)[0] || "Your mate";
  return {
    target,
    title: first,
    body: message.image_path ? "Sent you a photo." : "Sent you a message.",
    data: { route: "chat", mate_id: message.mate_id },
    tag: `chat-${message.mate_id}`,
  };
}

async function sendToUser(db: SupabaseClient, target: string, push: Push): Promise<number> {
  const { data: tokens } = await db
    .from("device_tokens")
    .select("token")
    .eq("user_id", target);
  if (!tokens?.length) return 0;

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
            notification: { title: push.title, body: push.body },
            data: push.data,
            android: {
              priority: "HIGH",
              ...(push.tag ? { notification: { tag: push.tag } } : {}),
            },
            ...(push.tag
              ? { apns: { headers: { "apns-collapse-id": push.tag } } }
              : {}),
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
  return sent;
}
