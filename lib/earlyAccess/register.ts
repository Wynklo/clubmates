import type { PoolClient } from "pg";
import { getPool } from "@/lib/db/postgres";
import { isDuplicateRegistration, type EarlyAccessData } from "@/lib/validation/earlyAccess";

export const EARLY_ACCESS_LIMIT = 500;

const LOCK_SQL = "select pg_advisory_xact_lock(4815, 1623)";

export async function earlyAccessCount(): Promise<number | null> {
  const pool = getPool();
  if (!pool) return null;

  const result = await pool.query<{ n: number }>(
    "select count(*)::int as n from public.early_access_registrations",
  );
  return result.rows[0]?.n ?? 0;
}

export async function registerEarlyAccess(
  data: EarlyAccessData,
): Promise<{ ok: true } | { ok: false; code: "duplicate" | "closed" | "error" }> {
  const pool = getPool();
  if (!pool) return { ok: false, code: "error" };

  let client: PoolClient | undefined;
  try {
    client = await pool.connect();
    await client.query("begin");
    await client.query(LOCK_SQL);

    const count = await client.query<{ n: number }>(
      "select count(*)::int as n from public.early_access_registrations",
    );
    if ((count.rows[0]?.n ?? 0) >= EARLY_ACCESS_LIMIT) {
      await client.query("commit");
      return { ok: false, code: "closed" };
    }

    await client.query(
      `insert into public.early_access_registrations
        (full_name, email, phone, city, is_18_plus, instagram, referral_source)
       values ($1, $2, $3, $4, true, $5, $6)`,
      [data.fullName, data.email, data.phone, data.city, data.instagram, data.referralSource],
    );
    await client.query("commit");
    return { ok: true };
  } catch (error) {
    await client?.query("rollback").catch(() => undefined);
    if (isDuplicateRegistration(error as { code?: string; message?: string })) {
      return { ok: false, code: "duplicate" };
    }
    const code = typeof error === "object" && error && "code" in error ? String(error.code) : "unknown";
    console.error("early-access insert failed", code);
    return { ok: false, code: "error" };
  } finally {
    client?.release();
  }
}
