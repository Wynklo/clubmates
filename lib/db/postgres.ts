import { readFileSync } from "node:fs";
import { join } from "node:path";
import pg from "pg";

const globalForDb = globalThis as unknown as { clubmatesPool?: pg.Pool };

function connectionStringWithoutSslMode(connectionString: string) {
  return connectionString.replace(/([?&])sslmode=[^&]*&?/gi, "$1").replace(/[?&]$/, "");
}

export function getPool() {
  const connectionString = process.env.DATABASE_URL?.trim();
  if (!connectionString) return null;
  if (globalForDb.clubmatesPool) return globalForDb.clubmatesPool;

  const ca = readFileSync(join(process.cwd(), "certs/supabase-root-2021.crt"), "utf8");
  globalForDb.clubmatesPool = new pg.Pool({
    connectionString: connectionStringWithoutSslMode(connectionString),
    max: 2,
    idleTimeoutMillis: 10_000,
    ssl: { ca, rejectUnauthorized: true },
  });

  return globalForDb.clubmatesPool;
}
