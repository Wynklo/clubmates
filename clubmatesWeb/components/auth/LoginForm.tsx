"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { login } from "@/app/auth/actions";
import { AuthShell } from "@/components/auth/AuthShell";
import { buttonClasses } from "@/components/ui/button";
import { describedBy, Field, inputClassName } from "@/components/ui/field";
import { AUTH_LINK_EXPIRED } from "@/lib/auth/messages";
import { loginSchema } from "@/lib/validation/auth";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

export function LoginForm({ linkError = false }: { linkError?: boolean }) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [serverErrors, setServerErrors] = useState<Record<string, string>>({});
  const [message, setMessage] = useState<string | null>(linkError ? AUTH_LINK_EXPIRED : null);
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const parsed = loginSchema.safeParse({ email, password });
  const clientErrors = parsed.success ? {} : fieldErrorsFromZod(parsed.error);

  function errorFor(field: "email" | "password") {
    if (!touched[field] && !submitAttempted) return undefined;
    return serverErrors[field] || clientErrors[field];
  }

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submittingRef.current) return;
    setSubmitAttempted(true);
    setMessage(null);
    if (!loginSchema.safeParse({ email, password }).success) return;

    submittingRef.current = true;
    setSubmitting(true);
    try {
      const result = await login({ email, password });
      if (result.ok) {
        router.push("/account");
        router.refresh();
        return;
      }
      setServerErrors(result.fieldErrors ?? {});
      setMessage(result.message ?? null);
    } catch {
      setMessage("Something went wrong. Please try again.");
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  }

  const emailError = errorFor("email");
  const passwordError = errorFor("password");

  return (
    <AuthShell
      title="Sign in"
      lede="Early access does not require an account. Sign in is for a Clubmates account."
      footer={
        <>
          <Link href="/forgot-password" className="text-ink underline-offset-4 hover:underline">
            Forgot password
          </Link>
          <p className="mt-3">
            New to Clubmates?{" "}
            <Link href="/signup" className="text-ink underline-offset-4 hover:underline">
              Create an account
            </Link>
          </p>
        </>
      }
    >
      <form className="space-y-5" onSubmit={onSubmit} noValidate aria-busy={submitting}>
        {message ? (
          <p role="alert" className="rounded-2xl border border-coral/40 bg-coral/10 px-4 py-3 text-sm text-error">
            {message}
          </p>
        ) : null}
        <Field id="login-email" label="Email" required error={emailError}>
          <input
            id="login-email"
            name="email"
            type="email"
            inputMode="email"
            autoComplete="email"
            autoCapitalize="none"
            spellCheck={false}
            required
            disabled={submitting}
            value={email}
            aria-invalid={Boolean(emailError)}
            aria-describedby={describedBy("login-email", emailError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, email: true }))}
            onChange={(event) => {
              setEmail(event.target.value);
              setServerErrors((current) => ({ ...current, email: "" }));
            }}
          />
        </Field>
        <Field id="login-password" label="Password" required error={passwordError}>
          <input
            id="login-password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            disabled={submitting}
            value={password}
            aria-invalid={Boolean(passwordError)}
            aria-describedby={describedBy("login-password", passwordError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, password: true }))}
            onChange={(event) => {
              setPassword(event.target.value);
              setServerErrors((current) => ({ ...current, password: "" }));
            }}
          />
        </Field>
        <button type="submit" className={`${buttonClasses("primary")} w-full`} disabled={submitting}>
          {submitting ? "Signing in..." : "Sign in"}
        </button>
      </form>
    </AuthShell>
  );
}
