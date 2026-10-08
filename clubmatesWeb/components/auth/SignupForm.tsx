"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { signup } from "@/app/auth/actions";
import { AuthShell } from "@/components/auth/AuthShell";
import { buttonClasses } from "@/components/ui/button";
import { describedBy, Field, inputClassName } from "@/components/ui/field";
import { signupSchema } from "@/lib/validation/auth";
import { fieldErrorsFromZod } from "@/lib/validation/errors";

const initial = {
  fullName: "",
  email: "",
  password: "",
  confirmPassword: "",
  is18Plus: false,
};

export function SignupForm() {
  const router = useRouter();
  const [values, setValues] = useState(initial);
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitAttempted, setSubmitAttempted] = useState(false);
  const [serverErrors, setServerErrors] = useState<Record<string, string>>({});
  const [message, setMessage] = useState<string | null>(null);
  const [needsConfirmation, setNeedsConfirmation] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const submittingRef = useRef(false);

  const parsed = signupSchema.safeParse(values);
  const clientErrors = parsed.success ? {} : fieldErrorsFromZod(parsed.error);

  function errorFor(field: keyof typeof initial) {
    if (!touched[field] && !submitAttempted) return undefined;
    return serverErrors[field] || clientErrors[field];
  }

  function update<K extends keyof typeof initial>(field: K, value: (typeof initial)[K]) {
    setValues((current) => ({ ...current, [field]: value }));
    setServerErrors((current) => ({ ...current, [field]: "" }));
    setMessage(null);
  }

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submittingRef.current) return;
    setSubmitAttempted(true);
    setMessage(null);
    if (!signupSchema.safeParse(values).success) return;

    submittingRef.current = true;
    setSubmitting(true);
    try {
      const result = await signup(values);
      if (result.ok && result.needsConfirmation) {
        setNeedsConfirmation(true);
        return;
      }
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

  if (needsConfirmation) {
    return (
      <AuthShell title="Check your inbox." lede="We've sent you a confirmation link.">
        <p className="text-base leading-7 text-stone">
          Open the link to finish creating your Clubmates account. You won&apos;t be signed in until
          that confirmation is complete.
        </p>
        <Link href="/" className={`${buttonClasses("primary")} mt-8`}>
          Back to Clubmates
        </Link>
      </AuthShell>
    );
  }

  const nameError = errorFor("fullName");
  const emailError = errorFor("email");
  const passwordError = errorFor("password");
  const confirmError = errorFor("confirmPassword");
  const ageError = errorFor("is18Plus");

  return (
    <AuthShell
      title="Create an account"
      lede="This is separate from early access. You can join the list without a password."
      footer={
        <p>
          Already have an account?{" "}
          <Link href="/login" className="text-ink underline-offset-4 hover:underline">
            Sign in
          </Link>
        </p>
      }
    >
      <form className="space-y-5" onSubmit={onSubmit} noValidate aria-busy={submitting}>
        {message ? (
          <p role="alert" className="rounded-2xl border border-coral/40 bg-coral/10 px-4 py-3 text-sm text-error">
            {message}
          </p>
        ) : null}
        <Field id="signup-name" label="Name" required error={nameError}>
          <input
            id="signup-name"
            name="fullName"
            type="text"
            autoComplete="name"
            required
            disabled={submitting}
            value={values.fullName}
            aria-invalid={Boolean(nameError)}
            aria-describedby={describedBy("signup-name", nameError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, fullName: true }))}
            onChange={(event) => update("fullName", event.target.value)}
          />
        </Field>
        <Field id="signup-email" label="Email" required error={emailError}>
          <input
            id="signup-email"
            name="email"
            type="email"
            inputMode="email"
            autoComplete="email"
            autoCapitalize="none"
            spellCheck={false}
            required
            disabled={submitting}
            value={values.email}
            aria-invalid={Boolean(emailError)}
            aria-describedby={describedBy("signup-email", emailError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, email: true }))}
            onChange={(event) => update("email", event.target.value)}
          />
        </Field>
        <Field id="signup-password" label="Password" required error={passwordError}>
          <input
            id="signup-password"
            name="password"
            type="password"
            autoComplete="new-password"
            required
            disabled={submitting}
            value={values.password}
            aria-invalid={Boolean(passwordError)}
            aria-describedby={describedBy("signup-password", passwordError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, password: true }))}
            onChange={(event) => update("password", event.target.value)}
          />
        </Field>
        <Field id="signup-confirm" label="Confirm password" required error={confirmError}>
          <input
            id="signup-confirm"
            name="confirmPassword"
            type="password"
            autoComplete="new-password"
            required
            disabled={submitting}
            value={values.confirmPassword}
            aria-invalid={Boolean(confirmError)}
            aria-describedby={describedBy("signup-confirm", confirmError)}
            className={inputClassName}
            onBlur={() => setTouched((current) => ({ ...current, confirmPassword: true }))}
            onChange={(event) => update("confirmPassword", event.target.value)}
          />
        </Field>
        <div>
          <label htmlFor="signup-age" className="flex items-start gap-3 text-sm leading-6">
            <input
              id="signup-age"
              name="is18Plus"
              type="checkbox"
              required
              disabled={submitting}
              checked={values.is18Plus}
              aria-invalid={Boolean(ageError)}
              aria-describedby={describedBy("signup-age", ageError)}
              className="mt-0.5 h-5 w-5 shrink-0 accent-aubergine"
              onBlur={() => setTouched((current) => ({ ...current, is18Plus: true }))}
              onChange={(event) => update("is18Plus", event.target.checked)}
            />
            <span>I confirm that I am 18 years of age or older.</span>
          </label>
          {ageError ? (
            <p id="signup-age-error" className="mt-2 text-sm text-error" role="alert">
              {ageError}
            </p>
          ) : null}
        </div>
        <button type="submit" className={`${buttonClasses("primary")} w-full`} disabled={submitting}>
          {submitting ? "Creating account..." : "Create account"}
        </button>
      </form>
    </AuthShell>
  );
}
