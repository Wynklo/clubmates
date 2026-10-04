import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  EARLY_ACCESS_DUPLICATE_MESSAGE,
  EARLY_ACCESS_ERROR_MESSAGE,
  earlyAccessSchema,
  isDuplicateRegistration,
} from "@/lib/validation/earlyAccess";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

function json(
  body: Record<string, unknown>,
  status: number,
) {
  return NextResponse.json(body, {
    status,
    headers: { "Cache-Control": "no-store" },
  });
}

export async function POST(request: Request) {
  let payload: unknown;

  try {
    payload = await request.json();
  } catch {
    return json(
      {
        ok: false,
        code: "validation",
        message: "Please check the form and try again.",
      },
      400,
    );
  }

  const parsed = earlyAccessSchema.safeParse(payload);
  if (!parsed.success) {
    return json(
      {
        ok: false,
        code: "validation",
        fieldErrors: fieldErrorsFromZod(parsed.error),
      },
      400,
    );
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.from("early_access_registrations").insert({
      full_name: parsed.data.fullName,
      email: parsed.data.email,
      phone: parsed.data.phone,
      city: parsed.data.city,
      is_18_plus: true,
      instagram: parsed.data.instagram,
      referral_source: parsed.data.referralSource,
    });

    if (error) {
      if (isDuplicateRegistration(error)) {
        return json(
          {
            ok: false,
            code: "duplicate",
            message: EARLY_ACCESS_DUPLICATE_MESSAGE,
          },
          409,
        );
      }

      console.error("early-access insert failed", error.code ?? "unknown");
      return json(
        { ok: false, code: "error", message: EARLY_ACCESS_ERROR_MESSAGE },
        500,
      );
    }

    return json({ ok: true }, 200);
  } catch {
    console.error("early-access insert failed", "unexpected");
    return json(
      { ok: false, code: "error", message: EARLY_ACCESS_ERROR_MESSAGE },
      500,
    );
  }
}
