"use client";

import Link from "next/link";
import { useRef, useState } from "react";
import { updatePassword } from "@/app/auth/actions";
import { AuthShell } from "@/components/auth/AuthShell";
import { buttonClasses } from "@/components/ui/button";
import { describedBy, Field, inputClassName } from "@/components/ui/field";
import { updatePasswordSchema } from "@/lib/validation/auth";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

export function UpdatePasswordForm() {
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [serverErrors, setServerErrors] = useState<Record<string, string>>({});
  const [message, setMessage] = useState<string | null>(null);
  const [updated, setUpdated] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const parsed = updatePasswordSchema.safeParse({ password, confirmPassword });
  const clientErrors = parsed.success ? {} : fieldErrorsFromZod(parsed.error);

  function errorFor(field: "password" | "confirmPassword") {
    if (!touched[field] && !submitAttempted) return undefined;
    return serverErrors[field] || clientErrors[field];
  }

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submittingRef.current) return;
    setSubmitAttempted(true);
    setMessage(null);
    if (!updatePasswordSchema.safeParse({ password, confirmPassword }).success) return;

    submittingRef.current = true;
    setSubmitting(true);
    try {
      const result = await updatePassword({ password, confirmPassword });
      if (result.ok) {
        setUpdated(true);
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

  if (updated) {
    return (
      <AuthShell title="Password updated.">
        <p className="text-base leading-7 text-stone" role="status">
          You can keep using your Clubmates account with the new password.
        </p>
        <Link href="/account" className={`${buttonClasses("primary")} mt-8`}>
          Back to account
        </Link>
      </AuthShell>
    );
  }

  const passwordError = errorFor("password");
  const confirmError = errorFor("confirmPassword");

  return (
    <AuthShell title="Choose a new password">
      <form className="space-y-5" onSubmit={onSubmit} noValidate aria-busy={submitting}>
        {message ? (
          <p role="alert" className="rounded-2xl border border-coral/40 bg-coral/10 px-4 py-3 text-sm text-error">
            {message}
          </p>
        ) : null}
        <Field id="new-password" label="New password" required error={passwordError}>
          <input
            id="new-password"
            name="password"
            type="password"
            autoComplete="new-password"
            required
            disabled={submitting}
            value={password}
            aria-invalid={Boolean(passwordError)}
            aria-describedby={describedBy("new-password", passwordError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, password: true }))}
            onChange={(event) => setPassword(event.target.value)}
          />
        </Field>
        <Field id="confirm-new-password" label="Confirm password" required error={confirmError}>
          <input
            id="confirm-new-password"
            name="confirmPassword"
            type="password"
            autoComplete="new-password"
            required
            disabled={submitting}
            value={confirmPassword}
            aria-invalid={Boolean(confirmError)}
            aria-describedby={describedBy("confirm-new-password", confirmError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, confirmPassword: true }))}
            onChange={(event) => setConfirmPassword(event.target.value)}
          />
        </Field>
        <button type="submit" className={`${buttonClasses("primary")} w-full`} disabled={submitting}>
          {submitting ? "Updating..." : "Update password"}
        </button>
      </form>
    </AuthShell>
  );
}
