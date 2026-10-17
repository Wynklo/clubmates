// Removes chat photos queued in public.chat_image_trash.
//
// Photos are queued when a message is unsent, when a closed thread passes
// its 30 days, or when an account is deleted. SQL cannot remove the stored
// file, so this function does it through the Storage API.
//
// Called only by pg_net (queue_chat_cleanup) with the notify secret.

import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const notifySecret = Deno.env.get("NOTIFY_SECRET") ?? "";

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

Deno.serve(async (request) => {
  if (request.method !== "POST") return reply(405, { error: "POST only" });
  if (!sameSecret(request.headers.get("x-notify-secret") ?? "", notifySecret)) {
    return reply(401, { error: "Not allowed" });
  }

  const db = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let removed = 0;
  for (let round = 0; round < 10; round++) {
    const { data: rows, error } = await db
      .from("chat_image_trash")
      .select("path")
      .order("queued_at")
      .limit(100);
    if (error) return reply(500, { error: "trash", removed });
    if (!rows?.length) break;

    const paths = rows.map((row) => row.path as string);
    const { error: storageError } = await db.storage.from("chat-images").remove(paths);
    if (storageError) return reply(502, { error: "storage", removed });

    await db.from("chat_image_trash").delete().in("path", paths);
    removed += paths.length;
  }

  return reply(200, { removed });
});
