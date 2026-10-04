"use client";

import Link from "next/link";
import { useRef, useState } from "react";
import { requestPasswordReset } from "@/app/auth/actions";
import { AuthShell } from "@/components/auth/AuthShell";
import { buttonClasses } from "@/components/ui/button";
import { describedBy, Field, inputClassName } from "@/components/ui/field";
import { forgotPasswordSchema } from "@/lib/validation/auth";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

export function ForgotPasswordForm() {
  const [email, setEmail] = useState("");
  const [touched, setTouched] = useState(false);
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [serverError, setServerError] = useState<string | undefined>();
  const [message, setMessage] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const parsed = forgotPasswordSchema.safeParse({ email });
  const clientError = parsed.success ? undefined : fieldErrorsFromZod(parsed.error).email;
  const emailError = touched || submitAttempted ? serverError || clientError : undefined;

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submittingRef.current) return;
    setSubmitAttempted(true);
    setMessage(null);
    if (!forgotPasswordSchema.safeParse({ email }).success) return;

    submittingRef.current = true;
    setSubmitting(true);
    try {
      const result = await requestPasswordReset({ email });
      if (result.ok) {
        setSent(true);
        return;
      }
      setServerError(result.fieldErrors?.email);
      setMessage(result.message ?? "Something went wrong. Please try again.");
    } catch {
      setMessage("Something went wrong. Please try again.");
    } finally {
      submittingRef.current = false;
      setSubmitting(false);
    }
  }

  if (sent) {
    return (
      <AuthShell title="Check your inbox.">
        <p className="text-base leading-7 text-stone" role="status">
          If an account exists for that email, we&apos;ve sent a reset link.
        </p>
        <Link href="/login" className={`${buttonClasses("primary")} mt-8`}>
          Back to sign in
        </Link>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      title="Reset password"
      lede="Enter the email on your Clubmates account."
      footer={
        <Link href="/login" className="text-ink underline-offset-4 hover:underline">
          Back to sign in
        </Link>
      }
    >
      <form className="space-y-5" onSubmit={onSubmit} noValidate aria-busy={submitting}>
        {message ? (
          <p role="alert" className="rounded-2xl border border-coral/40 bg-coral/10 px-4 py-3 text-sm text-error">
            {message}
          </p>
        ) : null}
        <Field id="reset-email" label="Email" required error={emailError}>
          <input
            id="reset-email"
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
            aria-describedby={describedBy("reset-email", emailError)}
            className={inputClassName}
            onBlur={() => setTouched(true)}
            onChange={(event) => {
              setEmail(event.target.value);
              setServerError(undefined);
            }}
          />
        </Field>
        <button type="submit" className={`${buttonClasses("primary")} w-full`} disabled={submitting}>
          {submitting ? "Sending..." : "Send reset link"}
        </button>
      </form>
    </AuthShell>
  );
}
