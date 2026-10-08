import { NextResponse } from "next/server";
import { earlyAccessCount, registerEarlyAccess, EARLY_ACCESS_LIMIT } from "@/lib/earlyAccess/register";
import { clientIp } from "@/lib/security/clientIp";
import { rateLimit } from "@/lib/security/rateLimit";
import {
  EARLY_ACCESS_CLOSED_MESSAGE,
  EARLY_ACCESS_DUPLICATE_MESSAGE,
  EARLY_ACCESS_ERROR_MESSAGE,
  EARLY_ACCESS_RATE_LIMIT_MESSAGE,
  earlyAccessSchema,
} from "@/lib/validation/earlyAccess";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

const MAX_BODY_BYTES = 8000;

function json(body: Record<string, unknown>, status: number, headers?: Record<string, string>) {
  return NextResponse.json(body, {
    status,
    headers: { "Cache-Control": "no-store", ...headers },
  });
}

function honeypotFilled(payload: unknown) {
  if (!payload || typeof payload !== "object") return false;
  const value = (payload as Record<string, unknown>).cm_hp;
  return typeof value === "string" ? value.trim().length > 0 : value != null;
}

export async function GET() {
  try {
    const count = await earlyAccessCount();
    return json({ open: count === null || count < EARLY_ACCESS_LIMIT }, 200);
  } catch {
    return json({ open: true }, 200);
  }
}

export async function POST(request: Request) {
  const limited = rateLimit(clientIp(request));
  if (!limited.ok) {
    return json(
      { ok: false, code: "rate_limited", message: EARLY_ACCESS_RATE_LIMIT_MESSAGE },
      429,
      { "Retry-After": String(limited.retryAfter) },
    );
  }

  const advertisedLength = Number(request.headers.get("content-length") || 0);
  if (Number.isFinite(advertisedLength) && advertisedLength > MAX_BODY_BYTES) {
    return json(
      { ok: false, code: "validation", message: "Please check the form and try again." },
      413,
    );
  }

  let payload: unknown;
  try {
    const raw = await request.text();
    if (raw.length > MAX_BODY_BYTES) {
      return json(
        { ok: false, code: "validation", message: "Please check the form and try again." },
        413,
      );
    }
    payload = JSON.parse(raw);
  } catch {
    return json(
      { ok: false, code: "validation", message: "Please check the form and try again." },
      400,
    );
  }

  if (honeypotFilled(payload)) {
    return json({ ok: true }, 200);
  }

  if (payload && typeof payload === "object") {
    delete (payload as Record<string, unknown>).cm_hp;
  }

  const parsed = earlyAccessSchema.safeParse(payload);
  if (!parsed.success) {
    return json(
      { ok: false, code: "validation", fieldErrors: fieldErrorsFromZod(parsed.error) },
      400,
    );
  }

  try {
    const result = await registerEarlyAccess(parsed.data);
    if (result.ok) return json({ ok: true }, 200);

    if (result.code === "duplicate") {
      return json(
        { ok: false, code: "duplicate", message: EARLY_ACCESS_DUPLICATE_MESSAGE },
        409,
      );
    }

    if (result.code === "closed") {
      return json({ ok: false, code: "closed", message: EARLY_ACCESS_CLOSED_MESSAGE }, 403);
    }

    return json({ ok: false, code: "error", message: EARLY_ACCESS_ERROR_MESSAGE }, 500);
  } catch {
    console.error("early-access insert failed", "unexpected");
    return json({ ok: false, code: "error", message: EARLY_ACCESS_ERROR_MESSAGE }, 500);
  }
}
