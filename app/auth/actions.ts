"use server";

import { headers } from "next/headers";
import { redirect } from "next/navigation";
import {
  AUTH_ALREADY_REGISTERED,
  AUTH_GENERIC_ERROR,
  AUTH_RATE_LIMIT,
  mapAuthError,
} from "@/lib/auth/messages";
import { createClient } from "@/lib/supabase/server";
import {
  forgotPasswordSchema,
  loginSchema,
  signupSchema,
  updatePasswordSchema,
} from "@/lib/validation/auth";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

export type AuthActionResult =
  | { ok: true; needsConfirmation?: boolean }
  | { ok: false; message?: string; fieldErrors?: Record<string, string> };

async function getRequestOrigin() {
  const headerList = await headers();
  const origin = headerList.get("origin");
  if (origin) return origin;

  const host = headerList.get("x-forwarded-host") ?? headerList.get("host");
  const proto = headerList.get("x-forwarded-proto") ?? "http";
  return host ? `${proto}://${host}` : "http://localhost:3000";
}

function validationResult(fieldErrors: Record<string, string>): AuthActionResult {
  return { ok: false, fieldErrors };
}

export async function login(input: unknown): Promise<AuthActionResult> {
  const parsed = loginSchema.safeParse(input);
  if (!parsed.success) {
    return validationResult(fieldErrorsFromZod(parsed.error));
  }

  try {
    const supabase = await createClient();
    const { error } = await supabase.auth.signInWithPassword({
      email: parsed.data.email,
      password: parsed.data.password,
    });

    if (error) {
      return { ok: false, message: mapAuthError(error.message) };
    }

    return { ok: true };
  } catch {
    return { ok: false, message: AUTH_GENERIC_ERROR };
  }
}

export async function signup(input: unknown): Promise<AuthActionResult> {
  const parsed = signupSchema.safeParse(input);
  if (!parsed.success) {
    return validationResult(fieldErrorsFromZod(parsed.error));
  }

  try {
    const supabase = await createClient();
    const origin = await getRequestOrigin();
    const { data, error } = await supabase.auth.signUp({
      email: parsed.data.email,
      password: parsed.data.password,
      options: {
        emailRedirectTo: `${origin}/auth/callback`,
        data: {
          full_name: parsed.data.fullName,
          is_18_plus: true,
        },
      },
    });

    if (error) {
      return { ok: false, message: mapAuthError(error.message) };
    }

    if (data.user && data.user.identities && data.user.identities.length === 0) {
      return { ok: false, message: AUTH_ALREADY_REGISTERED };
    }

    return { ok: true, needsConfirmation: !data.session };
  } catch {
    return { ok: false, message: AUTH_GENERIC_ERROR };
  }
}

export async function requestPasswordReset(
  input: unknown,
): Promise<AuthActionResult> {
  const parsed = forgotPasswordSchema.safeParse(input);
  if (!parsed.success) {
    return validationResult(fieldErrorsFromZod(parsed.error));
  }

  try {
    const supabase = await createClient();
    const origin = await getRequestOrigin();
    const { error } = await supabase.auth.resetPasswordForEmail(parsed.data.email, {
      redirectTo: `${origin}/auth/callback?next=/account/update-password`,
    });

    if (error) {
      const message = mapAuthError(error.message);
      if (message === AUTH_RATE_LIMIT) {
        return { ok: false, message };
      }
      return { ok: true };
    }

    return { ok: true };
  } catch {
    return { ok: false, message: AUTH_GENERIC_ERROR };
  }
}

export async function updatePassword(input: unknown): Promise<AuthActionResult> {
  const parsed = updatePasswordSchema.safeParse(input);
  if (!parsed.success) {
    return validationResult(fieldErrorsFromZod(parsed.error));
  }

  try {
    const supabase = await createClient();
    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return {
        ok: false,
        message: "Open the reset link from your email, then choose a new password.",
      };
    }

    const { error } = await supabase.auth.updateUser({
      password: parsed.data.password,
    });

    if (error) {
      return { ok: false, message: mapAuthError(error.message) };
    }

    return { ok: true };
  } catch {
    return { ok: false, message: AUTH_GENERIC_ERROR };
  }
}

export async function signOut() {
  try {
    const supabase = await createClient();
    await supabase.auth.signOut();
  } catch {
    // Still leave the account page if sign-out cannot reach Supabase.
  }

  redirect("/login");
}
